# Backend Implementation Guide for InheritX

This document outlines the backend functions that should be implemented off-chain to complement the Cairo smart contracts. These functions handle complex business logic, validation, and data processing that would be too expensive or complex to implement on-chain.

## Architecture Overview

The InheritX system follows a hybrid architecture with split smart contracts:
- **On-chain (Cairo Contracts)**: 
  - **InheritXPlans**: Plan management, beneficiary management, monthly disbursements, inactivity monitoring
  - **InheritXOperations**: Asset management, fee collection, wallet security, swap operations
- **Off-chain (Rust Backend)**: Complex validation, business logic, data processing, and user experience

## Deployed Smart Contracts

### InheritXPlans Contract
- **Contract Address**: `0xfd052d74b399aa085c01bd648af009d002bcaa3a29bcde1683f4720257d1e0`
- **Class Hash**: `0x4c04d2008a504f2fc7f8dc3e4c20e52f529f48bd64cdae512c4084750c57833`
- **Network**: Starknet Sepolia Testnet
- **Deployed**: September 10, 2025

### InheritXOperations Contract
- **Contract Address**: `0x313791f9b687cf29fd9cc9c395ce77854a6c8b6b267a2a34d6c4a5734a33050`
- **Class Hash**: `0x72edb586b5228bcd5b60550fec62447d4e5d7b5e953906d4e4b6bc1e1b8bc14`
- **Network**: Starknet Sepolia Testnet
- **Deployed**: September 10, 2025

## UI Design Flow Integration

The backend implementation follows the exact UI design flow structure:

### 1. **Create Plan - Basic Info** (Plan Creation)
- Plan owner information and contact details
- Basic plan details and naming
- Initial beneficiary setup and email verification
- Plan creation status tracking

### 2. **Create Plan - Asset Allocation** (Beneficiary Management)
- Multiple beneficiary selection and management
- Percentage-based distribution calculations
- Asset type specification and validation
- Real-time asset valuation integration

### 3. **Create Plan - Rules & Conditions** (Plan Configuration)
- Timeframes and execution conditions
- Guardian setup and permission management
- Auto-execution rules and triggers
- Emergency procedures configuration

### 4. **Create Plan - Verification & Legal Settings** (KYC & Compliance)
- KYC verification and document processing
- Legal compliance checks and validation
- Regulatory requirement verification
- Security settings and access control

### 5. **Create Plan - Preview** (Final Review)
- Comprehensive plan summary generation
- Risk assessment and compliance status
- Final confirmation and activation
- User acceptance and legal acknowledgment

### 6. **Plan Management** (Ongoing Operations)
- Plan listing and monitoring dashboard
- Status tracking and updates
- Activity logging and analytics
- Performance metrics and reporting

## UI Design Flow Integration

The backend implementation follows the exact UI design flow structure:

### 1. **Create Plan - Basic Info** (Plan Creation)
- Plan owner information and contact details
- Basic plan details and naming
- Initial beneficiary setup and email verification
- Plan creation status tracking

### 2. **Create Plan - Asset Allocation** (Beneficiary Management)
- Multiple beneficiary selection and management
- Percentage-based distribution calculations
- Asset type specification and validation
- Real-time asset valuation integration

### 3. **Create Plan - Rules & Conditions** (Plan Configuration)
- Timeframes and execution conditions
- Guardian setup and permission management
- Auto-execution rules and triggers
- Emergency procedures configuration

### 4. **Create Plan - Verification & Legal Settings** (KYC & Compliance)
- KYC verification and document processing
- Legal compliance checks and validation
- Regulatory requirement verification
- Security settings and access control

### 5. **Create Plan - Preview** (Final Review)
- Comprehensive plan summary generation
- Risk assessment and compliance status
- Final confirmation and activation
- User acceptance and legal acknowledgment

### 6. **Plan Management** (Ongoing Operations)
- Plan listing and monitoring dashboard
- Status tracking and updates
- Activity logging and analytics
- Performance metrics and reporting

## Core Backend Services

### 1. Plan Creation Flow Service

#### 1.1 Basic Plan Info Management
```rust
pub async fn create_basic_plan_info(
    plan_name: String,
    plan_description: String,
    owner_email: String,
    initial_beneficiary: String,
    initial_beneficiary_email: String,
    user_context: UserContext,
) -> Result<u256, BackendError> {
    // Validate plan name and description
    // Verify owner email format and uniqueness
    // Validate initial beneficiary information
    // Create basic plan info on-chain
    // Return basic_info_id for next steps
}
```

**Responsibilities:**
- Plan naming and description validation
- Owner email verification and uniqueness check
- Initial beneficiary setup and validation
- On-chain basic info creation
- Plan creation status tracking

#### 1.2 Asset Allocation Management
```rust
pub async fn set_asset_allocation(
    basic_info_id: u256,
    beneficiaries: Vec<Beneficiary>,
    asset_allocations: Vec<AssetAllocation>,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate beneficiary count and percentages
    // Verify total percentage equals 100%
    // Validate asset allocation data
    // Set asset allocation on-chain
    // Update plan creation status
}
```

**Responsibilities:**
- Beneficiary validation and percentage verification
- Asset allocation data validation
- On-chain asset allocation setting
- Plan creation step completion tracking

#### 1.3 Rules and Conditions Validation
```rust
pub async fn validate_and_set_plan_rules(
    plan_id: u256,
    rules: PlanRules,
    user_context: UserContext,
) -> Result<ValidationResult, BackendError> {
    // Validate business rules against current market conditions
    // Check legal compliance for user's jurisdiction
    // Verify guardian permissions and signatures
    // Calculate risk assessment scores
    // Store validated rules in database
    // Call smart contract: mark_rules_conditions_set(plan_id)
    
    // Return validation result with recommendations
}
```

**Responsibilities:**
- Validate business rule logic against current market conditions
- Check legal compliance requirements for user's jurisdiction
- Verify guardian permissions and multi-signature setup
- Calculate comprehensive risk assessment scores
- Store validated rules in secure database
- Update smart contract state via marker function
- Provide user feedback and recommendations

#### 1.2 Verification and Legal Compliance
```rust
pub async fn validate_verification_and_legal(
    plan_id: u256,
    verification_data: VerificationData,
    user_context: UserContext,
) -> Result<ComplianceResult, BackendError> {
    // KYC verification with external providers
    // Legal compliance checks for jurisdiction
    // Regulatory requirements validation
    // Document verification and storage
    // Store verification results securely
    // Call smart contract: mark_verification_completed(plan_id)
    
    // Return compliance status with detailed feedback
}
```

**Responsibilities:**
- KYC (Know Your Customer) verification with external providers
- Legal compliance validation for user's jurisdiction
- Regulatory requirement checks and updates
- Document verification, storage, and audit trail
- Compliance status calculation and reporting
- Update smart contract state via marker function
- Generate compliance certificates and reports

#### 1.3 Plan Preview Generation
```rust
pub async fn generate_plan_preview(
    plan_id: u256,
    user_context: UserContext,
) -> Result<PlanPreview, BackendError> {
    // Calculate total asset values from real-time feeds
    // Estimate fees, taxes, and legal costs
    // Generate comprehensive risk assessment
    // Create compliance summary and status
    // Generate warnings and recommendations
    // Create user-friendly preview interface
    // Call smart contract: mark_preview_ready(plan_id)
    
    // Return detailed preview with actionable insights
}
```

**Responsibilities:**
- Calculate total asset values from real-time market feeds
- Estimate fees, taxes, and legal costs accurately
- Generate comprehensive risk assessment with mitigation strategies
- Create compliance summary and regulatory status
- Generate user-friendly warnings and recommendations
- Create interactive preview interface for user review
- Update smart contract state via marker function
- Provide detailed insights and next steps

### 2. Asset Management Service

#### 2.1 Asset Valuation and Allocation
```rust
pub async fn calculate_asset_allocations(
    plan_id: u256,
    assets: Vec<Asset>,
    beneficiaries: Vec<Beneficiary>,
) -> Result<AssetAllocationResult, BackendError> {
    // Real-time asset valuation from multiple sources
    // Tax implications calculation for jurisdiction
    // Liquidity analysis and market depth
    // Risk distribution optimization
    // Optimal allocation strategy recommendations
    // Fee optimization and cost analysis
    
    // Return optimized allocation with detailed breakdown
}
```

**Responsibilities:**
- Real-time asset valuation (crypto, stocks, real estate, commodities)
- Tax implications calculation for user's jurisdiction
- Liquidity analysis and market depth assessment
- Risk distribution optimization across asset classes
- Optimal allocation strategy recommendations
- Fee optimization and cost analysis
- Market trend analysis and forecasting

#### 2.2 Distribution Schedule Management
```rust
pub async fn create_distribution_schedule(
    plan_id: u256,
    schedule_type: ScheduleType,
    conditions: Vec<ExecutionCondition>,
) -> Result<DistributionSchedule, BackendError> {
    // Time-based triggers with timezone handling
    // Event-based triggers and monitoring
    // Conditional execution logic
    // Tax optimization strategies
    // Legal compliance validation
    // Market condition monitoring
    // Automated rebalancing triggers
    
    // Return comprehensive schedule with monitoring
}
```

**Responsibilities:**
- Time-based distribution triggers with timezone handling
- Event-based execution conditions and monitoring
- Conditional execution logic and validation
- Tax optimization strategies and timing
- Legal compliance validation for distributions
- Market condition monitoring and alerts
- Automated rebalancing and adjustment triggers

### 3. Risk Assessment Service

#### 3.1 Comprehensive Risk Analysis
```rust
pub async fn assess_plan_risk(
    plan_id: u256,
    context: RiskContext,
) -> Result<RiskAssessment, BackendError> {
    // Market risk analysis with real-time data
    // Legal risk assessment and monitoring
    // Operational risk evaluation
    // Compliance risk analysis
    // Mitigation strategy development
    // Risk scoring and categorization
    // Trend analysis and forecasting
    
    // Return detailed risk assessment with mitigation
}
```

**Responsibilities:**
- Market risk analysis (crypto volatility, market conditions, correlations)
- Legal risk assessment (regulatory changes, legal challenges, jurisdiction risks)
- Operational risk evaluation (technical failures, human error, system risks)
- Compliance risk analysis (regulatory updates, enforcement actions)
- Mitigation strategy development and implementation
- Risk scoring and categorization for user understanding
- Trend analysis and risk forecasting

#### 3.2 Risk Monitoring and Alerts
```rust
pub async fn monitor_plan_risks(
    plan_id: u256,
) -> Result<RiskAlert, BackendError> {
    // Real-time risk monitoring with thresholds
    // Threshold-based alerts and notifications
    // Market condition analysis and alerts
    // Compliance status tracking and updates
    // Automated risk mitigation suggestions
    // Guardian and beneficiary notifications
    // Emergency procedure triggers
    
    // Return risk alerts with actionable recommendations
}
```

**Responsibilities:**
- Real-time risk monitoring with configurable thresholds
- Threshold-based alert generation and notifications
- Market condition analysis and trend monitoring
- Compliance status tracking and regulatory updates
- Automated risk mitigation suggestions and actions
- Guardian and beneficiary notification system
- Emergency procedure triggers and coordination

### 4. Compliance and Legal Service

#### 4.1 Regulatory Compliance Management
```rust
pub async fn check_regulatory_compliance(
    plan_id: u256,
    jurisdiction: Jurisdiction,
) -> Result<ComplianceStatus, BackendError> {
    // Jurisdiction-specific requirements and updates
    // Regulatory updates monitoring and alerts
    // Compliance reporting and documentation
    // Audit trail maintenance and verification
    // Legal document generation and storage
    // Compliance score calculation
    // Regulatory change impact assessment
    
    // Return comprehensive compliance status
}
```

**Responsibilities:**
- Jurisdiction-specific compliance requirements and updates
- Regulatory updates monitoring and real-time alerts
- Compliance reporting and documentation generation
- Audit trail maintenance and verification
- Legal document generation and secure storage
- Compliance score calculation and tracking
- Regulatory change impact assessment and recommendations

#### 4.2 KYC and AML Processing
```rust
pub async fn process_kyc_aml(
    user_id: u256,
    documents: Vec<Document>,
) -> Result<KYCResult, BackendError> {
    // Identity verification with multiple providers
    // Document validation and authenticity verification
    // AML screening and risk assessment
    // Risk scoring and categorization
    // Compliance reporting and monitoring
    // Continuous monitoring and updates
    // Fraud detection and prevention
    
    // Return KYC result with risk assessment
}
```

**Responsibilities:**
- Identity verification with multiple trusted providers
- Document authenticity verification and validation
- Anti-Money Laundering (AML) screening and assessment
- Risk scoring and categorization
- Compliance reporting and regulatory monitoring
- Continuous monitoring and periodic updates
- Fraud detection and prevention measures

### 5. Monthly Disbursement Service

#### 5.1 Monthly Disbursement Plan Management
```rust
pub async fn create_monthly_disbursement_plan(
    total_amount: u256,
    monthly_amount: u256,
    start_month: u64,
    end_month: u64,
    beneficiaries: Vec<DisbursementBeneficiary>,
    user_context: UserContext,
) -> Result<u256, BackendError> {
    // Validate total and monthly amounts
    // Verify start and end month logic
    // Validate beneficiary distribution
    // Create monthly disbursement plan on-chain
    // Return plan_id for management
}
```

**Responsibilities:**
- Monthly disbursement plan creation and validation
- Beneficiary distribution management
- Timeframe validation and scheduling
- On-chain plan creation and tracking

#### 5.2 Disbursement Execution and Management
```rust
pub async fn execute_monthly_disbursement(
    plan_id: u256,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Verify plan is active and ready
    // Check disbursement timing
    // Execute monthly disbursement on-chain
    // Update plan status and tracking
}
```

**Responsibilities:**
- Monthly disbursement execution
- Plan status management
- Disbursement tracking and history
- Beneficiary notification system

#### 5.3 Disbursement Plan Control
```rust
pub async fn pause_monthly_disbursement(
    plan_id: u256,
    reason: String,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate pause request
    // Pause disbursement on-chain
    // Notify beneficiaries
    // Log pause action
}

pub async fn resume_monthly_disbursement(
    plan_id: u256,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate resume request
    // Resume disbursement on-chain
    // Notify beneficiaries
    // Log resume action
}
```

**Responsibilities:**
- Disbursement plan pause/resume functionality
- Plan status management
- Beneficiary notification system
- Action logging and audit trails

### 6. Beneficiary Verification Service ⭐ NEW

#### 6.1 Beneficiary Identity Verification
```rust
pub async fn verify_beneficiary_identity(
    &self,
    plan_id: u256,
    beneficiary_address: String,
    email_hash: String,
    name_hash: String,
) -> Result<BeneficiaryVerificationResult, BackendError> {
    // Verify beneficiary identity on-chain
    let contract = self.get_inheritx_contract().await?;
    
    let result = contract
        .verify_beneficiary_identity(plan_id, beneficiary_address, email_hash, name_hash)
        .call()
        .await?;
    
    // Emit verification event
    self.event_service
        .emit_beneficiary_verification(plan_id, beneficiary_address, result)
        .await?;
    
    Ok(BeneficiaryVerificationResult {
        is_verified: result,
        verified_at: chrono::Utc::now(),
        verification_method: "on_chain".to_string(),
    })
}
```

#### 6.2 Beneficiary Verification Management
```rust
pub async fn manage_beneficiary_verifications(
    &self,
    plan_id: u256,
) -> Result<Vec<BeneficiaryVerificationRecord>, BackendError> {
    // Get all verification records for a plan
    let verifications = self.database
        .get_beneficiary_verifications(plan_id)
        .await?;
    
    Ok(verifications)
}
```

**Responsibilities:**
- On-chain beneficiary identity verification
- Email and name hash validation
- Verification event emission and tracking
- Verification history management

### 7. Enhanced Escrow and Security Service

#### 7.1 Advanced Escrow Management
```rust
pub async fn manage_escrow_lifecycle(
    escrow_id: u256,
    action: EscrowAction,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate escrow action
    // Execute escrow operation on-chain
    // Update escrow status and tracking
    // Notify relevant parties
    // Log escrow action
}
```

**Responsibilities:**
- Escrow lifecycle management (lock, release, monitor)
- Asset security and protection
- Fee and tax liability management
- Release condition validation
- Beneficiary notification system

#### 6.2 Security Settings Management
```rust
pub async fn update_security_settings(
    settings: SecuritySettings,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate security parameters
    // Update security settings on-chain
    // Notify users of changes
    // Log security updates
    // Update compliance status
}
```

**Responsibilities:**
- Security settings configuration and validation
- Multi-signature threshold management
- Guardian permission configuration
- Emergency procedure setup
- Compliance requirement enforcement

#### 6.3 Wallet Security Management
```rust
pub async fn manage_wallet_security(
    wallet_address: String,
    action: SecurityAction,
    reason: String,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate security action
    // Execute security action on-chain
    // Update wallet status
    // Notify affected users
    // Log security action
}
```

**Responsibilities:**
- Wallet freezing and unfreezing
- Blacklist management
- Security violation handling
- Emergency response coordination
- User notification system

### 7. Enhanced Inactivity Monitoring Service

#### 7.1 Inactivity Monitor Management
```rust
pub async fn create_inactivity_monitor(
    wallet_address: String,
    threshold: u64,
    beneficiary_email: String,
    plan_id: u256,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate inactivity threshold
    // Create inactivity monitor on-chain
    // Set up monitoring parameters
    // Initialize monitoring system
    // Log monitor creation
}
```

**Responsibilities:**
- Inactivity monitor creation and configuration
- Threshold validation and optimization
- Monitoring system initialization
- Plan integration and tracking

#### 7.2 Activity Tracking and Alerts
```rust
pub async fn track_wallet_activity(
    wallet_address: String,
    activity_type: ActivityType,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Update wallet activity timestamp
    // Check inactivity thresholds
    // Generate alerts if needed
    // Update monitoring status
    // Log activity tracking
}
```

**Responsibilities:**
- Real-time wallet activity tracking
- Inactivity threshold monitoring
- Alert generation and notification
- Monitoring status updates
- Activity pattern analysis

#### 7.3 Inactivity Response Management
```rust
pub async fn handle_inactivity_trigger(
    wallet_address: String,
    plan_id: u256,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Verify inactivity trigger
    // Execute response procedures
    // Notify beneficiaries
    // Update plan status
    // Log trigger response
}
```

**Responsibilities:**
- Inactivity trigger detection and validation
- Automated response execution
- Beneficiary notification system
- Plan status management
- Emergency procedure coordination

### 8. Enhanced Swap and DEX Integration Service

#### 8.1 Swap Request Management
```rust
pub async fn create_swap_request(
    plan_id: u256,
    from_token: String,
    to_token: String,
    amount: u256,
    slippage_tolerance: u256,
    user_context: UserContext,
) -> Result<u256, BackendError> {
    // Validate swap parameters
    // Check token compatibility
    // Calculate optimal slippage
    // Create swap request on-chain
    // Return swap_request_id
}
```

**Responsibilities:**
- Swap request creation and validation
- Token compatibility checking
- Slippage tolerance optimization
- On-chain swap request management
- DEX integration preparation

#### 8.2 Swap Execution and Monitoring
```rust
pub async fn execute_swap(
    swap_id: u256,
    user_context: UserContext,
) -> Result<SwapResult, BackendError> {
    // Verify swap request status
    // Execute swap through DEX
    // Monitor execution progress
    // Update swap status
    // Log swap execution
}
```

**Responsibilities:**
- Swap execution through DEX integration
- Real-time execution monitoring
- Gas optimization and cost management
- Execution status tracking
- Error handling and recovery

#### 8.3 DEX Integration and Optimization
```rust
pub async fn optimize_dex_routing(
    from_token: String,
    to_token: String,
    amount: u256,
    user_context: UserContext,
) -> Result<DEXRoute, BackendError> {
    // Analyze multiple DEX options
    // Calculate optimal routing
    // Estimate gas costs
    // Determine best execution path
    // Return optimal route
}
```

**Responsibilities:**
- Multi-DEX routing optimization
- Gas cost estimation and optimization
- Liquidity analysis and routing
- Best execution path determination
- Cost-benefit analysis

### 9. Enhanced Claim Code and Beneficiary Management Service

#### 9.1 Enhanced Claim Code Generation and Management ⭐ UPDATED
```rust
pub async fn generate_claim_code(
    plan_id: u256,
    beneficiary: String,
    expires_in: u64,
    user_context: UserContext,
) -> Result<String, BackendError> {
    // Generate secure claim code off-chain
    // Calculate hash for on-chain storage
    // Store claim code hash on-chain via store_claim_code_hash
    // Send plain code to beneficiary via secure channel
    // Log code generation and delivery
}
```

**Responsibilities:**
- **Off-Chain Code Generation**: Secure claim code creation using cryptographic libraries
- **Hash Calculation**: Generate hash for on-chain storage and validation
- **On-Chain Storage**: Store hash via `store_claim_code_hash` function
- **Secure Delivery**: Send plain code to beneficiary via encrypted channels
- **Security Audit Logging**: Comprehensive logging of all claim code operations
- **Time-Based Management**: Handle expiration and activation timeframes
- **Usage Tracking**: Monitor claim code usage and prevent duplicates
- **Revocation Support**: Handle admin-controlled claim code invalidation

#### 9.2 Beneficiary Management and Validation
```rust
pub async fn add_beneficiary_to_plan(
    plan_id: u256,
    beneficiary: BeneficiaryData,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate beneficiary data
    // Check plan beneficiary limits
    // Verify percentage distribution
    // Add beneficiary on-chain
    // Update plan status
}
```

**Responsibilities:**
- Beneficiary data validation
- Plan limit enforcement
- Percentage distribution verification
- On-chain beneficiary management
- Plan status updates

#### 9.3 Beneficiary Relationship Management
```rust
pub async fn manage_beneficiary_relationships(
    plan_id: u256,
    action: BeneficiaryAction,
    beneficiary: String,
    reason: String,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate beneficiary action
    // Execute action on-chain
    // Update beneficiary status
    // Notify affected parties
    // Log relationship changes
}
```

**Responsibilities:**
- Beneficiary relationship management
- Status updates and modifications
- Notification system coordination
- Change logging and audit trails
- Plan integrity maintenance

### 10. Activity Logging and Analytics

#### 10.1 Comprehensive Activity Tracking
```rust
pub async fn log_activity(
    plan_id: u256,
    activity_type: ActivityType,
    details: String,
    metadata: ActivityMetadata,
) -> Result<ActivityLog, BackendError> {
    // Activity categorization and tagging
    // Metadata enrichment and validation
    // Audit trail creation and maintenance
    // Analytics data collection and processing
    // Compliance reporting and monitoring
    // User behavior analysis
    // Security event monitoring
    
    // Return logged activity with enriched metadata
}
```

**Responsibilities:**
- Activity categorization and intelligent tagging
- Metadata enrichment (IP, user agent, session, location)
- Audit trail creation and immutable maintenance
- Analytics data collection and real-time processing
- Compliance reporting and regulatory monitoring
- User behavior analysis and pattern recognition
- Security event monitoring and alerting

#### 5.2 Analytics and Reporting
```rust
pub async fn generate_analytics_report(
    plan_id: u256,
    report_type: ReportType,
    time_range: TimeRange,
) -> Result<AnalyticsReport, BackendError> {
    // Performance metrics calculation
    // Risk analytics and trend analysis
    // Compliance reporting and status
    // User behavior analysis and insights
    // Trend identification and forecasting
    // Comparative analysis and benchmarking
    // Custom report generation
    
    // Return comprehensive analytics report
}
```

**Responsibilities:**
- Performance metrics calculation and analysis
- Risk analytics and trend identification
- Compliance reporting and status tracking
- User behavior analysis and insights
- Trend identification and forecasting
- Comparative analysis and benchmarking
- Custom report generation and scheduling

### 6. Fee Management Service ⭐ NEW

#### 6.1 Fee Configuration and Management
```rust
pub async fn update_fee_config(
    new_fee_percentage: u256,
    new_fee_recipient: ContractAddress,
    user_context: UserContext,
) -> Result<(), BackendError> {
    // Validate fee percentage (0-100%)
    if new_fee_percentage > 100 {
        return Err(BackendError::InvalidFeePercentage);
    }
    
    // Update fee configuration on-chain
    self.smart_contract
        .update_fee_config(new_fee_percentage, new_fee_recipient)
        .await?;
    
    // Emit fee config updated event
    self.event_service.emit_fee_config_updated(
        new_fee_percentage,
        new_fee_recipient,
        user_context.user_address,
    ).await?;
    
    Ok(())
}
```

#### 6.2 Fee Collection and Processing
```rust
pub async fn collect_fee(
    plan_id: u256,
    beneficiary: ContractAddress,
    gross_amount: u256,
) -> Result<u256, BackendError> {
    // Get current fee configuration
    let fee_config = self.smart_contract.get_fee_config().await?;
    
    // Calculate fee amount with min/max limits
    let fee_amount = self.calculate_fee_with_limits(
        gross_amount, 
        fee_config.fee_percentage,
        fee_config.min_fee,
        fee_config.max_fee,
    ).await?;
    
    // Calculate net amount
    let net_amount = gross_amount - fee_amount;
    
    // Emit fee collected event
    self.event_service.emit_fee_collected(
        plan_id,
        beneficiary,
        fee_amount,
        fee_config.fee_percentage,
        gross_amount,
        net_amount,
        fee_config.fee_recipient,
    ).await?;
    
    Ok(net_amount)
}
```

### 7. Withdrawal Request Management Service ⭐ NEW

#### 7.1 Withdrawal Request Creation
```rust
pub async fn create_withdrawal_request(
    plan_id: u256,
    asset_type: AssetType,
    withdrawal_type: WithdrawalType,
    amount: u256,
    nft_token_id: Option<u256>,
    nft_contract: Option<ContractAddress>,
    user_context: UserContext,
) -> Result<u256, BackendError> {
    // Validate withdrawal request parameters
    self.validate_withdrawal_request(
        plan_id,
        asset_type,
        withdrawal_type,
        amount,
        nft_token_id,
        nft_contract,
    ).await?;
    
    // Create withdrawal request on-chain
    let request_id = self.smart_contract
        .create_withdrawal_request(
            plan_id,
            asset_type as u8,
            withdrawal_type as u8,
            amount,
            nft_token_id.unwrap_or(0),
            nft_contract.unwrap_or(ZERO_ADDRESS),
        )
        .await?;
    
    // Emit withdrawal request created event
    self.event_service.emit_withdrawal_request_created(
        request_id,
        plan_id,
        user_context.user_address,
        asset_type,
        withdrawal_type,
        amount,
        nft_token_id,
        nft_contract,
    ).await?;
    
    Ok(request_id)
}
```

### 8. Enhanced KYC Management Service ⭐ NEW

#### 8.1 KYC Data Processing with Event Emission
```rust
pub async fn process_kyc_upload(
    user_address: ContractAddress,
    kyc_hash: String,
    user_type: UserType,
    documents_count: u8,
    verification_score: u8,
    fraud_risk: u8,
) -> Result<(), BackendError> {
    // Upload KYC data to smart contract
    self.kyc_contract
        .upload_kyc(kyc_hash, user_type as u8)
        .await?;
    
    // Emit KYC uploaded event
    self.event_service.emit_kyc_uploaded(
        user_address,
        kyc_hash,
        user_type,
        documents_count,
        verification_score,
        fraud_risk,
    ).await?;
    
    Ok(())
}
```

#### 8.2 Beneficiary Identity Verification
```rust
pub async fn verify_beneficiary_identity(
    plan_id: u256,
    beneficiary_address: ContractAddress,
    email_hash: String,
    name_hash: String,
) -> Result<bool, BackendError> {
    // Verify identity on KYC contract
    let verification_result = self.kyc_contract
        .verify_beneficiary_identity(
            plan_id,
            beneficiary_address,
            email_hash,
            name_hash,
        )
        .await?;
    
    // Emit verification event
    self.event_service.emit_beneficiary_identity_verified(
        plan_id,
        beneficiary_address,
        verification_result,
    ).await?;
    
    Ok(verification_result)
}
```

### 9. Enhanced Claim Code Management Service ⭐ NEW

#### 9.1 Claim Code Revocation
```rust
pub async fn revoke_claim_code(
    plan_id: u256,
    reason: String,
    admin_context: UserContext,
) -> Result<(), BackendError> {
    // Revoke claim code on smart contract
    self.claim_contract
        .revoke_claim_code(plan_id, reason)
        .await?;
    
    // Emit claim code revoked event
    self.event_service.emit_claim_code_revoked(
        plan_id,
        reason,
        admin_context.user_address,
    ).await?;
    
    Ok(())
}
```

### 10. Guardian and Multi-Signature Management

#### 6.1 Guardian Permission Management
```rust
pub async fn manage_guardian_permissions(
    plan_id: u256,
    guardian: ContractAddress,
    permissions: GuardianPermissions,
) -> Result<PermissionResult, BackendError> {
    // Permission validation and verification
    // Multi-signature setup and configuration
    // Threshold management and updates
    // Emergency procedures configuration
    // Audit logging and monitoring
    // Guardian notification system
    // Permission escalation procedures
    
    // Return permission management result
}
```

**Responsibilities:**
- Permission validation and verification
- Multi-signature setup and configuration
- Threshold management and dynamic updates
- Emergency procedures configuration and testing
- Audit logging and comprehensive monitoring
- Guardian notification system and coordination
- Permission escalation procedures and automation

### 7. Emergency and Recovery Services

#### 7.1 Emergency Response Management
```rust
pub async fn handle_emergency_situation(
    plan_id: u256,
    emergency_type: EmergencyType,
    context: EmergencyContext,
) -> Result<EmergencyResponse, BackendError> {
    // Emergency assessment and classification
    // Response coordination and execution
    // Guardian notification and coordination
    // Asset protection measures
    // Recovery planning and execution
    // Legal compliance during emergency
    // Communication and status updates
    
    // Return emergency response with recovery plan
}
```

**Responsibilities:**
- Emergency situation assessment and classification
- Response coordination and automated execution
- Guardian notification and coordination system
- Asset protection measures and implementation
- Recovery planning and execution
- Legal compliance during emergency situations
- Communication and status update system

### 8. Monthly Disbursement Management Service

#### 8.1 Monthly Disbursement Plan Creation and Management
```rust
pub async fn create_monthly_disbursement_plan(
    owner_address: ContractAddress,
    plan_data: MonthlyDisbursementPlanData,
    user_context: UserContext,
) -> Result<MonthlyDisbursementPlanResult, BackendError> {
    // Validate plan parameters and constraints
    // Calculate optimal disbursement schedule
    // Validate beneficiary allocations and percentages
    // Check regulatory compliance for recurring payments
    // Generate disbursement calendar and timeline
    // Store plan configuration in database
    // Call smart contract: create_monthly_disbursement_plan()
    
    // Return plan creation result with disbursement schedule
}
```

**Responsibilities:**
- Validate monthly disbursement plan parameters
- Calculate optimal disbursement schedules and timing
- Validate beneficiary allocations and percentage distributions
- Check regulatory compliance for recurring payment structures
- Generate comprehensive disbursement calendar and timeline
- Store detailed plan configuration in secure database
- Integrate with smart contract for on-chain execution
- Provide user-friendly plan preview and confirmation

#### 8.2 Automated Disbursement Execution
```rust
pub async fn execute_monthly_disbursements(
    execution_date: DateTime<Utc>,
) -> Result<DisbursementExecutionResult, BackendError> {
    // Identify due disbursements for the date
    // Validate plan status and conditions
    // Calculate beneficiary amounts and distributions
    // Execute smart contract disbursement functions
    // Record transaction hashes and confirmations
    // Update beneficiary balances and history
    // Generate disbursement reports and notifications
    
    // Return execution summary with transaction details
}
```

**Responsibilities:**
- Automated identification of due monthly disbursements
- Validation of plan status and execution conditions
- Calculation of beneficiary amounts and distribution percentages
- Execution of smart contract disbursement functions
- Recording and verification of transaction hashes
- Real-time update of beneficiary balances and history
- Generation of comprehensive disbursement reports
- Automated notification system for all stakeholders

#### 8.3 Disbursement Monitoring and Analytics
```rust
pub async fn monitor_monthly_disbursements(
    plan_id: u256,
    time_range: TimeRange,
) -> Result<DisbursementMonitoringResult, BackendError> {
    // Track disbursement execution status
    // Monitor beneficiary payment history
    // Analyze disbursement patterns and trends
    // Generate performance metrics and reports
    // Identify potential issues and delays
    // Provide real-time status updates
    // Calculate compliance and audit data
    
    // Return comprehensive monitoring and analytics
}
```

**Responsibilities:**
- Real-time tracking of disbursement execution status
- Comprehensive monitoring of beneficiary payment history
- Advanced analytics of disbursement patterns and trends
- Generation of detailed performance metrics and reports
- Proactive identification of potential issues and delays
- Real-time status updates and notifications
- Compliance monitoring and audit data generation

#### 8.4 Disbursement Schedule Management
```rust
pub async fn manage_disbursement_schedule(
    plan_id: u256,
    schedule_updates: DisbursementScheduleUpdates,
) -> Result<ScheduleManagementResult, BackendError> {
    // Validate schedule modification requests
    // Calculate impact on future disbursements
    // Update beneficiary allocations and amounts
    // Modify disbursement timing and frequency
    // Handle pause/resume/cancel operations
    // Update smart contract state
    // Generate modified schedule preview
    
    // Return updated schedule with impact analysis
}
```

**Responsibilities:**
- Validation of disbursement schedule modification requests
- Calculation of impact on future disbursements and beneficiaries
- Dynamic update of beneficiary allocations and amounts
- Flexible modification of disbursement timing and frequency
- Comprehensive pause/resume/cancel operation handling
- Synchronization with smart contract state updates
- Generation of modified schedule previews and confirmations

#### 8.5 Tax and Compliance for Recurring Payments
```rust
pub async fn handle_monthly_disbursement_compliance(
    plan_id: u256,
    disbursement_period: DisbursementPeriod,
) -> Result<ComplianceResult, BackendError> {
    // Calculate tax implications for monthly payments
    // Generate tax reporting and documentation
    // Monitor regulatory compliance for recurring structures
    // Handle jurisdiction-specific requirements
    // Generate compliance certificates and reports
    // Track regulatory changes and updates
    // Provide tax optimization recommendations
    
    // Return compliance status with detailed reporting
}
```

**Responsibilities:**
- Calculation of tax implications for monthly disbursement payments
- Generation of comprehensive tax reporting and documentation
- Continuous monitoring of regulatory compliance for recurring structures
- Handling of jurisdiction-specific compliance requirements
- Generation of compliance certificates and regulatory reports
- Proactive tracking of regulatory changes and updates
- Provision of tax optimization recommendations and strategies

## User Experience Flow Integration

### Frontend-Backend Integration Points

#### 1. **Plan Creation Wizard**
```rust
// Step-by-step plan creation with real-time validation
pub async fn create_plan_step(
    step: PlanCreationStep,
    data: StepData,
    user_context: UserContext,
) -> Result<StepResult, BackendError> {
    // Validate current step data
    // Provide real-time feedback and suggestions
    // Store progress and allow resumption
    // Integrate with smart contract state
    // Return next step instructions
}
```

#### 2. **Real-Time Validation and Feedback**
```rust
// Provide immediate feedback during plan creation
pub async fn validate_step_data(
    step: PlanCreationStep,
    data: StepData,
) -> Result<ValidationFeedback, BackendError> {
    // Real-time validation
    // User-friendly error messages
    // Suggestions for improvement
    // Progress indicators
    // Next step recommendations
}
```

#### 3. **Interactive Preview and Confirmation**
```rust
// Generate interactive plan preview
pub async fn generate_interactive_preview(
    plan_id: u256,
) -> Result<InteractivePreview, BackendError> {
    // Visual plan representation
    // Interactive elements for modification
    // Real-time calculations and updates
    // User acceptance tracking
    // Legal acknowledgment integration
}
```

## Database Schema

### Core Tables
```sql
-- Plan Management
CREATE TABLE inheritance_plans (
    id BIGINT PRIMARY KEY,
    owner_address VARCHAR(66),
    status VARCHAR(50),
    creation_step VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    last_activity TIMESTAMP
);

-- Asset Allocations
CREATE TABLE asset_allocations (
    id BIGINT PRIMARY KEY,
    plan_id BIGINT,
    asset_type VARCHAR(50),
    amount DECIMAL(20,8),
    beneficiary_id BIGINT,
    allocation_percentage DECIMAL(5,2),
    valuation_timestamp TIMESTAMP,
    market_value DECIMAL(20,8)
);

-- Risk Assessments
CREATE TABLE risk_assessments (
    id BIGINT PRIMARY KEY,
    plan_id BIGINT,
    risk_score INTEGER,
    risk_factors JSONB,
    mitigation_strategies JSONB,
    last_updated TIMESTAMP,
    risk_trend VARCHAR(20)
);

-- Activity Logs
CREATE TABLE activity_logs (
    id BIGINT PRIMARY KEY,
    plan_id BIGINT,
    user_address VARCHAR(66),
    activity_type VARCHAR(100),
    details TEXT,
    metadata JSONB,
    timestamp TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- Plan Creation Progress
CREATE TABLE plan_creation_progress (
    plan_id BIGINT PRIMARY KEY,
    current_step VARCHAR(50),
    step_data JSONB,
    validation_status VARCHAR(50),
    last_updated TIMESTAMP,
    user_session_id VARCHAR(100)
);

-- Monthly Disbursement Plans
CREATE TABLE monthly_disbursement_plans (
    plan_id BIGINT PRIMARY KEY,
    owner_address VARCHAR(66),
    total_amount DECIMAL(20,8),
    monthly_amount DECIMAL(20,8),
    start_month TIMESTAMP,
    end_month TIMESTAMP,
    total_months INTEGER,
    completed_months INTEGER,
    next_disbursement_date TIMESTAMP,
    is_active BOOLEAN,
    beneficiaries_count INTEGER,
    disbursement_status VARCHAR(50),
    created_at TIMESTAMP,
    last_activity TIMESTAMP
);

-- Monthly Disbursements
CREATE TABLE monthly_disbursements (
    disbursement_id BIGINT PRIMARY KEY,
    plan_id BIGINT,
    month TIMESTAMP,
    amount DECIMAL(20,8),
    status VARCHAR(50),
    scheduled_date TIMESTAMP,
    executed_date TIMESTAMP,
    beneficiaries_count INTEGER,
    transaction_hash VARCHAR(66),
    FOREIGN KEY (plan_id) REFERENCES monthly_disbursement_plans(plan_id)
);

-- Disbursement Beneficiaries
CREATE TABLE disbursement_beneficiaries (
    beneficiary_id BIGINT PRIMARY KEY,
    plan_id BIGINT,
    address VARCHAR(66),
    percentage DECIMAL(5,2),
    monthly_amount DECIMAL(20,8),
    total_received DECIMAL(20,8),
    last_disbursement TIMESTAMP,
    is_active BOOLEAN,
    FOREIGN KEY (plan_id) REFERENCES monthly_disbursement_plans(plan_id)
);
```

## API Endpoints

### Plan Creation Flow
```rust
// POST /api/v1/plans/{plan_id}/rules
async fn set_plan_rules(plan_id: u256, rules: PlanRules) -> Result<()>

// POST /api/v1/plans/{plan_id}/verification
async fn set_verification_data(plan_id: u256, data: VerificationData) -> Result<()>

// POST /api/v1/plans/{plan_id}/preview
async fn generate_preview(plan_id: u256) -> Result<PlanPreview>

// GET /api/v1/plans/{plan_id}/progress
async fn get_creation_progress(plan_id: u256) -> Result<CreationProgress>

// POST /api/v1/plans/{plan_id}/validate-step
async fn validate_step_data(step: PlanCreationStep, data: StepData) -> Result<ValidationResult>
```

### Asset Management
```rust
// GET /api/v1/plans/{plan_id}/assets
async fn get_asset_allocations(plan_id: u256) -> Result<Vec<AssetAllocation>>

// POST /api/v1/plans/{plan_id}/assets/rebalance
async fn rebalance_assets(plan_id: u256, strategy: RebalanceStrategy) -> Result<()>

// GET /api/v1/plans/{plan_id}/assets/valuation
async fn get_real_time_valuation(plan_id: u256) -> Result<AssetValuation>
```

### Risk Management
```rust
// GET /api/v1/plans/{plan_id}/risk
async fn get_risk_assessment(plan_id: u256) -> Result<RiskAssessment>

// POST /api/v1/plans/{plan_id}/risk/mitigate
async fn apply_risk_mitigation(plan_id: u256, strategy: MitigationStrategy) -> Result<()>

// GET /api/v1/plans/{plan_id}/risk/monitoring
async fn get_risk_monitoring_status(plan_id: u256) -> Result<RiskMonitoringStatus>
```

### User Experience
```rust
// GET /api/v1/plans/{plan_id}/preview/interactive
async fn get_interactive_preview(plan_id: u256) -> Result<InteractivePreview>

// POST /api/v1/plans/{plan_id}/preview/accept
async fn accept_plan_preview(plan_id: u256, acceptance: PlanAcceptance) -> Result<()>

// GET /api/v1/plans/{plan_id}/dashboard
async fn get_plan_dashboard(plan_id: u256) -> Result<PlanDashboard>

// GET /api/v1/plans/{plan_id}/progress
async fn get_creation_progress(plan_id: u256) -> Result<CreationProgress>

// POST /api/v1/plans/{plan_id}/validate-step
async fn validate_step_data(step: PlanCreationStep, data: StepData) -> Result<ValidationResult>

// GET /api/v1/plans/{plan_id}/preview/interactive
async fn get_interactive_preview(plan_id: u256) -> Result<InteractivePreview>

// POST /api/v1/plans/{plan_id}/preview/accept
async fn accept_plan_preview(plan_id: u256, acceptance: PlanAcceptance) -> Result<()>

### Monthly Disbursement Management
```rust
// POST /api/v1/monthly-disbursements
async fn create_monthly_disbursement_plan(plan_data: MonthlyDisbursementPlanData) -> Result<MonthlyDisbursementPlan>

// GET /api/v1/monthly-disbursements/{plan_id}
async fn get_monthly_disbursement_plan(plan_id: u256) -> Result<MonthlyDisbursementPlan>

// POST /api/v1/monthly-disbursements/{plan_id}/execute
async fn execute_monthly_disbursement(plan_id: u256) -> Result<DisbursementExecutionResult>

// POST /api/v1/monthly-disbursements/{plan_id}/pause
async fn pause_monthly_disbursement(plan_id: u256, reason: String) -> Result<()>

// POST /api/v1/monthly-disbursements/{plan_id}/resume
async fn resume_monthly_disbursement(plan_id: u256) -> Result<()>

// PUT /api/v1/monthly-disbursements/{plan_id}/schedule
async fn update_disbursement_schedule(plan_id: u256, updates: DisbursementScheduleUpdates) -> Result<ScheduleUpdateResult>

// GET /api/v1/monthly-disbursements/{plan_id}/analytics
async fn get_disbursement_analytics(plan_id: u256, time_range: TimeRange) -> Result<DisbursementAnalytics>

// GET /api/v1/monthly-disbursements/{plan_id}/compliance
async fn get_disbursement_compliance(plan_id: u256, period: DisbursementPeriod) -> Result<ComplianceReport>
```

### Beneficiary Management

// POST /api/v1/plans/{plan_id}/beneficiaries
async fn add_beneficiary_to_plan(beneficiary_data: BeneficiaryData) -> Result<BeneficiaryResult>

// PUT /api/v1/plans/{plan_id}/beneficiaries/{beneficiary_address}
async fn update_beneficiary_percentage(beneficiary_data: BeneficiaryData) -> Result<BeneficiaryResult>

// DELETE /api/v1/plans/{plan_id}/beneficiaries/{beneficiary_address}
async fn remove_beneficiary_from_plan(beneficiary_address: String) -> Result<()>

// GET /api/v1/plans/{plan_id}/beneficiaries
async fn get_plan_beneficiaries(plan_id: u256) -> Result<Vec<BeneficiaryData>>

// POST /api/v1/plans/{plan_id}/beneficiaries/verify ⭐ NEW
async fn verify_beneficiary_identity(
    plan_id: u256,
    beneficiary_address: String,
    email_hash: String,
    name_hash: String,
) -> Result<BeneficiaryVerificationResult>

// GET /api/v1/plans/{plan_id}/beneficiaries/verifications ⭐ NEW
async fn get_beneficiary_verifications(plan_id: u256) -> Result<Vec<BeneficiaryVerificationRecord>>
```

## User Experience Flow Integration

### Frontend-Backend Integration Points

#### 1. **Plan Creation Wizard**
```rust
// Step-by-step plan creation with real-time validation
pub async fn create_plan_step(
    step: PlanCreationStep,
    data: StepData,
    user_context: UserContext,
) -> Result<StepResult, BackendError> {
    // Validate current step data
    // Provide real-time feedback and suggestions
    // Store progress and allow resumption
    // Integrate with smart contract state
    // Return next step instructions
}
```

#### 2. **Real-Time Validation and Feedback**
```rust
// Provide immediate feedback during plan creation
pub async fn validate_step_data(
    step: PlanCreationStep,
    data: StepData,
) -> Result<ValidationFeedback, BackendError> {
    // Real-time validation
    // User-friendly error messages
    // Suggestions for improvement
    // Progress indicators
    // Next step recommendations
}
```

#### 3. **Interactive Preview and Confirmation**
```rust
// Generate interactive plan preview
pub async fn generate_interactive_preview(
    plan_id: u256,
) -> Result<InteractivePreview, BackendError> {
    // Visual plan representation
    // Interactive elements for modification
    // Real-time calculations and updates
    // User acceptance tracking
    // Legal acknowledgment integration
}
```

## Integration Points

### Smart Contract Events
The backend should listen to these smart contract events:
- `RulesConditionsSet` - Trigger backend validation completion
- `VerificationCompleted` - Trigger compliance processing
- `PlanPreviewGenerated` - Trigger preview generation
- `PlanActivated` - Trigger post-activation setup
- `PlanCreationStepCompleted` - Trigger next step processing

### External Services
- **KYC Providers**: Identity verification services (Jumio, Onfido, etc.)
- **Legal Services**: Compliance checking and legal advice
- **Market Data**: Real-time asset pricing and market conditions
- **Tax Services**: Tax calculation and optimization
- **Regulatory APIs**: Compliance status checking and updates
- **Document Processing**: OCR, verification, and storage services

## Security Considerations

### Data Protection
- End-to-end encryption for sensitive data
- Secure key management with HSM integration
- Regular security audits and penetration testing
- Compliance with data protection regulations (GDPR, CCPA)
- Secure document storage and access control

### Access Control
- Role-based access control (RBAC) with fine-grained permissions
- Multi-factor authentication (MFA) for all users
- Session management with secure token handling
- Audit logging for all operations and access attempts
- IP whitelisting and geolocation restrictions

### API Security
- Rate limiting and DDoS protection
- Input validation and sanitization
- API key management with rotation
- CORS configuration and security headers
- Request signing and verification

## Performance Optimization

### Caching Strategy
- Redis for frequently accessed data and session management
- Database query optimization with indexing strategies
- CDN for static assets and content delivery
- Background job processing with queue management
- Distributed caching for high availability

### Scalability
- Horizontal scaling with load balancers and auto-scaling
- Database sharding strategies for large datasets
- Microservices architecture with service mesh
- Event-driven processing with message queues
- Container orchestration with Kubernetes

## Monitoring and Alerting

### Metrics to Track
- API response times and throughput
- Error rates and failure patterns
- Database performance and query optimization
- External service availability and response times
- User activity patterns and engagement metrics
- Security events and threat detection

### Alerting Rules
- High error rates and failure thresholds
- Slow response times and performance degradation
- Service unavailability and health check failures
- Security incidents and suspicious activities
- Compliance violations and regulatory issues
- Resource utilization and capacity planning

## Testing Strategy

### Unit Tests
- Individual service function testing with comprehensive coverage
- Mock external dependencies and service integration
- Edge case coverage and boundary testing
- Performance testing and benchmarking
- Error handling and recovery testing

### Integration Tests
- End-to-end workflow testing with real data
- Smart contract integration testing with testnet
- External service integration testing with mocks
- Database operation testing with test databases
- Cross-service communication and data flow testing

### Load Testing
- High concurrent user simulation and stress testing
- Database performance under load and optimization
- API rate limiting validation and enforcement
- Memory and CPU usage monitoring and optimization
- Scalability testing and capacity planning

## Deployment and DevOps

### Infrastructure
- Container orchestration with Kubernetes and Helm
- Infrastructure as Code with Terraform and Ansible
- CI/CD pipelines with automated testing and deployment
- Environment management with configuration management
- Monitoring and logging with ELK stack and Prometheus

### Monitoring
- Application performance monitoring (APM) with distributed tracing
- Infrastructure monitoring with resource utilization tracking
- Log aggregation and analysis with structured logging
- Real-time alerting with escalation procedures
- Health checks and automated recovery procedures

This enhanced backend implementation provides a comprehensive, scalable foundation for the InheritX platform, handling all the complex business logic while keeping the smart contract focused on critical on-chain operations. The integration with the UI design flow ensures a seamless user experience from plan creation to ongoing management.

## New Features Summary

### 1. **Enhanced Plan Creation Flow**
- **Step-by-step plan creation** with validation at each stage
- **Basic plan info management** with owner and beneficiary setup
- **Asset allocation management** with percentage validation
- **Rules and conditions validation** with guardian setup
- **Verification and legal compliance** with KYC integration
- **Plan preview generation** with risk assessment
- **Plan activation** with final confirmation

### 2. **Monthly Disbursement System**
- **Recurring payment plans** with configurable timeframes
- **Beneficiary distribution management** with percentage-based allocations
- **Disbursement execution** with automated scheduling
- **Plan control features** including pause, resume, and cancellation
- **Status tracking** and monitoring capabilities

### 3. **Advanced Security Features**
- **Enhanced escrow management** with lifecycle control
- **Security settings management** with multi-signature support
- **Wallet security management** with freeze and blacklist capabilities
- **Inactivity monitoring** with automated response systems
- **Claim code management** with secure generation and validation

### 4. **DEX Integration and Swap Management**
- **Multi-DEX routing optimization** for best execution
- **Swap request management** with slippage protection
- **Real-time execution monitoring** with status tracking
- **Gas optimization** and cost management
- **Error handling** and recovery mechanisms

### 5. **Enhanced Beneficiary Management**
- **Dynamic beneficiary addition/removal** with validation
- **Relationship management** with status tracking
- **Percentage distribution** verification and enforcement
- **Communication systems** for notifications and updates
- **Audit trails** for all beneficiary changes

### 6. **Comprehensive Activity Logging**
- **Real-time activity tracking** with metadata enrichment
- **Analytics and reporting** with performance metrics
- **Compliance monitoring** with regulatory reporting
- **Security event logging** with alert systems
- **User behavior analysis** with pattern recognition

### 7. **Fee Management System** ⭐ NEW
- **2% fee collection** on all inheritance features
- **Configurable fee parameters** with minimum and maximum limits
- **Fee recipient management** with admin controls
- **Real-time fee calculation** and collection
- **Fee analytics** and reporting
- **Fee collection events** for audit trails

### 8. **Withdrawal Request System** ⭐ NEW
- **Beneficiary withdrawal requests** for assets and NFTs
- **Multiple withdrawal types** (full, percentage, fixed amount, NFT)
- **Request approval workflow** with admin controls
- **Withdrawal processing** with fee deduction
- **Request status tracking** and monitoring
- **Withdrawal analytics** and reporting

### 9. **Enhanced KYC System** ⭐ NEW
- **Proper event emissions** for all KYC operations
- **Identity verification tracking** with detailed status
- **KYC data management** with secure storage
- **Verification workflow** with approval/rejection
- **Compliance monitoring** and reporting
- **Real-time KYC status updates**

### 10. **Enhanced Claim Code System** ⭐ NEW
- **Claim code revocation** functionality
- **Admin-controlled invalidation** with reason tracking
- **Enhanced security** with revocation events
- **Audit trail** for all claim code operations
- **Status monitoring** and tracking

This implementation ensures that the InheritX platform provides a secure, compliant, and user-friendly experience while maintaining the highest standards of security and regulatory compliance. The modular architecture allows for easy scaling and feature additions as the platform evolves.

## Smart Contract Integration

### Deployed Contract Integration

The backend integrates with the deployed split smart contracts:

#### InheritXPlans Contract Integration
- **Contract Address**: `0xfd052d74b399aa085c01bd648af009d002bcaa3a29bcde1683f4720257d1e0`
- **Primary Functions**: Plan creation, beneficiary management, monthly disbursements, inactivity monitoring
- **Key Events**: Plan lifecycle events, beneficiary events, disbursement events, inactivity events

#### InheritXOperations Contract Integration
- **Contract Address**: `0x313791f9b687cf29fd9cc9c395ce77854a6c8b6b267a2a34d6c4a5734a33050`
- **Primary Functions**: Asset management, fee collection, wallet security, swap operations
- **Key Events**: Asset events, fee events, security events, swap events

### Smart Contract Functions

The backend now integrates with the following smart contract functions for enhanced inheritance plan management:

#### 1. **Percentage-Based Plan Creation**
```rust
// Create inheritance plan with percentage-based beneficiary allocations
pub async fn create_inheritance_plan_with_percentages(
    &self,
    beneficiary_data: Vec<BeneficiaryData>,
    asset_type: AssetType,
    asset_amount: u256,
    nft_token_id: u256,
    nft_contract: ContractAddress,
    timeframe: u64,
    guardian: ContractAddress,
    encrypted_details: String,
    security_level: u8,
    auto_execute: bool,
    emergency_contacts: Vec<ContractAddress>,
) -> Result<u256, Box<dyn std::error::Error>> {
    // Validate beneficiary data and percentages
    self.validate_beneficiary_percentages(&beneficiary_data)?;
    
    // Call smart contract function
    let plan_id = self.smart_contract
        .create_inheritance_plan_with_percentages(
            beneficiary_data,
            asset_type as u8,
            asset_amount,
            nft_token_id,
            nft_contract,
            timeframe,
            guardian,
            encrypted_details,
            security_level,
            auto_execute,
            emergency_contacts,
        )
        .await?;
    
    Ok(plan_id)
}
```

#### 2. **Beneficiary Percentage Updates**
```rust
// Update beneficiary percentages for existing plans
pub async fn update_beneficiary_percentages(
    &self,
    plan_id: u256,
    beneficiary_data: Vec<BeneficiaryData>,
) -> Result<(), Box<dyn std::error::Error>> {
    // Validate updated percentages sum to 100%
    self.validate_beneficiary_percentages(&beneficiary_data)?;
    
    // Update smart contract
    self.smart_contract
        .update_beneficiary_percentages(plan_id, beneficiary_data)
        .await?;
    
    // Update database
    self.database.update_beneficiary_percentages(plan_id, &beneficiary_data).await?;
    
    Ok(())
}
```

#### 3. **Balance Validation Integration**
```rust
// Validate user has sufficient balance before plan creation
pub async fn validate_user_balance(
    &self,
    user_address: ContractAddress,
    asset_type: AssetType,
    asset_amount: u256,
) -> Result<bool, Box<dyn std::error::Error>> {
    match asset_type {
        AssetType::STRK => {
            let balance = self.strk_token.balance_of(user_address).await?;
            Ok(balance >= asset_amount)
        },
        AssetType::USDT => {
            let balance = self.usdt_token.balance_of(user_address).await?;
            Ok(balance >= asset_amount)
        },
        AssetType::USDC => {
            let balance = self.usdc_token.balance_of(user_address).await?;
            Ok(balance >= asset_amount)
        },
        AssetType::NFT => {
            // NFT ownership validation handled separately
            Ok(true)
        }
    }
}
```

#### 4. **Plan Editing Integration** ⭐ NEW
```rust
// Extend plan timeframe
pub async fn extend_plan_timeframe(
    &self,
    plan_id: u256,
    additional_time: u64,
) -> Result<(), Box<dyn std::error::Error>> {
    self.smart_contract
        .extend_plan_timeframe(plan_id, additional_time)
        .await?;
    
    // Update database with new timeframe
    self.database.update_plan_timeframe(plan_id, additional_time).await?;
    
    Ok(())
}

// Update plan parameters
pub async fn update_plan_parameters(
    &self,
    plan_id: u256,
    new_security_level: u8,
    new_auto_execute: bool,
    new_guardian: ContractAddress,
) -> Result<(), Box<dyn std::error::Error>> {
    // Validate security level
    if new_security_level < 1 || new_security_level > 5 {
        return Err(Box::new(ValidationError::InvalidSecurityLevel));
    }
    
    self.smart_contract
        .update_plan_parameters(plan_id, new_security_level, new_auto_execute, new_guardian)
        .await?;
    
    // Update database
    self.database.update_plan_parameters(plan_id, new_security_level, new_auto_execute, new_guardian).await?;
    
    Ok(())
}

// Update inactivity threshold
pub async fn update_inactivity_threshold(
    &self,
    plan_id: u256,
    new_threshold: u64,
) -> Result<(), Box<dyn std::error::Error>> {
    // Validate threshold (max 6 months)
    if new_threshold == 0 || new_threshold > 15768000 {
        return Err(Box::new(ValidationError::InvalidInactivityThreshold));
    }
    
    self.smart_contract
        .update_inactivity_threshold(plan_id, new_threshold)
        .await?;
    
    // Update database
    self.database.update_inactivity_threshold(plan_id, new_threshold).await?;
    
    Ok(())
}
```

### Data Structures

#### **BeneficiaryData**
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BeneficiaryData {
    pub address: ContractAddress,
    pub percentage: u8, // Share percentage (0-100)
    pub email_hash: String, // Hash of beneficiary email
    pub age: u8, // Age for minor protection
    pub relationship: String, // Encrypted relationship information
}
```

#### **Validation Functions**
```rust
impl BeneficiaryData {
    // Validate beneficiary data
    pub fn validate(&self) -> Result<(), ValidationError> {
        if self.percentage == 0 || self.percentage > 100 {
            return Err(ValidationError::InvalidPercentage);
        }
        if self.age > 120 {
            return Err(ValidationError::InvalidAge);
        }
        if self.email_hash.is_empty() {
            return Err(ValidationError::EmptyEmailHash);
        }
        Ok(())
    }
}

// Validate total percentage equals 100%
pub fn validate_total_percentage(
    beneficiaries: &[BeneficiaryData]
) -> Result<(), ValidationError> {
    let total: u8 = beneficiaries.iter()
        .map(|b| b.percentage)
        .sum();
    
    if total != 100 {
        return Err(ValidationError::InvalidTotalPercentage);
    }
    Ok(())
}
```

### Error Handling

The smart contract integration includes comprehensive error handling for the new functionality:

```rust
#[derive(Debug, thiserror::Error)]
pub enum SmartContractError {
    #[error("Insufficient user balance: {asset_type}")]
    InsufficientUserBalance { asset_type: AssetType },
    
    #[error("Invalid beneficiary percentages: total must equal 100%")]
    InvalidBeneficiaryPercentages,
    
    #[error("Beneficiary not found: {address}")]
    BeneficiaryNotFound { address: ContractAddress },
    
    #[error("Plan not found: {plan_id}")]
    PlanNotFound { plan_id: u256 },
    
    #[error("Unauthorized access: {operation}")]
    Unauthorized { operation: String },
    
    #[error("Invalid security level: {level} (must be 1-5)")]
    InvalidSecurityLevel { level: u8 },
    
    #[error("Invalid inactivity threshold: {threshold} (must be > 0 and ≤ 6 months)")]
    InvalidInactivityThreshold { threshold: u64 },
    
    #[error("Plan not in active state: {status}")]
    PlanNotActive { status: String },
}
```

### Security Features

1. **Balance Validation**: Prevents creation of plans with insufficient funds
2. **Percentage Validation**: Ensures beneficiary allocations sum to exactly 100%
3. **Access Control**: Only plan owners can modify beneficiary percentages
4. **Data Integrity**: All changes are recorded on-chain with event emission
5. **Audit Trail**: Complete history of all beneficiary modifications
6. **Plan Editing Security**: ⭐ NEW
   - Only plan owners can modify plan parameters
   - Timeframe extensions limited to maximum 1 year
   - Security level validation (1-5 range)
   - Inactivity threshold validation (max 6 months)
   - All modifications require plan to be in Active state 