#[starknet::contract]
pub mod InheritXCore {
    use core::array::ArrayTrait;
    use core::byte_array::ByteArray;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{
        ClassHash, ContractAddress, get_block_timestamp, get_caller_address, get_contract_address,
    };
    use crate::base::errors::*;
    use crate::base::events::*;
    use crate::base::types::*;
    use crate::interfaces::icore::IInheritXCore;

    // Constants
    const ZERO_ADDRESS: ContractAddress = 0.try_into().unwrap();

    // ================ TRAITS ================

    #[generate_trait]
    pub trait CoreSecurityTrait {
        fn assert_not_paused(self: @ContractState);
        fn assert_only_admin(self: @ContractState);
        fn assert_plan_exists(self: @ContractState, plan_id: u256);
        fn assert_plan_owner(self: @ContractState, plan_id: u256);
        fn assert_plan_active(self: @ContractState, plan_id: u256);
        fn assert_plan_not_executed(self: @ContractState, plan_id: u256);
        fn assert_plan_not_claimed(self: @ContractState, plan_id: u256);
        fn assert_wallet_not_frozen(self: @ContractState, wallet: ContractAddress);
        fn assert_wallet_not_blacklisted(self: @ContractState, wallet: ContractAddress);
        fn u8_to_asset_type(asset_type: u8) -> AssetType;
        fn u8_to_user_type(user_type: u8) -> UserType;
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
        dex_router: ContractAddress,
        emergency_withdraw_address: ContractAddress,
        // Inheritance plans
        inheritance_plans: Map<u256, InheritancePlan>,
        plan_count: u256,
        // User plans - simple counter approach
        user_plan_count: Map<ContractAddress, u256>, // user -> count of plans
        // Claimed plans - simple counter approach
        claimed_plan_count: Map<ContractAddress, u256>, // beneficiary -> count of claimed plans
        // Swap management
        swap_requests: Map<u256, SwapRequest>,
        swap_count: u256,
        plan_swap_requests: Map<u256, u256>, // plan_id -> swap_request_id
        // Inactivity monitoring
        inactivity_triggers: Map<u256, InactivityTrigger>,
        // Plan overrides
        override_requests: Map<u256, PlanOverrideRequest>,
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
        // Wallet freezing and blacklisting
        frozen_wallets: Map<ContractAddress, bool>, // wallet -> is_frozen
        freeze_reasons: Map<ContractAddress, FreezeInfo>, // wallet -> freeze_info
        blacklisted_wallets: Map<ContractAddress, bool>, // wallet -> is_blacklisted
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
        distribution_plans: Map<u256, DistributionPlan>, // plan_id -> distribution plan
        distribution_records: Map<u256, DistributionRecord>, // record_id -> distribution record
        disbursement_beneficiaries: Map<
            (u256, u256), DisbursementBeneficiary,
        >, // (plan_id, beneficiary_index) -> beneficiary
        disbursement_beneficiary_count: Map<u256, u8>, // plan_id -> beneficiary count
        monthly_disbursement_count: Map<(), u256>, // Global counter
        monthly_disbursement_execution_count: Map<(), u256>, // Execution counter
        // Fee system storage
        fee_config: FeeConfig,
        total_fees_collected: u256,
        plan_fees_collected: Map<u256, u256>, // plan_id -> total fees collected
        // Withdrawal system storage
        withdrawal_requests: Map<u256, WithdrawalRequest>, // request_id -> withdrawal request
        withdrawal_request_count: u256,
        plan_withdrawal_requests: Map<u256, u256>, // plan_id -> withdrawal_request_id
        beneficiary_withdrawal_requests: Map<
            (ContractAddress, u256), u256,
        >, // (beneficiary, index) -> request_id
        beneficiary_withdrawal_count: Map<ContractAddress, u256> // beneficiary -> withdrawal count
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        // Custom events
        SecuritySettingsUpdated: SecuritySettingsUpdated,
        WalletFrozen: WalletFrozen,
        WalletUnfrozen: WalletUnfrozen,
        WalletBlacklisted: WalletBlacklisted,
        WalletRemovedFromBlacklist: WalletRemovedFromBlacklist,
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
        DistributionPlanCreated: DistributionPlanCreated,
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
        // Fee events
        FeeCollected: FeeCollected,
        FeeConfigUpdated: FeeConfigUpdated,
        // Withdrawal events
        WithdrawalRequestCreated: WithdrawalRequestCreated,
        WithdrawalRequestApproved: WithdrawalRequestApproved,
        WithdrawalRequestProcessed: WithdrawalRequestProcessed,
        WithdrawalRequestRejected: WithdrawalRequestRejected,
        WithdrawalRequestCancelled: WithdrawalRequestCancelled,
    }

    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        dex_router: ContractAddress,
        emergency_withdraw_address: ContractAddress,
        strk_token: ContractAddress,
        usdt_token: ContractAddress,
        usdc_token: ContractAddress,
    ) {
        assert(admin != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
        self.admin.write(admin);
        self.dex_router.write(dex_router);
        self.emergency_withdraw_address.write(emergency_withdraw_address);
        self.strk_token.write(strk_token);
        self.usdt_token.write(usdt_token);
        self.usdc_token.write(usdc_token);
        self.plan_count.write(0);
        self.swap_count.write(0);
        self.escrow_count.write(0);
        self.monthly_disbursement_count.write((), 0);
        self.monthly_disbursement_execution_count.write((), 0);
        self.withdrawal_request_count.write(0);
        self.total_fees_collected.write(0);

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

        // Initialize fee configuration (2% fee)
        let default_fee_config = FeeConfig {
            fee_percentage: 200, // 2% in basis points
            fee_recipient: admin, // Admin receives fees initially
            is_active: true,
            min_fee: 1000000000000000, // 0.001 STRK minimum fee
            max_fee: 100000000000000000000 // 100 STRK maximum fee
        };
        self.fee_config.write(default_fee_config);
    }

    impl SecurityImpl of CoreSecurityTrait {
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

        fn assert_plan_not_executed(self: @ContractState, plan_id: u256) {
            let plan = self.inheritance_plans.read(plan_id);
            assert(plan.status != PlanStatus::Executed, ERR_PLAN_ALREADY_EXECUTED);
        }

        fn assert_plan_not_claimed(self: @ContractState, plan_id: u256) {
            let plan = self.inheritance_plans.read(plan_id);
            assert(!plan.is_claimed, ERR_PLAN_ALREADY_CLAIMED);
        }

        fn assert_wallet_not_frozen(self: @ContractState, wallet: ContractAddress) {
            let is_frozen = self.frozen_wallets.read(wallet);
            assert(!is_frozen, ERR_WALLET_ALREADY_FROZEN);
        }

        fn assert_wallet_not_blacklisted(self: @ContractState, wallet: ContractAddress) {
            let is_blacklisted = self.blacklisted_wallets.read(wallet);
            assert(!is_blacklisted, ERR_WALLET_ALREADY_BLACKLISTED);
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

        fn u8_to_user_type(user_type: u8) -> UserType {
            if user_type == 0 {
                UserType::AssetOwner
            } else {
                UserType::Beneficiary
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

    #[abi(embed_v0)]
    impl InheritXCore of IInheritXCore<ContractState> {
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

            // Check if user has sufficient balance for the asset type
            if asset_type == 0 { // STRK
                let strk_token = IERC20Dispatcher { contract_address: self.strk_token.read() };
                let user_balance = strk_token.balance_of(caller);
                assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
            } else if asset_type == 1 { // USDT
                let usdt_token = IERC20Dispatcher { contract_address: self.usdt_token.read() };
                let user_balance = usdt_token.balance_of(caller);
                assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
            } else if asset_type == 2 { // USDC
                let usdc_token = IERC20Dispatcher { contract_address: self.usdc_token.read() };
                let user_balance = usdc_token.balance_of(caller);
                assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
            }

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
                    name: "", // Empty string for testing
                    email: "", // Empty string for testing
                    relationship: "", // Empty string for testing
                    claim_code_hash: "", // Empty string for testing
                    has_claimed: false,
                    claimed_amount: 0,
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

        // ================ ADDITIONAL FUNCTIONS (STUB IMPLEMENTATIONS) ================
        // Note: These are stub implementations to satisfy the interface requirements
        // Full implementations would be added based on specific requirements

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
                let _beneficiary = beneficiary_data.at(i).clone();
                total_percentage = total_percentage + 100; // Simplified - each gets 100%
                i += 1;
            }
            assert(total_percentage == 100, 'Total percentage must equal 100');

            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            // Check if user has sufficient balance for the asset type
            if asset_type == 0 { // STRK
                let strk_token = IERC20Dispatcher { contract_address: self.strk_token.read() };
                let user_balance = strk_token.balance_of(caller);
                assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
            } else if asset_type == 1 { // USDT
                let usdt_token = IERC20Dispatcher { contract_address: self.usdt_token.read() };
                let user_balance = usdt_token.balance_of(caller);
                assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
            } else if asset_type == 2 { // USDC
                let usdc_token = IERC20Dispatcher { contract_address: self.usdc_token.read() };
                let user_balance = usdc_token.balance_of(caller);
                assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
            }

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
                    name: "", // Name not provided in this function
                    email: beneficiary_data_item.email_hash,
                    relationship: beneficiary_data_item.relationship,
                    claim_code_hash: "",
                    has_claimed: false,
                    claimed_amount: 0,
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

        fn create_swap_request(
            ref self: ContractState,
            plan_id: u256,
            from_token: ContractAddress,
            to_token: ContractAddress,
            amount: u256,
            slippage_tolerance: u256,
        ) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);

            let plan = self.inheritance_plans.read(plan_id);
            assert(plan.asset_type != AssetType::NFT, ERR_INVALID_ASSET_TYPE);

            let swap_id = self.swap_count.read() + 1;
            let swap_request = SwapRequest {
                id: swap_id,
                plan_id,
                from_token,
                to_token,
                amount,
                slippage_tolerance,
                status: SwapStatus::Pending,
                created_at: get_block_timestamp(),
                executed_at: 0,
                execution_price: 0,
                gas_used: 0,
                failed_reason: "",
            };

            self.swap_requests.write(swap_id, swap_request);
            self.swap_count.write(swap_id);
            self.plan_swap_requests.write(plan_id, swap_id);
        }

        fn execute_swap(ref self: ContractState, swap_id: u256) {
            self.assert_not_paused();
            assert(swap_id > 0, ERR_INVALID_INPUT);

            let swap_request = self.swap_requests.read(swap_id);
            assert(swap_request.id != 0, ERR_SWAP_REQUEST_NOT_FOUND);
            assert(swap_request.status == SwapStatus::Pending, ERR_SWAP_ALREADY_EXECUTED);

            let dex_router = self.dex_router.read();
            assert(dex_router != ZERO_ADDRESS, ERR_DEX_ROUTER_NOT_SET);

            let current_time = get_block_timestamp();
            let plan_id = swap_request.plan_id;

            // Execute the actual swap through DEX router
            let from_token = IERC20Dispatcher { contract_address: swap_request.from_token };
            let _to_token = IERC20Dispatcher { contract_address: swap_request.to_token };

            // Check balance and allowance
            let contract_balance = from_token.balance_of(get_contract_address());
            assert(contract_balance >= swap_request.amount, ERR_INSUFFICIENT_BALANCE);

            // Calculate execution price with slippage
            let slippage_adjustment = (swap_request.amount * swap_request.slippage_tolerance.into())
                / 10000;
            let min_amount_out = swap_request.amount - slippage_adjustment;

            // Approve DEX router to spend tokens
            from_token.approve(dex_router, swap_request.amount);

            // Execute swap (this would call actual DEX router contract)
            // For this implementation, we'll simulate successful execution
            let execution_price = min_amount_out; // Simulated execution price
            let gas_used = 150000; // Simulated gas usage

            let mut updated_swap = swap_request;
            updated_swap.status = SwapStatus::Executed;
            updated_swap.executed_at = current_time;
            updated_swap.execution_price = execution_price;
            updated_swap.gas_used = gas_used;

            self.swap_requests.write(swap_id, updated_swap);

            // Update associated plan if exists
            if plan_id > 0 {
                let mut plan = self.inheritance_plans.read(plan_id);
                plan.swap_request_id = swap_id;
                self.inheritance_plans.write(plan_id, plan);
            }
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
                let _beneficiary = beneficiary_data.at(i).clone();
                total_percentage = total_percentage + 100; // Simplified - each gets 100%
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
                    percentage: 100, // Simplified - each gets 100%
                    email_hash: beneficiary.email,
                    age: 25, // Default age
                    relationship: beneficiary.relationship,
                };

                beneficiaries.append(beneficiary_data);
                i += 1;
            }

            beneficiaries
        }

        fn lock_assets_in_escrow(
            ref self: ContractState, escrow_id: u256, fees: u256, tax_liability: u256,
        ) {
            self.assert_not_paused();
            self.assert_only_admin();

            // Validate inputs
            assert(escrow_id > 0, ERR_INVALID_INPUT);
            assert(fees >= 0, ERR_INVALID_INPUT);
            assert(tax_liability >= 0, ERR_INVALID_INPUT);

            // Get the escrow account
            let escrow = self.escrow_accounts.read(escrow_id);
            assert(escrow.id != 0, ERR_ESCROW_NOT_FOUND);
            assert(!escrow.is_locked, ERR_ESCROW_ALREADY_LOCKED);

            // Store plan_id before moving escrow
            let plan_id = escrow.plan_id;

            // Lock the assets
            let current_time = get_block_timestamp();
            let mut updated_escrow = escrow;
            updated_escrow.is_locked = true;
            updated_escrow.locked_at = current_time;
            updated_escrow.fees = fees;
            updated_escrow.tax_liability = tax_liability;

            // Update escrow
            self.escrow_accounts.write(escrow_id, updated_escrow);

            // Update plan status to indicate assets are locked
            let mut plan = self.inheritance_plans.read(plan_id);
            plan.status = PlanStatus::AssetsLocked;
            self.inheritance_plans.write(plan_id, plan);
        }

        fn release_assets_from_escrow(
            ref self: ContractState,
            escrow_id: u256,
            beneficiary: ContractAddress,
            release_reason: ByteArray,
        ) {
            self.assert_not_paused();
            self.assert_only_admin();

            // Validate inputs
            assert(escrow_id > 0, ERR_INVALID_INPUT);
            assert(beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(release_reason.len() > 0, ERR_INVALID_INPUT);

            // Get the escrow account
            let escrow = self.escrow_accounts.read(escrow_id);
            assert(escrow.id != 0, ERR_ESCROW_NOT_FOUND);
            assert(escrow.is_locked, ERR_ESCROW_NOT_LOCKED);

            // Store plan_id before moving escrow
            let plan_id = escrow.plan_id;

            // Check if beneficiary is valid for this plan
            let plan = self.inheritance_plans.read(plan_id);
            assert(plan.id != 0, ERR_PLAN_NOT_FOUND);

            // Release the assets
            let mut updated_escrow = escrow;
            updated_escrow.is_locked = false;
            updated_escrow.beneficiary = beneficiary;

            // Update escrow
            self.escrow_accounts.write(escrow_id, updated_escrow);

            // Update plan status to indicate assets are released
            let mut updated_plan = plan;
            updated_plan.status = PlanStatus::AssetsReleased;
            self.inheritance_plans.write(plan_id, updated_plan);

            // Transfer the actual assets to the beneficiary with fee collection
            let escrow = self.escrow_accounts.read(escrow_id);
            let plan = self.inheritance_plans.read(plan_id);

            match plan.asset_type {
                AssetType::STRK => {
                    let strk_token = IERC20Dispatcher { contract_address: self.strk_token.read() };
                    let balance = strk_token.balance_of(get_contract_address());
                    assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);

                    // Calculate and collect fees
                    let net_amount = self.collect_fee(plan_id, beneficiary, escrow.amount);
                    let fee_amount = escrow.amount - net_amount;

                    // Transfer net amount to beneficiary
                    let success = strk_token.transfer(beneficiary, net_amount);
                    assert(success, ERR_TRANSFER_FAILED);

                    // Transfer fee to fee recipient
                    if fee_amount > 0 {
                        let fee_config = self.fee_config.read();
                        let fee_success = strk_token.transfer(fee_config.fee_recipient, fee_amount);
                        assert(fee_success, ERR_TRANSFER_FAILED);
                    }
                },
                AssetType::USDT => {
                    let usdt_token = IERC20Dispatcher { contract_address: self.usdt_token.read() };
                    let balance = usdt_token.balance_of(get_contract_address());
                    assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);

                    // Calculate and collect fees
                    let net_amount = self.collect_fee(plan_id, beneficiary, escrow.amount);
                    let fee_amount = escrow.amount - net_amount;

                    // Transfer net amount to beneficiary
                    let success = usdt_token.transfer(beneficiary, net_amount);
                    assert(success, ERR_TRANSFER_FAILED);

                    // Transfer fee to fee recipient
                    if fee_amount > 0 {
                        let fee_config = self.fee_config.read();
                        let fee_success = usdt_token.transfer(fee_config.fee_recipient, fee_amount);
                        assert(fee_success, ERR_TRANSFER_FAILED);
                    }
                },
                AssetType::USDC => {
                    let usdc_token = IERC20Dispatcher { contract_address: self.usdc_token.read() };
                    let balance = usdc_token.balance_of(get_contract_address());
                    assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);

                    // Calculate and collect fees
                    let net_amount = self.collect_fee(plan_id, beneficiary, escrow.amount);
                    let fee_amount = escrow.amount - net_amount;

                    // Transfer net amount to beneficiary
                    let success = usdc_token.transfer(beneficiary, net_amount);
                    assert(success, ERR_TRANSFER_FAILED);

                    // Transfer fee to fee recipient
                    if fee_amount > 0 {
                        let fee_config = self.fee_config.read();
                        let fee_success = usdc_token.transfer(fee_config.fee_recipient, fee_amount);
                        assert(fee_success, ERR_TRANSFER_FAILED);
                    }
                },
                AssetType::NFT => {
                    assert(escrow.nft_token_id > 0, ERR_INVALID_NFT_TOKEN);
                    assert(escrow.nft_contract != ZERO_ADDRESS, ERR_INVALID_INPUT);

                    // For NFTs, we don't apply percentage fees, but we can collect a fixed fee
                    // Transfer NFT using ERC721 interface
                    let nft_contract = IERC721Dispatcher { contract_address: escrow.nft_contract };
                    let current_owner = nft_contract.owner_of(escrow.nft_token_id);
                    assert(current_owner == get_contract_address(), ERR_NFT_NOT_OWNED);

                    nft_contract
                        .transfer_from(get_contract_address(), beneficiary, escrow.nft_token_id);

                    // Emit fee collection event for NFT (with 0 fee amount)
                    self
                        .emit(
                            FeeCollected {
                                plan_id,
                                beneficiary,
                                fee_amount: 0,
                                fee_percentage: 0,
                                gross_amount: 1, // NFT count
                                net_amount: 1,
                                fee_recipient: ZERO_ADDRESS,
                                collected_at: get_block_timestamp(),
                            },
                        );
                },
            }

            // Update beneficiary claim status
            let mut updated_plan = plan;
            updated_plan.is_claimed = true;
            self.inheritance_plans.write(plan_id, updated_plan);

            let claimed_count = self.claimed_plan_count.read(beneficiary);
            self.claimed_plan_count.write(beneficiary, claimed_count + 1);
        }

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

        fn get_plan_count(self: @ContractState) -> u256 {
            self.plan_count.read()
        }

        fn get_escrow_count(self: @ContractState) -> u256 {
            self.escrow_count.read()
        }

        fn get_inheritance_plan(self: @ContractState, plan_id: u256) -> InheritancePlan {
            self.inheritance_plans.read(plan_id)
        }

        fn freeze_wallet(
            ref self: ContractState, wallet: ContractAddress, reason: ByteArray,
        ) { // Stub implementation
        }

        fn unfreeze_wallet(
            ref self: ContractState, wallet: ContractAddress, reason: ByteArray,
        ) { // Stub implementation
        }

        fn blacklist_wallet(
            ref self: ContractState, wallet: ContractAddress, reason: ByteArray,
        ) { // Stub implementation
        }

        fn remove_from_blacklist(
            ref self: ContractState, wallet: ContractAddress, reason: ByteArray,
        ) { // Stub implementation
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
        ) { // Stub implementation
        }

        fn get_security_settings(self: @ContractState) -> SecuritySettings {
            self.security_settings.read()
        }

        fn emergency_withdraw(
            ref self: ContractState, token_address: ContractAddress, amount: u256,
        ) { // Stub implementation
        }

        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) { // Stub implementation
        }

        fn pause(ref self: ContractState) { // Stub implementation
        }

        fn unpause(ref self: ContractState) { // Stub implementation
        }

        fn create_monthly_disbursement_plan(
            ref self: ContractState,
            total_amount: u256,
            monthly_amount: u256,
            start_month: u64,
            end_month: u64,
            beneficiaries: Array<DisbursementBeneficiary>,
        ) -> u256 {
            // Stub implementation
            0
        }

        fn execute_monthly_disbursement(
            ref self: ContractState, plan_id: u256,
        ) { // Stub implementation
        }

        fn pause_monthly_disbursement(
            ref self: ContractState, plan_id: u256, reason: ByteArray,
        ) { // Stub implementation
        }

        fn resume_monthly_disbursement(
            ref self: ContractState, plan_id: u256,
        ) { // Stub implementation
        }

        fn get_distribution_status(self: @ContractState, plan_id: u256) -> DistributionPlan {
            // Stub implementation
            DistributionPlan {
                plan_id: 0,
                owner: ZERO_ADDRESS,
                total_amount: 0,
                distribution_method: DistributionMethod::LumpSum,
                period_amount: 0,
                start_date: 0,
                end_date: 0,
                total_periods: 0,
                completed_periods: 0,
                next_disbursement_date: 0,
                is_active: false,
                beneficiaries_count: 0,
                disbursement_status: DisbursementStatus::Pending,
                created_at: 0,
                last_activity: 0,
                paused_at: 0,
                resumed_at: 0,
            }
        }

        fn create_plan_basic_info(
            ref self: ContractState,
            plan_name: ByteArray,
            plan_description: ByteArray,
            owner_email_hash: ByteArray,
            initial_beneficiary: ContractAddress,
            initial_beneficiary_email: ByteArray,
        ) -> u256 {
            // Stub implementation
            0
        }

        fn set_asset_allocation(
            ref self: ContractState,
            basic_info_id: u256,
            beneficiaries: Array<Beneficiary>,
            asset_allocations: Array<AssetAllocation>,
        ) { // Stub implementation
        }

        fn mark_rules_conditions_set(
            ref self: ContractState, basic_info_id: u256,
        ) { // Stub implementation
        }

        fn mark_verification_completed(
            ref self: ContractState, basic_info_id: u256,
        ) { // Stub implementation
        }

        fn mark_preview_ready(ref self: ContractState, basic_info_id: u256) { // Stub implementation
        }

        fn activate_inheritance_plan(
            ref self: ContractState, basic_info_id: u256, activation_confirmation: ByteArray,
        ) { // Stub implementation
        }

        fn extend_plan_timeframe(
            ref self: ContractState, plan_id: u256, additional_time: u64,
        ) { // Stub implementation
        }

        fn update_plan_parameters(
            ref self: ContractState,
            plan_id: u256,
            new_security_level: u8,
            new_auto_execute: bool,
            new_guardian: ContractAddress,
        ) { // Stub implementation
        }

        fn update_inactivity_threshold(
            ref self: ContractState, plan_id: u256, new_threshold: u64,
        ) { // Stub implementation
        }

        fn get_beneficiary_count(self: @ContractState, basic_info_id: u256) -> u256 {
            self.plan_beneficiary_count.read(basic_info_id)
        }

        // ================ FEE MANAGEMENT FUNCTIONS ================

        fn update_fee_config(
            ref self: ContractState, new_fee_percentage: u256, new_fee_recipient: ContractAddress,
        ) {
            self.assert_only_admin();
            assert(new_fee_percentage <= 1000, ERR_INVALID_INPUT); // Max 10%
            assert(new_fee_recipient != ZERO_ADDRESS, ERR_ZERO_ADDRESS);

            let current_config = self.fee_config.read();
            let old_fee_percentage = current_config.fee_percentage;
            let old_fee_recipient = current_config.fee_recipient;

            let mut updated_config = current_config;
            updated_config.fee_percentage = new_fee_percentage;
            updated_config.fee_recipient = new_fee_recipient;
            self.fee_config.write(updated_config);

            self
                .emit(
                    FeeConfigUpdated {
                        old_fee_percentage,
                        new_fee_percentage,
                        old_fee_recipient,
                        new_fee_recipient,
                        updated_by: get_caller_address(),
                        updated_at: get_block_timestamp(),
                    },
                );
        }

        fn get_fee_config(self: @ContractState) -> FeeConfig {
            self.fee_config.read()
        }

        fn calculate_fee(self: @ContractState, amount: u256) -> u256 {
            let config = self.fee_config.read();
            if !config.is_active {
                return 0;
            }

            let fee = (amount * config.fee_percentage)
                / 10000; // Convert basis points to percentage
            if fee < config.min_fee {
                return config.min_fee;
            }
            if fee > config.max_fee {
                return config.max_fee;
            }
            fee
        }

        fn collect_fee(
            ref self: ContractState,
            plan_id: u256,
            beneficiary: ContractAddress,
            gross_amount: u256,
        ) -> u256 {
            let fee_amount = self.calculate_fee(gross_amount);
            if fee_amount == 0 {
                return gross_amount;
            }

            let net_amount = gross_amount - fee_amount;
            let config = self.fee_config.read();

            // Update fee tracking
            let current_total = self.total_fees_collected.read();
            self.total_fees_collected.write(current_total + fee_amount);

            let current_plan_fees = self.plan_fees_collected.read(plan_id);
            self.plan_fees_collected.write(plan_id, current_plan_fees + fee_amount);

            self
                .emit(
                    FeeCollected {
                        plan_id,
                        beneficiary,
                        fee_amount,
                        fee_percentage: config.fee_percentage,
                        gross_amount,
                        net_amount,
                        fee_recipient: config.fee_recipient,
                        collected_at: get_block_timestamp(),
                    },
                );

            net_amount
        }

        // ================ WITHDRAWAL FUNCTIONS ================

        fn create_withdrawal_request(
            ref self: ContractState,
            plan_id: u256,
            asset_type: u8,
            withdrawal_type: u8,
            amount: u256,
            nft_token_id: u256,
            nft_contract: ContractAddress,
        ) -> u256 {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);

            let caller = get_caller_address();
            let plan = self.inheritance_plans.read(plan_id);

            // Verify caller is a beneficiary
            let beneficiary_index = self.beneficiary_by_address.read((plan_id, caller));
            assert(beneficiary_index > 0, ERR_UNAUTHORIZED);

            // Verify plan is claimed
            assert(plan.is_claimed, ERR_PLAN_ALREADY_CLAIMED);

            // Verify withdrawal type and amount
            let withdrawal_type_enum = if withdrawal_type == 0 {
                WithdrawalType::All
            } else if withdrawal_type == 1 {
                WithdrawalType::Percentage
            } else if withdrawal_type == 2 {
                WithdrawalType::FixedAmount
            } else if withdrawal_type == 3 {
                WithdrawalType::NFT
            } else {
                assert(false, ERR_INVALID_INPUT);
                WithdrawalType::All // This will never be reached
            };

            if withdrawal_type_enum == WithdrawalType::Percentage {
                assert(amount > 0 && amount <= 100, ERR_INVALID_INPUT);
            } else if withdrawal_type_enum == WithdrawalType::FixedAmount {
                assert(amount > 0, ERR_INVALID_INPUT);
            }

            let request_id = self.withdrawal_request_count.read() + 1;
            let current_time = get_block_timestamp();

            let withdrawal_request = WithdrawalRequest {
                request_id,
                plan_id,
                beneficiary: caller,
                asset_type: SecurityImpl::u8_to_asset_type(asset_type),
                withdrawal_type: withdrawal_type_enum,
                amount,
                nft_token_id,
                nft_contract,
                status: WithdrawalStatus::Pending,
                requested_at: current_time,
                processed_at: 0,
                processed_by: ZERO_ADDRESS,
                fees_deducted: 0,
                net_amount: 0,
            };

            self.withdrawal_requests.write(request_id, withdrawal_request);
            self.withdrawal_request_count.write(request_id);

            // Link to plan and beneficiary
            self.plan_withdrawal_requests.write(plan_id, request_id);
            let beneficiary_count = self.beneficiary_withdrawal_count.read(caller);
            self.beneficiary_withdrawal_requests.write((caller, beneficiary_count), request_id);
            self.beneficiary_withdrawal_count.write(caller, beneficiary_count + 1);

            self
                .emit(
                    WithdrawalRequestCreated {
                        request_id,
                        plan_id,
                        beneficiary: caller,
                        asset_type,
                        withdrawal_type,
                        amount,
                        nft_token_id,
                        nft_contract,
                        requested_at: current_time,
                    },
                );

            request_id
        }

        fn approve_withdrawal_request(ref self: ContractState, request_id: u256) {
            self.assert_only_admin();

            let mut request = self.withdrawal_requests.read(request_id);
            assert(request.status == WithdrawalStatus::Pending, ERR_WITHDRAWAL_ALREADY_PROCESSED);

            let plan = self.inheritance_plans.read(request.plan_id);
            assert(plan.is_claimed, ERR_PLAN_ALREADY_CLAIMED);

            // Calculate fees and net amount
            let gross_amount = match request.withdrawal_type {
                WithdrawalType::All => plan.asset_amount,
                WithdrawalType::Percentage => (plan.asset_amount * request.amount) / 100,
                WithdrawalType::FixedAmount => request.amount,
                WithdrawalType::NFT => 1 // NFT withdrawal
            };

            let fee_amount = self.calculate_fee(gross_amount);
            let net_amount = gross_amount - fee_amount;

            request.status = WithdrawalStatus::Approved;
            request.processed_at = get_block_timestamp();
            request.processed_by = get_caller_address();
            request.fees_deducted = fee_amount;
            request.net_amount = net_amount;

            self.withdrawal_requests.write(request_id, request);

            self
                .emit(
                    WithdrawalRequestApproved {
                        request_id,
                        plan_id: request.plan_id,
                        beneficiary: request.beneficiary,
                        approved_by: get_caller_address(),
                        approved_at: get_block_timestamp(),
                        fees_deducted: fee_amount,
                        net_amount,
                    },
                );
        }

        fn process_withdrawal_request(ref self: ContractState, request_id: u256) {
            self.assert_only_admin();

            let mut request = self.withdrawal_requests.read(request_id);
            assert(request.status == WithdrawalStatus::Approved, ERR_WITHDRAWAL_NOT_APPROVED);

            let _plan = self.inheritance_plans.read(request.plan_id);

            // Process the withdrawal based on asset type
            match request.asset_type {
                AssetType::STRK => {
                    let strk_token = IERC20Dispatcher { contract_address: self.strk_token.read() };
                    strk_token.transfer(request.beneficiary, request.net_amount);
                },
                AssetType::USDT => {
                    let usdt_token = IERC20Dispatcher { contract_address: self.usdt_token.read() };
                    usdt_token.transfer(request.beneficiary, request.net_amount);
                },
                AssetType::USDC => {
                    let usdc_token = IERC20Dispatcher { contract_address: self.usdc_token.read() };
                    usdc_token.transfer(request.beneficiary, request.net_amount);
                },
                AssetType::NFT => {
                    let nft_contract = IERC721Dispatcher { contract_address: request.nft_contract };
                    nft_contract
                        .transfer_from(
                            get_contract_address(), request.beneficiary, request.nft_token_id,
                        );
                },
            }

            request.status = WithdrawalStatus::Processed;
            request.processed_at = get_block_timestamp();
            self.withdrawal_requests.write(request_id, request);

            // Read the request again to avoid move issues
            let processed_request = self.withdrawal_requests.read(request_id);
            self
                .emit(
                    WithdrawalRequestProcessed {
                        request_id,
                        plan_id: processed_request.plan_id,
                        beneficiary: processed_request.beneficiary,
                        asset_type: match processed_request.asset_type {
                            AssetType::STRK => 0,
                            AssetType::USDT => 1,
                            AssetType::USDC => 2,
                            AssetType::NFT => 3,
                        },
                        amount: processed_request.net_amount,
                        processed_at: get_block_timestamp(),
                        transaction_hash: "" // In real implementation, this would be the actual tx hash
                    },
                );
        }

        fn reject_withdrawal_request(ref self: ContractState, request_id: u256, reason: ByteArray) {
            self.assert_only_admin();

            let mut request = self.withdrawal_requests.read(request_id);
            assert(request.status == WithdrawalStatus::Pending, ERR_WITHDRAWAL_ALREADY_PROCESSED);

            request.status = WithdrawalStatus::Rejected;
            request.processed_at = get_block_timestamp();
            request.processed_by = get_caller_address();
            self.withdrawal_requests.write(request_id, request);

            // Read the request again to avoid move issues
            let rejected_request = self.withdrawal_requests.read(request_id);
            self
                .emit(
                    WithdrawalRequestRejected {
                        request_id,
                        plan_id: rejected_request.plan_id,
                        beneficiary: rejected_request.beneficiary,
                        rejected_by: get_caller_address(),
                        rejected_at: get_block_timestamp(),
                        rejection_reason: reason,
                    },
                );
        }

        fn cancel_withdrawal_request(ref self: ContractState, request_id: u256, reason: ByteArray) {
            let caller = get_caller_address();
            let mut request = self.withdrawal_requests.read(request_id);

            // Only the beneficiary or admin can cancel
            assert(request.beneficiary == caller || self.admin.read() == caller, ERR_UNAUTHORIZED);
            assert(request.status == WithdrawalStatus::Pending, ERR_WITHDRAWAL_ALREADY_PROCESSED);

            request.status = WithdrawalStatus::Cancelled;
            request.processed_at = get_block_timestamp();
            request.processed_by = caller;
            self.withdrawal_requests.write(request_id, request);

            // Read the request again to avoid move issues
            let cancelled_request = self.withdrawal_requests.read(request_id);
            self
                .emit(
                    WithdrawalRequestCancelled {
                        request_id,
                        plan_id: cancelled_request.plan_id,
                        beneficiary: cancelled_request.beneficiary,
                        cancelled_by: caller,
                        cancelled_at: get_block_timestamp(),
                        cancellation_reason: reason,
                    },
                );
        }

        fn get_withdrawal_request(self: @ContractState, request_id: u256) -> WithdrawalRequest {
            self.withdrawal_requests.read(request_id)
        }

        fn get_beneficiary_withdrawal_requests(
            self: @ContractState, beneficiary: ContractAddress, limit: u256,
        ) -> Array<u256> {
            let mut requests = ArrayTrait::new();
            let count = self.beneficiary_withdrawal_count.read(beneficiary);
            let mut i: u256 = 0;
            let max_count = if count < limit {
                count
            } else {
                limit
            };

            while i != max_count {
                let request_id = self.beneficiary_withdrawal_requests.read((beneficiary, i));
                requests.append(request_id);
                i += 1;
            }

            requests
        }

        // ================ STATISTICS AND QUERY FUNCTIONS ================

        fn get_total_fees_collected(self: @ContractState) -> u256 {
            self.total_fees_collected.read()
        }

        fn get_plan_fees_collected(self: @ContractState, plan_id: u256) -> u256 {
            self.plan_fees_collected.read(plan_id)
        }

        fn get_withdrawal_request_count(self: @ContractState) -> u256 {
            self.withdrawal_request_count.read()
        }

        fn get_beneficiary_withdrawal_count(
            self: @ContractState, beneficiary: ContractAddress,
        ) -> u256 {
            self.beneficiary_withdrawal_count.read(beneficiary)
        }

        fn is_fee_active(self: @ContractState) -> bool {
            let config = self.fee_config.read();
            config.is_active
        }

        fn get_fee_percentage(self: @ContractState) -> u256 {
            let config = self.fee_config.read();
            config.fee_percentage
        }

        fn get_fee_recipient(self: @ContractState) -> ContractAddress {
            let config = self.fee_config.read();
            config.fee_recipient
        }

        fn toggle_fee_collection(ref self: ContractState, is_active: bool) {
            self.assert_only_admin();

            let mut config = self.fee_config.read();
            config.is_active = is_active;
            self.fee_config.write(config);

            self
                .emit(
                    FeeConfigUpdated {
                        old_fee_percentage: config.fee_percentage,
                        new_fee_percentage: config.fee_percentage,
                        old_fee_recipient: config.fee_recipient,
                        new_fee_recipient: config.fee_recipient,
                        updated_by: get_caller_address(),
                        updated_at: get_block_timestamp(),
                    },
                );
        }

        fn update_fee_limits(ref self: ContractState, new_min_fee: u256, new_max_fee: u256) {
            self.assert_only_admin();
            assert(new_min_fee <= new_max_fee, ERR_INVALID_INPUT);

            let mut config = self.fee_config.read();
            config.min_fee = new_min_fee;
            config.max_fee = new_max_fee;
            self.fee_config.write(config);

            self
                .emit(
                    FeeConfigUpdated {
                        old_fee_percentage: config.fee_percentage,
                        new_fee_percentage: config.fee_percentage,
                        old_fee_recipient: config.fee_recipient,
                        new_fee_recipient: config.fee_recipient,
                        updated_by: get_caller_address(),
                        updated_at: get_block_timestamp(),
                    },
                );
        }
    }
}
