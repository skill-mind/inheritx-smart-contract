# InheritX Indexer Requirements Specification

## Overview
The InheritX indexer serves as a critical bridge in the hybrid architecture, monitoring smart contract events, tracking wallet activity, and providing real-time data synchronization between on-chain and off-chain systems. Built in Rust for maximum performance and reliability, it handles both inheritance plan monitoring and wallet inactivity detection while maintaining data consistency across the entire platform.

## Core Responsibilities

### 1. Smart Contract Event Monitoring

#### Event Types to Monitor
```cairo
// ================ INHERITANCE PLAN EVENTS ================
event InheritancePlanCreated {
    plan_id: u256,
    owner: ContractAddress,
    asset_type: u8,
    amount: u256,
    timeframe: u64,
    beneficiary_count: u8,
    created_at: u64,
    security_level: u8,
    auto_execute: bool
}

event InheritancePlanUpdated {
    plan_id: u256,
    updated_at: u64,
    updated_by: ContractAddress,
    changes: ByteArray
}

event InheritancePlanExecuted {
    plan_id: u256,
    executed_at: u64,
    executed_by: ContractAddress,
    execution_reason: ByteArray
}

event InheritancePlanCancelled {
    plan_id: u256,
    cancelled_at: u64,
    cancelled_by: ContractAddress,
    cancellation_reason: ByteArray
}

event InheritancePlanPaused {
    plan_id: u256,
    paused_at: u64,
    paused_by: ContractAddress,
    pause_reason: ByteArray
}

event InheritancePlanExpired {
    plan_id: u256,
    expired_at: u64,
    expiry_reason: ByteArray
}

// ================ BENEFICIARY EVENTS ================
event BeneficiaryAdded {
    plan_id: u256,
    beneficiary: ContractAddress,
    percentage: u8,
    added_at: u64,
    added_by: ContractAddress,
    email_hash: ByteArray,
    age: u8,
    is_minor: bool
}

event BeneficiaryRemoved {
    plan_id: u256,
    beneficiary: ContractAddress,
    removed_at: u64,
    removed_by: ContractAddress,
    removal_reason: ByteArray
}

event BeneficiaryUpdated {
    plan_id: u256,
    beneficiary: ContractAddress,
    updated_at: u64,
    updated_by: ContractAddress,
    changes: ByteArray
}

event BeneficiaryClaimed {
    plan_id: u256,
    beneficiary: ContractAddress,
    amount: u256,
    claimed_at: u64,
    claim_code: ByteArray,
    tax_amount: u256,
    net_amount: u256
}

// ================ CLAIM CODE EVENTS ================
event ClaimCodeGenerated {
    plan_id: u256,
    beneficiary: ContractAddress,
    code_hash: ByteArray,
    generated_at: u64,
    expires_at: u64,
    generated_by: ContractAddress
}

event ClaimCodeUsed {
    plan_id: u256,
    beneficiary: ContractAddress,
    code_hash: ByteArray,
    used_at: u64,
    used_by: ContractAddress
}

event ClaimCodeRevoked {
    plan_id: u256,
    beneficiary: ContractAddress,
    code_hash: ByteArray,
    revoked_at: u64,
    revoked_by: ContractAddress,
    revocation_reason: ByteArray
}

event ClaimCodeExpired {
    plan_id: u256,
    beneficiary: ContractAddress,
    code_hash: ByteArray,
    expired_at: u64
}

// ================ ESCROW EVENTS ================
event EscrowCreated {
    escrow_id: u256,
    plan_id: u256,
    asset_type: u8,
    amount: u256,
    created_at: u64,
    created_by: ContractAddress
}

event AssetsLocked {
    escrow_id: u256,
    plan_id: u256,
    asset_type: u8,
    amount: u256,
    locked_at: u64,
    locked_by: ContractAddress,
    fees: u256,
    tax_liability: u256
}

event AssetsReleased {
    escrow_id: u256,
    plan_id: u256,
    beneficiary: ContractAddress,
    amount: u256,
    released_at: u64,
    released_by: ContractAddress,
    release_reason: ByteArray
}

event EscrowValuationUpdated {
    escrow_id: u256,
    new_value: u256,
    new_price: u256,
    updated_at: u64,
    updated_by: ContractAddress,
    confidence: u8
}

// ================ INACTIVITY EVENTS ================
event InactivityMonitorCreated {
    wallet_address: ContractAddress,
    threshold: u64,
    beneficiary_email_hash: ByteArray,
    created_at: u64,
    created_by: ContractAddress,
    plan_id: u256
}

event InactivityTriggered {
    wallet_address: ContractAddress,
    threshold: u64,
    triggered_at: u64,
    beneficiary_email_hash: ByteArray,
    plan_id: u256,
    last_activity: u64
}

event WalletActivityUpdated {
    wallet_address: ContractAddress,
    last_activity: u64,
    updated_at: u64,
    updated_by: ContractAddress
}

event InactivityNotificationSent {
    wallet_address: ContractAddress,
    beneficiary_email_hash: ByteArray,
    sent_at: u64,
    notification_type: ByteArray
}

// ================ KYC EVENTS ================
event KYCUploaded {
    user_address: ContractAddress,
    kyc_hash: ByteArray,
    user_type: u8,
    uploaded_at: u64,
    documents_count: u8,
    verification_score: u8,
    fraud_risk: u8
}

event KYCApproved {
    user_address: ContractAddress,
    approved_by: ContractAddress,
    approved_at: u64,
    approval_notes: ByteArray,
    final_verification_score: u8
}

event KYCRejected {
    user_address: ContractAddress,
    rejected_by: ContractAddress,
    rejected_at: u64,
    rejection_reason: ByteArray,
    fraud_risk_score: u8
}

event KYCExpired {
    user_address: ContractAddress,
    expired_at: u64,
    expiry_reason: ByteArray
}

// ================ SWAP EVENTS ================
event SwapRequestCreated {
    swap_id: u256,
    plan_id: u256,
    from_token: ContractAddress,
    to_token: ContractAddress,
    amount: u256,
    slippage_tolerance: u256,
    created_at: u64,
    created_by: ContractAddress
}

event SwapExecuted {
    swap_id: u256,
    executed_at: u64,
    execution_price: u256,
    gas_used: u256,
    executed_by: ContractAddress
}

event SwapFailed {
    swap_id: u256,
    failed_at: u64,
    failed_reason: ByteArray,
    gas_used: u256
}

event SwapExpired {
    swap_id: u256,
    expired_at: u64,
    expiry_reason: ByteArray
}

// ================ TIME TRIGGER EVENTS ================
event TimeTriggerCreated {
    trigger_id: u256,
    plan_id: u256,
    trigger_type: u8,
    trigger_time: u64,
    created_at: u64,
    created_by: ContractAddress
}

event TimeTriggerExecuted {
    trigger_id: u256,
    plan_id: u256,
    executed_at: u64,
    executed_by: ContractAddress,
    execution_result: ByteArray
}

// ================ SECURITY EVENTS ================
event SecurityViolation {
    wallet_address: ContractAddress,
    violation_type: u8,
    severity: u8,
    detected_at: u64,
    detected_by: ContractAddress,
    description: ByteArray
}

event SuspiciousActivityReported {
    wallet_address: ContractAddress,
    activity_type: u8,
    severity: u8,
    reported_at: u64,
    reported_by: ContractAddress,
    description: ByteArray
}

event WalletFrozen {
    wallet_address: ContractAddress,
    frozen_at: u64,
    frozen_by: ContractAddress,
    freeze_reason: ByteArray,
    freeze_duration: u64
}

event WalletUnfrozen {
    wallet_address: ContractAddress,
    unfrozen_at: u64,
    unfrozen_by: ContractAddress,
    unfreeze_reason: ByteArray
}

event WalletBlacklisted {
    wallet_address: ContractAddress,
    blacklisted_at: u64,
    blacklisted_by: ContractAddress,
    reason: ByteArray
}

event WalletRemovedFromBlacklist {
    wallet_address: ContractAddress,
    removed_at: u64,
    removed_by: ContractAddress,
    reason: ByteArray
}

event SecuritySettingsUpdated {
    updated_at: u64,
    updated_by: ContractAddress,
    max_beneficiaries: u8,
    min_timeframe: u64,
    max_timeframe: u64,
    require_guardian: bool,
    allow_early_execution: bool,
    max_asset_amount: u256,
    require_multi_sig: bool,
    multi_sig_threshold: u8,
    emergency_timeout: u64
}

// ================ ROLE AND PERMISSION EVENTS ================
event RoleAssigned {
    user_address: ContractAddress,
    plan_id: u256,
    role: u8,
    assigned_at: u64,
    assigned_by: ContractAddress
}

event RoleRevoked {
    user_address: ContractAddress,
    plan_id: u256,
    role: u8,
    revoked_at: u64,
    revoked_by: ContractAddress,
    revocation_reason: ByteArray
}

// ================ AUDIT EVENTS ================
event AuditLogCreated {
    log_id: u256,
    user_address: ContractAddress,
    action: ByteArray,
    timestamp: u64,
    ipfs_hash: ByteArray,
    block_number: u64,
    transaction_hash: ByteArray
}

// ================ EMERGENCY EVENTS ================
event EmergencyDeclared {
    plan_id: u256,
    emergency_level: u8,
    declared_at: u64,
    declared_by: ContractAddress,
    emergency_reason: ByteArray,
    timeout_duration: u64
}

event EmergencyResolved {
    plan_id: u256,
    resolved_at: u64,
    resolved_by: ContractAddress,
    resolution_notes: ByteArray
}

// ================ PLAN OVERRIDE EVENTS ================
event PlanOverrideRequested {
    plan_id: u256,
    requester: ContractAddress,
    requested_at: u64,
    emergency_level: u8,
    reason: ByteArray
}

event PlanOverrideApproved {
    plan_id: u256,
    approved_at: u64,
    approved_by: ContractAddress,
    approval_notes: ByteArray
}

event PlanOverrideRejected {
    plan_id: u256,
    rejected_at: u64,
    rejected_by: ContractAddress,
    rejection_reason: ByteArray
}

// ================ PLAN CREATION FLOW EVENTS ================
event BasicPlanInfoCreated {
    basic_info_id: u256,
    owner: ContractAddress,
    plan_name: ByteArray,
    created_at: u64
}

event AssetAllocationSet {
    plan_id: u256,
    beneficiary_count: u8,
    total_percentage: u8,
    set_at: u64
}

event RulesConditionsSet {
    plan_id: u256,
    guardian: ContractAddress,
    auto_execute: bool,
    set_at: u64
}

event VerificationCompleted {
    plan_id: u256,
    kyc_status: KYCStatus,
    compliance_status: ComplianceStatus,
    verified_at: u64
}

event PlanPreviewGenerated {
    plan_id: u256,
    validation_status: ValidationStatus,
    activation_ready: bool,
    generated_at: u64
}

event PlanActivated {
    plan_id: u256,
    activated_by: ContractAddress,
    activated_at: u64
}

event PlanCreationStepCompleted {
    plan_id: u256,
    step: PlanCreationStatus,
    completed_at: u64,
    completed_by: ContractAddress
}

// ================ ACTIVITY LOGGING EVENTS ================
event ActivityLogged {
    activity_id: u256,
    plan_id: u256,
    user_address: ContractAddress,
    activity_type: ActivityType,
    timestamp: u64
}

event PlanStatusUpdated {
    plan_id: u256,
    old_status: PlanStatus,
    new_status: PlanStatus,
    updated_by: ContractAddress,
    updated_at: u64,
    reason: ByteArray
}

event BeneficiaryModified {
    plan_id: u256,
    beneficiary_address: ContractAddress,
    modification_type: ByteArray,
    modified_at: u64,
    modified_by: ContractAddress
}

// ================ MONTHLY DISBURSEMENT EVENTS ================
event MonthlyDisbursementPlanCreated {
    plan_id: u256,
    owner: ContractAddress,
    total_amount: u256,
    monthly_amount: u256,
    start_month: u64,
    end_month: u64,
    created_at: u64
}

event MonthlyDisbursementExecuted {
    disbursement_id: u256,
    plan_id: u256,
    month: u64,
    amount: u256,
    beneficiaries_count: u8,
    executed_at: u64,
    transaction_hash: ByteArray
}

event MonthlyDisbursementPaused {
    plan_id: u256,
    paused_at: u64,
    paused_by: ContractAddress,
    reason: ByteArray
}

event MonthlyDisbursementResumed {
    plan_id: u256,
    resumed_at: u64,
    resumed_by: ContractAddress
}

event MonthlyDisbursementCancelled {
    plan_id: u256,
    cancelled_at: u64,
    cancelled_by: ContractAddress,
    reason: ByteArray
}

event DisbursementBeneficiaryAdded {
    plan_id: u256,
    beneficiary_address: ContractAddress,
    percentage: u8,
    monthly_amount: u256,
    added_at: u64
}

event DisbursementBeneficiaryRemoved {
    plan_id: u256,
    beneficiary_address: ContractAddress,
    removed_at: u64,
    removed_by: ContractAddress
}
```

#### Event Processing Pipeline
1. **Event Detection**: Monitor blockchain for new events
2. **Event Parsing**: Extract relevant data from event logs
3. **Data Validation**: Verify event data integrity
4. **Database Update**: Store processed events in database
5. **Notification Trigger**: Alert backend of new events
6. **State Synchronization**: Update application state

### 2. Hybrid Data Synchronization

#### On-Chain to Off-Chain Sync
```typescript
interface DataSyncJob {
  id: string;
  syncType: 'event_processing' | 'state_sync' | 'cache_update';
  source: 'blockchain' | 'database' | 'external_api';
  target: 'database' | 'cache' | 'notification_service';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  priority: 'high' | 'medium' | 'low';
  createdAt: Date;
  processedAt?: Date;
}

interface SyncResult {
  jobId: string;
  recordsProcessed: number;
  recordsUpdated: number;
  errors: string[];
  executionTime: number;
  success: boolean;
}
```

#### Wallet Activity Monitoring
```typescript
interface WalletActivity {
  address: string;
  lastTransaction: string;
  lastActivity: Date;
  inactivityThreshold: number; // in seconds
  isInactive: boolean;
  beneficiaryEmail: string;
  notificationSent: boolean;
  onChainStatus: 'active' | 'inactive' | 'triggered';
  lastSyncTimestamp: Date;
}

interface InactivityTrigger {
  walletAddress: string;
  threshold: number; // 1 week, 1 month, 6 months
  email: string;
  createdAt: Date;
  isActive: boolean;
  lastChecked: Date;
  onChainEventId?: string;
}
```

#### Monitoring Strategies
- **Transaction Monitoring**: Track all incoming/outgoing transactions
- **Contract Interactions**: Monitor smart contract calls
- **Balance Changes**: Track token balance fluctuations
- **NFT Transfers**: Monitor NFT ownership changes
- **DeFi Activity**: Track lending, staking, and swapping

### 3. Hybrid Data Consistency Management

#### Data Consistency Patterns
```typescript
interface ConsistencyCheck {
  id: string;
  checkType: 'on_chain_off_chain' | 'cross_system' | 'temporal';
  sourceSystem: string;
  targetSystem: string;
  dataHash: string;
  expectedHash: string;
  actualHash: string;
  isConsistent: boolean;
  lastChecked: Date;
  resolutionStatus: 'pending' | 'resolved' | 'escalated';
}

interface ConsistencyRule {
  id: string;
  ruleType: 'hash_match' | 'timestamp_sync' | 'state_consistency';
  source: string;
  target: string;
  validationLogic: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  autoResolution: boolean;
}
```

#### Database Schema for Hybrid Architecture
```sql
-- Events table with hybrid tracking
CREATE TABLE blockchain_events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    block_number BIGINT NOT NULL,
    transaction_hash VARCHAR(66) NOT NULL,
    block_timestamp BIGINT NOT NULL,
    contract_address VARCHAR(42) NOT NULL,
    event_data JSONB NOT NULL,
    processed_at TIMESTAMP DEFAULT NOW(),
    off_chain_sync_status VARCHAR(20) DEFAULT 'pending',
    sync_attempts INTEGER DEFAULT 0,
    last_sync_attempt TIMESTAMP,
    INDEX idx_event_type (event_type),
    INDEX idx_block_number (block_number),
    INDEX idx_timestamp (block_timestamp),
    INDEX idx_sync_status (off_chain_sync_status)
);

-- Hybrid data consistency tracking
CREATE TABLE data_consistency_checks (
    id SERIAL PRIMARY KEY,
    check_type VARCHAR(50) NOT NULL,
    source_system VARCHAR(50) NOT NULL,
    target_system VARCHAR(50) NOT NULL,
    data_hash VARCHAR(255) NOT NULL,
    expected_hash VARCHAR(255) NOT NULL,
    actual_hash VARCHAR(255),
    is_consistent BOOLEAN DEFAULT FALSE,
    last_checked TIMESTAMP DEFAULT NOW(),
    resolution_status VARCHAR(20) DEFAULT 'pending',
    INDEX idx_check_type (check_type),
    INDEX idx_resolution_status (resolution_status)
);
```

-- Wallet activity table
CREATE TABLE wallet_activity (
    id SERIAL PRIMARY KEY,
    wallet_address VARCHAR(42) NOT NULL,
    last_transaction_hash VARCHAR(66),
    last_activity_timestamp BIGINT NOT NULL,
    inactivity_threshold BIGINT NOT NULL,
    beneficiary_email VARCHAR(255),
    is_inactive BOOLEAN DEFAULT FALSE,
    notification_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_wallet_address (wallet_address),
    INDEX idx_last_activity (last_activity_timestamp),
    INDEX idx_is_inactive (is_inactive)
);

-- Inheritance plans table
CREATE TABLE inheritance_plans (
    id SERIAL PRIMARY KEY,
    plan_id BIGINT NOT NULL,
    owner_address VARCHAR(42) NOT NULL,
    asset_type VARCHAR(20) NOT NULL,
    asset_amount NUMERIC(78,0) NOT NULL,
    timeframe BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at BIGINT NOT NULL,
    becomes_active_at BIGINT NOT NULL,
    is_claimed BOOLEAN DEFAULT FALSE,
    claimed_at BIGINT,
    claimed_by VARCHAR(42),
    ipfs_hash VARCHAR(255),
    security_level INTEGER DEFAULT 3,
    auto_execute BOOLEAN DEFAULT FALSE,
    beneficiary_count INTEGER DEFAULT 0,
    INDEX idx_plan_id (plan_id),
    INDEX idx_owner (owner_address),
    INDEX idx_status (status),
    INDEX idx_becomes_active (becomes_active_at)
);

-- Plan creation flow tracking table
CREATE TABLE plan_creation_flow (
    id SERIAL PRIMARY KEY,
    plan_id BIGINT NOT NULL,
    basic_info_id BIGINT,
    creation_step VARCHAR(50) NOT NULL,
    step_data JSONB,
    step_completed_at BIGINT,
    validation_status VARCHAR(20) DEFAULT 'pending',
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    INDEX idx_plan_id (plan_id),
    INDEX idx_creation_step (creation_step),
    INDEX idx_validation_status (validation_status)
);

-- Monthly disbursement plans table
CREATE TABLE monthly_disbursement_plans (
    id SERIAL PRIMARY KEY,
    plan_id BIGINT NOT NULL,
    owner_address VARCHAR(42) NOT NULL,
    total_amount NUMERIC(78,0) NOT NULL,
    monthly_amount NUMERIC(78,0) NOT NULL,
    start_month BIGINT NOT NULL,
    end_month BIGINT NOT NULL,
    total_months INTEGER NOT NULL,
    completed_months INTEGER DEFAULT 0,
    next_disbursement_date BIGINT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    beneficiaries_count INTEGER DEFAULT 0,
    disbursement_status VARCHAR(20) DEFAULT 'pending',
    created_at BIGINT NOT NULL,
    last_activity BIGINT NOT NULL,
    INDEX idx_plan_id (plan_id),
    INDEX idx_owner (owner_address),
    INDEX idx_disbursement_status (disbursement_status),
    INDEX idx_next_disbursement_date (next_disbursement_date)
);

-- Monthly disbursements execution history
CREATE TABLE monthly_disbursements (
    id SERIAL PRIMARY KEY,
    disbursement_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL,
    month BIGINT NOT NULL,
    amount NUMERIC(78,0) NOT NULL,
    status VARCHAR(20) NOT NULL,
    scheduled_date BIGINT NOT NULL,
    executed_date BIGINT,
    beneficiaries_count INTEGER DEFAULT 0,
    transaction_hash VARCHAR(66),
    created_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_disbursement_id (disbursement_id),
    INDEX idx_plan_id (plan_id),
    INDEX idx_month (month),
    INDEX idx_status (status)
);

-- Disbursement beneficiaries table
CREATE TABLE disbursement_beneficiaries (
    id SERIAL PRIMARY KEY,
    plan_id BIGINT NOT NULL,
    beneficiary_address VARCHAR(42) NOT NULL,
    percentage INTEGER NOT NULL,
    monthly_amount NUMERIC(78,0) NOT NULL,
    total_received NUMERIC(78,0) DEFAULT 0,
    last_disbursement BIGINT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at BIGINT NOT NULL,
    INDEX idx_plan_id (plan_id),
    INDEX idx_beneficiary_address (beneficiary_address),
    INDEX idx_is_active (is_active)
);

-- Security settings table
CREATE TABLE security_settings (
    id SERIAL PRIMARY KEY,
    max_beneficiaries INTEGER NOT NULL,
    min_timeframe BIGINT NOT NULL,
    max_timeframe BIGINT NOT NULL,
    require_guardian BOOLEAN DEFAULT FALSE,
    allow_early_execution BOOLEAN DEFAULT FALSE,
    max_asset_amount NUMERIC(78,0) NOT NULL,
    require_multi_sig BOOLEAN DEFAULT FALSE,
    multi_sig_threshold INTEGER DEFAULT 2,
    emergency_timeout BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    updated_by VARCHAR(42) NOT NULL,
    INDEX idx_updated_at (updated_at)
);

-- Wallet security table
CREATE TABLE wallet_security (
    id SERIAL PRIMARY KEY,
    wallet_address VARCHAR(42) NOT NULL,
    is_frozen BOOLEAN DEFAULT FALSE,
    is_blacklisted BOOLEAN DEFAULT FALSE,
    freeze_reason TEXT,
    freeze_duration BIGINT DEFAULT 0,
    frozen_at BIGINT,
    frozen_by VARCHAR(42),
    blacklisted_at BIGINT,
    blacklisted_by VARCHAR(42),
    blacklist_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_wallet_address (wallet_address),
    INDEX idx_is_frozen (is_frozen),
    INDEX idx_is_blacklisted (is_blacklisted)
);

-- Inactivity monitors table
CREATE TABLE inactivity_monitors (
    id SERIAL PRIMARY KEY,
    wallet_address VARCHAR(42) NOT NULL,
    threshold BIGINT NOT NULL,
    last_activity BIGINT NOT NULL,
    beneficiary_email_hash VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at BIGINT NOT NULL,
    triggered_at BIGINT,
    plan_id BIGINT NOT NULL,
    monitoring_enabled BOOLEAN DEFAULT TRUE,
    INDEX idx_wallet_address (wallet_address),
    INDEX idx_plan_id (plan_id),
    INDEX idx_is_active (is_active),
    INDEX idx_last_activity (last_activity)
);

-- Escrow accounts table
CREATE TABLE escrow_accounts (
    id SERIAL PRIMARY KEY,
    escrow_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL,
    asset_type VARCHAR(20) NOT NULL,
    amount NUMERIC(78,0) NOT NULL,
    nft_token_id BIGINT DEFAULT 0,
    nft_contract VARCHAR(42),
    is_locked BOOLEAN DEFAULT FALSE,
    locked_at BIGINT,
    beneficiary VARCHAR(42),
    release_conditions_count INTEGER DEFAULT 0,
    fees NUMERIC(78,0) DEFAULT 0,
    tax_liability NUMERIC(78,0) DEFAULT 0,
    last_valuation BIGINT DEFAULT 0,
    valuation_price NUMERIC(78,0) DEFAULT 0,
    created_at BIGINT NOT NULL,
    INDEX idx_escrow_id (escrow_id),
    INDEX idx_plan_id (plan_id),
    INDEX idx_is_locked (is_locked)
);

-- Swap requests table
CREATE TABLE swap_requests (
    id SERIAL PRIMARY KEY,
    swap_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL,
    from_token VARCHAR(42) NOT NULL,
    to_token VARCHAR(42) NOT NULL,
    amount NUMERIC(78,0) NOT NULL,
    slippage_tolerance NUMERIC(78,0) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at BIGINT NOT NULL,
    executed_at BIGINT,
    execution_price NUMERIC(78,0) DEFAULT 0,
    gas_used BIGINT DEFAULT 0,
    failed_reason TEXT,
    INDEX idx_swap_id (swap_id),
    INDEX idx_plan_id (plan_id),
    INDEX idx_status (status)
);

-- Claim codes table
CREATE TABLE claim_codes (
    id SERIAL PRIMARY KEY,
    code_hash VARCHAR(255) NOT NULL,
    plan_id BIGINT NOT NULL,
    beneficiary VARCHAR(42) NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    generated_at BIGINT NOT NULL,
    expires_at BIGINT NOT NULL,
    used_at BIGINT,
    attempts INTEGER DEFAULT 0,
    is_revoked BOOLEAN DEFAULT FALSE,
    revoked_at BIGINT,
    revoked_by VARCHAR(42),
    INDEX idx_code_hash (code_hash),
    INDEX idx_plan_id (plan_id),
    INDEX idx_beneficiary (beneficiary),
    INDEX idx_is_used (is_used)
);

-- KYC data table
CREATE TABLE kyc_data (
    id SERIAL PRIMARY KEY,
    user_address VARCHAR(42) NOT NULL,
    kyc_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    uploaded_at BIGINT NOT NULL,
    approved_at BIGINT,
    approved_by VARCHAR(42),
    ipfs_hash VARCHAR(255),
    INDEX idx_user_address (user_address),
    INDEX idx_status (status),
    INDEX idx_uploaded_at (uploaded_at)
);
```

### 4. Real-Time Data Synchronization

#### WebSocket Integration
```typescript
interface WebSocketMessage {
  type: 'event' | 'wallet_activity' | 'plan_update' | 'kyc_update';
  data: any;
  timestamp: number;
  signature?: string;
}

class WebSocketService {
  // Broadcast new events to connected clients
  broadcastEvent(event: BlockchainEvent): void;
  
  // Send wallet inactivity alerts
  sendInactivityAlert(wallet: WalletActivity): void;
  
  // Update plan status in real-time
  updatePlanStatus(planId: string, status: string): void;
  
  // Notify KYC status changes
  notifyKYCUpdate(userAddress: string, status: string): void;
}
```

#### API Endpoints
```typescript
// Real-time data endpoints
GET /api/indexer/events/latest
GET /api/indexer/events/range?from={timestamp}&to={timestamp}
GET /api/indexer/wallet/{address}/activity
GET /api/indexer/plans/{planId}/status
GET /api/indexer/kyc/{userAddress}/status

// New feature endpoints
GET /api/indexer/plans/{planId}/creation-flow
GET /api/indexer/plans/{planId}/creation-step/{step}
GET /api/indexer/monthly-disbursements/{planId}
GET /api/indexer/monthly-disbursements/{planId}/executions
GET /api/indexer/security/settings
GET /api/indexer/security/wallet/{address}
GET /api/indexer/inactivity-monitors/{walletAddress}
GET /api/indexer/escrow/{escrowId}
GET /api/indexer/swap-requests/{swapId}
GET /api/indexer/claim-codes/{codeHash}

// WebSocket endpoints
WS /api/indexer/ws/events
WS /api/indexer/ws/wallet-activity
WS /api/indexer/ws/plans
WS /api/indexer/ws/kyc
WS /api/indexer/ws/plan-creation-flow
WS /api/indexer/ws/monthly-disbursements
WS /api/indexer/ws/security
WS /api/indexer/ws/inactivity-monitors
```

### 5. Inactivity Detection Algorithm

#### Detection Logic
```typescript
class InactivityDetector {
  // Check if wallet is inactive based on threshold
  isWalletInactive(wallet: WalletActivity): boolean {
    const now = Date.now();
    const timeSinceLastActivity = now - wallet.lastActivity;
    return timeSinceLastActivity >= wallet.inactivityThreshold;
  }
  
  // Process inactivity triggers
  async processInactivityTriggers(): Promise<void> {
    const triggers = await this.getActiveTriggers();
    
    for (const trigger of triggers) {
      const isInactive = await this.checkWalletInactivity(trigger.walletAddress);
      
      if (isInactive && !trigger.notificationSent) {
        await this.sendInactivityNotification(trigger);
        await this.markNotificationSent(trigger.id);
      }
    }
  }
  
  // Send email notification for inactivity
  async sendInactivityNotification(trigger: InactivityTrigger): Promise<void> {
    const emailData = {
      to: trigger.beneficiaryEmail,
      subject: 'Wallet Inactivity Alert - InheritX',
      template: 'inactivity-alert',
      data: {
        walletAddress: trigger.walletAddress,
        threshold: this.formatThreshold(trigger.threshold),
        platformUrl: process.env.PLATFORM_URL
      }
    };
    
    await this.emailService.sendEmail(emailData);
  }
}
```

### 6. Performance & Scalability

#### Indexing Performance
- **Block Processing**: Process 100+ blocks per second
- **Event Parsing**: Parse 1000+ events per second
- **Database Writes**: Handle 10,000+ writes per second
- **Real-Time Updates**: < 100ms latency for updates

#### Scalability Features
- **Horizontal Scaling**: Multiple indexer instances
- **Load Balancing**: Distribute blockchain queries
- **Database Sharding**: Partition data by time ranges
- **Caching Layer**: Redis-based event caching
- **Queue Processing**: Background job processing

#### Rust-Specific Performance Optimizations
```rust
// High-performance event processing with Rust
#[derive(Debug, Clone)]
pub struct EventProcessor {
    event_queue: Arc<Mutex<VecDeque<BlockchainEvent>>>,
    workers: Vec<JoinHandle<()>>,
    batch_size: usize,
}

impl EventProcessor {
    pub async fn process_events_batch(&self) -> Result<(), Box<dyn std::error::Error>> {
        let mut events = Vec::new();
        
        // Collect events in batches for efficiency
        {
            let mut queue = self.event_queue.lock().await;
            while events.len() < self.batch_size && !queue.is_empty() {
                if let Some(event) = queue.pop_front() {
                    events.push(event);
                }
            }
        }
        
        // Process events in parallel with Tokio
        let chunks: Vec<_> = events.chunks(self.batch_size / 4).collect();
        let handles: Vec<_> = chunks
            .into_iter()
            .map(|chunk| {
                let chunk = chunk.to_vec();
                tokio::spawn(async move {
                    Self::process_event_chunk(chunk).await
                })
            })
            .collect();
        
        // Wait for all chunks to complete
        for handle in handles {
            handle.await??;
        }
        
        Ok(())
    }
}

// Efficient database operations with Rust async
#[derive(Debug, Clone)]
pub struct DatabaseManager {
    pool: PgPool,
    redis_client: RedisClient,
    cache: Arc<Mutex<LruCache<String, Vec<u8>>>>,
}

impl DatabaseManager {
    pub async fn batch_insert_events(
        &self,
        events: Vec<BlockchainEvent>,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Use batch insert for efficiency
        let mut query_builder = QueryBuilder::new(
            "INSERT INTO blockchain_events (event_type, block_number, transaction_hash, event_data) "
        );
        
        query_builder.push_values(events.iter(), |mut b, event| {
            b.push_bind(&event.event_type)
                .push_bind(event.block_number)
                .push_bind(&event.transaction_hash)
                .push_bind(&event.event_data);
        });
        
        let query = query_builder.build();
        query.execute(&self.pool).await?;
        
        Ok(())
    }
}
```

### 7. Error Handling & Recovery

#### Failure Scenarios
- **Blockchain Node Failure**: Fallback to multiple RPC endpoints
- **Database Connection Loss**: Automatic reconnection with retry logic
- **Event Processing Errors**: Dead letter queue for failed events
- **Network Timeouts**: Exponential backoff for retries

#### Recovery Mechanisms
```typescript
class IndexerRecovery {
  // Recover from blockchain node failure
  async switchRpcEndpoint(): Promise<void> {
    const endpoints = this.getRpcEndpoints();
    for (const endpoint of endpoints) {
      if (await this.testEndpoint(endpoint)) {
        this.currentEndpoint = endpoint;
        break;
      }
    }
  }
  
  // Replay missed events
  async replayEvents(fromBlock: number, toBlock: number): Promise<void> {
    const events = await this.getEventsInRange(fromBlock, toBlock);
    for (const event of events) {
      await this.processEvent(event);
    }
  }
  
  // Verify data integrity
  async verifyDataIntegrity(): Promise<boolean> {
    const lastProcessedBlock = await this.getLastProcessedBlock();
    const blockchainBlock = await this.getLatestBlockNumber();
    
    return lastProcessedBlock >= blockchainBlock - 10; // Allow 10 block lag
  }
}
```

### 8. Hybrid System Monitoring & Alerting

#### Cross-System Health Checks
- **Block Processing Rate**: Monitor blocks processed per second
- **Event Processing Rate**: Track events processed per second
- **Off-Chain Sync Status**: Monitor data synchronization between systems
- **Data Consistency**: Track consistency between on-chain and off-chain data
- **Cross-System Latency**: Monitor response times between all components

#### Hybrid Health Metrics
```typescript
interface HybridHealthMetrics {
  blockchain: {
    blockProcessingRate: number;
    eventProcessingRate: number;
    rpcLatency: number;
    lastBlockProcessed: number;
  };
  backend: {
    apiResponseTime: number;
    databasePerformance: number;
    externalApiHealth: number;
    cacheHitRate: number;
  };
  synchronization: {
    onChainToOffChainSync: number;
    dataConsistencyScore: number;
    syncQueueLength: number;
    lastSyncTimestamp: Date;
  };
  overall: {
    systemHealth: 'healthy' | 'degraded' | 'critical';
    criticalIssues: string[];
    recommendations: string[];
  };
}
```

#### Hybrid Alerting System
```typescript
interface HybridAlert {
  id: string;
  alertType: 'consistency_breach' | 'sync_failure' | 'performance_degradation';
  severity: 'low' | 'medium' | 'high' | 'critical';
  sourceSystem: string;
  targetSystem: string;
  description: string;
  impact: string;
  recommendedAction: string;
  createdAt: Date;
  resolvedAt?: Date;
  resolutionNotes?: string;
}

class HybridAlertingService {
  // Monitor data consistency between systems
  async checkDataConsistency(): Promise<void> {
    const consistencyChecks = await this.performConsistencyChecks();
    
    for (const check of consistencyChecks) {
      if (!check.isConsistent) {
        await this.createAlert({
          alertType: 'consistency_breach',
          severity: 'high',
          sourceSystem: check.sourceSystem,
          targetSystem: check.targetSystem,
          description: `Data inconsistency detected between ${check.sourceSystem} and ${check.targetSystem}`,
          impact: 'Potential data loss or corruption',
          recommendedAction: 'Investigate and resolve data sync issues'
        });
      }
    }
  }
  
  // Monitor synchronization performance
  async checkSyncPerformance(): Promise<void> {
    const syncMetrics = await this.getSyncMetrics();
    
    if (syncMetrics.lag > 300) { // 5 minutes
      await this.createAlert({
        alertType: 'sync_failure',
        severity: 'medium',
        sourceSystem: 'blockchain',
        targetSystem: 'backend',
        description: 'Blockchain sync lag detected',
        impact: 'Delayed data updates',
        recommendedAction: 'Check indexer performance and blockchain connectivity'
      });
    }
  }
}
```

#### Alerting System
```typescript
interface Alert {
  type: 'error' | 'warning' | 'info';
  message: string;
  timestamp: Date;
  severity: 'low' | 'medium' | 'high' | 'critical';
  metadata: Record<string, any>;
}

class AlertingService {
  // Send critical alerts
  async sendCriticalAlert(alert: Alert): Promise<void> {
    await this.slackService.sendMessage(alert);
    await this.emailService.sendAlert(alert);
    await this.pagerDutyService.createIncident(alert);
  }
  
  // Monitor indexer health
  async checkIndexerHealth(): Promise<boolean> {
    const metrics = await this.getHealthMetrics();
    
    if (metrics.blockProcessingRate < 50) {
      await this.sendCriticalAlert({
        type: 'error',
        message: 'Block processing rate below threshold',
        timestamp: new Date(),
        severity: 'high',
        metadata: { currentRate: metrics.blockProcessingRate, threshold: 50 }
      });
      return false;
    }
    
    return true;
  }
}
```

### 9. Enhanced Monitoring & Analytics

#### Performance Metrics
- **Block Processing**: Process 100+ blocks per second
- **Event Processing**: Parse 1000+ events per second
- **Database Writes**: Handle 10,000+ writes per second
- **Real-Time Updates**: < 100ms latency for updates
- **Plan Creation Flow Metrics**: Step completion rates and timing
- **Monthly Disbursement Metrics**: Execution success rates and performance
- **Security Operation Metrics**: Response times and effectiveness

#### Enhanced Usage Analytics
- **Plan Creation Flow Analysis**: Step-by-step completion patterns, validation success rates, time per step
- **Monthly Disbursement Patterns**: Execution frequency, success rates, beneficiary distribution patterns
- **Security Event Analysis**: Freeze/blacklist patterns, security violation triggers, response effectiveness
- **Inactivity Monitoring Metrics**: Trigger frequency, notification success rates, response times
- **Escrow Management Analytics**: Lock/release patterns, fee structures, tax liability trends
- **Swap Execution Analytics**: Success rates, gas optimization, DEX routing efficiency
- **Claim Code Usage**: Generation patterns, usage rates, expiration management

#### Cross-System Health Monitoring
- **Blockchain Health**: Block processing rate, event processing rate, RPC latency
- **Backend Synchronization**: API response times, database performance, external API health
- **Data Consistency**: On-chain to off-chain sync, data consistency score, sync queue length
- **Overall System Health**: System status, critical issues, recommendations

### 10. Security & Privacy

#### Data Protection
- **Encryption**: Encrypt sensitive data at rest
- **Access Control**: Role-based access to indexer data
- **Audit Logging**: Log all data access and modifications
- **Data Retention**: Implement data retention policies

#### Blockchain Security
- **RPC Security**: Secure connections to blockchain nodes
- **Event Validation**: Verify event authenticity
- **Replay Protection**: Prevent duplicate event processing
- **Signature Verification**: Validate event signatures

### 11. Integration Points

#### Backend Integration
- **Event Notifications**: Real-time updates to backend services
- **Data Synchronization**: Keep backend database in sync
- **API Endpoints**: Provide indexed data to backend
- **WebSocket Connections**: Real-time data streaming

#### Frontend Integration
- **Real-Time Updates**: Live data updates in user interface
- **Search & Filtering**: Fast data queries for user searches
- **Dashboard Data**: Real-time dashboard updates
- **Notification System**: User alerts and updates

### 12. Development & Testing

#### Local Development
- **Local Blockchain**: Ganache or Hardhat for testing
- **Mock Events**: Simulated blockchain events
- **Test Database**: Local PostgreSQL instance
- **Development Tools**: Hot reloading and debugging

#### Testing Strategy
- **Unit Tests**: Individual component testing
- **Integration Tests**: End-to-end workflow testing
- **Performance Tests**: Load and stress testing
- **Security Tests**: Vulnerability assessment

### 13. Deployment & Operations

#### Rust Dependencies (Cargo.toml)
```toml
[dependencies]
# Async runtime
tokio = { version = "1.0", features = ["full"] }

# Database
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "postgres", "chrono"] }
redis = { version = "0.23", features = ["tokio-comp"] }

# HTTP client
reqwest = { version = "0.11", features = ["json"] }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Cryptography
sha2 = "0.10"
hex = "0.4"

# Logging
tracing = "0.1"
tracing-subscriber = "0.3"

# Error handling
anyhow = "1.0"
thiserror = "1.0"

# Time handling
chrono = { version = "0.4", features = ["serde"] }

# Caching
lru = "0.12"

# WebSocket
tokio-tungstenite = "0.20"
```

#### Infrastructure Requirements
- **High-Performance Servers**: CPU and memory optimized for Rust
- **Fast Storage**: SSD storage for database with async I/O
- **Network Bandwidth**: High-speed internet connection
- **Redundancy**: Multiple blockchain node connections

#### Deployment Options
- **Docker Containers**: Containerized deployment
- **Kubernetes**: Orchestrated container management
- **Cloud Deployment**: AWS, Azure, or Google Cloud
- **On-Premises**: Self-hosted infrastructure

#### Monitoring & Maintenance
- **Log Management**: Centralized log collection
- **Performance Monitoring**: Real-time performance tracking
- **Backup & Recovery**: Automated backup procedures
- **Update Management**: Seamless deployment updates

## New Features Summary

### 1. **Enhanced Plan Creation Flow Support**
- **Step-by-step event monitoring** for each creation phase
- **Real-time progress tracking** with validation status
- **Metadata synchronization** between on-chain and off-chain systems
- **Plan preview generation** with risk assessment data

### 2. **Monthly Disbursement System Integration**
- **Disbursement plan monitoring** with real-time status updates
- **Execution history tracking** with transaction records
- **Beneficiary record management** with payment history
- **Plan modification monitoring** for pause/resume/cancel actions

### 3. **Advanced Security Event Monitoring**
- **Security settings tracking** with configuration changes
- **Wallet security monitoring** with freeze/blacklist events
- **Inactivity monitoring** with trigger detection and response
- **Access control logging** with permission management

### 4. **Enhanced Escrow and Swap Management**
- **Escrow lifecycle tracking** with lock/release events
- **Swap request monitoring** with execution status
- **DEX integration tracking** with performance metrics
- **Claim code management** with generation and usage tracking

### 5. **Comprehensive Activity Logging**
- **Real-time activity tracking** for all operations
- **Cross-system event correlation** for data consistency
- **Performance analytics** for all new features
- **Security event monitoring** with automated alerts

### 6. **Enhanced Data Consistency Management**
- **On-chain to off-chain synchronization** for all new features
- **Real-time data validation** with consistency checks
- **Cross-system health monitoring** with alerting
- **Automated recovery procedures** for data inconsistencies

This enhanced indexer implementation ensures that all new InheritX features are properly monitored, indexed, and synchronized between on-chain and off-chain systems while maintaining the highest standards of performance, reliability, and data consistency. 