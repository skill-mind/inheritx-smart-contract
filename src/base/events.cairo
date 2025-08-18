use starknet::{ClassHash, ContractAddress};
use super::types::AssetType;

// ================ INHERITANCE PLAN EVENTS ================

/// Event emitted when an inheritance plan is created
#[derive(Serde, Drop, starknet::Event)]
pub struct InheritancePlanCreated {
    #[key]
    pub plan_id: u256,
    pub owner: ContractAddress,
    pub asset_type: AssetType,
    pub asset_amount: u256,
    pub nft_token_id: u256,
    pub timeframe: u64,
    pub guardian: ContractAddress,
    pub created_at: u64,
}

/// Event emitted when an inheritance plan is executed
#[derive(Serde, Drop, starknet::Event)]
pub struct InheritancePlanExecuted {
    #[key]
    pub plan_id: u256,
    pub executed_by: ContractAddress,
    pub executed_at: u64,
}

/// Event emitted when an inheritance plan is claimed
#[derive(Serde, Drop, starknet::Event)]
pub struct InheritanceClaimed {
    #[key]
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub claimed_amount: u256,
    pub claimed_at: u64,
}

/// Event emitted when an inheritance plan is overridden
#[derive(Serde, Drop, starknet::Event)]
pub struct InheritancePlanOverridden {
    #[key]
    pub plan_id: u256,
    pub new_timeframe: u64,
    pub overridden_at: u64,
}

/// Event emitted when an inheritance plan is cancelled
#[derive(Serde, Drop, starknet::Event)]
pub struct InheritancePlanCancelled {
    #[key]
    pub plan_id: u256,
    pub cancelled_by: ContractAddress,
    pub cancelled_at: u64,
}

// ================ SWAP EVENTS ================

/// Event emitted when a swap request is created
#[derive(Serde, Drop, starknet::Event)]
pub struct SwapRequestCreated {
    #[key]
    pub swap_id: u256,
    pub plan_id: u256,
    pub from_token: ContractAddress,
    pub to_token: ContractAddress,
    pub amount: u256,
    pub created_at: u64,
}

/// Event emitted when a swap is executed
#[derive(Serde, Drop, starknet::Event)]
pub struct SwapExecuted {
    #[key]
    pub swap_id: u256,
    pub plan_id: u256,
    pub from_token: ContractAddress,
    pub to_token: ContractAddress,
    pub amount_in: u256,
    pub amount_out: u256,
    pub executed_at: u64,
}

/// Event emitted when a swap fails
#[derive(Serde, Drop, starknet::Event)]
pub struct SwapFailed {
    #[key]
    pub swap_id: u256,
    pub plan_id: u256,
    pub reason: ByteArray,
    pub failed_at: u64,
}

// ================ KYC EVENTS ================

/// Event emitted when KYC data is uploaded
#[derive(Serde, Drop, starknet::Event)]
pub struct KYCUploaded {
    #[key]
    pub user_address: ContractAddress,
    pub kyc_hash: ByteArray,
    pub user_type: u8,
    pub uploaded_at: u64,
}

/// Event emitted when KYC data is approved
#[derive(Serde, Drop, starknet::Event)]
pub struct KYCApproved {
    #[key]
    pub user_address: ContractAddress,
    pub approved_by: ContractAddress,
    pub approved_at: u64,
}

/// Event emitted when KYC data is rejected
#[derive(Serde, Drop, starknet::Event)]
pub struct KYCRejected {
    #[key]
    pub user_address: ContractAddress,
    pub rejected_by: ContractAddress,
    pub rejected_at: u64,
}

// ================ INACTIVITY EVENTS ================

/// Event emitted when inactivity is triggered
#[derive(Serde, Drop, starknet::Event)]
pub struct InactivityTriggered {
    #[key]
    pub plan_id: u256,
    pub last_activity: u64,
    pub threshold: u64,
    pub triggered_at: u64,
}

/// Event emitted when inactivity auto-execution occurs
#[derive(Serde, Drop, starknet::Event)]
pub struct InactivityAutoExecuted {
    #[key]
    pub plan_id: u256,
    pub executed_at: u64,
    pub reason: ByteArray,
}

// ================ ADMIN EVENTS ================

/// Event emitted when the contract is upgraded
#[derive(Serde, Drop, starknet::Event)]
pub struct ContractUpgraded {
    #[key]
    pub old_class_hash: ClassHash,
    pub new_class_hash: ClassHash,
    pub upgraded_at: u64,
}

/// Event emitted when the contract is paused
#[derive(Serde, Drop, starknet::Event)]
pub struct ContractPaused {
    #[key]
    pub paused_by: ContractAddress,
    pub paused_at: u64,
}

/// Event emitted when the contract is unpaused
#[derive(Serde, Drop, starknet::Event)]
pub struct ContractUnpaused {
    #[key]
    pub unpaused_by: ContractAddress,
    pub unpaused_at: u64,
}

/// Event emitted when admin is changed
#[derive(Serde, Drop, starknet::Event)]
pub struct AdminChanged {
    #[key]
    pub old_admin: ContractAddress,
    pub new_admin: ContractAddress,
    pub changed_at: u64,
}

/// Event emitted when DEX router is set
#[derive(Serde, Drop, starknet::Event)]
pub struct DEXRouterSet {
    #[key]
    pub old_router: ContractAddress,
    pub new_router: ContractAddress,
    pub set_at: u64,
}

// ================ EMERGENCY EVENTS ================

/// Event emitted during emergency withdrawal
#[derive(Serde, Drop, starknet::Event)]
pub struct EmergencyWithdrawal {
    #[key]
    pub token_address: ContractAddress,
    pub amount: u256,
    pub withdrawn_by: ContractAddress,
    pub withdrawn_at: u64,
}

// ================ VALIDATION EVENTS ================

/// Event emitted when claim code is generated
#[derive(Serde, Drop, starknet::Event)]
pub struct ClaimCodeGenerated {
    #[key]
    pub plan_id: u256,
    pub code_hash: ByteArray,
    pub generated_at: u64,
}

/// Event emitted when guardian is notified
#[derive(Serde, Drop, starknet::Event)]
pub struct GuardianNotified {
    #[key]
    pub plan_id: u256,
    pub guardian: ContractAddress,
    pub notified_at: u64,
}
