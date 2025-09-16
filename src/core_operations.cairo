#[starknet::contract]
pub mod InheritXOperations {
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
    use crate::interfaces::idex_router::{IDEXRouterDispatcher, IDEXRouterDispatcherTrait};
    use crate::interfaces::ioperations::IInheritXOperations;

    // Constants
    const ZERO_ADDRESS: ContractAddress = 0.try_into().unwrap();

    // ================ TRAITS ================

    #[generate_trait]
    pub trait OperationsSecurityTrait {
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
        // Core contract reference
        core_contract: ContractAddress,
        // Swap management
        swap_requests: Map<u256, SwapRequest>,
        swap_count: u256,
        plan_swap_requests: Map<u256, u256>, // plan_id -> swap_request_id
        // Inactivity monitoring
        inactivity_triggers: Map<u256, InactivityTrigger>,
        // Plan overrides
        override_requests: Map<u256, PlanOverrideRequest>,
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
        // Activity logging
        activity_count: Map<u256, u256>, // plan_id -> activity count
        global_activity_log: Map<u256, ActivityLog>, // activity_id -> activity
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
        beneficiary_withdrawal_count: Map<ContractAddress, u256>, // beneficiary -> withdrawal count
        // Claimed plans - simple counter approach
        claimed_plan_count: Map<ContractAddress, u256> // beneficiary -> count of claimed plans
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
        // Activity logging events
        ActivityLogged: ActivityLogged,
        PlanStatusUpdated: PlanStatusUpdated,
        BeneficiaryModified: BeneficiaryModified,
        // Fee events
        FeeCollected: FeeCollected,
        FeeConfigUpdated: FeeConfigUpdated,
        // Withdrawal events
        WithdrawalRequestCreated: WithdrawalRequestCreated,
        WithdrawalRequestApproved: WithdrawalRequestApproved,
        WithdrawalRequestProcessed: WithdrawalRequestProcessed,
        WithdrawalRequestRejected: WithdrawalRequestRejected,
        WithdrawalRequestCancelled: WithdrawalRequestCancelled,
        // Swap events
        SwapRequestCreated: SwapRequestCreated,
        SwapExecuted: SwapExecuted,
        // Escrow events
        AssetsLockedInEscrow: AssetsLockedInEscrow,
        AssetsReleasedFromEscrow: AssetsReleasedFromEscrow,
        // Emergency events
        EmergencyWithdraw: EmergencyWithdraw,
    }

    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        dex_router: ContractAddress,
        emergency_withdraw_address: ContractAddress,
        core_contract: ContractAddress,
        strk_token: ContractAddress,
        usdt_token: ContractAddress,
        usdc_token: ContractAddress,
    ) {
        assert(admin != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
        self.admin.write(admin);
        self.dex_router.write(dex_router);
        self.emergency_withdraw_address.write(emergency_withdraw_address);
        self.core_contract.write(core_contract);
        self.strk_token.write(strk_token);
        self.usdt_token.write(usdt_token);
        self.usdc_token.write(usdc_token);
        self.swap_count.write(0);
        self.escrow_count.write(0);
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

    impl SecurityImpl of OperationsSecurityTrait {
        fn assert_not_paused(self: @ContractState) {
            self.pausable.assert_not_paused();
        }

        fn assert_only_admin(self: @ContractState) {
            let caller = get_caller_address();
            let admin = self.admin.read();
            assert(caller == admin, ERR_UNAUTHORIZED);
        }

        fn assert_plan_exists(self: @ContractState, plan_id: u256) {
            // This would need to check with the core contract
            // For now, we'll assume the plan exists
            assert(plan_id > 0, ERR_PLAN_NOT_FOUND);
        }

        fn assert_plan_owner(self: @ContractState, plan_id: u256) {
            // This would need to check with the core contract
            // For now, we'll just check that plan_id is valid
            assert(plan_id > 0, ERR_UNAUTHORIZED);
        }

        fn assert_plan_active(self: @ContractState, plan_id: u256) {
            // This would need to check with the core contract
            assert(plan_id > 0, ERR_PLAN_NOT_ACTIVE);
        }

        fn assert_plan_not_executed(self: @ContractState, plan_id: u256) {
            // This would need to check with the core contract
            assert(plan_id > 0, ERR_PLAN_ALREADY_EXECUTED);
        }

        fn assert_plan_not_claimed(self: @ContractState, plan_id: u256) {
            // This would need to check with the core contract
            assert(plan_id > 0, ERR_PLAN_ALREADY_CLAIMED);
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


    // Internal helper functions
    #[generate_trait]
    pub trait InternalHelpersTrait {
        fn calculate_fee(self: @ContractState, amount: u256) -> u256;
        fn collect_fee(
            ref self: ContractState,
            plan_id: u256,
            beneficiary: ContractAddress,
            gross_amount: u256,
        ) -> u256;
    }

    impl InternalHelpers of InternalHelpersTrait {
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
            let fee_amount = Self::calculate_fee(@self, gross_amount);
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
    }

    #[abi(embed_v0)]
    impl InheritXOperations of IInheritXOperations<ContractState> {
        // ================ SWAP FUNCTIONS ================

        fn swap_tokens(
            ref self: ContractState,
            from_token: ContractAddress,
            to_token: ContractAddress,
            amount: u256,
            min_amount_out: u256,
        ) -> u256 {
            self.assert_not_paused();
            assert(amount > 0, ERR_INVALID_INPUT);
            assert(from_token != to_token, ERR_INVALID_INPUT);

            let dex_router = self.dex_router.read();
            assert(dex_router != ZERO_ADDRESS, ERR_DEX_ROUTER_NOT_SET);

            let current_time = get_block_timestamp();

            // Check balance and approve tokens
            let from_token_interface = IERC20Dispatcher { contract_address: from_token };
            let _to_token_interface = IERC20Dispatcher { contract_address: to_token };

            let contract_balance = from_token_interface.balance_of(get_contract_address());
            assert(contract_balance >= amount, ERR_INSUFFICIENT_BALANCE);

            // Approve DEX router to spend tokens
            from_token_interface.approve(dex_router, amount);

            // Execute swap through DEX router
            let dex_router_interface = IDEXRouterDispatcher { contract_address: dex_router };
            let deadline = current_time + 1800; // 30 minutes deadline

            let amount_out = dex_router_interface
                .swap_exact_tokens_for_tokens(
                    from_token, to_token, amount, min_amount_out, get_contract_address(), deadline,
                );

            // Verify the swap was successful
            let received_balance = _to_token_interface.balance_of(get_contract_address());
            assert(received_balance >= min_amount_out, ERR_SWAP_FAILED);

            self
                .emit(
                    SwapExecuted {
                        swap_id: 0, // Direct swap, no swap_id
                        executed_at: current_time,
                        execution_price: amount_out,
                        gas_used: 0,
                        executed_by: get_caller_address(),
                    },
                );

            amount_out
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

            self
                .emit(
                    SwapRequestCreated {
                        swap_id,
                        plan_id,
                        from_token,
                        to_token,
                        amount,
                        slippage_tolerance,
                        created_at: get_block_timestamp(),
                        created_by: get_caller_address(),
                    },
                );
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
            let to_token = IERC20Dispatcher { contract_address: swap_request.to_token };

            // Check balance and allowance
            let contract_balance = from_token.balance_of(get_contract_address());
            assert(contract_balance >= swap_request.amount, ERR_INSUFFICIENT_BALANCE);

            // Calculate execution price with slippage
            let slippage_adjustment = (swap_request.amount * swap_request.slippage_tolerance.into())
                / 10000;
            let min_amount_out = swap_request.amount - slippage_adjustment;

            // Approve DEX router to spend tokens
            from_token.approve(dex_router, swap_request.amount);

            // Execute real swap through DEX router
            let dex_router_interface = IDEXRouterDispatcher { contract_address: dex_router };
            let deadline = current_time + 1800; // 30 minutes deadline

            let execution_price = dex_router_interface
                .swap_exact_tokens_for_tokens(
                    swap_request.from_token,
                    swap_request.to_token,
                    swap_request.amount,
                    min_amount_out,
                    get_contract_address(),
                    deadline,
                );

            // Verify the swap was successful by checking the received amount
            let _received_balance = to_token.balance_of(get_contract_address());
            assert(_received_balance >= min_amount_out, ERR_SWAP_FAILED);

            let mut updated_swap = swap_request;
            updated_swap.status = SwapStatus::Executed;
            updated_swap.executed_at = current_time;
            updated_swap.execution_price = execution_price;
            updated_swap.gas_used = 0; // Gas usage is handled by the DEX router

            self.swap_requests.write(swap_id, updated_swap);

            // Update associated plan if exists
            if plan_id > 0 { // This would update the plan in the core contract
            }

            self
                .emit(
                    SwapExecuted {
                        swap_id,
                        executed_at: current_time,
                        execution_price,
                        gas_used: 0,
                        executed_by: get_caller_address(),
                    },
                );
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

            self
                .emit(
                    AssetsLockedInEscrow {
                        escrow_id, plan_id: plan_id, locked_at: current_time, fees, tax_liability,
                    },
                );
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

            // Release the assets
            let mut updated_escrow = escrow;
            updated_escrow.is_locked = false;
            updated_escrow.beneficiary = beneficiary;

            // Update escrow
            self.escrow_accounts.write(escrow_id, updated_escrow);

            // Transfer the actual assets to the beneficiary with fee collection
            let escrow = self.escrow_accounts.read(escrow_id);

            match escrow.asset_type {
                AssetType::STRK => {
                    let strk_token = IERC20Dispatcher { contract_address: self.strk_token.read() };
                    let balance = strk_token.balance_of(get_contract_address());
                    assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);

                    // Calculate and collect fees
                    let net_amount = InternalHelpers::collect_fee(
                        ref self, plan_id, beneficiary, escrow.amount,
                    );
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
                    let net_amount = InternalHelpers::collect_fee(
                        ref self, plan_id, beneficiary, escrow.amount,
                    );
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
                    let net_amount = InternalHelpers::collect_fee(
                        ref self, plan_id, beneficiary, escrow.amount,
                    );
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
            let claimed_count = self.claimed_plan_count.read(beneficiary);
            self.claimed_plan_count.write(beneficiary, claimed_count + 1);

            self
                .emit(
                    AssetsReleasedFromEscrow {
                        escrow_id,
                        plan_id,
                        beneficiary,
                        released_at: get_block_timestamp(),
                        release_reason,
                    },
                );
        }

        // ================ WALLET MANAGEMENT FUNCTIONS ================

        fn freeze_wallet(ref self: ContractState, wallet: ContractAddress, reason: ByteArray) {
            self.assert_only_admin();
            assert(wallet != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            let is_already_frozen = self.frozen_wallets.read(wallet);
            assert(!is_already_frozen, ERR_WALLET_ALREADY_FROZEN);

            let current_time = get_block_timestamp();
            let reason_clone = reason.clone();
            let freeze_info = FreezeInfo {
                reason, frozen_at: current_time, frozen_by: get_caller_address(),
            };

            self.frozen_wallets.write(wallet, true);
            self.freeze_reasons.write(wallet, freeze_info);

            self
                .emit(
                    WalletFrozen {
                        wallet_address: wallet,
                        frozen_at: current_time,
                        frozen_by: get_caller_address(),
                        freeze_reason: reason_clone,
                        freeze_duration: 0,
                    },
                );
        }

        fn unfreeze_wallet(ref self: ContractState, wallet: ContractAddress, reason: ByteArray) {
            self.assert_only_admin();
            assert(wallet != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            let is_frozen = self.frozen_wallets.read(wallet);
            assert(is_frozen, ERR_WALLET_NOT_FROZEN);

            let current_time = get_block_timestamp();

            self.frozen_wallets.write(wallet, false);

            self
                .emit(
                    WalletUnfrozen {
                        wallet_address: wallet,
                        unfrozen_at: current_time,
                        unfrozen_by: get_caller_address(),
                        unfreeze_reason: reason,
                    },
                );
        }

        fn blacklist_wallet(ref self: ContractState, wallet: ContractAddress, reason: ByteArray) {
            self.assert_only_admin();
            assert(wallet != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            let is_already_blacklisted = self.blacklisted_wallets.read(wallet);
            assert(!is_already_blacklisted, ERR_WALLET_ALREADY_BLACKLISTED);

            let current_time = get_block_timestamp();

            self.blacklisted_wallets.write(wallet, true);

            self
                .emit(
                    WalletBlacklisted {
                        wallet_address: wallet,
                        blacklisted_at: current_time,
                        blacklisted_by: get_caller_address(),
                        reason,
                    },
                );
        }

        fn remove_from_blacklist(
            ref self: ContractState, wallet: ContractAddress, reason: ByteArray,
        ) {
            self.assert_only_admin();
            assert(wallet != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
            assert(reason.len() > 0, ERR_INVALID_INPUT);

            let is_blacklisted = self.blacklisted_wallets.read(wallet);
            assert(is_blacklisted, ERR_WALLET_NOT_BLACKLISTED);

            let current_time = get_block_timestamp();

            self.blacklisted_wallets.write(wallet, false);

            self
                .emit(
                    WalletRemovedFromBlacklist {
                        wallet_address: wallet,
                        removed_at: current_time,
                        removed_by: get_caller_address(),
                        reason,
                    },
                );
        }

        // ================ SECURITY SETTINGS FUNCTIONS ================

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

            let _current_settings = self.security_settings.read();
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

        fn get_security_settings(self: @ContractState) -> SecuritySettings {
            self.security_settings.read()
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

            // Calculate fees and net amount
            let gross_amount = match request.withdrawal_type {
                WithdrawalType::All => 1000000000000000000, // 1 STRK for simulation
                WithdrawalType::Percentage => (1000000000000000000 * request.amount) / 100,
                WithdrawalType::FixedAmount => request.amount,
                WithdrawalType::NFT => 1 // NFT withdrawal
            };

            let fee_amount = InternalHelpers::calculate_fee(@self, gross_amount);
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

        // ================ EMERGENCY FUNCTIONS ================

        fn emergency_withdraw(
            ref self: ContractState, token_address: ContractAddress, amount: u256,
        ) {
            self.assert_only_admin();

            if token_address == ZERO_ADDRESS {
                // Withdraw native ETH
                // This would be handled differently in Starknet
                return;
            }

            // Withdraw ERC20 tokens
            let token = IERC20Dispatcher { contract_address: token_address };
            let balance = token.balance_of(get_contract_address());
            let withdraw_amount = if amount == 0 {
                balance
            } else {
                amount
            };
            assert(withdraw_amount <= balance, ERR_INSUFFICIENT_BALANCE);

            let emergency_address = self.emergency_withdraw_address.read();
            let success = token.transfer(emergency_address, withdraw_amount);
            assert(success, ERR_TRANSFER_FAILED);

            self
                .emit(
                    EmergencyWithdraw {
                        token_address,
                        amount: withdraw_amount,
                        withdrawn_to: emergency_address,
                        withdrawn_at: get_block_timestamp(),
                    },
                );
        }

        // ================ UPGRADE FUNCTIONS ================

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

        // ================ QUERY FUNCTIONS ================

        fn get_swap_request(self: @ContractState, swap_id: u256) -> SwapRequest {
            self.swap_requests.read(swap_id)
        }

        fn get_escrow_account(self: @ContractState, escrow_id: u256) -> EscrowAccount {
            self.escrow_accounts.read(escrow_id)
        }

        fn get_withdrawal_request(self: @ContractState, request_id: u256) -> WithdrawalRequest {
            self.withdrawal_requests.read(request_id)
        }

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
