use core::byte_array::ByteArray;
use starknet::{ClassHash, ContractAddress};
use crate::base::types::{InheritancePlan, KYCData, SwapRequest};

#[starknet::interface]
pub trait IInheritX<TContractState> {
    // ================ INHERITANCE PLAN FUNCTIONS ================

    /// @notice Creates a new inheritance plan
    /// @param beneficiaries Array of beneficiary addresses
    /// @param asset_type Type of asset (0: STRK, 1: USDT, 2: USDC, 3: NFT)
    /// @param asset_amount Amount of tokens (0 for NFTs)
    /// @param nft_token_id NFT token ID (0 for tokens)
    /// @param timeframe Time in seconds until plan becomes active
    /// @param guardian Optional guardian address (0 for no guardian)
    /// @param encrypted_details Encrypted inheritance details
    fn create_inheritance_plan(
        ref self: TContractState,
        beneficiaries: Array<ContractAddress>,
        asset_type: u8,
        asset_amount: u256,
        nft_token_id: u256,
        timeframe: u64,
        guardian: ContractAddress,
        encrypted_details: ByteArray,
    ) -> u256;

    /// @notice Executes an inheritance plan immediately
    /// @param plan_id ID of the plan to execute
    fn execute_plan_immediately(ref self: TContractState, plan_id: u256);

    /// @notice Overrides an existing inheritance plan
    /// @param plan_id ID of the plan to override
    /// @param new_beneficiaries New beneficiary addresses
    /// @param new_timeframe New timeframe
    /// @param new_encrypted_details New encrypted details
    fn override_inheritance_plan(
        ref self: TContractState,
        plan_id: u256,
        new_beneficiaries: Array<ContractAddress>,
        new_timeframe: u64,
        new_encrypted_details: ByteArray,
    );

    /// @notice Claims assets from an inheritance plan
    /// @param plan_id ID of the plan to claim from
    /// @param claim_code Secret claim code
    fn claim_inheritance(ref self: TContractState, plan_id: u256, claim_code: ByteArray);

    // ================ SWAP FUNCTIONS ================

    /// @notice Swaps tokens (standalone function)
    /// @param from_token Source token address
    /// @param to_token Target token address
    /// @param amount Amount to swap
    /// @param slippage_tolerance Slippage tolerance in basis points
    fn swap_tokens(
        ref self: TContractState,
        from_token: ContractAddress,
        to_token: ContractAddress,
        amount: u256,
        slippage_tolerance: u256,
    );

    /// @notice Creates a swap request for inheritance plans
    /// @param plan_id ID of the inheritance plan
    /// @param target_token Target token address for conversion
    fn create_swap_request(ref self: TContractState, plan_id: u256, target_token: ContractAddress);

    // ================ KYC FUNCTIONS ================

    /// @notice Uploads KYC data for asset owner or beneficiary
    /// @param kyc_hash Hash of the KYC document
    /// @param user_type 0: Asset Owner, 1: Beneficiary
    fn upload_kyc(ref self: TContractState, kyc_hash: ByteArray, user_type: u8);

    /// @notice Approves KYC data (admin only)
    /// @param user_address Address of the user whose KYC to approve
    fn approve_kyc(ref self: TContractState, user_address: ContractAddress);

    /// @notice Rejects KYC data (admin only)
    /// @param user_address Address of the user whose KYC to reject
    fn reject_kyc(ref self: TContractState, user_address: ContractAddress);

    // ================ MONITORING FUNCTIONS ================

    /// @notice Gets a single inheritance plan
    /// @param plan_id ID of the plan
    fn get_inheritance_plan(self: @TContractState, plan_id: u256) -> InheritancePlan;

    /// @notice Gets all plans created by a specific user
    /// @param user_address Address of the user
    fn get_user_plans(
        self: @TContractState, user_address: ContractAddress,
    ) -> Array<InheritancePlan>;

    /// @notice Gets all assets claimed by a specific user
    /// @param user_address Address of the user
    fn get_user_claimed_assets(
        self: @TContractState, user_address: ContractAddress,
    ) -> Array<InheritancePlan>;

    /// @notice Gets all inheritance plans (admin only)
    fn get_all_plans(self: @TContractState) -> Array<InheritancePlan>;

    /// @notice Gets all pending KYC requests (admin only)
    fn get_pending_kyc_requests(self: @TContractState) -> Array<KYCData>;

    /// @notice Gets all swap requests (admin only)
    fn get_all_swap_requests(self: @TContractState) -> Array<SwapRequest>;

    // ================ INACTIVITY MONITORING ================

    /// @notice Triggers inactivity check for a specific plan
    /// @param plan_id ID of the plan to check
    fn check_inactivity_trigger(ref self: TContractState, plan_id: u256);

    /// @notice Sets inactivity threshold for a plan
    /// @param plan_id ID of the plan
    /// @param threshold Inactivity threshold in seconds
    fn set_inactivity_threshold(ref self: TContractState, plan_id: u256, threshold: u64);

    // ================ ADMIN FUNCTIONS ================

    /// @notice Upgrades the contract implementation
    /// @param new_class_hash The class hash of the new implementation
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);

    /// @notice Pauses the contract
    fn pause(ref self: TContractState);

    /// @notice Unpauses the contract
    fn unpause(ref self: TContractState);

    /// @notice Sets the admin address
    /// @param new_admin New admin address
    fn set_admin(ref self: TContractState, new_admin: ContractAddress);

    /// @notice Sets the DEX router address
    /// @param dex_router New DEX router address
    fn set_dex_router(ref self: TContractState, dex_router: ContractAddress);

    /// @notice Emergency withdrawal function
    /// @param token_address Token address to withdraw
    /// @param amount Amount to withdraw
    fn emergency_withdraw(ref self: TContractState, token_address: ContractAddress, amount: u256);
}
