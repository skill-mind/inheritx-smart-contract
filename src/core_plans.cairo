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

    // Constants
    const ZERO_ADDRESS: ContractAddress = 0.try_into().unwrap();

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
        // Monthly disbursement storage
        monthly_disbursement_plans: Map<u256, MonthlyDisbursementPlan>, // plan_id -> monthly plan
        monthly_disbursements: Map<u256, MonthlyDisbursement>, // disbursement_id -> disbursement
        disbursement_beneficiaries: Map<
            (u256, u256), DisbursementBeneficiary,
        >, // (plan_id, beneficiary_index) -> beneficiary
        disbursement_beneficiary_count: Map<u256, u8>, // plan_id -> beneficiary count
        monthly_disbursement_count: Map<(), u256>, // Global counter
        monthly_disbursement_execution_count: Map<(), u256> // Execution counter
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        // Plan creation flow events
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
        // Monthly disbursement events
        MonthlyDisbursementPlanCreated: MonthlyDisbursementPlanCreated,
        MonthlyDisbursementExecuted: MonthlyDisbursementExecuted,
        MonthlyDisbursementPaused: MonthlyDisbursementPaused,
        MonthlyDisbursementResumed: MonthlyDisbursementResumed,
        MonthlyDisbursementCancelled: MonthlyDisbursementCancelled,
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
        self.monthly_disbursement_count.write((), 0);
        self.monthly_disbursement_execution_count.write((), 0);

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
            percentage: u8,
            email_hash: ByteArray,
            age: u8,
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

        // Monthly disbursement
        fn create_monthly_disbursement_plan(
            ref self: ContractState,
            total_amount: u256,
            monthly_amount: u256,
            start_month: u64,
            end_month: u64,
            beneficiaries: Array<DisbursementBeneficiary>,
        ) -> u256;

        fn execute_monthly_disbursement(ref self: ContractState, plan_id: u256);

        fn pause_monthly_disbursement(ref self: ContractState, plan_id: u256, reason: ByteArray);

        fn resume_monthly_disbursement(ref self: ContractState, plan_id: u256);

        fn get_monthly_disbursement_status(
            self: @ContractState, plan_id: u256,
        ) -> MonthlyDisbursementPlan;

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

    impl PlansImpl of PlansTrait {
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
        ) -> u256 {
            self.assert_not_paused();
            assert(beneficiaries.len() > 0, ERR_INVALID_INPUT);
            assert(asset_type < 4, ERR_INVALID_ASSET_TYPE);
            assert(asset_amount > 0 || asset_type == 3, ERR_INVALID_INPUT);
            assert(timeframe > 0, ERR_INVALID_INPUT);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            let plan_id = self.plan_count.read() + 1;
            let escrow_id = self.escrow_count.read() + 1;

            // Create inheritance plan
            let plan = InheritancePlan {
                id: plan_id,
                owner: caller,
                beneficiary_count: beneficiaries.len().try_into().unwrap(),
                asset_type: SecurityImpl::u8_to_asset_type(asset_type),
                asset_amount,
                nft_token_id,
                nft_contract,
                timeframe,
                created_at: current_time,
                becomes_active_at: current_time + timeframe,
                guardian,
                encrypted_details,
                status: PlanStatus::Active,
                is_claimed: false,
                claim_code_hash: "",
                inactivity_threshold: 0,
                last_activity: current_time,
                swap_request_id: 0,
                escrow_id,
                security_level,
                auto_execute,
                emergency_contacts_count: 0,
            };

            self.inheritance_plans.write(plan_id, plan);
            self.plan_count.write(plan_id);

            // Store beneficiary count
            self.plan_beneficiary_count.write(plan_id, beneficiaries.len().into());

            // Add beneficiaries to storage maps
            let mut i: u256 = 0;
            while i != beneficiaries.len().into() {
                let beneficiary = *beneficiaries.at(i.try_into().unwrap());
                let beneficiary_index = i + 1;

                let new_beneficiary = Beneficiary {
                    address: beneficiary,
                    email_hash: "", // Empty string for testing
                    percentage: 100, // Default 100% for single beneficiary
                    has_claimed: false,
                    claimed_amount: 0,
                    claim_code_hash: "", // Empty string for testing
                    added_at: current_time,
                    kyc_status: KYCStatus::Pending,
                    relationship: "", // Empty string for testing
                    age: 25, // Default age
                    is_minor: false,
                };

                // Store beneficiary in storage maps
                self.plan_beneficiaries.write((plan_id, beneficiary_index), new_beneficiary);
                self.beneficiary_by_address.write((plan_id, beneficiary), beneficiary_index);

                i += 1;
            }

            // Create escrow account for this plan
            let escrow = EscrowAccount {
                id: escrow_id,
                plan_id,
                asset_type: SecurityImpl::u8_to_asset_type(asset_type),
                amount: asset_amount,
                nft_token_id,
                nft_contract,
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

            // Add to user plans
            let user_plan_count = self.user_plan_count.read(caller);
            self.user_plan_count.write(caller, user_plan_count + 1);

            plan_id
        }

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
        ) -> u256 {
            self.assert_not_paused();
            assert(beneficiary_data.len() > 0, ERR_INVALID_INPUT);
            assert(asset_type < 4, ERR_INVALID_ASSET_TYPE);
            assert(asset_amount > 0 || asset_type == 3, ERR_INVALID_INPUT);
            assert(timeframe > 0, ERR_INVALID_INPUT);

            // Validate that percentages sum to 100%
            let mut total_percentage: u8 = 0;
            let mut i: u32 = 0;
            while i != beneficiary_data.len() {
                let beneficiary = beneficiary_data.at(i).clone();
                total_percentage = total_percentage + beneficiary.percentage;
                i += 1;
            }
            assert(total_percentage == 100, 'Total percentage must equal 100');

            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            let plan_id = self.plan_count.read() + 1;
            let escrow_id = self.escrow_count.read() + 1;

            // Create inheritance plan
            let plan = InheritancePlan {
                id: plan_id,
                owner: caller,
                beneficiary_count: beneficiary_data.len().try_into().unwrap(),
                asset_type: SecurityImpl::u8_to_asset_type(asset_type),
                asset_amount,
                nft_token_id,
                nft_contract,
                timeframe,
                created_at: current_time,
                becomes_active_at: current_time + timeframe,
                guardian,
                encrypted_details,
                status: PlanStatus::Active,
                is_claimed: false,
                claim_code_hash: "",
                inactivity_threshold: 0,
                last_activity: current_time,
                swap_request_id: 0,
                escrow_id,
                security_level,
                auto_execute,
                emergency_contacts_count: emergency_contacts.len().try_into().unwrap(),
            };

            self.inheritance_plans.write(plan_id, plan);
            self.plan_count.write(plan_id);

            // Store beneficiary count
            self.plan_beneficiary_count.write(plan_id, beneficiary_data.len().into());

            // Add beneficiaries to storage maps with their percentages
            let mut i: u256 = 0;
            while i != beneficiary_data.len().into() {
                let beneficiary_data_item = beneficiary_data.at(i.try_into().unwrap()).clone();
                let beneficiary_index = i + 1;

                let beneficiary = Beneficiary {
                    address: beneficiary_data_item.address,
                    email_hash: beneficiary_data_item.email_hash,
                    percentage: beneficiary_data_item.percentage,
                    has_claimed: false,
                    claimed_amount: 0,
                    claim_code_hash: "",
                    added_at: current_time,
                    kyc_status: KYCStatus::Pending,
                    relationship: beneficiary_data_item.relationship,
                    age: beneficiary_data_item.age,
                    is_minor: beneficiary_data_item.age < 18,
                };

                // Store beneficiary
                self.plan_beneficiaries.write((plan_id, beneficiary_index), beneficiary);
                self
                    .beneficiary_by_address
                    .write((plan_id, beneficiary_data_item.address), beneficiary_index);
                i += 1;
            }

            // Create escrow account for this plan
            let escrow = EscrowAccount {
                id: escrow_id,
                plan_id,
                asset_type: SecurityImpl::u8_to_asset_type(asset_type),
                amount: asset_amount,
                nft_token_id,
                nft_contract,
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

            // Add to user plans
            let user_plan_count = self.user_plan_count.read(caller);
            self.user_plan_count.write(caller, user_plan_count + 1);

            plan_id
        }

        fn add_beneficiary_to_plan(
            ref self: ContractState,
            plan_id: u256,
            beneficiary: ContractAddress,
            percentage: u8,
            email_hash: ByteArray,
            age: u8,
            relationship: ByteArray,
        ) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            assert(percentage > 0 && percentage <= 100, ERR_INVALID_PERCENTAGE);
            assert(age <= 120, ERR_INVALID_INPUT);
            assert(beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(email_hash.len() > 0, ERR_INVALID_INPUT);
            assert(relationship.len() > 0, ERR_INVALID_INPUT);

            let current_count = self.plan_beneficiary_count.read(plan_id);
            assert(current_count < 10, ERR_MAX_BENEFICIARIES_REACHED);

            // Check if beneficiary already exists for this plan
            let existing_index = self.beneficiary_by_address.read((plan_id, beneficiary));
            assert(existing_index == 0, ERR_BENEFICIARY_ALREADY_EXISTS);

            // Create new beneficiary
            let beneficiary_index = current_count + 1;
            let new_beneficiary = Beneficiary {
                address: beneficiary,
                email_hash,
                percentage,
                has_claimed: false,
                claimed_amount: 0,
                claim_code_hash: "",
                added_at: get_block_timestamp(),
                kyc_status: KYCStatus::Pending,
                relationship,
                age,
                is_minor: age < 18,
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

                // Update beneficiary with new percentage
                let updated_beneficiary = Beneficiary {
                    address: beneficiary_data_item.address,
                    email_hash: beneficiary_data_item.email_hash,
                    percentage: beneficiary_data_item.percentage,
                    has_claimed: existing_beneficiary.has_claimed,
                    claimed_amount: existing_beneficiary.claimed_amount,
                    claim_code_hash: existing_beneficiary.claim_code_hash,
                    added_at: existing_beneficiary.added_at,
                    kyc_status: existing_beneficiary.kyc_status,
                    relationship: beneficiary_data_item.relationship,
                    age: beneficiary_data_item.age,
                    is_minor: beneficiary_data_item.age < 18,
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
                    percentage: beneficiary.percentage,
                    email_hash: beneficiary.email_hash,
                    age: beneficiary.age,
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

        // ================ PLAN CREATION FLOW FUNCTIONS ================

        fn create_plan_basic_info(
            ref self: ContractState,
            plan_name: ByteArray,
            plan_description: ByteArray,
            owner_email_hash: ByteArray,
            initial_beneficiary: ContractAddress,
            initial_beneficiary_email: ByteArray,
        ) -> u256 {
            self.assert_not_paused();
            assert(plan_name.len() > 0, ERR_INVALID_INPUT);
            assert(plan_description.len() > 0, ERR_INVALID_INPUT);
            assert(owner_email_hash.len() > 0, ERR_INVALID_INPUT);
            assert(initial_beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(initial_beneficiary_email.len() > 0, ERR_INVALID_INPUT);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            let basic_info_id = self.plan_count.read() + 1;

            let plan_name_clone = plan_name.clone();
            let basic_info = BasicPlanInfo {
                plan_name,
                plan_description,
                owner_email_hash,
                initial_beneficiary,
                initial_beneficiary_email,
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
        ) {
            self.assert_not_paused();
            assert(basic_info_id > 0, ERR_INVALID_INPUT);
            assert(beneficiaries.len() > 0, ERR_INVALID_INPUT);
            assert(asset_allocations.len() > 0, ERR_INVALID_INPUT);

            let basic_info = self.basic_plan_info.read(basic_info_id);
            assert(basic_info.created_at != 0, ERR_PLAN_NOT_FOUND);

            let current_time = get_block_timestamp();
            let beneficiary_count = beneficiaries.len().try_into().unwrap();
            let mut total_percentage: u8 = 0;

            // Validate percentages sum to 100%
            let mut i: u32 = 0;
            while i != beneficiaries.len() {
                let beneficiary = beneficiaries.at(i).clone();
                total_percentage = total_percentage + beneficiary.percentage;
                i += 1;
            }
            assert(total_percentage == 100, 'Total percentage must equal 100');

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

            let current_time = get_block_timestamp();

            self
                .emit(
                    RulesConditionsSet {
                        plan_id: basic_info_id,
                        guardian: ZERO_ADDRESS, // Default guardian
                        auto_execute: false, // Default auto_execute
                        set_at: current_time,
                    },
                );
        }

        fn mark_verification_completed(ref self: ContractState, basic_info_id: u256) {
            self.assert_not_paused();
            assert(basic_info_id > 0, ERR_INVALID_INPUT);

            let basic_info = self.basic_plan_info.read(basic_info_id);
            assert(basic_info.created_at != 0, ERR_PLAN_NOT_FOUND);

            let current_time = get_block_timestamp();

            self
                .emit(
                    VerificationCompleted {
                        plan_id: basic_info_id,
                        kyc_status: KYCStatus::Approved,
                        compliance_status: ComplianceStatus::Compliant,
                        verified_at: current_time,
                    },
                );
        }

        fn mark_preview_ready(ref self: ContractState, basic_info_id: u256) {
            self.assert_not_paused();
            assert(basic_info_id > 0, ERR_INVALID_INPUT);

            let basic_info = self.basic_plan_info.read(basic_info_id);
            assert(basic_info.created_at != 0, ERR_PLAN_NOT_FOUND);

            let current_time = get_block_timestamp();

            self
                .emit(
                    PlanPreviewGenerated {
                        plan_id: basic_info_id,
                        validation_status: ValidationStatus::Valid,
                        activation_ready: true,
                        generated_at: current_time,
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

        // ================ MONTHLY DISBURSEMENT FUNCTIONS ================

        fn create_monthly_disbursement_plan(
            ref self: ContractState,
            total_amount: u256,
            monthly_amount: u256,
            start_month: u64,
            end_month: u64,
            beneficiaries: Array<DisbursementBeneficiary>,
        ) -> u256 {
            self.assert_not_paused();
            assert(total_amount > 0, ERR_INVALID_INPUT);
            assert(monthly_amount > 0, ERR_INVALID_INPUT);
            assert(start_month > 0, ERR_INVALID_INPUT);
            assert(end_month > start_month, ERR_INVALID_INPUT);
            assert(beneficiaries.len() > 0, ERR_INVALID_INPUT);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            let plan_id = self.monthly_disbursement_count.read(()) + 1;

            let total_months = (end_month - start_month + 1).try_into().unwrap();

            let monthly_plan = MonthlyDisbursementPlan {
                plan_id,
                owner: caller,
                total_amount,
                monthly_amount,
                start_month,
                end_month,
                total_months,
                completed_months: 0,
                next_disbursement_date: start_month,
                is_active: true,
                beneficiaries_count: beneficiaries.len().try_into().unwrap(),
                disbursement_status: DisbursementStatus::Active,
                created_at: current_time,
                last_activity: current_time,
            };

            self.monthly_disbursement_plans.write(plan_id, monthly_plan);
            self.monthly_disbursement_count.write((), plan_id);

            // Store beneficiaries
            let mut i: u256 = 0;
            while i != beneficiaries.len().into() {
                let beneficiary = beneficiaries.at(i.try_into().unwrap()).clone();
                let beneficiary_index = i + 1;
                self.disbursement_beneficiaries.write((plan_id, beneficiary_index), beneficiary);
                i += 1;
            }

            self
                .disbursement_beneficiary_count
                .write(plan_id, beneficiaries.len().try_into().unwrap());

            self
                .emit(
                    MonthlyDisbursementPlanCreated {
                        plan_id,
                        owner: caller,
                        total_amount,
                        monthly_amount,
                        start_month,
                        end_month,
                        created_at: current_time,
                    },
                );

            plan_id
        }

        fn execute_monthly_disbursement(ref self: ContractState, plan_id: u256) {
            self.assert_not_paused();
            self.assert_only_admin();

            let mut plan = self.monthly_disbursement_plans.read(plan_id);
            assert(plan.plan_id != 0, ERR_PLAN_NOT_FOUND);
            assert(plan.is_active, ERR_PLAN_NOT_ACTIVE);

            let current_time = get_block_timestamp();
            let disbursement_id = self.monthly_disbursement_execution_count.read(()) + 1;

            // Execute disbursement logic here
            plan.completed_months += 1;
            plan.next_disbursement_date += 1;
            plan.last_activity = current_time;

            if plan.completed_months >= plan.total_months {
                plan.is_active = false;
                plan.disbursement_status = DisbursementStatus::Completed;
            }

            // Extract values before moving plan
            let completed_months = plan.completed_months;
            let monthly_amount = plan.monthly_amount;
            let beneficiaries_count = plan.beneficiaries_count;

            self.monthly_disbursement_plans.write(plan_id, plan);
            self.monthly_disbursement_execution_count.write((), disbursement_id);

            self
                .emit(
                    MonthlyDisbursementExecuted {
                        disbursement_id,
                        plan_id,
                        month: completed_months.try_into().unwrap(),
                        amount: monthly_amount,
                        beneficiaries_count,
                        executed_at: current_time,
                        transaction_hash: "" // In real implementation, this would be the actual tx hash
                    },
                );
        }

        fn pause_monthly_disbursement(ref self: ContractState, plan_id: u256, reason: ByteArray) {
            self.assert_not_paused();
            self.assert_only_admin();
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            let mut plan = self.monthly_disbursement_plans.read(plan_id);
            assert(plan.plan_id != 0, ERR_PLAN_NOT_FOUND);
            assert(plan.is_active, ERR_PLAN_NOT_ACTIVE);

            plan.is_active = false;
            plan.disbursement_status = DisbursementStatus::Paused;
            plan.last_activity = get_block_timestamp();

            self.monthly_disbursement_plans.write(plan_id, plan);

            self
                .emit(
                    MonthlyDisbursementPaused {
                        plan_id,
                        paused_at: get_block_timestamp(),
                        paused_by: get_caller_address(),
                        reason,
                    },
                );
        }

        fn resume_monthly_disbursement(ref self: ContractState, plan_id: u256) {
            self.assert_not_paused();
            self.assert_only_admin();

            let mut plan = self.monthly_disbursement_plans.read(plan_id);
            assert(plan.plan_id != 0, ERR_PLAN_NOT_FOUND);
            assert(!plan.is_active, ERR_PLAN_ALREADY_ACTIVE);

            plan.is_active = true;
            plan.disbursement_status = DisbursementStatus::Active;
            plan.last_activity = get_block_timestamp();

            self.monthly_disbursement_plans.write(plan_id, plan);

            self
                .emit(
                    MonthlyDisbursementResumed {
                        plan_id,
                        resumed_at: get_block_timestamp(),
                        resumed_by: get_caller_address(),
                    },
                );
        }

        fn get_monthly_disbursement_status(
            self: @ContractState, plan_id: u256,
        ) -> MonthlyDisbursementPlan {
            self.monthly_disbursement_plans.read(plan_id)
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
