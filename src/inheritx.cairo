#[starknet::contract]
#[feature("deprecated-starknet-consts")]
pub mod InheritX {
    use core::array::ArrayTrait;
    use core::byte_array::ByteArray;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
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
        // Beneficiary management - simple approach
        plan_beneficiary_count: Map<u256, u256>, // plan_id -> beneficiary count
        // Token addresses
        strk_token: ContractAddress,
        usdt_token: ContractAddress,
        usdc_token: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        // Custom events will be added here
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
            timeframe: u64,
            guardian: ContractAddress,
            encrypted_details: ByteArray,
        ) -> u256 {
            self.assert_not_paused();
            assert(beneficiaries.len() > 0, ERR_INVALID_INPUT);
            assert(asset_type < 4, ERR_INVALID_ASSET_TYPE);
            assert(asset_amount > 0 || asset_type == 3, ERR_INVALID_INPUT);
            assert(timeframe > 0, ERR_INVALID_INPUT);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            let plan_id = self.plan_count.read() + 1;

            // Create inheritance plan
            let plan = InheritancePlan {
                id: plan_id,
                owner: caller,
                beneficiary_count: beneficiaries.len().try_into().unwrap(),
                asset_type: SecurityImpl::u8_to_asset_type(asset_type),
                asset_amount,
                nft_token_id,
                nft_contract: contract_address_const::<0>(),
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
            };

            self.inheritance_plans.write(plan_id, plan);
            self.plan_count.write(plan_id);

            // Store beneficiary count
            self.plan_beneficiary_count.write(plan_id, beneficiaries.len().into());

            // Add to user plans
            let user_plan_count = self.user_plan_count.read(caller);
            self.user_plan_count.write(caller, user_plan_count + 1);

            plan_id
        }

        fn execute_plan_immediately(ref self: ContractState, plan_id: u256) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            self.assert_plan_active(plan_id);
            self.assert_plan_not_executed(plan_id);

            let mut plan = self.inheritance_plans.read(plan_id);
            plan.status = PlanStatus::Executed;
            self.inheritance_plans.write(plan_id, plan.clone());
        }

        fn override_inheritance_plan(
            ref self: ContractState,
            plan_id: u256,
            new_beneficiaries: Array<ContractAddress>,
            new_timeframe: u64,
            new_encrypted_details: ByteArray,
        ) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            self.assert_plan_active(plan_id);

            // Validate new parameters
            assert(new_beneficiaries.len() > 0, ERR_INVALID_INPUT);
            assert(new_timeframe > 0, ERR_INVALID_INPUT);

            let current_time = get_block_timestamp();
            let new_active_time = current_time + new_timeframe;
            assert(new_active_time > current_time, ERR_INVALID_TIMEFRAME);

            // Clone the encrypted details since we need to use it twice
            let encrypted_details_clone = new_encrypted_details.clone();

            // Create override request
            let override_request = PlanOverrideRequest {
                plan_id,
                new_beneficiary_count: new_beneficiaries.len().try_into().unwrap(),
                new_timeframe,
                new_encrypted_details: encrypted_details_clone,
                requester: get_caller_address(),
                requested_at: current_time,
                is_approved: false,
            };

            self.override_requests.write(plan_id, override_request);

            // Update beneficiary count
            self.plan_beneficiary_count.write(plan_id, new_beneficiaries.len().into());

            // Update plan
            let mut plan = self.inheritance_plans.read(plan_id);
            plan.status = PlanStatus::Overridden;
            plan.timeframe = new_timeframe;
            plan.encrypted_details = new_encrypted_details;
            plan.beneficiary_count = new_beneficiaries.len().try_into().unwrap();
            self.inheritance_plans.write(plan_id, plan);
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

        fn swap_tokens(
            ref self: ContractState,
            from_token: ContractAddress,
            to_token: ContractAddress,
            amount: u256,
            slippage_tolerance: u256,
        ) {
            self.assert_not_paused();
            assert(from_token != to_token, ERR_INVALID_INPUT);
            assert(amount > 0, ERR_INVALID_INPUT);
            assert(slippage_tolerance > 0, ERR_INVALID_INPUT);

            let caller = get_caller_address();
            let dex_router = self.dex_router.read();
            assert(dex_router != contract_address_const::<0>(), ERR_DEX_ROUTER_NOT_SET);

            // Check balance and allowance
            let token = IERC20Dispatcher { contract_address: from_token };
            let balance = token.balance_of(caller);
            assert(balance >= amount, ERR_INSUFFICIENT_BALANCE);

            let allowance = token.allowance(caller, get_contract_address());
            assert(allowance >= amount, ERR_INSUFFICIENT_ALLOWANCE);

            // Transfer tokens to contract
            token.transfer_from(caller, get_contract_address(), amount);

            // Transfer tokens back to user (simulated swap)
            let to_token_contract = IERC20Dispatcher { contract_address: to_token };
            to_token_contract.transfer(caller, amount); // Simplified for now

            // Create swap request for tracking
            let swap_id = self.swap_count.read() + 1;
            let swap_request = SwapRequest {
                id: swap_id,
                plan_id: 0, // Standalone swap
                from_token,
                to_token,
                amount,
                slippage_tolerance,
                status: SwapStatus::Executed,
                created_at: get_block_timestamp(),
                executed_at: get_block_timestamp(),
            };

            self.swap_requests.write(swap_id, swap_request);
            self.swap_count.write(swap_id);
        }

        fn create_swap_request(
            ref self: ContractState, plan_id: u256, target_token: ContractAddress,
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
                from_token: SecurityImpl::get_token_address_from_enum(@self, plan.asset_type),
                to_token: target_token,
                amount: plan.asset_amount,
                slippage_tolerance: 100, // 1% default slippage
                status: SwapStatus::Pending,
                created_at: get_block_timestamp(),
                executed_at: 0,
            };

            self.swap_requests.write(swap_id, swap_request);
            self.swap_count.write(swap_id);
            self.plan_swap_requests.write(plan_id, swap_id);
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
            };

            self.kyc_data.write(caller, kyc_data);
            let current_count = self.pending_kyc_count.read();
            self.pending_kyc_count.write(current_count + 1);
        }

        fn approve_kyc(ref self: ContractState, user_address: ContractAddress) {
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

        fn reject_kyc(ref self: ContractState, user_address: ContractAddress) {
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

        fn get_user_plans(
            self: @ContractState, user_address: ContractAddress,
        ) -> Array<InheritancePlan> {
            let mut plans = ArrayTrait::new();
            let user_plan_count = self.user_plan_count.read(user_address);
            let mut i: u256 = 0;
            while i != user_plan_count {
                let plan = self.inheritance_plans.read(i + 1);
                if plan.owner == user_address {
                    plans.append(plan);
                }
                i += 1;
            }
            plans
        }

        fn get_user_claimed_assets(
            self: @ContractState, user_address: ContractAddress,
        ) -> Array<InheritancePlan> {
            let mut plans = ArrayTrait::new();
            let claimed_count = self.claimed_plan_count.read(user_address);
            let mut i: u256 = 0;
            while i != claimed_count {
                let plan = self.inheritance_plans.read(i + 1);
                if plan.is_claimed {
                    plans.append(plan);
                }
                i += 1;
            }
            plans
        }

        fn get_all_plans(self: @ContractState) -> Array<InheritancePlan> {
            let mut plans = ArrayTrait::new();
            let count = self.plan_count.read();
            let mut i: u256 = 1;
            let end_index = count + 1;
            while i != end_index {
                let plan = self.inheritance_plans.read(i);
                if plan.id != 0 {
                    plans.append(plan);
                }
                i += 1;
            }
            plans
        }

        fn get_pending_kyc_requests(self: @ContractState) -> Array<KYCData> {
            let mut kyc_requests = ArrayTrait::new();
            let count = self.pending_kyc_count.read();
            let mut i: u256 = 0;
            while i != count {
                i += 1;
            }
            kyc_requests
        }

        fn get_all_swap_requests(self: @ContractState) -> Array<SwapRequest> {
            let mut swap_requests = ArrayTrait::new();
            let count = self.swap_count.read();
            let mut i: u256 = 1;
            let end_index = count + 1;
            while i != end_index {
                let swap_request = self.swap_requests.read(i);
                if swap_request.id != 0 {
                    swap_requests.append(swap_request);
                }
                i += 1;
            }
            swap_requests
        }

        // ================ INACTIVITY MONITORING ================

        fn check_inactivity_trigger(ref self: ContractState, plan_id: u256) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);

            let plan = self.inheritance_plans.read(plan_id);
            let current_time = get_block_timestamp();
            let time_since_activity = current_time - plan.last_activity;

            if time_since_activity >= plan.inactivity_threshold {
                let mut inactivity_trigger = self.inactivity_triggers.read(plan_id);
                inactivity_trigger.is_triggered = true;
                inactivity_trigger.triggered_at = current_time;
                self.inactivity_triggers.write(plan_id, inactivity_trigger);
            }
        }

        fn set_inactivity_threshold(ref self: ContractState, plan_id: u256, threshold: u64) {
            self.assert_not_paused();
            self.assert_plan_exists(plan_id);
            self.assert_plan_owner(plan_id);
            assert(threshold > 0, ERR_INVALID_THRESHOLD);

            let mut plan = self.inheritance_plans.read(plan_id);
            plan.inactivity_threshold = threshold;
            self.inheritance_plans.write(plan_id, plan);
        }

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

        fn set_admin(ref self: ContractState, new_admin: ContractAddress) {
            self.assert_only_admin();
            assert(new_admin != contract_address_const::<0>(), ERR_ZERO_ADDRESS);

            self.admin.write(new_admin);
        }

        fn set_dex_router(ref self: ContractState, dex_router: ContractAddress) {
            self.assert_only_admin();

            self.dex_router.write(dex_router);
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
    }
}

