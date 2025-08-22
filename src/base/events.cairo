use core::byte_array::ByteArray;
use starknet::ContractAddress;

// ================ INHERITANCE PLAN EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct InheritancePlanCreated {
    pub plan_id: u256,
    pub owner: ContractAddress,
    pub asset_type: u8,
    pub amount: u256,
    pub timeframe: u64,
    pub beneficiary_count: u8,
    pub created_at: u64,
    pub security_level: u8,
    pub auto_execute: bool,
}

#[derive(Drop, starknet::Event)]
pub struct InheritancePlanUpdated {
    pub plan_id: u256,
    pub updated_at: u64,
    pub updated_by: ContractAddress,
    pub changes: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct InheritancePlanExecuted {
    pub plan_id: u256,
    pub executed_at: u64,
    pub executed_by: ContractAddress,
    pub execution_reason: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct InheritancePlanCancelled {
    pub plan_id: u256,
    pub cancelled_at: u64,
    pub cancelled_by: ContractAddress,
    pub cancellation_reason: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct InheritancePlanPaused {
    pub plan_id: u256,
    pub paused_at: u64,
    pub paused_by: ContractAddress,
    pub pause_reason: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct InheritancePlanExpired {
    pub plan_id: u256,
    pub expired_at: u64,
    pub expiry_reason: ByteArray,
}

// ================ BENEFICIARY EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct BeneficiaryAdded {
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub percentage: u8,
    pub added_at: u64,
    pub added_by: ContractAddress,
    pub email_hash: ByteArray,
    pub age: u8,
    pub is_minor: bool,
}

#[derive(Drop, starknet::Event)]
pub struct BeneficiaryRemoved {
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub removed_at: u64,
    pub removed_by: ContractAddress,
    pub removal_reason: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct BeneficiaryUpdated {
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub updated_at: u64,
    pub updated_by: ContractAddress,
    pub changes: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct BeneficiaryClaimed {
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub amount: u256,
    pub claimed_at: u64,
    pub claim_code: ByteArray,
    pub tax_amount: u256,
    pub net_amount: u256,
}

// ================ CLAIM CODE EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct ClaimCodeGenerated {
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub code_hash: ByteArray,
    pub generated_at: u64,
    pub expires_at: u64,
    pub generated_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct ClaimCodeUsed {
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub code_hash: ByteArray,
    pub used_at: u64,
    pub used_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct ClaimCodeRevoked {
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub code_hash: ByteArray,
    pub revoked_at: u64,
    pub revoked_by: ContractAddress,
    pub revocation_reason: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct ClaimCodeExpired {
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub code_hash: ByteArray,
    pub expired_at: u64,
}

// ================ ESCROW EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct EscrowCreated {
    pub escrow_id: u256,
    pub plan_id: u256,
    pub asset_type: u8,
    pub amount: u256,
    pub created_at: u64,
    pub created_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct AssetsLocked {
    pub escrow_id: u256,
    pub plan_id: u256,
    pub asset_type: u8,
    pub amount: u256,
    pub locked_at: u64,
    pub locked_by: ContractAddress,
    pub fees: u256,
    pub tax_liability: u256,
}

#[derive(Drop, starknet::Event)]
pub struct AssetsReleased {
    pub escrow_id: u256,
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub amount: u256,
    pub released_at: u64,
    pub released_by: ContractAddress,
    pub release_reason: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct EscrowValuationUpdated {
    pub escrow_id: u256,
    pub new_value: u256,
    pub new_price: u256,
    pub updated_at: u64,
    pub updated_by: ContractAddress,
    pub confidence: u8,
}

// ================ INACTIVITY EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct InactivityMonitorCreated {
    pub wallet_address: ContractAddress,
    pub threshold: u64,
    pub beneficiary_email_hash: ByteArray,
    pub created_at: u64,
    pub created_by: ContractAddress,
    pub plan_id: u256,
}

#[derive(Drop, starknet::Event)]
pub struct InactivityTriggered {
    pub wallet_address: ContractAddress,
    pub threshold: u64,
    pub triggered_at: u64,
    pub beneficiary_email_hash: ByteArray,
    pub plan_id: u256,
    pub last_activity: u64,
}

#[derive(Drop, starknet::Event)]
pub struct WalletActivityUpdated {
    pub wallet_address: ContractAddress,
    pub last_activity: u64,
    pub updated_at: u64,
    pub updated_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct InactivityNotificationSent {
    pub wallet_address: ContractAddress,
    pub beneficiary_email_hash: ByteArray,
    pub sent_at: u64,
    pub notification_type: ByteArray,
}

// ================ KYC EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct KYCUploaded {
    pub user_address: ContractAddress,
    pub kyc_hash: ByteArray,
    pub user_type: u8,
    pub uploaded_at: u64,
    pub documents_count: u8,
    pub verification_score: u8,
    pub fraud_risk: u8,
}

#[derive(Drop, starknet::Event)]
pub struct KYCApproved {
    pub user_address: ContractAddress,
    pub approved_by: ContractAddress,
    pub approved_at: u64,
    pub approval_notes: ByteArray,
    pub final_verification_score: u8,
}

#[derive(Drop, starknet::Event)]
pub struct KYCRejected {
    pub user_address: ContractAddress,
    pub rejected_by: ContractAddress,
    pub rejected_at: u64,
    pub rejection_reason: ByteArray,
    pub fraud_risk_score: u8,
}

#[derive(Drop, starknet::Event)]
pub struct KYCExpired {
    pub user_address: ContractAddress,
    pub expired_at: u64,
    pub expiry_reason: ByteArray,
}

// ================ SWAP EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct SwapRequestCreated {
    pub swap_id: u256,
    pub plan_id: u256,
    pub from_token: ContractAddress,
    pub to_token: ContractAddress,
    pub amount: u256,
    pub slippage_tolerance: u256,
    pub created_at: u64,
    pub created_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct SwapExecuted {
    pub swap_id: u256,
    pub executed_at: u64,
    pub execution_price: u256,
    pub gas_used: u256,
    pub executed_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct SwapFailed {
    pub swap_id: u256,
    pub failed_at: u64,
    pub failed_reason: ByteArray,
    pub gas_used: u256,
}

#[derive(Drop, starknet::Event)]
pub struct SwapExpired {
    pub swap_id: u256,
    pub expired_at: u64,
    pub expiry_reason: ByteArray,
}

// ================ TIME TRIGGER EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct TimeTriggerCreated {
    pub trigger_id: u256,
    pub plan_id: u256,
    pub trigger_type: u8,
    pub trigger_time: u64,
    pub created_at: u64,
    pub created_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct TimeTriggerExecuted {
    pub trigger_id: u256,
    pub plan_id: u256,
    pub executed_at: u64,
    pub executed_by: ContractAddress,
    pub execution_result: ByteArray,
}

// ================ SECURITY EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct SecurityViolation {
    pub wallet_address: ContractAddress,
    pub violation_type: u8,
    pub severity: u8,
    pub detected_at: u64,
    pub detected_by: ContractAddress,
    pub description: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct SuspiciousActivityReported {
    pub wallet_address: ContractAddress,
    pub activity_type: u8,
    pub severity: u8,
    pub reported_at: u64,
    pub reported_by: ContractAddress,
    pub description: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct WalletFrozen {
    pub wallet_address: ContractAddress,
    pub frozen_at: u64,
    pub frozen_by: ContractAddress,
    pub freeze_reason: ByteArray,
    pub freeze_duration: u64,
}

#[derive(Drop, starknet::Event)]
pub struct WalletUnfrozen {
    pub wallet_address: ContractAddress,
    pub unfrozen_at: u64,
    pub unfrozen_by: ContractAddress,
    pub unfreeze_reason: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct SecuritySettingsUpdated {
    pub updated_at: u64,
    pub updated_by: ContractAddress,
    pub max_beneficiaries: u8,
    pub min_timeframe: u64,
    pub max_timeframe: u64,
    pub require_guardian: bool,
    pub allow_early_execution: bool,
    pub max_asset_amount: u256,
    pub require_multi_sig: bool,
    pub multi_sig_threshold: u8,
    pub emergency_timeout: u64,
}

// ================ ROLE AND PERMISSION EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct RoleAssigned {
    pub user_address: ContractAddress,
    pub plan_id: u256,
    pub role: u8,
    pub assigned_at: u64,
    pub assigned_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct RoleRevoked {
    pub user_address: ContractAddress,
    pub plan_id: u256,
    pub role: u8,
    pub revoked_at: u64,
    pub revoked_by: ContractAddress,
    pub revocation_reason: ByteArray,
}

// ================ AUDIT EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct AuditLogCreated {
    pub log_id: u256,
    pub user_address: ContractAddress,
    pub action: ByteArray,
    pub timestamp: u64,
    pub ipfs_hash: ByteArray,
    pub block_number: u64,
    pub transaction_hash: ByteArray,
}

// ================ EMERGENCY EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct EmergencyDeclared {
    pub plan_id: u256,
    pub emergency_level: u8,
    pub declared_at: u64,
    pub declared_by: ContractAddress,
    pub emergency_reason: ByteArray,
    pub timeout_duration: u64,
}

#[derive(Drop, starknet::Event)]
pub struct EmergencyResolved {
    pub plan_id: u256,
    pub resolved_at: u64,
    pub resolved_by: ContractAddress,
    pub resolution_notes: ByteArray,
}

// ================ PLAN OVERRIDE EVENTS ================

#[derive(Drop, starknet::Event)]
pub struct PlanOverrideRequested {
    pub plan_id: u256,
    pub requester: ContractAddress,
    pub requested_at: u64,
    pub emergency_level: u8,
    pub reason: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct PlanOverrideApproved {
    pub plan_id: u256,
    pub approved_at: u64,
    pub approved_by: ContractAddress,
    pub approval_notes: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct PlanOverrideRejected {
    pub plan_id: u256,
    pub rejected_at: u64,
    pub rejected_by: ContractAddress,
    pub rejection_reason: ByteArray,
}
