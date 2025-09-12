#[starknet::contract]
pub mod InheritXPlans {
    use core::array::ArrayTrait;
    use core::byte_array::ByteArray;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use crate::base::errors::*;
    use crate::base::events::*;
    use crate::base::types::*;
    use crate::interfaces::iplans::IInheritXPlans;

    // Constants
    const ZERO_ADDRESS: ContractAddress = 0.try_into().unwrap();

    // Helper functions
    fn get_period_interval(method: DistributionMethod) -> u64 {
        match method {
            DistributionMethod::LumpSum => 0,
            DistributionMethod::Quarterly => 7776000, // 3 months
            DistributionMethod::Yearly => 31536000, // 1 year
            DistributionMethod::Monthly => 2592000 // 1 month
        }
    }

    fn u8_to_distribution_method(method: u8) -> DistributionMethod {
        match method {
            0 => DistributionMethod::LumpSum,
            1 => DistributionMethod::Quarterly,
            2 => DistributionMethod::Yearly,
            3 => DistributionMethod::Monthly,
            _ => DistributionMethod::LumpSum,
        }
    }


    // ================ TRAITS ================

    #[generate_trait]
    pub trait PlansSecurityTrait {
        fn assert_not_paused(self: @ContractState);
        fn assert_only_admin(self: @ContractState);
        fn assert_plan_exists(self: @ContractState, plan_id: u256);
        fn assert_plan_owner(self: @ContractState, plan_id: u256);
        fn assert_plan_active(self: @ContractState, plan_id: u256);
        fn u8_to_asset_type(asset_type: u8) -> AssetType;
        fn get_token_address_from_enum(
            self: @ContractState, asset_type: AssetType,
        ) -> ContractAddress;
    }

    // Components
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);

    // Implementations
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        // Core contract state
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        // Admin and configuration
        admin: ContractAddress,
        // Inheritance plans
        inheritance_plans: Map<u256, InheritancePlan>,
        plan_count: u256,
        // User plans - simple counter approach
        user_plan_count: Map<ContractAddress, u256>, // user -> count of plans
        // Beneficiary management - real storage
        plan_beneficiaries: Map<
            (u256, u256), Beneficiary,
        >, // (plan_id, beneficiary_index) -> beneficiary
        plan_beneficiary_count: Map<u256, u256>, // plan_id -> beneficiary count
        beneficiary_by_address: Map<
            (u256, ContractAddress), u256,
        >, // (plan_id, address) -> beneficiary_index
        // Inactivity monitoring - real storage
        inactivity_monitors: Map<ContractAddress, InactivityMonitor>, // wallet_address -> monitor
        // Escrow system
        escrow_accounts: Map<u256, EscrowAccount>, // escrow_id -> escrow account
        escrow_count: u256,
        plan_escrow: Map<u256, u256>, // plan_id -> escrow_id
        // Token addresses
        strk_token: ContractAddress,
        usdt_token: ContractAddress,
        usdc_token: ContractAddress,
        // Security settings
        security_settings: SecuritySettings,
        // Plan creation flow storage
        basic_plan_info: Map<u256, BasicPlanInfo>, // basic_info_id -> basic_info
        plan_rules: Map<u256, PlanRules>, // plan_id -> rules
        verification_data: Map<u256, VerificationData>, // plan_id -> verification
        plan_previews: Map<u256, PlanPreview>, // plan_id -> preview
        plan_asset_allocations: Map<u256, u8>, // plan_id -> allocation count
        // Activity logging
        activity_count: Map<u256, u256>, // plan_id -> activity count
        global_activity_log: Map<u256, ActivityLog>, // activity_id -> activity
        // Plan creation tracking
        plan_creation_steps: Map<u256, PlanCreationStatus>, // plan_id -> creation status
        pending_plans: Map<u256, bool>, // plan_id -> is_pending
        // Distribution storage
        distribution_plans: Map<u256, DistributionPlan>, // plan_id -> distribution plan
        distribution_records: Map<u256, DistributionRecord>, // record_id -> distribution record
        disbursement_beneficiaries: Map<
            (u256, u256), DisbursementBeneficiary,
        >, // (plan_id, beneficiary_index) -> beneficiary
        disbursement_beneficiary_count: Map<u256, u8>, // plan_id -> beneficiary count
        distribution_plan_count: Map<(), u256>, // Global counter
        distribution_record_count: Map<(), u256> // Record counter
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        // Plan creation flow events
        PlanCreated: PlanCreated,
        BasicPlanInfoCreated: BasicPlanInfoCreated,
        AssetAllocationSet: AssetAllocationSet,
        RulesConditionsSet: RulesConditionsSet,
        VerificationCompleted: VerificationCompleted,
        PlanPreviewGenerated: PlanPreviewGenerated,
        PlanActivated: PlanActivated,
        PlanCreationStepCompleted: PlanCreationStepCompleted,
        // Activity logging events
        ActivityLogged: ActivityLogged,
        PlanStatusUpdated: PlanStatusUpdated,
        BeneficiaryModified: BeneficiaryModified,
        // Distribution events
        DistributionPlanCreated: DistributionPlanCreated,
        DistributionExecuted: DistributionExecuted,
        DistributionPaused: DistributionPaused,
        DistributionResumed: DistributionResumed,
        DistributionCancelled: DistributionCancelled,
        DisbursementBeneficiaryAdded: DisbursementBeneficiaryAdded,
        DisbursementBeneficiaryRemoved: DisbursementBeneficiaryRemoved,
        InheritancePlanCreated: InheritancePlanCreated,
        PlanTimeframeExtended: PlanTimeframeExtended,
        PlanParametersUpdated: PlanParametersUpdated,
        InactivityThresholdUpdated: InactivityThresholdUpdated,
    }

    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        strk_token: ContractAddress,
        usdt_token: ContractAddress,
        usdc_token: ContractAddress,
    ) {
        assert(admin != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
        self.admin.write(admin);
        self.strk_token.write(strk_token);
        self.usdt_token.write(usdt_token);
        self.usdc_token.write(usdc_token);
        self.plan_count.write(0);
        self.escrow_count.write(0);
        self.distribution_plan_count.write((), 0);
        self.distribution_record_count.write((), 0);

        // Initialize default security settings
        let default_security = SecuritySettings {
            max_beneficiaries: 10,
            min_timeframe: 86400, // 1 day
            max_timeframe: 31536000, // 1 year
            require_guardian: false,
            allow_early_execution: false,
            max_asset_amount: 1000000000000000000000000, // 1M STRK
            require_multi_sig: false,
            multi_sig_threshold: 2,
            emergency_timeout: 604800 // 7 days
        };
        self.security_settings.write(default_security);
    }

    impl SecurityImpl of PlansSecurityTrait {
        fn assert_not_paused(self: @ContractState) {
            self.pausable.assert_not_paused();
        }

        fn assert_only_admin(self: @ContractState) {
            let caller = get_caller_address();
            let admin = self.admin.read();
            assert(caller == admin, ERR_UNAUTHORIZED);
        }

        fn assert_plan_exists(self: @ContractState, plan_id: u256) {
            let plan = self.inheritance_plans.read(plan_id);
            assert(plan.id != 0, ERR_PLAN_NOT_FOUND);
        }

        fn assert_plan_owner(self: @ContractState, plan_id: u256) {
            let caller = get_caller_address();
            let plan = self.inheritance_plans.read(plan_id);
            assert(plan.owner == caller, ERR_UNAUTHORIZED);
        }

        fn assert_plan_active(self: @ContractState, plan_id: u256) {
            let plan = self.inheritance_plans.read(plan_id);
            assert(plan.status == PlanStatus::Active, ERR_PLAN_NOT_ACTIVE);
        }

        fn u8_to_asset_type(asset_type: u8) -> AssetType {
            if asset_type == 0 {
                AssetType::STRK
            } else if asset_type == 1 {
                AssetType::USDT
            } else if asset_type == 2 {
                AssetType::USDC
            } else {
                AssetType::NFT
            }
        }

        fn get_token_address_from_enum(
            self: @ContractState, asset_type: AssetType,
        ) -> ContractAddress {
            match asset_type {
                AssetType::STRK => self.strk_token.read(),
                AssetType::USDT => self.usdt_token.read(),
                AssetType::USDC => self.usdc_token.read(),
                AssetType::NFT => ZERO_ADDRESS,
            }
        }
    }

    // ================ PLAN MANAGEMENT FUNCTIONS ================

    #[generate_trait]
    pub trait PlansTrait {
        // Plan creation
        fn create_inheritance_plan(
            ref self: ContractState,
            beneficiaries: Array<ContractAddress>,
            asset_type: u8,
            asset_amount: u256,
            nft_token_id: u256,
            nft_contract: ContractAddress,
            timeframe: u64,
            guardian: ContractAddress,
            encrypted_details: ByteArray,
            security_level: u8,
            auto_execute: bool,
            emergency_contacts: Array<ContractAddress>,
        ) -> u256;

        fn create_inheritance_plan_with_percentages(
            ref self: ContractState,
            beneficiary_data: Array<BeneficiaryData>,
            asset_type: u8,
            asset_amount: u256,
            nft_token_id: u256,
            nft_contract: ContractAddress,
            timeframe: u64,
            guardian: ContractAddress,
            encrypted_details: ByteArray,
            security_level: u8,
            auto_execute: bool,
            emergency_contacts: Array<ContractAddress>,
        ) -> u256;

        // Beneficiary management
        fn add_beneficiary_to_plan(
            ref self: ContractState,
            plan_id: u256,
            beneficiary: ContractAddress,
            name: ByteArray,
            email: ByteArray,
            relationship: ByteArray,
        );

        fn remove_beneficiary_from_plan(
            ref self: ContractState, plan_id: u256, beneficiary: ContractAddress, reason: ByteArray,
        );

        fn update_beneficiary_percentages(
            ref self: ContractState, plan_id: u256, beneficiary_data: Array<BeneficiaryData>,
        );

        fn get_beneficiary_percentages(
            self: @ContractState, plan_id: u256,
        ) -> Array<BeneficiaryData>;

        fn get_beneficiaries(self: @ContractState, plan_id: u256) -> Array<Beneficiary>;

        // Plan queries
        fn get_plan_count(self: @ContractState) -> u256;
        fn get_inheritance_plan(self: @ContractState, plan_id: u256) -> InheritancePlan;
        fn get_escrow_details(self: @ContractState, plan_id: u256) -> EscrowAccount;
        fn get_inactivity_monitor(
            self: @ContractState, wallet_address: ContractAddress,
        ) -> InactivityMonitor;
        fn get_beneficiary_count(self: @ContractState, basic_info_id: u256) -> u256;

        // Plan creation flow
        fn create_plan_basic_info(
            ref self: ContractState,
            plan_name: ByteArray,
            plan_description: ByteArray,
            owner_email_hash: ByteArray,
            initial_beneficiary: ContractAddress,
            initial_beneficiary_email: ByteArray,
        ) -> u256;

        fn set_asset_allocation(
            ref self: ContractState,
            basic_info_id: u256,
            beneficiaries: Array<Beneficiary>,
            asset_allocations: Array<AssetAllocation>,
        );

        fn mark_rules_conditions_set(ref self: ContractState, basic_info_id: u256);

        fn mark_verification_completed(ref self: ContractState, basic_info_id: u256);

        fn mark_preview_ready(ref self: ContractState, basic_info_id: u256);

        fn activate_inheritance_plan(
            ref self: ContractState, basic_info_id: u256, activation_confirmation: ByteArray,
        );

        // Plan updates
        fn extend_plan_timeframe(ref self: ContractState, plan_id: u256, additional_time: u64);

        fn update_plan_parameters(
            ref self: ContractState,
            plan_id: u256,
            new_security_level: u8,
            new_auto_execute: bool,
            new_guardian: ContractAddress,
        );

        fn update_inactivity_threshold(ref self: ContractState, plan_id: u256, new_threshold: u64);

        // Unified Distribution methods
        fn create_distribution_plan(
            ref self: ContractState,
            distribution_method: u8, // 0: LumpSum, 1: Quarterly, 2: Yearly, 3: Monthly
            total_amount: u256,
            period_amount: u256,
            start_date: u64,
            end_date: u64,
            beneficiaries: Array<DisbursementBeneficiary>,
        ) -> u256;

        fn execute_distribution(ref self: ContractState, plan_id: u256);

        fn pause_distribution(ref self: ContractState, plan_id: u256, reason: ByteArray);

        fn resume_distribution(ref self: ContractState, plan_id: u256);

        fn get_distribution_status(self: @ContractState, plan_id: u256) -> DistributionPlan;

        // Inactivity monitoring
        fn create_inactivity_monitor(
            ref self: ContractState,
            wallet_address: ContractAddress,
            threshold: u64,
            beneficiary_email_hash: ByteArray,
            plan_id: u256,
        );

        fn update_wallet_activity(ref self: ContractState, wallet_address: ContractAddress);

        fn check_inactivity_status(self: @ContractState, plan_id: u256) -> bool;

        // Security
        fn get_security_settings(self: @ContractState) -> SecuritySettings;

        fn update_security_settings(
            ref self: ContractState,
            max_beneficiaries: u8,
            min_timeframe: u64,
            max_timeframe: u64,
            require_guardian: bool,
            allow_early_execution: bool,
            max_asset_amount: u256,
            require_multi_sig: bool,
            multi_sig_threshold: u8,
            emergency_timeout: u64,
        );
    }

    #[abi(embed_v0)]
    impl InheritXPlans of IInheritXPlans<ContractState> {
        fn create_inheritance_plan(
            ref self: ContractState,
            // Step 1: Plan Creation Name & Description
            plan_name: ByteArray,
            plan_description: ByteArray,
            // Step 2: Add Beneficiary (name, relationship, email)
            beneficiary_name: ByteArray,
            beneficiary_relationship: ByteArray,
            beneficiary_email: ByteArray,
            beneficiary_address: ContractAddress,
            // Step 3: Asset Allocation
            asset_type: u8,
            asset_amount: u256,
            // Step 4: Rules for Plan Creation (distribution method)
            distribution_method: u8, // 0: Lump Sum, 1: Quarterly, 2: Yearly, 3: Monthly
            claim_code: ByteArray // Single 6-digit claim code
        ) -> u256 {
            self.assert_not_paused();
            assert(plan_name.len() > 0, ERR_INVALID_INPUT);
            assert(plan_description.len() > 0, ERR_INVALID_INPUT);
            assert(beneficiary_name.len() > 0, ERR_INVALID_INPUT);
            assert(beneficiary_relationship.len() > 0, ERR_INVALID_INPUT);
            assert(beneficiary_email.len() > 0, ERR_INVALID_INPUT);
            assert(asset_type < 3, ERR_INVALID_ASSET_TYPE); // Only STRK, USDT, USDC (no NFT)
            assert(asset_amount > 0, ERR_INVALID_INPUT);
            assert(claim_code.len() == 6, 'Invalid length');
            assert(distribution_method < 4, 'Invalid method');

            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            let plan_id = self.plan_count.read() + 1;
            let escrow_id = self.escrow_count.read() + 1;

            // Hash the claim code for storage
            let claim_code_hash = self.hash_claim_code(claim_code.clone());

            // Create simplified inheritance plan
            let plan = InheritancePlan {
                id: plan_id,
                owner: caller,
                beneficiary_count: 1,
                asset_type: SecurityImpl::u8_to_asset_type(asset_type),
                asset_amount,
                nft_token_id: 0,
                nft_contract: ZERO_ADDRESS,
                timeframe: 0, // No timeframe needed for distribution methods
                created_at: current_time,
                becomes_active_at: current_time, // Immediate activation
                guardian: ZERO_ADDRESS,
                encrypted_details: "",
                status: PlanStatus::Active,
                is_claimed: false,
                claim_code_hash: claim_code_hash.clone(),
                inactivity_threshold: 0,
                last_activity: current_time,
                swap_request_id: 0,
                escrow_id,
                security_level: 1, // Default security level
                auto_execute: false, // Default auto_execute
                emergency_contacts_count: 0,
            };

            self.inheritance_plans.write(plan_id, plan);
            self.plan_count.write(plan_id);

            // Store beneficiary count
            self.plan_beneficiary_count.write(plan_id, 1);

            // Create simplified beneficiary (name, email, relationship only)
            let new_beneficiary = Beneficiary {
                address: beneficiary_address,
                name: beneficiary_name.clone(),
                email: beneficiary_email.clone(),
                relationship: beneficiary_relationship.clone(),
                claim_code_hash: claim_code_hash.clone(),
                has_claimed: false,
                claimed_amount: 0,
            };

            // Store beneficiary in storage maps
            self.plan_beneficiaries.write((plan_id, 1), new_beneficiary);
            self.beneficiary_by_address.write((plan_id, beneficiary_address), 1);

            // Create escrow account for this plan
            let escrow = EscrowAccount {
                id: escrow_id,
                plan_id,
                asset_type: SecurityImpl::u8_to_asset_type(asset_type),
                amount: asset_amount,
                nft_token_id: 0,
                nft_contract: ZERO_ADDRESS,
                is_locked: false,
                locked_at: 0,
                beneficiary: ZERO_ADDRESS,
                release_conditions_count: 0,
                fees: 0,
                tax_liability: 0,
                last_valuation: current_time,
                valuation_price: 0,
            };

            self.escrow_accounts.write(escrow_id, escrow);
            self.plan_escrow.write(plan_id, escrow_id);
            self.escrow_count.write(escrow_id);

            // Create simplified distribution plan based on selected method
            let (period_interval, total_periods) = match distribution_method {
                0 => (0, 1), // Lump Sum
                1 => (7776000, 4), // Quarterly - 4 quarters (1 year)
                2 => (31536000, 1), // Yearly - 1 year
                3 => (2592000, 12), // Monthly - 12 months
                _ => (0, 1),
            };

            let period_amount = if distribution_method == 0 {
                asset_amount // Lump sum gets full amount
            } else {
                asset_amount / total_periods.into() // Distribute equally across periods
            };

            let distribution_plan = DistributionPlan {
                plan_id,
                owner: caller,
                total_amount: asset_amount,
                distribution_method: u8_to_distribution_method(distribution_method),
                period_amount,
                start_date: current_time,
                end_date: current_time + (period_interval * total_periods),
                total_periods: total_periods.try_into().unwrap(),
                completed_periods: 0,
                next_disbursement_date: current_time,
                is_active: true,
                beneficiaries_count: 1,
                disbursement_status: DisbursementStatus::Pending,
                created_at: current_time,
                last_activity: current_time,
                paused_at: 0,
                resumed_at: 0,
            };

            self.distribution_plans.write(plan_id, distribution_plan);
            self.distribution_plan_count.write((), plan_id);

            // Add to user plans
            let user_plan_count = self.user_plan_count.read(caller);
            self.user_plan_count.write(caller, user_plan_count + 1);

            // Emit comprehensive plan creation event
            self
                .emit(
                    PlanCreated {
                        plan_id,
                        owner: caller,
                        plan_name: plan_name.clone(),
                        plan_description: plan_description.clone(),
                        beneficiary_name: beneficiary_name.clone(),
                        beneficiary_relationship: beneficiary_relationship.clone(),
                        beneficiary_email: beneficiary_email.clone(),
                        asset_type,
                        asset_amount,
                        distribution_method,
                        created_at: current_time,
                    },
                );

            plan_id
        }


        fn add_beneficiary_to_plan(
            ref self: ContractState,
            plan_id: u256,
            beneficiary: ContractAddress,
            name: ByteArray,
            email: ByteArray,
            relationship: ByteArray,
        ) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            assert(beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(name.len() > 0, ERR_INVALID_INPUT);
            assert(email.len() > 0, ERR_INVALID_INPUT);
            assert(relationship.len() > 0, ERR_INVALID_INPUT);

            let current_count = self.plan_beneficiary_count.read(plan_id);
            assert(current_count < 10, ERR_MAX_BENEFICIARIES_REACHED);

            // Check if beneficiary already exists for this plan
            let existing_index = self.beneficiary_by_address.read((plan_id, beneficiary));
            assert(existing_index == 0, ERR_BENEFICIARY_ALREADY_EXISTS);

            // Create new beneficiary (simplified)
            let beneficiary_index = current_count + 1;
            let new_beneficiary = Beneficiary {
                address: beneficiary,
                name,
                email,
                relationship,
                claim_code_hash: "",
                has_claimed: false,
                claimed_amount: 0,
            };

            // Store beneficiary in storage maps
            self.plan_beneficiaries.write((plan_id, beneficiary_index), new_beneficiary);
            self.beneficiary_by_address.write((plan_id, beneficiary), beneficiary_index);
            self.plan_beneficiary_count.write(plan_id, beneficiary_index);

            // Update plan beneficiary count
            let mut plan = self.inheritance_plans.read(plan_id);
            plan.beneficiary_count = beneficiary_index.try_into().unwrap();
            self.inheritance_plans.write(plan_id, plan);
        }

        fn remove_beneficiary_from_plan(
            ref self: ContractState, plan_id: u256, beneficiary: ContractAddress, reason: ByteArray,
        ) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            assert(beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            // Check if beneficiary exists for this plan
            let beneficiary_index = self.beneficiary_by_address.read((plan_id, beneficiary));
            assert(beneficiary_index > 0, ERR_BENEFICIARY_NOT_FOUND);

            // Mark beneficiary as claimed (which effectively removes them from active
            // beneficiaries)
            let mut existing_beneficiary = self
                .plan_beneficiaries
                .read((plan_id, beneficiary_index));
            existing_beneficiary.has_claimed = true;

            // Update the beneficiary record
            self.plan_beneficiaries.write((plan_id, beneficiary_index), existing_beneficiary);

            // Decrease the active beneficiary count
            let current_count = self.plan_beneficiary_count.read(plan_id);
            if current_count > 0 {
                self.plan_beneficiary_count.write(plan_id, current_count - 1);

                // Update plan beneficiary count
                let mut plan = self.inheritance_plans.read(plan_id);
                plan.beneficiary_count = (current_count - 1).try_into().unwrap();
                self.inheritance_plans.write(plan_id, plan);
            }
        }

        fn update_beneficiary_percentages(
            ref self: ContractState, plan_id: u256, beneficiary_data: Array<BeneficiaryData>,
        ) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            assert(beneficiary_data.len() > 0, ERR_INVALID_INPUT);

            // Validate that percentages sum to 100%
            let mut total_percentage: u8 = 0;
            let mut i: u32 = 0;
            while i != beneficiary_data.len() {
                let beneficiary = beneficiary_data.at(i).clone();
                total_percentage = total_percentage + beneficiary.percentage;
                i += 1;
            }
            assert(total_percentage == 100, 'Total percentage must equal 100');

            let _current_time = get_block_timestamp();
            let _caller = get_caller_address();

            // Update beneficiaries with new percentages
            let mut i: u256 = 0;
            while i != beneficiary_data.len().into() {
                let beneficiary_data_item = beneficiary_data.at(i.try_into().unwrap()).clone();
                let beneficiary_index = i + 1;

                // Check if beneficiary exists
                let existing_beneficiary = self
                    .plan_beneficiaries
                    .read((plan_id, beneficiary_index));
                assert(
                    existing_beneficiary.address == beneficiary_data_item.address,
                    'Beneficiary address mismatch',
                );

                // Update beneficiary (simplified)
                let updated_beneficiary = Beneficiary {
                    address: beneficiary_data_item.address,
                    name: "", // Name not provided in this function
                    email: beneficiary_data_item.email_hash,
                    relationship: beneficiary_data_item.relationship,
                    claim_code_hash: existing_beneficiary.claim_code_hash,
                    has_claimed: existing_beneficiary.has_claimed,
                    claimed_amount: existing_beneficiary.claimed_amount,
                };

                // Store updated beneficiary
                self.plan_beneficiaries.write((plan_id, beneficiary_index), updated_beneficiary);

                i += 1;
            }

            // Update beneficiary count if it changed
            let new_count = beneficiary_data.len().try_into().unwrap();
            self.plan_beneficiary_count.write(plan_id, new_count.into());

            // Update plan beneficiary count
            let mut plan = self.inheritance_plans.read(plan_id);
            plan.beneficiary_count = new_count;
            self.inheritance_plans.write(plan_id, plan);
        }

        fn get_beneficiary_percentages(
            self: @ContractState, plan_id: u256,
        ) -> Array<BeneficiaryData> {
            self.assert_plan_exists(plan_id);

            let beneficiary_count = self.plan_beneficiary_count.read(plan_id);
            let mut beneficiaries = ArrayTrait::new();

            let mut i: u256 = 1;
            while i != beneficiary_count + 1 {
                let beneficiary = self.plan_beneficiaries.read((plan_id, i));

                let beneficiary_data = BeneficiaryData {
                    address: beneficiary.address,
                    percentage: 100, // Default percentage for simplified structure
                    email_hash: beneficiary.email,
                    age: 25, // Default age
                    relationship: beneficiary.relationship,
                };

                beneficiaries.append(beneficiary_data);
                i += 1;
            }

            beneficiaries
        }

        fn get_beneficiaries(self: @ContractState, plan_id: u256) -> Array<Beneficiary> {
            let mut beneficiaries = ArrayTrait::new();
            let beneficiary_count = self.plan_beneficiary_count.read(plan_id);

            let mut _i: u256 = 1;
            while _i != beneficiary_count + 1 {
                let beneficiary = self.plan_beneficiaries.read((plan_id, _i));
                if !beneficiary.has_claimed {
                    beneficiaries.append(beneficiary);
                }
                _i += 1;
            }

            beneficiaries
        }

        fn get_plan_count(self: @ContractState) -> u256 {
            self.plan_count.read()
        }

        fn get_inheritance_plan(self: @ContractState, plan_id: u256) -> InheritancePlan {
            self.inheritance_plans.read(plan_id)
        }

        fn get_escrow_details(self: @ContractState, plan_id: u256) -> EscrowAccount {
            // Get the escrow ID for this plan
            let escrow_id = self.plan_escrow.read(plan_id);
            if escrow_id == 0 {
                // Return default escrow if none exists
                return EscrowAccount {
                    id: 0,
                    plan_id: 0,
                    asset_type: AssetType::STRK,
                    amount: 0,
                    nft_token_id: 0,
                    nft_contract: ZERO_ADDRESS,
                    is_locked: false,
                    locked_at: 0,
                    beneficiary: ZERO_ADDRESS,
                    release_conditions_count: 0,
                    fees: 0,
                    tax_liability: 0,
                    last_valuation: 0,
                    valuation_price: 0,
                };
            }

            // Return the actual escrow account
            self.escrow_accounts.read(escrow_id)
        }

        fn get_inactivity_monitor(
            self: @ContractState, wallet_address: ContractAddress,
        ) -> InactivityMonitor {
            let monitor = self.inactivity_monitors.read(wallet_address);

            // If no monitor exists, return a default one
            if monitor.plan_id == 0 {
                return InactivityMonitor {
                    wallet_address,
                    threshold: 0,
                    last_activity: 0,
                    beneficiary_email_hash: "",
                    is_active: false,
                    created_at: 0,
                    triggered_at: 0,
                    plan_id: 0,
                    monitoring_enabled: false,
                };
            }

            monitor
        }

        fn get_beneficiary_count(self: @ContractState, basic_info_id: u256) -> u256 {
            self.plan_beneficiary_count.read(basic_info_id)
        }

        // ================ HELPER FUNCTIONS ================

        fn hash_claim_code(self: @ContractState, code: ByteArray) -> ByteArray {
            // Generate deterministic hash for 6-digit claim codes
            if code.len() == 0 {
                return "empty_code_hash";
            }

            // Validate that the code is exactly 6 digits
            assert(code.len() == 6, 'Invalid claim code length');

            // Process the 6-digit code to create a deterministic hash
            let mut hash_seed: u256 = 0;
            let mut i: u8 = 0;
            let code_len: u8 = 6;

            // Process each byte of the 6-digit code
            while i != code_len {
                let byte = code.at(i.into()).unwrap();
                // Create hash seed by combining bytes with position weighting
                hash_seed = hash_seed + (byte.into() * (i + 1).into());
                i += 1;
            }

            // Generate deterministic hash that fits within felt252
            // Use modulo to ensure the result is within felt252 range
            let hash_mod = hash_seed % 1000000; // 6-digit number

            // Convert to string representation
            if hash_mod == 0 {
                "000000"
            } else if hash_mod < 10 {
                "00000"
            } else if hash_mod < 100 {
                "0000"
            } else if hash_mod < 1000 {
                "000"
            } else if hash_mod < 10000 {
                "00"
            } else if hash_mod < 100000 {
                "0"
            } else {
                ""
            }
        }

        // ================ PLAN CREATION FLOW FUNCTIONS ================

        fn create_plan_basic_info(
            ref self: ContractState,
            plan_name: ByteArray,
            plan_description: ByteArray,
            owner_email_hash: ByteArray,
            initial_beneficiary: ContractAddress,
            initial_beneficiary_email: ByteArray,
            claim_code: ByteArray,
        ) -> u256 {
            self.assert_not_paused();
            assert(plan_name.len() > 0, ERR_INVALID_INPUT);
            assert(plan_description.len() > 0, ERR_INVALID_INPUT);
            assert(owner_email_hash.len() > 0, ERR_INVALID_INPUT);
            assert(initial_beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(initial_beneficiary_email.len() > 0, ERR_INVALID_INPUT);
            assert(claim_code.len() == 6, 'Invalid claim code length');

            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            let basic_info_id = self.plan_count.read() + 1;

            // Hash the claim code for storage
            let claim_code_hash = self.hash_claim_code(claim_code.clone());

            let plan_name_clone = plan_name.clone();
            let basic_info = BasicPlanInfo {
                plan_name,
                plan_description,
                owner_email_hash,
                initial_beneficiary,
                initial_beneficiary_email,
                claim_code_hash,
                created_at: current_time,
                status: PlanCreationStatus::BasicInfoCreated,
            };

            self.basic_plan_info.write(basic_info_id, basic_info);

            self
                .emit(
                    BasicPlanInfoCreated {
                        basic_info_id,
                        owner: caller,
                        plan_name: plan_name_clone,
                        created_at: current_time,
                    },
                );

            basic_info_id
        }

        fn set_asset_allocation(
            ref self: ContractState,
            basic_info_id: u256,
            beneficiaries: Array<Beneficiary>,
            asset_allocations: Array<AssetAllocation>,
            claim_codes: Array<ByteArray>,
        ) {
            self.assert_not_paused();
            assert(basic_info_id > 0, ERR_INVALID_INPUT);
            assert(beneficiaries.len() > 0, ERR_INVALID_INPUT);
            assert(asset_allocations.len() > 0, ERR_INVALID_INPUT);
            assert(claim_codes.len() == beneficiaries.len(), 'Count mismatch');

            let basic_info = self.basic_plan_info.read(basic_info_id);
            assert(basic_info.created_at != 0, ERR_PLAN_NOT_FOUND);

            let current_time = get_block_timestamp();
            let beneficiary_count = beneficiaries.len().try_into().unwrap();
            let mut total_percentage: u8 = 0;

            // Simplified validation - assume equal distribution
            let mut i: u32 = 0;
            while i != beneficiaries.len() {
                total_percentage = total_percentage + 100; // Each gets 100% in simplified structure
                i += 1;
            }

            // Store claim codes for each beneficiary
            let mut i: u32 = 0;
            while i != beneficiaries.len() {
                let claim_code = claim_codes.at(i).clone();
                assert(claim_code.len() == 6, 'Invalid length');
                let claim_code_hash = self.hash_claim_code(claim_code);

                // Store claim code hash for this beneficiary
                let beneficiary = beneficiaries.at(i).clone();
                let mut updated_beneficiary = beneficiary;
                updated_beneficiary.claim_code_hash = claim_code_hash;

                // Store the updated beneficiary back
                self.plan_beneficiaries.write((basic_info_id, i.into() + 1), updated_beneficiary);
                i += 1;
            }

            self.plan_asset_allocations.write(basic_info_id, beneficiary_count);

            self
                .emit(
                    AssetAllocationSet {
                        plan_id: basic_info_id,
                        beneficiary_count,
                        total_percentage,
                        set_at: current_time,
                    },
                );
        }

        fn mark_rules_conditions_set(ref self: ContractState, basic_info_id: u256) {
            self.assert_not_paused();
            assert(basic_info_id > 0, ERR_INVALID_INPUT);
            let basic_info = self.basic_plan_info.read(basic_info_id);
            assert(basic_info.created_at != 0, ERR_PLAN_NOT_FOUND);
            self
                .emit(
                    RulesConditionsSet {
                        plan_id: basic_info_id,
                        guardian: ZERO_ADDRESS,
                        auto_execute: false,
                        set_at: get_block_timestamp(),
                    },
                );
        }

        fn mark_verification_completed(ref self: ContractState, basic_info_id: u256) {
            self.assert_not_paused();
            assert(basic_info_id > 0, ERR_INVALID_INPUT);
            let basic_info = self.basic_plan_info.read(basic_info_id);
            assert(basic_info.created_at != 0, ERR_PLAN_NOT_FOUND);
            self
                .emit(
                    VerificationCompleted {
                        plan_id: basic_info_id,
                        kyc_status: KYCStatus::Approved,
                        compliance_status: ComplianceStatus::Compliant,
                        verified_at: get_block_timestamp(),
                    },
                );
        }

        fn mark_preview_ready(ref self: ContractState, basic_info_id: u256) {
            self.assert_not_paused();
            assert(basic_info_id > 0, ERR_INVALID_INPUT);
            let basic_info = self.basic_plan_info.read(basic_info_id);
            assert(basic_info.created_at != 0, ERR_PLAN_NOT_FOUND);
            self
                .emit(
                    PlanPreviewGenerated {
                        plan_id: basic_info_id,
                        validation_status: ValidationStatus::Valid,
                        activation_ready: true,
                        generated_at: get_block_timestamp(),
                    },
                );
        }


        fn activate_inheritance_plan(
            ref self: ContractState, basic_info_id: u256, activation_confirmation: ByteArray,
        ) {
            self.assert_not_paused();
            assert(basic_info_id > 0, ERR_INVALID_INPUT);
            assert(activation_confirmation.len() > 0, ERR_INVALID_INPUT);

            let basic_info = self.basic_plan_info.read(basic_info_id);
            assert(basic_info.created_at != 0, ERR_PLAN_NOT_FOUND);

            let current_time = get_block_timestamp();

            self
                .emit(
                    PlanActivated {
                        plan_id: basic_info_id,
                        activated_by: get_caller_address(),
                        activated_at: current_time,
                    },
                );
        }

        fn extend_plan_timeframe(ref self: ContractState, plan_id: u256, additional_time: u64) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            assert(additional_time > 0, ERR_INVALID_INPUT);

            let mut plan = self.inheritance_plans.read(plan_id);
            let current_time = get_block_timestamp();
            let new_active_date = plan.becomes_active_at + additional_time;

            plan.becomes_active_at = new_active_date;
            self.inheritance_plans.write(plan_id, plan);

            self
                .emit(
                    PlanTimeframeExtended {
                        plan_id,
                        extended_by: get_caller_address(),
                        additional_time,
                        new_active_date,
                        extended_at: current_time,
                    },
                );
        }

        fn update_plan_parameters(
            ref self: ContractState,
            plan_id: u256,
            new_security_level: u8,
            new_auto_execute: bool,
            new_guardian: ContractAddress,
        ) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            assert(new_security_level <= 3, ERR_INVALID_INPUT);
            assert(new_guardian != ZERO_ADDRESS, ERR_ZERO_ADDRESS);

            let mut plan = self.inheritance_plans.read(plan_id);
            let current_time = get_block_timestamp();

            let old_security_level = plan.security_level;
            let old_auto_execute = plan.auto_execute;
            let old_guardian = plan.guardian;

            plan.security_level = new_security_level;
            plan.auto_execute = new_auto_execute;
            plan.guardian = new_guardian;

            self.inheritance_plans.write(plan_id, plan);

            self
                .emit(
                    PlanParametersUpdated {
                        plan_id,
                        updated_by: get_caller_address(),
                        old_security_level,
                        new_security_level,
                        old_auto_execute,
                        new_auto_execute,
                        old_guardian,
                        new_guardian,
                        updated_at: current_time,
                    },
                );
        }

        fn update_inactivity_threshold(ref self: ContractState, plan_id: u256, new_threshold: u64) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            assert(new_threshold > 0, ERR_INVALID_INPUT);
            assert(new_threshold <= 15768000, ERR_INVALID_INPUT); // Max 6 months

            let mut plan = self.inheritance_plans.read(plan_id);
            let current_time = get_block_timestamp();
            let old_threshold = plan.inactivity_threshold;

            plan.inactivity_threshold = new_threshold;
            self.inheritance_plans.write(plan_id, plan);

            self
                .emit(
                    InactivityThresholdUpdated {
                        plan_id,
                        updated_by: get_caller_address(),
                        old_threshold,
                        new_threshold,
                        updated_at: current_time,
                    },
                );
        }

        // ================ UNIFIED DISTRIBUTION FUNCTIONS ================

        fn create_distribution_plan(
            ref self: ContractState,
            distribution_method: u8, // 0: LumpSum, 1: Quarterly, 2: Yearly, 3: Monthly
            total_amount: u256,
            period_amount: u256,
            start_date: u64,
            end_date: u64,
            beneficiaries: Array<DisbursementBeneficiary>,
        ) -> u256 {
            self.assert_not_paused();
            assert(total_amount > 0, ERR_INVALID_INPUT);
            assert(period_amount > 0, ERR_INVALID_INPUT);
            assert(distribution_method <= 3, 'Invalid distribution method');
            assert(beneficiaries.len() > 0, ERR_INVALID_INPUT);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            let plan_id = self.distribution_plan_count.read(()) + 1;

            // Calculate period interval and total periods based on method
            let (_period_interval, total_periods) = match distribution_method {
                0 => (0, 1), // Lump sum - no intervals
                1 => (7776000, (end_date - start_date) / 7776000), // Quarterly - 3 months
                2 => (31536000, (end_date - start_date) / 31536000), // Yearly - 1 year
                3 => (2592000, (end_date - start_date) / 2592000), // Monthly - 1 month
                _ => (0, 1),
            };

            let distribution_plan = DistributionPlan {
                plan_id,
                owner: caller,
                total_amount,
                distribution_method: u8_to_distribution_method(distribution_method),
                period_amount,
                start_date,
                end_date,
                total_periods: total_periods.try_into().unwrap(),
                completed_periods: 0,
                next_disbursement_date: if distribution_method == 0 {
                    current_time
                } else {
                    start_date
                },
                is_active: true,
                beneficiaries_count: beneficiaries.len().try_into().unwrap(),
                disbursement_status: DisbursementStatus::Pending,
                created_at: current_time,
                last_activity: current_time,
                paused_at: 0,
                resumed_at: 0,
            };

            self.distribution_plans.write(plan_id, distribution_plan);
            self.distribution_plan_count.write((), plan_id);

            // Store beneficiaries
            let mut i: u32 = 0;
            while i != beneficiaries.len() {
                let beneficiary = beneficiaries.at(i).clone();
                let beneficiary_index = i + 1;
                self
                    .disbursement_beneficiaries
                    .write((plan_id, beneficiary_index.into()), beneficiary);
                i += 1;
            }

            self
                .disbursement_beneficiary_count
                .write(plan_id, beneficiaries.len().try_into().unwrap());

            self
                .emit(
                    DistributionPlanCreated {
                        plan_id,
                        owner: caller,
                        distribution_method,
                        total_amount,
                        period_amount,
                        start_date,
                        end_date,
                        created_at: current_time,
                    },
                );

            plan_id
        }

        fn execute_distribution(ref self: ContractState, plan_id: u256) {
            self.assert_not_paused();
            self.assert_only_admin();

            let mut plan = self.distribution_plans.read(plan_id);
            assert(plan.plan_id != 0, ERR_PLAN_NOT_FOUND);
            assert(plan.is_active, ERR_PLAN_NOT_ACTIVE);

            let current_time = get_block_timestamp();
            let record_id = self.distribution_record_count.read(()) + 1;

            // Capture values before moving plan
            let period = plan.completed_periods + 1;
            let amount = plan.period_amount;
            let beneficiaries_count = plan.beneficiaries_count;
            let distribution_method = plan.distribution_method;

            // Create distribution record
            let record = DistributionRecord {
                record_id,
                plan_id,
                period: period.try_into().unwrap(),
                amount,
                status: DisbursementStatus::Active,
                scheduled_date: plan.next_disbursement_date,
                executed_date: current_time,
                beneficiaries_count: beneficiaries_count.try_into().unwrap(),
                transaction_hash: "",
            };

            self.distribution_records.write(record_id, record);
            self.distribution_record_count.write((), record_id);

            // Update plan based on distribution method
            if distribution_method == DistributionMethod::LumpSum {
                plan.is_active = false;
                plan.disbursement_status = DisbursementStatus::Completed;
            } else {
                plan.completed_periods += 1;
                plan.next_disbursement_date += get_period_interval(distribution_method);
                plan.last_activity = current_time;

                if plan.completed_periods >= plan.total_periods {
                    plan.is_active = false;
                    plan.disbursement_status = DisbursementStatus::Completed;
                }
            }

            self.distribution_plans.write(plan_id, plan);

            self
                .emit(
                    DistributionExecuted {
                        plan_id,
                        record_id,
                        period: period.into(),
                        amount,
                        executed_at: current_time,
                        beneficiaries_count,
                    },
                );
        }

        fn pause_distribution(ref self: ContractState, plan_id: u256, reason: ByteArray) {
            self.assert_not_paused();
            self.assert_only_admin();

            let mut plan = self.distribution_plans.read(plan_id);
            assert(plan.plan_id != 0, ERR_PLAN_NOT_FOUND);
            assert(plan.is_active, ERR_PLAN_NOT_ACTIVE);

            plan.is_active = false;
            plan.disbursement_status = DisbursementStatus::Paused;
            plan.last_activity = get_block_timestamp();

            self.distribution_plans.write(plan_id, plan);

            self.emit(DistributionPaused { plan_id, paused_at: get_block_timestamp(), reason });
        }

        fn resume_distribution(ref self: ContractState, plan_id: u256) {
            self.assert_not_paused();
            self.assert_only_admin();

            let mut plan = self.distribution_plans.read(plan_id);
            assert(plan.plan_id != 0, ERR_PLAN_NOT_FOUND);
            assert(!plan.is_active, 'Already active');

            plan.is_active = true;
            plan.disbursement_status = DisbursementStatus::Active;
            plan.last_activity = get_block_timestamp();

            self.distribution_plans.write(plan_id, plan);

            self.emit(DistributionResumed { plan_id, resumed_at: get_block_timestamp() });
        }

        fn get_distribution_status(self: @ContractState, plan_id: u256) -> DistributionPlan {
            self.distribution_plans.read(plan_id)
        }


        // ================ INACTIVITY MONITORING FUNCTIONS ================

        fn create_inactivity_monitor(
            ref self: ContractState,
            wallet_address: ContractAddress,
            threshold: u64,
            beneficiary_email_hash: ByteArray,
            plan_id: u256,
        ) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);

            // Validate inputs
            assert(wallet_address != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(threshold > 0, ERR_INVALID_THRESHOLD);
            assert(threshold <= 15768000, ERR_INVALID_THRESHOLD); // Max 6 months

            let current_time = get_block_timestamp();

            // Create inactivity monitor
            let inactivity_monitor = InactivityMonitor {
                wallet_address,
                threshold,
                last_activity: current_time,
                beneficiary_email_hash,
                is_active: true,
                created_at: current_time,
                triggered_at: 0,
                plan_id,
                monitoring_enabled: true,
            };

            // Store the monitor in the storage map
            self.inactivity_monitors.write(wallet_address, inactivity_monitor);

            // Update the plan's inactivity threshold
            let mut plan = self.inheritance_plans.read(plan_id);
            plan.inactivity_threshold = threshold;
            self.inheritance_plans.write(plan_id, plan);
        }

        fn update_wallet_activity(ref self: ContractState, wallet_address: ContractAddress) {
            self.assert_not_paused();
            assert(wallet_address != ZERO_ADDRESS, ERR_ZERO_ADDRESS);

            let current_time = get_block_timestamp();

            // Update the inactivity monitor for this wallet
            let monitor = self.inactivity_monitors.read(wallet_address);
            if monitor.plan_id > 0 {
                let monitor_plan_id = monitor.plan_id; // Store plan_id before moving monitor

                let mut updated_monitor = monitor;
                updated_monitor.last_activity = current_time;
                self.inactivity_monitors.write(wallet_address, updated_monitor);

                // Also update the plan's last activity
                let mut plan = self.inheritance_plans.read(monitor_plan_id);
                plan.last_activity = current_time;
                self.inheritance_plans.write(monitor_plan_id, plan);
            } else {
                // Fallback: update all plans owned by this wallet
                let user_plan_count = self.user_plan_count.read(wallet_address);
                let mut _i: u256 = 0;

                while _i != user_plan_count {
                    let plan_id = _i + 1;
                    let plan = self.inheritance_plans.read(plan_id);

                    if plan.owner == wallet_address {
                        let mut updated_plan = plan;
                        updated_plan.last_activity = current_time;
                        self.inheritance_plans.write(plan_id, updated_plan);
                    }

                    _i += 1;
                }
            }
        }

        fn check_inactivity_status(self: @ContractState, plan_id: u256) -> bool {
            let plan = self.inheritance_plans.read(plan_id);
            if plan.inactivity_threshold == 0 {
                return false; // No monitoring set
            }

            let current_time = get_block_timestamp();
            let time_since_activity = current_time - plan.last_activity;

            // Check if inactivity threshold has been exceeded
            if time_since_activity >= plan.inactivity_threshold {
                return true; // Inactive
            }

            false // Still active
        }

        // ================ SECURITY FUNCTIONS ================

        fn get_security_settings(self: @ContractState) -> SecuritySettings {
            self.security_settings.read()
        }

        fn update_security_settings(
            ref self: ContractState,
            max_beneficiaries: u8,
            min_timeframe: u64,
            max_timeframe: u64,
            require_guardian: bool,
            allow_early_execution: bool,
            max_asset_amount: u256,
            require_multi_sig: bool,
            multi_sig_threshold: u8,
            emergency_timeout: u64,
        ) {
            self.assert_only_admin();

            let updated_settings = SecuritySettings {
                max_beneficiaries,
                min_timeframe,
                max_timeframe,
                require_guardian,
                allow_early_execution,
                max_asset_amount,
                require_multi_sig,
                multi_sig_threshold,
                emergency_timeout,
            };

            self.security_settings.write(updated_settings);
        }
    }
}
