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
    Guardian,
    Admin,
    EmergencyContact,
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
    Paused,
    Expired,
    AssetsLocked,
    AssetsReleased,
}

// User role enum for access control
#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum UserRole {
    Owner,
    Beneficiary,
    Guardian,
    Admin,
    EmergencyContact,
}

// Enhanced Inheritance Plan type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct InheritancePlan {
    pub id: u256,
    pub owner: ContractAddress,
    pub beneficiary_count: u8,
    pub asset_type: AssetType,
    pub asset_amount: u256,
    pub nft_token_id: u256,
    pub nft_contract: ContractAddress,
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
    pub swap_request_id: u256,
    pub escrow_id: u256, // New: escrow account reference
    pub security_level: u8, // New: security level (1-5)
    pub auto_execute: bool, // New: auto-execute on maturity
    pub emergency_contacts_count: u8 // Count of emergency contacts
}

// Enhanced Beneficiary type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct Beneficiary {
    pub address: ContractAddress,
    pub email_hash: ByteArray, // Hash of beneficiary email
    pub percentage: u8, // Share percentage (0-100)
    pub has_claimed: bool,
    pub claimed_amount: u256,
    pub claim_code_hash: ByteArray,
    pub added_at: u64,
    pub kyc_status: KYCStatus,
    pub relationship: ByteArray, // Encrypted relationship info
    pub age: u8, // Age for minor protection
    pub is_minor: bool // Special handling for minors
}

// Enhanced Claim Code type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct ClaimCode {
    pub code_hash: ByteArray, // Hash of off-chain generated code
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub is_used: bool,
    pub generated_at: u64,
    pub expires_at: u64,
    pub used_at: u64,
    pub attempts: u8, // Number of failed attempts
    pub is_revoked: bool,
    pub revoked_at: u64,
    pub revoked_by: ContractAddress,
}

// Claim Code type (legacy compatibility)
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct ClaimCodeLegacy {
    pub plan_id: u256,
    pub code_hash: ByteArray,
    pub is_used: bool,
    pub claimed_at: u64,
    pub claimed_by: ContractAddress,
}

// Escrow Account type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct EscrowAccount {
    pub id: u256,
    pub plan_id: u256,
    pub asset_type: AssetType,
    pub amount: u256,
    pub nft_token_id: u256,
    pub nft_contract: ContractAddress,
    pub is_locked: bool,
    pub locked_at: u64,
    pub beneficiary: ContractAddress,
    pub release_conditions_count: u8, // Count of release conditions
    pub fees: u256,
    pub tax_liability: u256,
    pub last_valuation: u64,
    pub valuation_price: u256,
}

// Release Condition type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct ReleaseCondition {
    pub condition_type: u8, // 1: time-based, 2: event-based, 3: manual
    pub trigger_time: u64,
    pub event_hash: ByteArray,
    pub is_met: bool,
    pub met_at: u64,
}

// Enhanced KYC Data type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct KYCData {
    pub user_address: ContractAddress,
    pub kyc_hash: ByteArray,
    pub user_type: UserType,
    pub status: KYCStatus,
    pub uploaded_at: u64,
    pub approved_at: u64,
    pub approved_by: ContractAddress,
    pub verification_score: u8, // 0-100 verification score
    pub fraud_risk: u8, // 0-100 fraud risk score
    pub documents_count: u8,
    pub last_updated: u64,
    pub expiry_date: u64,
}

// Enhanced Swap Request type
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
    pub execution_price: u256,
    pub gas_used: u256,
    pub failed_reason: ByteArray,
}

// Swap status enum
#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum SwapStatus {
    Pending,
    Executed,
    Failed,
    Cancelled,
    Expired,
}

// Enhanced Beneficiary Share type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct BeneficiaryShare {
    pub address: ContractAddress,
    pub percentage: u8,
    pub has_claimed: bool,
    pub claimed_amount: u256,
    pub base_amount: u256,
    pub tax_amount: u256,
    pub net_amount: u256,
    pub distribution_schedule_count: u8 // Count of distribution schedules
}

// Distribution Schedule type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct DistributionSchedule {
    pub phase: u8, // 1: immediate, 2: time-based, 3: milestone-based
    pub amount: u256,
    pub trigger_time: u64,
    pub milestone: ByteArray,
    pub is_executed: bool,
    pub executed_at: u64,
}

// Enhanced Plan Override Request type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct PlanOverrideRequest {
    pub plan_id: u256,
    pub new_beneficiary_count: u8,
    pub new_timeframe: u64,
    pub new_encrypted_details: ByteArray,
    pub requester: ContractAddress,
    pub requested_at: u64,
    pub is_approved: bool,
    pub approved_at: u64,
    pub approved_by: ContractAddress,
    pub reason: ByteArray,
    pub emergency_level: u8 // 1-5 emergency level
}

// Enhanced Inactivity Trigger type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct InactivityTrigger {
    pub plan_id: u256,
    pub last_activity: u64,
    pub threshold: u64,
    pub is_triggered: bool,
    pub triggered_at: u64,
    pub executed_by: ContractAddress,
    pub wallet_address: ContractAddress,
    pub beneficiary_email_hash: ByteArray,
    pub notification_sent: bool,
    pub notification_sent_at: u64,
}

// Inactivity Monitor type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct InactivityMonitor {
    pub wallet_address: ContractAddress,
    pub threshold: u64, // Inactivity threshold in seconds
    pub last_activity: u64,
    pub beneficiary_email_hash: ByteArray,
    pub is_active: bool,
    pub created_at: u64,
    pub triggered_at: u64,
    pub plan_id: u256,
    pub monitoring_enabled: bool,
}

// Time Trigger type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct TimeTrigger {
    pub trigger_id: u256,
    pub plan_id: u256,
    pub trigger_type: TimeTriggerType,
    pub trigger_time: u64,
    pub is_executed: bool,
    pub executed_at: u64,
    pub conditions_count: u8, // Count of conditions
    pub action: ByteArray,
}

// Time Trigger Type enum
#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum TimeTriggerType {
    PlanMaturity,
    InactivityCheck,
    EscrowRelease,
    Notification,
    TaxReporting,
    ComplianceCheck,
}

// Security Settings type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct SecuritySettings {
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

// Suspicious Activity type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct SuspiciousActivity {
    pub wallet_address: ContractAddress,
    pub activity_type: u8,
    pub description: ByteArray,
    pub reported_at: u64,
    pub reported_by: ContractAddress,
    pub severity: u8, // 1-5 severity level
    pub is_investigated: bool,
    pub investigation_result: ByteArray,
    pub action_taken: u8 // 1: none, 2: warning, 3: freeze, 4: blacklist
}

// Asset Valuation type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct AssetValuation {
    pub asset_id: u256,
    pub current_value: u256,
    pub market_price: u256,
    pub volatility_score: u8,
    pub last_updated: u64,
    pub price_source: ByteArray,
    pub confidence: u8, // 0-100 confidence level
    pub currency: ByteArray,
}

// Audit Log type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct AuditLog {
    pub log_id: u256,
    pub user_address: ContractAddress,
    pub action: ByteArray,
    pub timestamp: u64,
    pub details: ByteArray,
    pub ipfs_hash: ByteArray,
    pub block_number: u64,
    pub transaction_hash: ByteArray,
}

// Freeze Info type
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct FreezeInfo {
    pub reason: ByteArray,
    pub frozen_at: u64,
    pub frozen_by: ContractAddress,
}
