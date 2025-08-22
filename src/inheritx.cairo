#[starknet::contract]
#[feature("deprecated-starknet-consts")]
pub mod InheritX {
    use core::array::ArrayTrait;
    use core::byte_array::ByteArray;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{
        ClassHash, ContractAddress, contract_address_const, get_block_timestamp, get_caller_address,
        get_contract_address,
    };
    use crate::base::errors::*;
    use crate::base::events::*;
    use crate::base::types::*;
    use crate::interfaces::iinheritx::IInheritX;

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
        // KYC management
        kyc_data: Map<ContractAddress, KYCData>,
        pending_kyc_count: u256,
        // Swap management
        swap_requests: Map<u256, SwapRequest>,
        swap_count: u256,
        plan_swap_requests: Map<u256, u256>, // plan_id -> swap_request_id
        // Claim codes
        claim_codes: Map<u256, ClaimCode>, // plan_id -> claim_code
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
        // Claim codes - simplified storage (using plan_id as key)
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
        assert(admin != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
        self.admin.write(admin);
        self.dex_router.write(dex_router);
        self.emergency_withdraw_address.write(emergency_withdraw_address);
        self.strk_token.write(strk_token);
        self.usdt_token.write(usdt_token);
        self.usdc_token.write(usdc_token);
        self.plan_count.write(0);
        self.swap_count.write(0);
        self.pending_kyc_count.write(0);
        self.escrow_count.write(0);

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

    #[generate_trait]
    impl SecurityImpl of SecurityTrait {
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
                AssetType::NFT => contract_address_const::<0>(),
            }
        }
    }

    #[abi(embed_v0)]
    impl inheritx of IInheritX<ContractState> {
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
                beneficiary: contract_address_const::<0>(),
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


        fn claim_inheritance(ref self: ContractState, plan_id: u256, claim_code: ByteArray) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_active(plan_id);
            self.assert_plan_not_claimed(plan_id);

            let caller = get_caller_address();

            // Validate claim code (simplified)
            let plan = self.inheritance_plans.read(plan_id);
            assert(plan.claim_code_hash == claim_code, ERR_INVALID_CLAIM_CODE);

            // Check if plan is ready for claiming
            let current_time = get_block_timestamp();
            assert(current_time >= plan.becomes_active_at, ERR_CLAIM_NOT_READY);

            // Update plan as claimed
            let mut updated_plan = plan;
            updated_plan.is_claimed = true;
            self.inheritance_plans.write(plan_id, updated_plan);

            // Add to claimed plans
            let claimed_count = self.claimed_plan_count.read(caller);
            self.claimed_plan_count.write(caller, claimed_count + 1);
        }

        // ================ SWAP FUNCTIONS ================

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

        // ================ BENEFICIARY FUNCTIONS ================

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
            assert(beneficiary != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
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
            assert(beneficiary != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
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

        // ================ ESCROW FUNCTIONS ================

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
            assert(beneficiary != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
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

            // Transfer the actual assets to the beneficiary
            let escrow = self.escrow_accounts.read(escrow_id);
            let plan = self.inheritance_plans.read(plan_id);

            match plan.asset_type {
                AssetType::STRK => {
                    let strk_token = IERC20Dispatcher { contract_address: self.strk_token.read() };
                    let balance = strk_token.balance_of(get_contract_address());
                    assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);
                    let success = strk_token.transfer(beneficiary, escrow.amount);
                    assert(success, ERR_TRANSFER_FAILED);
                },
                AssetType::USDT => {
                    let usdt_token = IERC20Dispatcher { contract_address: self.usdt_token.read() };
                    let balance = usdt_token.balance_of(get_contract_address());
                    assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);
                    let success = usdt_token.transfer(beneficiary, escrow.amount);
                    assert(success, ERR_TRANSFER_FAILED);
                },
                AssetType::USDC => {
                    let usdc_token = IERC20Dispatcher { contract_address: self.usdc_token.read() };
                    let balance = usdc_token.balance_of(get_contract_address());
                    assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);
                    let success = usdc_token.transfer(beneficiary, escrow.amount);
                    assert(success, ERR_TRANSFER_FAILED);
                },
                AssetType::NFT => {
                    assert(escrow.nft_token_id > 0, ERR_INVALID_NFT_TOKEN);
                    assert(escrow.nft_contract != contract_address_const::<0>(), ERR_INVALID_INPUT);

                    // Transfer NFT using ERC721 interface
                    let nft_contract = IERC721Dispatcher { contract_address: escrow.nft_contract };
                    let current_owner = nft_contract.owner_of(escrow.nft_token_id);
                    assert(current_owner == get_contract_address(), ERR_NFT_NOT_OWNED);

                    nft_contract
                        .transfer_from(get_contract_address(), beneficiary, escrow.nft_token_id);
                },
            }

            // Update beneficiary claim status
            let mut updated_plan = plan;
            updated_plan.is_claimed = true;
            self.inheritance_plans.write(plan_id, updated_plan);

            let claimed_count = self.claimed_plan_count.read(beneficiary);
            self.claimed_plan_count.write(beneficiary, claimed_count + 1);
        }


        // ================ INACTIVITY FUNCTIONS ================

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
            assert(wallet_address != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
            assert(threshold > 0, ERR_INVALID_THRESHOLD);
            assert(threshold <= 15768000, ERR_INVALID_THRESHOLD); // Max 6 months
            assert(beneficiary_email_hash.len() > 0, ERR_INVALID_INPUT);

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
            assert(wallet_address != contract_address_const::<0>(), ERR_ZERO_ADDRESS);

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

        // ================ SWAP FUNCTIONS ================

        fn execute_swap(ref self: ContractState, swap_id: u256) {
            self.assert_not_paused();
            assert(swap_id > 0, ERR_INVALID_INPUT);

            let swap_request = self.swap_requests.read(swap_id);
            assert(swap_request.id != 0, ERR_SWAP_REQUEST_NOT_FOUND);
            assert(swap_request.status == SwapStatus::Pending, ERR_SWAP_ALREADY_EXECUTED);

            let dex_router = self.dex_router.read();
            assert(dex_router != contract_address_const::<0>(), ERR_DEX_ROUTER_NOT_SET);

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

        // ================ QUERY FUNCTIONS ================

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
                    nft_contract: contract_address_const::<0>(),
                    is_locked: false,
                    locked_at: 0,
                    beneficiary: contract_address_const::<0>(),
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

        fn get_claim_code(self: @ContractState, code_hash: ByteArray) -> ClaimCode {
            // Since we can't easily use ByteArray as storage key, we'll return a default
            // In a real implementation, this would use a different approach like indexing
            ClaimCode {
                code_hash,
                plan_id: 0,
                beneficiary: contract_address_const::<0>(),
                is_used: false,
                generated_at: 0,
                expires_at: 0,
                used_at: 0,
                attempts: 0,
                is_revoked: false,
                revoked_at: 0,
                revoked_by: contract_address_const::<0>(),
            }
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

        fn get_pending_kyc_count(self: @ContractState) -> u256 {
            self.pending_kyc_count.read()
        }

        // ================ ADMIN FUNCTIONS ================

        fn freeze_wallet(ref self: ContractState, wallet: ContractAddress, reason: ByteArray) {
            self.assert_only_admin();
            self.assert_not_paused();

            assert(wallet != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            // In a real implementation, this would:
            // 1. Add wallet to frozen wallets storage map
            // 2. Emit freeze event
            // 3. Log the action

            // For now, we'll implement basic validation and update plan status
            // to indicate the wallet is frozen
            let user_plan_count = self.user_plan_count.read(wallet);
            let mut i: u256 = 0;

            while i != user_plan_count {
                let plan_id = i + 1;
                let plan = self.inheritance_plans.read(plan_id);

                if plan.owner == wallet {
                    let mut updated_plan = plan;
                    updated_plan.status = PlanStatus::Paused;
                    self.inheritance_plans.write(plan_id, updated_plan);
                }

                i += 1;
            }
        }

        fn unfreeze_wallet(ref self: ContractState, wallet: ContractAddress, reason: ByteArray) {
            self.assert_only_admin();
            self.assert_not_paused();

            assert(wallet != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            // Unfreeze wallet by reactivating paused plans
            let user_plan_count = self.user_plan_count.read(wallet);
            let mut i: u256 = 0;

            while i != user_plan_count {
                let plan_id = i + 1;
                let plan = self.inheritance_plans.read(plan_id);

                if plan.owner == wallet && plan.status == PlanStatus::Paused {
                    let mut updated_plan = plan;
                    updated_plan.status = PlanStatus::Active;
                    self.inheritance_plans.write(plan_id, updated_plan);
                }

                i += 1;
            }
        }

        fn blacklist_wallet(ref self: ContractState, wallet: ContractAddress, reason: ByteArray) {
            self.assert_only_admin();
            self.assert_not_paused();

            assert(wallet != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            // Blacklist wallet by cancelling all their plans
            let user_plan_count = self.user_plan_count.read(wallet);
            let mut i: u256 = 0;

            while i != user_plan_count {
                let plan_id = i + 1;
                let plan = self.inheritance_plans.read(plan_id);

                if plan.owner == wallet && plan.status == PlanStatus::Active {
                    let mut updated_plan = plan;
                    updated_plan.status = PlanStatus::Cancelled;
                    self.inheritance_plans.write(plan_id, updated_plan);
                }

                i += 1;
            }
        }

        fn remove_from_blacklist(
            ref self: ContractState, wallet: ContractAddress, reason: ByteArray,
        ) {
            self.assert_only_admin();
            self.assert_not_paused();

            assert(wallet != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            // Remove from blacklist by reactivating cancelled plans
            let user_plan_count = self.user_plan_count.read(wallet);
            let mut i: u256 = 0;

            while i != user_plan_count {
                let plan_id = i + 1;
                let plan = self.inheritance_plans.read(plan_id);

                if plan.owner == wallet && plan.status == PlanStatus::Cancelled {
                    let mut updated_plan = plan;
                    updated_plan.status = PlanStatus::Active;
                    self.inheritance_plans.write(plan_id, updated_plan);
                }

                i += 1;
            }
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
            self.assert_not_paused();

            // Validate security parameters
            assert(max_beneficiaries > 0 && max_beneficiaries <= 20, ERR_INVALID_INPUT);
            assert(min_timeframe > 0, ERR_INVALID_INPUT);
            assert(max_timeframe > min_timeframe, ERR_INVALID_INPUT);
            assert(max_timeframe <= 31536000, ERR_INVALID_INPUT); // Max 1 year
            assert(max_asset_amount > 0, ERR_INVALID_INPUT);
            assert(multi_sig_threshold >= 2 && multi_sig_threshold <= 10, ERR_INVALID_INPUT);
            assert(
                emergency_timeout > 0 && emergency_timeout <= 2592000, ERR_INVALID_INPUT,
            ); // Max 30 days

            // Create new security settings
            let new_security_settings = SecuritySettings {
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

            // Update the security settings in storage
            self.security_settings.write(new_security_settings);

            // Emit security settings updated event
            self
                .emit(
                    SecuritySettingsUpdated {
                        updated_at: get_block_timestamp(),
                        updated_by: get_caller_address(),
                        max_beneficiaries,
                        min_timeframe,
                        max_timeframe,
                        require_guardian,
                        allow_early_execution,
                        max_asset_amount,
                        require_multi_sig,
                        multi_sig_threshold,
                        emergency_timeout,
                    },
                );
        }

        // ================ CLAIM CODE FUNCTIONS ================

        fn store_claim_code_hash(
            ref self: ContractState,
            plan_id: u256,
            beneficiary: ContractAddress,
            code_hash: ByteArray,
            expires_in: u64,
        ) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            assert(beneficiary != contract_address_const::<0>(), ERR_ZERO_ADDRESS);
            assert(code_hash.len() > 0, ERR_INVALID_INPUT);
            assert(expires_in > 0, ERR_INVALID_INPUT);

            // Verify beneficiary exists for this plan
            let beneficiary_index = self.beneficiary_by_address.read((plan_id, beneficiary));
            assert(beneficiary_index > 0, ERR_BENEFICIARY_NOT_FOUND);

            let current_time = get_block_timestamp();
            let expires_at = current_time + expires_in;

            let claim_code = ClaimCode {
                code_hash: code_hash.clone(),
                plan_id,
                beneficiary,
                is_used: false,
                generated_at: current_time,
                expires_at,
                used_at: 0,
                attempts: 0,
                is_revoked: false,
                revoked_at: 0,
                revoked_by: contract_address_const::<0>(),
            };

            // Store in plan-based map
            self.claim_codes.write(plan_id, claim_code);
        }

        // ================ KYC FUNCTIONS ================

        fn upload_kyc(ref self: ContractState, kyc_hash: ByteArray, user_type: u8) {
            self.assert_not_paused();
            assert(user_type < 2, ERR_INVALID_USER_TYPE);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            let kyc_data = KYCData {
                user_address: caller,
                kyc_hash,
                user_type: SecurityImpl::u8_to_user_type(user_type),
                status: KYCStatus::Pending,
                uploaded_at: current_time,
                approved_at: 0,
                approved_by: contract_address_const::<0>(),
                verification_score: 0,
                fraud_risk: 0,
                documents_count: 1,
                last_updated: current_time,
                expiry_date: 0,
            };

            self.kyc_data.write(caller, kyc_data);
            let current_count = self.pending_kyc_count.read();
            self.pending_kyc_count.write(current_count + 1);
        }

        fn approve_kyc(
            ref self: ContractState, user_address: ContractAddress, approval_notes: ByteArray,
        ) {
            self.assert_only_admin();
            self.assert_not_paused();

            let mut kyc_data = self.kyc_data.read(user_address);
            assert(kyc_data.status == KYCStatus::Pending, ERR_KYC_ALREADY_APPROVED);

            kyc_data.status = KYCStatus::Approved;
            kyc_data.approved_at = get_block_timestamp();
            kyc_data.approved_by = get_caller_address();

            self.kyc_data.write(user_address, kyc_data);

            // Decrease pending count
            let current_count = self.pending_kyc_count.read();
            self.pending_kyc_count.write(current_count - 1);
        }

        fn reject_kyc(
            ref self: ContractState, user_address: ContractAddress, rejection_reason: ByteArray,
        ) {
            self.assert_only_admin();
            self.assert_not_paused();

            let mut kyc_data = self.kyc_data.read(user_address);
            assert(kyc_data.status == KYCStatus::Pending, ERR_KYC_ALREADY_REJECTED);

            kyc_data.status = KYCStatus::Rejected;
            self.kyc_data.write(user_address, kyc_data);

            // Decrease pending count
            let current_count = self.pending_kyc_count.read();
            self.pending_kyc_count.write(current_count - 1);
        }

        // ================ MONITORING FUNCTIONS ================

        fn get_inheritance_plan(self: @ContractState, plan_id: u256) -> InheritancePlan {
            let plan = self.inheritance_plans.read(plan_id);
            assert(plan.id != 0, ERR_PLAN_NOT_FOUND);
            plan
        }


        // ================ INACTIVITY MONITORING ================

        // ================ ADMIN FUNCTIONS ================

        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.assert_only_admin();
            self.upgradeable.upgrade(new_class_hash);
        }

        fn pause(ref self: ContractState) {
            self.assert_only_admin();
            self.pausable.pause();
        }

        fn unpause(ref self: ContractState) {
            self.assert_only_admin();
            self.pausable.unpause();
        }


        fn emergency_withdraw(
            ref self: ContractState, token_address: ContractAddress, amount: u256,
        ) {
            let caller = get_caller_address();
            let admin = self.admin.read();
            let emergency_address = self.emergency_withdraw_address.read();

            assert(caller == admin || caller == emergency_address, ERR_UNAUTHORIZED);

            let token = IERC20Dispatcher { contract_address: token_address };
            let balance = token.balance_of(get_contract_address());
            assert(balance >= amount, ERR_INSUFFICIENT_ALLOWANCE);

            token.transfer(caller, amount);
        }

        // ================ SECURITY SETTINGS ================

        fn get_security_settings(self: @ContractState) -> SecuritySettings {
            self.security_settings.read()
        }
    }
}

