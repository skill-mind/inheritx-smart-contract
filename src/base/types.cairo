use core::byte_array::ByteArray;
use starknet::ContractAddress;

// Asset types enum
#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum AssetType {
    STRK,
    USDT,
    USDC,
    NFT,
}

// User types for KYC
#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum UserType {
    AssetOwner,
    Beneficiary,
}

// KYC status enum
#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum KYCStatus {
    Pending,
    Approved,
    Rejected,
}

// Plan status enum
#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum PlanStatus {
    Active,
    Executed,
    Cancelled,
    Overridden,
}

// Inheritance Plan type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct InheritancePlan {
    pub id: u256,
    pub owner: ContractAddress,
    pub beneficiary_count: u8, // Number of beneficiaries
    pub asset_type: AssetType,
    pub asset_amount: u256,
    pub nft_token_id: u256,
    pub nft_contract: ContractAddress, // NFT contract address
    pub timeframe: u64,
    pub created_at: u64,
    pub becomes_active_at: u64,
    pub guardian: ContractAddress,
    pub encrypted_details: ByteArray,
    pub status: PlanStatus,
    pub is_claimed: bool,
    pub claim_code_hash: ByteArray,
    pub inactivity_threshold: u64,
    pub last_activity: u64,
    pub swap_request_id: u256 // 0 if no swap request
}

// KYC Data type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct KYCData {
    pub user_address: ContractAddress,
    pub kyc_hash: ByteArray,
    pub user_type: UserType,
    pub status: KYCStatus,
    pub uploaded_at: u64,
    pub approved_at: u64,
    pub approved_by: ContractAddress,
}

// Swap Request type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct SwapRequest {
    pub id: u256,
    pub plan_id: u256,
    pub from_token: ContractAddress,
    pub to_token: ContractAddress,
    pub amount: u256,
    pub slippage_tolerance: u256,
    pub status: SwapStatus,
    pub created_at: u64,
    pub executed_at: u64,
}

// Swap status enum
#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum SwapStatus {
    Pending,
    Executed,
    Failed,
    Cancelled,
}

// Claim Code type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct ClaimCode {
    pub plan_id: u256,
    pub code_hash: ByteArray,
    pub is_used: bool,
    pub claimed_at: u64,
    pub claimed_by: ContractAddress,
}

// Beneficiary Share type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct BeneficiaryShare {
    pub address: ContractAddress,
    pub percentage: u8,
    pub has_claimed: bool,
    pub claimed_amount: u256,
}

// Plan Override Request type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct PlanOverrideRequest {
    pub plan_id: u256,
    pub new_beneficiary_count: u8, // Number of new beneficiaries
    pub new_timeframe: u64,
    pub new_encrypted_details: ByteArray,
    pub requester: ContractAddress,
    pub requested_at: u64,
    pub is_approved: bool,
}

// Inactivity Trigger type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct InactivityTrigger {
    pub plan_id: u256,
    pub last_activity: u64,
    pub threshold: u64,
    pub is_triggered: bool,
    pub triggered_at: u64,
    pub executed_by: ContractAddress,
}
