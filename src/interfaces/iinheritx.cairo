use core::byte_array::ByteArray;
use starknet::{ClassHash, ContractAddress};
use crate::base::types::{
    AssetAllocation, Beneficiary, ClaimCode, DisbursementBeneficiary, EscrowAccount,
    InactivityMonitor, InheritancePlan, MonthlyDisbursementPlan, SecuritySettings,
};

#[starknet::interface]
pub trait IInheritX<TContractState> {
    // ================ INHERITANCE PLAN FUNCTIONS ================

    /// @notice Creates a new inheritance plan with enhanced features
    /// @param beneficiaries Array of beneficiary addresses
    /// @param asset_type Type of asset (0: STRK, 1: USDT, 2: USDC, 3: NFT)
    /// @param asset_amount Amount of tokens (0 for NFTs)
    /// @param nft_token_id NFT token ID (0 for tokens)
    /// @param nft_contract NFT contract address (0 for tokens)
    /// @param timeframe Time in seconds until plan becomes active
    /// @param guardian Optional guardian address (0 for no guardian)
    /// @param encrypted_details Encrypted inheritance details
    /// @param security_level Security level (1-5)
    /// @param auto_execute Whether to auto-execute on maturity
    /// @param emergency_contacts Array of emergency contact addresses
    fn create_inheritance_plan(
        ref self: TContractState,
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

    /// @notice Adds a beneficiary to an existing plan
    /// @param plan_id ID of the plan
    /// @param beneficiary Beneficiary address
    /// @param percentage Share percentage (0-100)
    /// @param email_hash Hash of beneficiary email
    /// @param age Beneficiary age
    /// @param relationship Encrypted relationship information
    fn add_beneficiary_to_plan(
        ref self: TContractState,
        plan_id: u256,
        beneficiary: ContractAddress,
        percentage: u8,
        email_hash: ByteArray,
        age: u8,
        relationship: ByteArray,
    );

    /// @notice Removes a beneficiary from a plan
    /// @param plan_id ID of the plan
    /// @param beneficiary Beneficiary address to remove
    /// @param reason Reason for removal
    fn remove_beneficiary_from_plan(
        ref self: TContractState, plan_id: u256, beneficiary: ContractAddress, reason: ByteArray,
    );

    /// @notice Claims assets from an inheritance plan using claim code
    /// @param plan_id ID of the plan to claim from
    /// @param claim_code Secret claim code hash
    fn claim_inheritance(ref self: TContractState, plan_id: u256, claim_code: ByteArray);

    // ================ CLAIM CODE FUNCTIONS ================

    /// @notice Stores claim code hash for a beneficiary (called by backend)
    /// @param plan_id ID of the plan
    /// @param beneficiary Beneficiary address
    /// @param code_hash Hash of the claim code
    /// @param expires_in Expiration time in seconds
    fn store_claim_code_hash(
        ref self: TContractState,
        plan_id: u256,
        beneficiary: ContractAddress,
        code_hash: ByteArray,
        expires_in: u64,
    );

    // ================ INACTIVITY MONITORING ================

    /// @notice Creates an inactivity monitor for a wallet
    /// @param wallet_address Wallet to monitor
    /// @param threshold Inactivity threshold in seconds
    /// @param beneficiary_email_hash Hash of beneficiary email
    /// @param plan_id Associated plan ID
    fn create_inactivity_monitor(
        ref self: TContractState,
        wallet_address: ContractAddress,
        threshold: u64,
        beneficiary_email_hash: ByteArray,
        plan_id: u256,
    );

    /// @notice Updates wallet activity timestamp
    /// @param wallet_address Wallet address
    fn update_wallet_activity(ref self: TContractState, wallet_address: ContractAddress);

    /// @notice Checks inactivity status for a plan
    /// @param plan_id ID of the plan
    /// @return Whether inactivity has been triggered
    fn check_inactivity_status(self: @TContractState, plan_id: u256) -> bool;

    // ================ ESCROW FUNCTIONS ================

    /// @notice Locks assets in escrow (called by backend after validation)
    /// @param escrow_id ID of the escrow account
    /// @param fees Escrow fees
    /// @param tax_liability Tax liability amount
    fn lock_assets_in_escrow(
        ref self: TContractState, escrow_id: u256, fees: u256, tax_liability: u256,
    );

    /// @notice Releases assets from escrow to beneficiary
    /// @param escrow_id ID of the escrow account
    /// @param beneficiary Beneficiary address
    /// @param release_reason Reason for release
    fn release_assets_from_escrow(
        ref self: TContractState,
        escrow_id: u256,
        beneficiary: ContractAddress,
        release_reason: ByteArray,
    );

    // ================ KYC FUNCTIONS ================

    /// @notice Uploads KYC data for asset owner or beneficiary
    /// @param kyc_hash Hash of the KYC document
    /// @param user_type 0: Asset Owner, 1: Beneficiary, 2: Guardian, 3: Admin, 4: Emergency Contact
    fn upload_kyc(ref self: TContractState, kyc_hash: ByteArray, user_type: u8);

    /// @notice Approves KYC data (admin only)
    /// @param user_address Address of the user whose KYC to approve
    /// @param approval_notes Notes about the approval
    fn approve_kyc(
        ref self: TContractState, user_address: ContractAddress, approval_notes: ByteArray,
    );

    /// @notice Rejects KYC data (admin only)
    /// @param user_address Address of the user whose KYC to reject
    /// @param rejection_reason Reason for rejection
    fn reject_kyc(
        ref self: TContractState, user_address: ContractAddress, rejection_reason: ByteArray,
    );

    // ================ SWAP FUNCTIONS ================

    /// @notice Creates a swap request for inheritance plans
    /// @param plan_id ID of the inheritance plan
    /// @param from_token Source token address
    /// @param to_token Target token address
    /// @param amount Amount to swap
    /// @param slippage_tolerance Slippage tolerance in basis points
    fn create_swap_request(
        ref self: TContractState,
        plan_id: u256,
        from_token: ContractAddress,
        to_token: ContractAddress,
        amount: u256,
        slippage_tolerance: u256,
    );

    /// @notice Executes a swap request
    /// @param swap_id ID of the swap request
    fn execute_swap(ref self: TContractState, swap_id: u256);

    // ================ QUERY FUNCTIONS ================

    /// @notice Gets a single inheritance plan
    /// @param plan_id ID of the plan
    fn get_inheritance_plan(self: @TContractState, plan_id: u256) -> InheritancePlan;

    /// @notice Gets all beneficiaries for a plan
    /// @param plan_id ID of the plan
    fn get_beneficiaries(self: @TContractState, plan_id: u256) -> Array<Beneficiary>;

    /// @notice Gets escrow details for a plan
    /// @param plan_id ID of the plan
    fn get_escrow_details(self: @TContractState, plan_id: u256) -> EscrowAccount;

    /// @notice Gets claim code details
    /// @param code_hash Hash of the claim code
    fn get_claim_code(self: @TContractState, code_hash: ByteArray) -> ClaimCode;

    /// @notice Gets inactivity monitor for a wallet
    /// @param wallet_address Wallet address
    fn get_inactivity_monitor(
        self: @TContractState, wallet_address: ContractAddress,
    ) -> InactivityMonitor;

    /// @notice Gets total plan count
    fn get_plan_count(self: @TContractState) -> u256;

    /// @notice Gets total escrow count
    fn get_escrow_count(self: @TContractState) -> u256;

    /// @notice Gets pending KYC count
    fn get_pending_kyc_count(self: @TContractState) -> u256;

    // ================ ADMIN FUNCTIONS ================

    /// @notice Upgrades the contract implementation
    /// @param new_class_hash The class hash of the new implementation
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);

    /// @notice Pauses the contract
    fn pause(ref self: TContractState);

    /// @notice Unpauses the contract
    fn unpause(ref self: TContractState);

    /// @notice Freezes a wallet due to security concerns
    /// @param wallet Wallet address to freeze
    /// @param reason Reason for freezing
    fn freeze_wallet(ref self: TContractState, wallet: ContractAddress, reason: ByteArray);

    /// @notice Unfreezes a previously frozen wallet
    /// @param wallet Wallet address to unfreeze
    /// @param reason Reason for unfreezing
    fn unfreeze_wallet(ref self: TContractState, wallet: ContractAddress, reason: ByteArray);

    /// @notice Blacklists a wallet due to severe violations
    /// @param wallet Wallet address to blacklist
    /// @param reason Reason for blacklisting
    fn blacklist_wallet(ref self: TContractState, wallet: ContractAddress, reason: ByteArray);

    /// @notice Removes a wallet from blacklist
    /// @param wallet Wallet address to remove from blacklist
    /// @param reason Reason for removal
    fn remove_from_blacklist(ref self: TContractState, wallet: ContractAddress, reason: ByteArray);

    /// @notice Updates security settings
    /// @param max_beneficiaries Maximum number of beneficiaries per plan
    /// @param min_timeframe Minimum timeframe in seconds
    /// @param max_timeframe Maximum timeframe in seconds
    /// @param require_guardian Whether to require guardian for plans
    /// @param allow_early_execution Whether to allow early execution
    /// @param max_asset_amount Maximum asset amount per plan
    /// @param require_multi_sig Whether to require multi-signature
    /// @param multi_sig_threshold Multi-signature threshold
    /// @param emergency_timeout Emergency timeout in seconds
    fn update_security_settings(
        ref self: TContractState,
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

    /// @notice Emergency withdrawal function
    /// @param token_address Token address to withdraw
    /// @param amount Amount to withdraw
    fn emergency_withdraw(ref self: TContractState, token_address: ContractAddress, amount: u256);

    /// @notice Gets current security settings
    fn get_security_settings(self: @TContractState) -> SecuritySettings;

    // ================ PLAN CREATION FLOW FUNCTIONS ================

    // Step 1: Create basic plan info
    fn create_plan_basic_info(
        ref self: TContractState,
        plan_name: ByteArray,
        plan_description: ByteArray,
        owner_email_hash: ByteArray,
        initial_beneficiary: ContractAddress,
        initial_beneficiary_email: ByteArray,
    ) -> u256;

    // Step 2: Set asset allocation
    fn set_asset_allocation(
        ref self: TContractState,
        basic_info_id: u256,
        beneficiaries: Array<Beneficiary>,
        asset_allocations: Array<AssetAllocation>,
    );

    // Step 3: Mark rules and conditions set (Backend validates)
    fn mark_rules_conditions_set(ref self: TContractState, basic_info_id: u256);

    // Step 4: Mark verification completed (Backend validates)
    fn mark_verification_completed(ref self: TContractState, basic_info_id: u256);

    // Step 5: Mark preview ready (Backend generates preview)
    fn mark_preview_ready(ref self: TContractState, basic_info_id: u256);

    // Step 6: Activate plan
    fn activate_inheritance_plan(
        ref self: TContractState, basic_info_id: u256, activation_confirmation: ByteArray,
    );

    // ================ BASIC QUERIES ================

    // Get beneficiary count (Backend fetches actual beneficiaries)
    fn get_beneficiary_count(self: @TContractState, basic_info_id: u256) -> u256;

    // ================ MONTHLY DISBURSEMENT FUNCTIONS ================

    // Create monthly disbursement plan
    fn create_monthly_disbursement_plan(
        ref self: TContractState,
        total_amount: u256,
        monthly_amount: u256,
        start_month: u64,
        end_month: u64,
        beneficiaries: Array<DisbursementBeneficiary>,
    ) -> u256;

    // Execute monthly disbursement
    fn execute_monthly_disbursement(ref self: TContractState, plan_id: u256);

    // Pause monthly disbursement plan
    fn pause_monthly_disbursement(ref self: TContractState, plan_id: u256, reason: ByteArray);

    // Resume monthly disbursement plan
    fn resume_monthly_disbursement(ref self: TContractState, plan_id: u256);

    // Get monthly disbursement plan status
    fn get_monthly_disbursement_status(
        self: @TContractState, plan_id: u256,
    ) -> MonthlyDisbursementPlan;
}
