# InheritX Smart Contract Improvement Suggestions - Cairo Implementation

## Overview
Based on the requirements analysis and UI design flow, here are comprehensive suggestions to enhance the current smart contract to better support the InheritX platform's functionality, security, and user experience. This document is specifically tailored for **Cairo smart contract development** with Rust backend services and indexer integration.

## Design Flow Alignment

The smart contract follows the exact UI design flow structure with hybrid on-chain/off-chain implementation:

### 1. **Create Plan - Basic Info** (Plan Creation) ✅ IMPLEMENTED
- **Smart Contract**: `create_plan_basic_info()` - Stores basic plan information
- **Backend**: Handles user input validation, email verification, and contact management
- **Integration**: Contract emits `BasicPlanInfoCreated` event for backend processing

### 2. **Create Plan - Asset Allocation** (Beneficiary Management) ✅ IMPLEMENTED
- **Smart Contract**: `set_asset_allocation()` - Stores beneficiaries and asset allocations
- **Backend**: Handles complex validation, percentage calculations, and asset valuation
- **Integration**: Contract emits `AssetAllocationSet` event for backend processing

### 3. **Create Plan - Rules & Conditions** (Plan Configuration) 🔄 HYBRID
- **Smart Contract**: `mark_rules_conditions_set()` - Marks step completion
- **Backend**: `validate_and_set_plan_rules()` - Handles complex business logic validation
- **Integration**: Backend validates rules, then calls contract marker function

### 4. **Create Plan - Verification & Legal Settings** (KYC & Compliance) 🔄 HYBRID
- **Smart Contract**: `mark_verification_completed()` - Marks step completion
- **Backend**: `validate_verification_and_legal()` - Handles KYC, compliance, and legal checks
- **Integration**: Backend processes verification, then calls contract marker function

### 5. **Create Plan - Preview** (Final Review) 🔄 HYBRID
- **Smart Contract**: `mark_preview_ready()` - Marks step completion
- **Backend**: `generate_plan_preview()` - Generates comprehensive preview with risk assessment
- **Integration**: Backend generates preview, then calls contract marker function

### 6. **Plan Management** (Ongoing Operations) ✅ IMPLEMENTED
- **Smart Contract**: Core plan management functions and status tracking
- **Backend**: Activity logging, analytics, and user experience features
- **Integration**: Contract emits events, backend processes and stores detailed data

### 7. **Monthly Disbursement Plans** ✅ IMPLEMENTED
- **Smart Contract**: `create_monthly_disbursement_plan()`, `execute_monthly_disbursement()`, pause/resume functions
- **Backend**: Plan creation, execution, and management services
- **Indexer**: Real-time monitoring and analytics
- **Integration**: Complete monthly distribution system with percentage-based sharing

### 8. **Beneficiary Identity Verification System** ✅ IMPLEMENTED ⭐ NEW
- **Smart Contract**: `verify_beneficiary_identity()` function with email and name hash validation
- **Security**: Multi-factor verification combining claim codes with identity checks
- **Integration**: Seamlessly integrated with inheritance claim process
- **Events**: `BeneficiaryIdentityVerified` event for monitoring and tracking

## Current Contract Analysis

### Strengths
- ✅ Comprehensive inheritance plan management with step-by-step creation flow
- ✅ KYC system integration and verification
- ✅ Swap functionality for asset conversion
- ✅ Upgradeable and pausable architecture
- ✅ Guardian system for plan oversight
- ✅ Hybrid on-chain/off-chain architecture for optimal performance
- ✅ Comprehensive event system for backend integration
- ✅ Asset allocation and beneficiary management

### Areas for Improvement
- ⚠️ Some complex functions moved to backend for gas efficiency
- ⚠️ Limited inactivity monitoring (handled by backend)
- ⚠️ No claim code generation mechanism (handled by backend)
- ⚠️ Asset escrow functionality could be enhanced

## Hybrid Architecture Implementation

### Overview
The InheritX platform implements a hybrid architecture that combines the security and immutability of blockchain technology with the performance and flexibility of modern backend services. This approach optimizes for gas costs, security, user experience, and system performance.

### Architecture Benefits

#### 1. **Gas Efficiency**
- Complex operations (validation, risk assessment, analytics) are performed off-chain
- Smart contract focuses on critical state changes and asset transfers
- Reduced gas costs for users while maintaining security

#### 2. **Performance Optimization**
- Backend services provide real-time responses and rich functionality
- Smart contract handles immutable state changes and verification
- Parallel processing of complex operations off-chain

#### 3. **User Experience Enhancement**
- Interactive interfaces and real-time feedback
- Step-by-step plan creation with validation
- Rich analytics and reporting capabilities

#### 4. **Maintainability and Scalability**
- Business logic can be updated without smart contract upgrades
- Backend services can be scaled independently
- Easier integration with external services and APIs

## Off-Chain vs On-Chain Computation Strategy

### Overview
Many functions in the InheritX platform require careful consideration of whether they should be computed on-chain or off-chain. This decision impacts gas costs, security, user experience, and system performance.

### Off-Chain Computation Required

#### 1. **Cryptographic Operations (Rust Implementation)**
- **Claim Code Generation**: Using `rand` crate for secure random number generation
- **Hash Computations**: Using `sha2` and `keccak` crates for SHA-256, Keccak-256 hashing
- **Digital Signatures**: Using `ed25519-dalek` or `secp256k1` for signature verification
- **Encryption/Decryption**: Using `aes` and `chacha20poly1305` crates for AES operations

#### 2. **Complex Calculations (Rust Implementation)**
- **Beneficiary Share Calculations**: Using `rust_decimal` for precise percentage distributions
- **Time-Based Computations**: Using `chrono` and `time` crates for date arithmetic
- **Asset Valuations**: Using `reqwest` and `serde_json` for price feed integration
- **Fee Calculations**: Using `rust_decimal` for complex fee structures and discounts

#### 3. **External Data Integration (Rust Implementation)**
- **KYC Verification**: Using `image` and `tesseract-rs` for document processing
- **Email Notifications**: Using `lettre` crate for SMTP operations
- **Market Data**: Using `reqwest` and `tokio` for async API calls
- **Regulatory Checks**: Using `serde` for compliance data serialization

#### 4. **User Experience Features (Rust Implementation)**
- **Search and Filtering**: Using `tantivy` or `meilisearch` for search operations
- **Data Aggregation**: Using `polars` for analytics and reporting
- **Notification Management**: Using `tokio` and `redis` for async processing
- **Session Management**: Using `jsonwebtoken` and `bcrypt` for authentication

### On-Chain Storage Only

#### 1. **Critical State Data**
- **Asset Ownership**: Who owns what and when
- **Plan Status**: Active, executed, cancelled states
- **Claim Status**: Whether inheritance has been claimed
- **Permission Levels**: Role-based access control

#### 2. **Verification Data**
- **Hash References**: IPFS hashes for off-chain data
- **Signature Proofs**: Cryptographic proof of actions
- **Timestamp Records**: When actions occurred
- **Event Logs**: Immutable audit trail

#### 3. **Business Logic Validation**
- **Access Control**: Who can perform what actions
- **State Transitions**: Valid plan status changes
- **Asset Transfers**: Secure token movements
- **Emergency Functions**: Pause and recovery mechanisms

### Hybrid Approach Benefits

#### 1. **Gas Optimization**
- **Reduced On-Chain Storage**: Store only essential data
- **Batch Operations**: Process multiple items together
- **Lazy Loading**: Defer non-critical computations
- **Caching Strategies**: Store frequently accessed data off-chain

#### 2. **Security Enhancement**
- **Zero-Knowledge Proofs**: Verify without revealing data
- **Multi-Signature Schemes**: Distributed decision making
- **Time-Locks**: Automated execution with delays
- **Circuit Breakers**: Emergency stop mechanisms

#### 3. **Scalability Improvements (Rust Implementation)**
- **Horizontal Scaling**: Multiple Rust backend instances using `tokio` runtime
- **Load Distribution**: Balance computational load with `actix-web` or `axum` load balancers
- **Async Processing**: Non-blocking operations with `tokio` async/await patterns
- **Microservices**: Specialized service architecture using `tonic` for gRPC communication

## Rust Ecosystem & Tools for InheritX Backend

### Core Rust Crates for Backend Development

#### 1. **Async Runtime & Concurrency**
- **`tokio`**: Async runtime for non-blocking I/O operations
- **`async-trait`**: Async trait support for service abstractions
- **`futures`**: Future and stream utilities for async programming
- **`tokio-stream`**: Stream utilities for async data processing

#### 2. **Web Framework & HTTP**
- **`axum`**: Modern, fast web framework built on `tokio` and `tower`
- **`actix-web`**: Powerful, pragmatic web framework
- **`warp`**: Lightweight web framework with functional programming
- **`tower`**: Network application primitives and middleware

#### 3. **Database & ORM**
- **`diesel`**: Safe, extensible ORM and query builder
- **`sqlx`**: Async SQL toolkit with compile-time checked queries
- **`redis`**: Redis client for caching and real-time data
- **`mongodb`**: MongoDB driver for document storage

#### 4. **Cryptography & Security**
- **`sha2`**: SHA-2 family of hash functions
- **`ed25519-dalek`**: Ed25519 signature scheme
- **`aes`**: AES encryption/decryption
- **`bcrypt`**: Password hashing
- **`jsonwebtoken`**: JWT token handling

#### 5. **Data Processing & Serialization**
- **`serde`**: Serialization framework for converting data
- **`serde_json`**: JSON serialization/deserialization
- **`polars`**: Fast data manipulation and analysis
- **`rust_decimal`**: Decimal arithmetic for financial calculations

#### 6. **Blockchain Integration**
- **`starknet-rs`**: Starknet client library
- **`web3`**: Ethereum Web3 client
- **`tonic`**: gRPC client and server implementation
- **`reqwest`**: HTTP client for external API calls

#### 7. **Monitoring & Observability**
- **`tracing`**: Application-level tracing
- **`metrics`**: Metrics collection and reporting
- **`opentelemetry`**: Distributed tracing and metrics
- **`log`**: Logging facade for Rust

#### 8. **Testing & Development**
- **`tokio-test`**: Testing utilities for async code
- **`mockall`**: Mocking framework for testing
- **`criterion`**: Benchmarking framework
- **`proptest`**: Property-based testing

## Recommended Improvements by Design Flow Step

### Step 1: Create Plan - Basic Info

#### Current Issue
The contract needs better support for the initial plan creation flow with proper validation and setup.

#### Suggested Implementation
```cairo
// Enhanced plan creation with step-by-step flow
fn create_plan_basic_info(
    ref self: ContractState,
    plan_name: ByteArray,
    plan_description: ByteArray,
    owner_email_hash: ByteArray,
    initial_beneficiary: ContractAddress,
    initial_beneficiary_email: ByteArray,
) -> u256;

// Complete plan setup after all steps
fn finalize_inheritance_plan(
    ref self: ContractState,
    basic_info_id: u256,
    asset_allocation: Array<Beneficiary>,
    rules_conditions: PlanRules,
    verification_data: VerificationData,
) -> u256;
```

#### Rust Backend Implementation
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanCreationService {
    database: Arc<Database>,
    smart_contract: Arc<SmartContractClient>,
    validation_service: Arc<ValidationService>,
}

impl PlanCreationService {
    // Step 1: Create basic plan info
    pub async fn create_basic_info(
        &self,
        plan_data: &BasicPlanInfo,
    ) -> Result<u256, Box<dyn std::error::Error>> {
        // Validate input data
        self.validation_service.validate_basic_info(plan_data).await?;
        
        // Create basic plan on-chain
        let basic_info_id = self.smart_contract
            .create_plan_basic_info(
                &plan_data.name,
                &plan_data.description,
                &plan_data.owner_email_hash,
                &plan_data.initial_beneficiary,
                &plan_data.initial_beneficiary_email,
            )
            .await?;
        
        // Store in database for completion tracking
        self.database.store_basic_info(basic_info_id, plan_data).await?;
        
        Ok(basic_info_id)
    }
    
    // Final step: Complete plan creation
    pub async fn finalize_plan(
        &self,
        basic_info_id: u256,
        asset_allocation: &[Beneficiary],
        rules_conditions: &PlanRules,
        verification_data: &VerificationData,
    ) -> Result<u256, Box<dyn std::error::Error>> {
        // Validate all components
        self.validation_service.validate_complete_plan(
            asset_allocation,
            rules_conditions,
            verification_data,
        ).await?;
        
        // Finalize on-chain
        let plan_id = self.smart_contract
            .finalize_inheritance_plan(
                basic_info_id,
                asset_allocation,
                rules_conditions,
                verification_data,
            )
            .await?;
        
        // Update database status
        self.database.mark_plan_complete(basic_info_id, plan_id).await?;
        
        Ok(plan_id)
    }
}
```

### Step 2: Create Plan - Asset Allocation

#### Current Issue
✅ **IMPLEMENTED**: The contract now supports multiple beneficiaries with percentage-based allocation and asset management.

#### Current Implementation
The contract includes the following percentage-based functionality:

```cairo
// Create inheritance plan with percentage-based beneficiary allocations
fn create_inheritance_plan_with_percentages(
    ref self: ContractState,
    beneficiary_data: Array<BeneficiaryData>,
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

// Update beneficiary percentages for existing plans
fn update_beneficiary_percentages(
    ref self: ContractState,
    plan_id: u256,
    beneficiary_data: Array<BeneficiaryData>,
);

// Get beneficiary data with percentages
fn get_beneficiary_percentages(
    self: @ContractState,
    plan_id: u256,
) -> Array<BeneficiaryData>;

// Plan editing functions
fn extend_plan_timeframe(
    ref self: ContractState,
    plan_id: u256,
    additional_time: u64,
);

fn update_plan_parameters(
    ref self: ContractState,
    plan_id: u256,
    new_security_level: u8,
    new_auto_execute: bool,
    new_guardian: ContractAddress,
);

fn update_inactivity_threshold(
    ref self: ContractState,
    plan_id: u256,
    new_threshold: u64,
);
```

**BeneficiaryData Structure**:
```cairo
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct BeneficiaryData {
    pub address: ContractAddress,
    pub percentage: u8, // Share percentage (0-100)
    pub email_hash: ByteArray, // Hash of beneficiary email
    pub age: u8, // Age for minor protection
    pub relationship: ByteArray, // Encrypted relationship information
}
```

**Balance Validation**:
- ✅ On-chain validation of user token balances before plan creation
- ✅ Prevents creation of plans with insufficient funds
- ✅ Supports STRK, USDT, and USDC balance checking

#### Suggested Implementation
```cairo
// Enhanced beneficiary management
fn add_beneficiary_with_assets(
    ref self: ContractState,
    plan_id: u256,
    beneficiary: ContractAddress,
    percentage: u8,
    asset_type: AssetType,
    asset_amount: u256,
    nft_token_id: u256,
    nft_contract: ContractAddress,
    email_hash: ByteArray,
    age: u8,
    relationship: ByteArray,
);

// Asset allocation validation
fn validate_asset_allocation(
    self: @ContractState,
    plan_id: u256,
) -> bool;
```

#### Rust Backend Implementation
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AssetAllocationService {
    database: Arc<Database>,
    smart_contract: Arc<SmartContractClient>,
    asset_validation_service: Arc<AssetValidationService>,
}

impl AssetAllocationService {
    // Add beneficiary with asset allocation
    pub async fn add_beneficiary_with_assets(
        &self,
        plan_id: u256,
        beneficiary_data: &BeneficiaryAssetAllocation,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Validate asset allocation
        self.asset_validation_service
            .validate_beneficiary_allocation(plan_id, beneficiary_data)
            .await?;
        
        // Add to smart contract
        self.smart_contract
            .add_beneficiary_with_assets(
                plan_id,
                &beneficiary_data.address,
                beneficiary_data.percentage,
                beneficiary_data.asset_type as u8,
                beneficiary_data.asset_amount,
                beneficiary_data.nft_token_id,
                beneficiary_data.nft_contract,
                &beneficiary_data.email_hash,
                beneficiary_data.age,
                &beneficiary_data.relationship,
            )
            .await?;
        
        // Update database
        self.database.store_beneficiary_allocation(plan_id, beneficiary_data).await?;
        
        Ok(())
    }
    
    // Validate total allocation doesn't exceed 100%
    pub async fn validate_total_allocation(
        &self,
        plan_id: u256,
    ) -> Result<bool, Box<dyn std::error::Error>> {
        let beneficiaries = self.database.get_plan_beneficiaries(plan_id).await?;
        let total_percentage: u8 = beneficiaries.iter().map(|b| b.percentage).sum();
        
        Ok(total_percentage <= 100)
    }
}
```

### Step 3: Create Plan - Rules & Conditions

#### Current Issue
The contract needs comprehensive rules and conditions management for plan execution.

#### Suggested Implementation
```cairo
// Enhanced plan rules and conditions
fn set_plan_rules_and_conditions(
    ref self: ContractState,
    plan_id: u256,
    rules: PlanRules,
);

// Validate execution conditions
fn validate_execution_conditions(
    self: @ContractState,
    plan_id: u256,
) -> bool;
```

#### Rust Backend Implementation
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanRulesService {
    database: Arc<Database>,
    smart_contract: Arc<SmartContractClient>,
    rules_validation_service: Arc<RulesValidationService>,
}

impl PlanRulesService {
    // Set plan rules and conditions
    pub async fn set_plan_rules(
        &self,
        plan_id: u256,
        rules: &PlanRules,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Validate rules
        self.rules_validation_service.validate_plan_rules(rules).await?;
        
        // Set on-chain
        self.smart_contract
            .set_plan_rules_and_conditions(plan_id, rules)
            .await?;
        
        // Store in database
        self.database.store_plan_rules(plan_id, rules).await?;
        
        Ok(())
    }
    
    // Validate execution conditions
    pub async fn validate_execution_conditions(
        &self,
        plan_id: u256,
    ) -> Result<bool, Box<dyn std::error::Error>> {
        let rules = self.database.get_plan_rules(plan_id).await?;
        
        for condition in &rules.execution_conditions {
            if !self.check_condition(condition).await? {
                return Ok(false);
            }
        }
        
        Ok(true)
    }
}
```

### Step 4: Create Plan - Verification & Legal Settings

#### Current Issue
The contract needs enhanced KYC and legal compliance features.

#### Suggested Implementation
```cairo
// Enhanced verification data
fn set_verification_and_legal_settings(
    ref self: ContractState,
    plan_id: u256,
    verification_data: VerificationData,
);

// Validate KYC and compliance
fn validate_verification_data(
    self: @ContractState,
    plan_id: u256,
) -> bool;
```

#### Rust Backend Implementation
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationService {
    database: Arc<Database>,
    smart_contract: Arc<SmartContractClient>,
    kyc_service: Arc<KYCService>,
    legal_service: Arc<LegalComplianceService>,
}

impl VerificationService {
    // Set verification and legal settings
    pub async fn set_verification_settings(
        &self,
        plan_id: u256,
        verification_data: &VerificationData,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Verify KYC status
        let kyc_valid = self.kyc_service.verify_kyc_status(&verification_data.kyc_status).await?;
        if !kyc_valid {
            return Err("KYC verification failed".into());
        }
        
        // Check legal compliance
        let legal_valid = self.legal_service.check_compliance(&verification_data.legal_compliance).await?;
        if !legal_valid {
            return Err("Legal compliance check failed".into());
        }
        
        // Set on-chain
        self.smart_contract
            .set_verification_and_legal_settings(plan_id, verification_data)
            .await?;
        
        // Store in database
        self.database.store_verification_data(plan_id, verification_data).await?;
        
        Ok(())
    }
}
```

### Step 5: Create Plan - Preview

#### Current Issue
The contract needs comprehensive plan preview and validation before activation.

#### Suggested Implementation
```cairo
// Plan preview and validation
fn preview_inheritance_plan(
    self: @ContractState,
    plan_id: u256,
) -> PlanPreview;

// Activate plan after preview
fn activate_inheritance_plan(
    ref self: ContractState,
    plan_id: u256,
    activation_confirmation: ByteArray,
);
```

#### Rust Backend Implementation
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanPreviewService {
    database: Arc<Database>,
    smart_contract: Arc<SmartContractClient>,
    preview_generator: Arc<PreviewGenerator>,
}

impl PlanPreviewService {
    // Generate plan preview
    pub async fn generate_plan_preview(
        &self,
        plan_id: u256,
    ) -> Result<PlanPreview, Box<dyn std::error::Error>> {
        // Get plan data from database
        let plan_data = self.database.get_complete_plan_data(plan_id).await?;
        
        // Generate preview
        let preview = self.preview_generator.generate_preview(&plan_data).await?;
        
        // Validate preview
        self.validate_plan_preview(&preview).await?;
        
        Ok(preview)
    }
    
    // Activate plan after preview confirmation
    pub async fn activate_plan(
        &self,
        plan_id: u256,
        confirmation: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Verify confirmation
        if confirmation != "CONFIRM" {
            return Err("Invalid confirmation".into());
        }
        
        // Activate on-chain
        self.smart_contract
            .activate_inheritance_plan(plan_id, confirmation)
            .await?;
        
        // Update database status
        self.database.mark_plan_active(plan_id).await?;
        
        Ok(())
    }
}
```

### Step 6: Plan Management

#### Current Issue
The contract needs better plan management, monitoring, and status tracking.

#### Suggested Implementation
```cairo
// Enhanced plan management functions
fn get_plan_summary(
    self: @ContractState,
    plan_id: u256,
) -> PlanSummary;

fn update_plan_status(
    ref self: ContractState,
    plan_id: u256,
    new_status: PlanStatus,
);

fn get_user_plans(
    self: @ContractState,
    user_address: ContractAddress,
) -> Array<u256>;
```

#### Rust Backend Implementation
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanManagementService {
    database: Arc<Database>,
    smart_contract: Arc<SmartContractClient>,
    plan_monitor: Arc<PlanMonitor>,
}

impl PlanManagementService {
    // Get plan summary
    pub async fn get_plan_summary(
        &self,
        plan_id: u256,
    ) -> Result<PlanSummary, Box<dyn std::error::Error>> {
        // Get on-chain data
        let on_chain_summary = self.smart_contract.get_plan_summary(plan_id).await?;
        
        // Enhance with off-chain data
        let off_chain_data = self.database.get_plan_metadata(plan_id).await?;
        
        let summary = PlanSummary {
            on_chain: on_chain_summary,
            off_chain: off_chain_data,
            last_updated: Utc::now(),
        };
        
        Ok(summary)
    }
    
    // Update plan status
    pub async fn update_plan_status(
        &self,
        plan_id: u256,
        new_status: PlanStatus,
        reason: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Update on-chain
        self.smart_contract
            .update_plan_status(plan_id, new_status as u8, reason)
            .await?;
        
        // Update database
        self.database.update_plan_status(plan_id, new_status, reason).await?;
        
        // Notify relevant parties
        self.notify_status_change(plan_id, new_status, reason).await?;
        
        Ok(())
    }
}
```

### Step 7: Activity Log

#### Current Issue
The contract needs comprehensive activity logging and monitoring.

#### Suggested Implementation
```cairo
// Enhanced activity logging
fn log_activity(
    ref self: ContractState,
    plan_id: u256,
    activity_type: u8,
    details: ByteArray,
);

fn get_activity_log(
    self: @ContractState,
    plan_id: u256,
    limit: u8,
) -> Array<ActivityLog>;
```

#### Rust Backend Implementation
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActivityLogService {
    database: Arc<Database>,
    smart_contract: Arc<SmartContractClient>,
    log_processor: Arc<LogProcessor>,
}

impl ActivityLogService {
    // Log activity
    pub async fn log_activity(
        &self,
        plan_id: u256,
        activity_type: ActivityType,
        details: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Log on-chain
        self.smart_contract
            .log_activity(plan_id, activity_type as u8, details)
            .await?;
        
        // Store in database for indexing
        let activity = ActivityLogEntry {
            plan_id,
            activity_type,
            details: details.to_string(),
            timestamp: Utc::now(),
            user_address: self.get_current_user().await?,
        };
        
        self.database.store_activity_log(activity).await?;
        
        // Process for notifications
        self.log_processor.process_activity(&activity).await?;
        
        Ok(())
    }
    
    // Get activity log
    pub async fn get_activity_log(
        &self,
        plan_id: u256,
        limit: u8,
    ) -> Result<Vec<ActivityLogEntry>, Box<dyn std::error::Error>> {
        // Get from database (more efficient for reading)
        let activities = self.database.get_activity_log(plan_id, limit).await?;
        
        Ok(activities)
    }
}
```

## Additional Improvements

#### Suggested Implementation
```cairo
// Add to types.cairo
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct Beneficiary {
    pub address: ContractAddress,
    pub email_hash: ByteArray, // Hash of beneficiary email
    pub percentage: u8, // Share percentage (0-100)
    pub has_claimed: bool,
    pub claimed_amount: u256,
    pub claim_code_hash: ByteArray,
    pub added_at: u64,
}

// Add to Storage struct
beneficiaries: Map<u256, Array<Beneficiary>>, // plan_id -> beneficiaries
beneficiary_claim_status: Map<u256, Map<ContractAddress, bool>>, // plan_id -> beneficiary -> claimed
```

#### Benefits
- Track individual beneficiary shares
- Support multiple beneficiaries per plan
- Enable partial claiming
- Better audit trail

### 2. Claim Code System Implementation ✅ COMPLETED

#### Current Status
The contract now has a complete enhanced claim code system with hash-based validation, time-based security, and multi-layer protection.

#### Implemented Features ✅
- **Hash-Based Validation**: Secure cryptographic verification using on-chain hashing
- **Time-Based Security**: Configurable expiration and activation controls
- **Usage Tracking**: Prevents duplicate usage and tracks claim history
- **Revocation Support**: Admin-controlled claim code invalidation
- **Multi-Layer Protection**: Multiple validation layers for enhanced security
- **Off-Chain Generation**: Secure off-chain claim code creation with on-chain validation
- **Event Logging**: Comprehensive audit trail for all claim code operations

#### Current Implementation
```cairo
// Claim code storage and validation
claim_codes: Map<u256, ClaimCode>, // plan_id -> claim_code
```

#### Implemented Functions ✅
```cairo
// Store claim code hash (called by backend after off-chain generation)
fn store_claim_code_hash(
    ref self: ContractState,
    plan_id: u256,
    beneficiary: ContractAddress,
    code_hash: ByteArray,
    timeframe: u64,
);

// Hash claim code for validation purposes
fn hash_claim_code(
    self: @ContractState,
    code: ByteArray,
) -> ByteArray;

// Claim inheritance with enhanced validation
fn claim_inheritance(
    ref self: ContractState,
    plan_id: u256,
    claim_code: ByteArray,
) -> bool;
```

#### Enhanced Security Features ✅
- **Hash Validation**: On-chain verification of claim code hashes
- **Expiration Checks**: Time-based code expiration with contract validation
- **Usage Status**: Prevents duplicate usage with comprehensive tracking
- **Revocation Support**: Admin-controlled invalidation for security management
- **Multi-Layer Validation**: Hash matching, expiration, usage status, and revocation checks
- **Security Controls**: Contract-level security settings for minimum timeframes

### 3. Enhanced Inactivity Monitoring

#### Current Issue
The contract has basic inactivity tracking but lacks comprehensive monitoring and automatic triggering.

#### Off-Chain vs On-Chain Considerations (Rust Implementation)
**Off-Chain Computation Required:**
- **Wallet Activity Monitoring**: Using `tokio` for continuous blockchain scanning with `starknet-rs`
- **Inactivity Detection**: Using `chrono` and `time` for time-based threshold calculations
- **Email Notifications**: Using `lettre` crate for automated alert delivery
- **Activity Pattern Analysis**: Using `polars` for complex behavioral analysis

**On-Chain Storage Only:**
- **Monitor Configuration**: Threshold settings and email hashes stored with `diesel` ORM
- **Last Activity Timestamp**: When wallet was last active using `chrono::Utc::now()`
- **Trigger Status**: Whether inactivity has been detected with `redis` for real-time updates
- **Event Logging**: Inactivity trigger events using `tracing` crate for logging

#### Suggested Implementation
```cairo
// Add to types.cairo
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct InactivityMonitor {
    pub wallet_address: ContractAddress,
    pub threshold: u64, // Inactivity threshold in seconds
    pub last_activity: u64,
    pub beneficiary_email_hash: ByteArray,
    pub is_active: bool,
    pub created_at: u64,
    pub triggered_at: u64,
}

// Add to Storage struct
inactivity_monitors: Map<ContractAddress, InactivityMonitor>,
inactivity_triggers: Map<u256, InactivityTrigger>, // trigger_id -> trigger
```

#### New Functions
```cairo
// Create inactivity monitor (called by backend)
fn create_inactivity_monitor(
    ref self: ContractState,
    beneficiary_email_hash: ByteArray,
    threshold: u64,
);

// Update wallet activity (called by indexer)
fn update_wallet_activity(
    ref self: ContractState,
    wallet_address: ContractAddress,
);

// Check inactivity status (on-chain verification)
fn check_inactivity_status(
    self: @ContractState,
    wallet_address: ContractAddress,
) -> bool;
```

#### Off-Chain Indexer Functions (Rust Implementation)
```rust
// Backend inactivity monitoring service
use tokio::sync::Mutex;
use std::collections::HashMap;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone)]
pub struct InactivityMonitoringService {
    database: Arc<Database>,
    smart_contract: Arc<SmartContractClient>,
    blockchain_client: Arc<BlockchainClient>,
    email_service: Arc<EmailService>,
    monitors: Arc<Mutex<HashMap<String, InactivityMonitor>>>,
}

impl InactivityMonitoringService {
    // Monitor wallet activity continuously
    pub async fn monitor_wallet_activity(
        &self,
        wallet_address: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let monitor = self.get_inactivity_monitor(wallet_address).await?;
        if monitor.is_none() {
            return Ok(());
        }
        let monitor = monitor.unwrap();
        
        let last_activity = self.get_last_wallet_activity(wallet_address).await?;
        let current_time = Utc::now().timestamp();
        let time_since_activity = current_time - last_activity;
        
        if time_since_activity >= monitor.threshold as i64 && !monitor.triggered {
            // Trigger inactivity alert
            self.trigger_inactivity_alert(wallet_address, &monitor).await?;
            
            // Update on-chain status
            self.smart_contract
                .update_wallet_activity(wallet_address)
                .await?;
        }
        
        Ok(())
    }
    
    // Get last wallet activity from blockchain
    pub async fn get_last_wallet_activity(
        &self,
        wallet_address: &str,
    ) -> Result<i64, Box<dyn std::error::Error>> {
        let transactions = self.blockchain_client
            .get_recent_transactions(wallet_address)
            .await?;
        
        if let Some(last_tx) = transactions.first() {
            Ok(last_tx.timestamp)
        } else {
            Ok(0)
        }
    }
    
    // Trigger inactivity alert
    pub async fn trigger_inactivity_alert(
        &self,
        wallet_address: &str,
        monitor: &InactivityMonitor,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Send email notification
        self.email_service
            .send_inactivity_alert(&monitor.beneficiary_email, wallet_address)
            .await?;
        
        // Update database
        self.database
            .update_inactivity_trigger(wallet_address, true)
            .await?;
        
        // Emit on-chain event
        self.smart_contract
            .emit_inactivity_triggered(wallet_address, monitor.threshold)
            .await?;
        
        Ok(())
    }
}
```

### 4. Asset Escrow System

#### Current Issue
The contract doesn't have a proper escrow mechanism to hold assets until inheritance is claimed.

#### Off-Chain vs On-Chain Considerations (Rust Implementation)
**Off-Chain Computation Required:**
- **Asset Valuation**: Using `reqwest` and `serde_json` for real-time price calculations
- **Fee Calculations**: Using `rust_decimal` for complex fee structures and tax calculations
- **Asset Allocation**: Using `polars` for percentage-based distribution logic
- **Market Data**: Using `tokio` and `reqwest` for exchange rates and liquidity checks

**On-Chain Storage Only:**
- **Asset Locks**: Token amounts and contract addresses stored with `diesel` ORM
- **Escrow Status**: Locked, released, emergency states using `redis` for real-time status
- **Beneficiary Mapping**: Who gets what assets with `diesel` for relational data
- **Release Conditions**: Time-based or claim-based triggers using `chrono` for time management

#### Suggested Implementation
```cairo
// Add to types.cairo
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct EscrowAccount {
    pub plan_id: u256,
    pub asset_type: AssetType,
    pub amount: u256,
    pub nft_token_id: u256,
    pub nft_contract: ContractAddress,
    pub is_locked: bool,
    pub locked_at: u64,
    pub beneficiary: ContractAddress,
}

// Add to Storage struct
escrow_accounts: Map<u256, EscrowAccount>, // plan_id -> escrow
escrow_balances: Map<ContractAddress, Map<AssetType, u256>>, // contract -> asset_type -> balance
```

#### New Functions
```cairo
// Lock assets in escrow (called by backend after validation)
fn lock_assets_in_escrow(
    ref self: ContractState,
    plan_id: u256,
    asset_type: u8,
    amount: u256,
);

// Release assets from escrow (on-chain execution)
fn release_assets_from_escrow(
    ref self: ContractState,
    plan_id: u256,
    beneficiary: ContractAddress,
);

// Emergency escrow release (admin function)
fn emergency_escrow_release(
    ref self: ContractState,
    plan_id: u256,
);
```

#### Off-Chain Backend Functions (Rust Implementation)
```rust
// Backend escrow management service
use tokio::sync::Mutex;
use std::collections::HashMap;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use crate::database::Database;
use crate::smart_contract::SmartContractClient;
use crate::models::{Asset, Beneficiary, AssetAllocation};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EscrowManagementService {
    database: Arc<Database>,
    smart_contract: Arc<SmartContractClient>,
    asset_cache: Arc<Mutex<HashMap<String, Decimal>>>,
}

impl EscrowManagementService {
    // Calculate asset allocation for beneficiaries
    pub async fn calculate_asset_allocation(
        &self,
        plan_id: &str,
        beneficiaries: &[Beneficiary],
    ) -> Result<Vec<AssetAllocation>, Box<dyn std::error::Error>> {
        let plan = self.get_inheritance_plan(plan_id).await?;
        let total_value = self.calculate_total_asset_value(&plan.assets).await?;
        
        let allocations: Vec<AssetAllocation> = beneficiaries
            .iter()
            .map(|beneficiary| {
                let amount = self.calculate_beneficiary_amount(total_value, beneficiary.percentage);
                let fees = self.calculate_fees(beneficiary.percentage, total_value);
                
                AssetAllocation {
                    address: beneficiary.address.clone(),
                    percentage: beneficiary.percentage,
                    amount,
                    fees,
                }
            })
            .collect();
        
        Ok(allocations)
    }
    
    // Calculate total asset value with market data
    pub async fn calculate_total_asset_value(&self, assets: &[Asset]) -> Result<Decimal, Box<dyn std::error::Error>> {
        let mut total_value = Decimal::ZERO;
        
        for asset in assets {
            match asset.asset_type.as_str() {
                "token" => {
                    let price = self.get_token_price(&asset.token_address).await?;
                    total_value += asset.amount * price;
                }
                "nft" => {
                    let nft_value = self.get_nft_value(&asset.nft_contract, asset.nft_token_id).await?;
                    total_value += nft_value;
                }
                _ => return Err("Invalid asset type".into()),
            }
        }
        
        Ok(total_value)
    }
    
    // Lock assets in escrow with validation
    pub async fn lock_assets_in_escrow(
        &self,
        plan_id: &str,
        asset_allocations: &[AssetAllocation],
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Validate asset availability
        for allocation in asset_allocations {
            let balance = self.check_asset_balance(plan_id, &allocation.asset_type).await?;
            if balance < allocation.amount {
                return Err(format!(
                    "Insufficient assets for beneficiary {}",
                    allocation.address
                ).into());
            }
        }
        
        // Lock assets on-chain
        for allocation in asset_allocations {
            self.smart_contract
                .lock_assets_in_escrow(
                    plan_id,
                    allocation.asset_type.as_str(),
                    allocation.amount,
                )
                .await?;
        }
        
        // Update database
        self.database.update_escrow_status(plan_id, "locked").await?;
        
        Ok(())
    }
}
```

### 5. Enhanced Event System

#### Current Issue
The contract lacks comprehensive events for better indexing and monitoring.

#### Suggested Implementation
```cairo
// Add to Event enum
#[event]
#[derive(Drop, starknet::Event)]
pub enum Event {
    #[flat]
    UpgradeableEvent: UpgradeableComponent::Event,
    #[flat]
    PausableEvent: PausableComponent::Event,
    
    // Inheritance Plan Events
    InheritancePlanCreated: InheritancePlanCreated,
    InheritancePlanUpdated: InheritancePlanUpdated,
    InheritancePlanExecuted: InheritancePlanExecuted,
    InheritancePlanCancelled: InheritancePlanCancelled,
    
    // Beneficiary Events
    BeneficiaryAdded: BeneficiaryAdded,
    BeneficiaryRemoved: BeneficiaryRemoved,
    BeneficiaryClaimed: BeneficiaryClaimed,
    
    // Claim Code Events
    ClaimCodeGenerated: ClaimCodeGenerated,
    ClaimCodeUsed: ClaimCodeUsed,
    ClaimCodeRevoked: ClaimCodeRevoked,
    
    // Escrow Events
    AssetsLocked: AssetsLocked,
    AssetsReleased: AssetsReleased,
    EscrowCreated: EscrowCreated,
    
    // Inactivity Events
    InactivityMonitorCreated: InactivityMonitorCreated,
    InactivityTriggered: InactivityTriggered,
    WalletActivityUpdated: WalletActivityUpdated,
    
    // KYC Events
    KYCUploaded: KYCUploaded,
    KYCApproved: KYCApproved,
    KYCRejected: KYCRejected,
}

// Event structs
#[derive(Drop, starknet::Event)]
pub struct InheritancePlanCreated {
    pub plan_id: u256,
    pub owner: ContractAddress,
    pub asset_type: AssetType,
    pub amount: u256,
    pub timeframe: u64,
    pub beneficiary_count: u8,
    pub created_at: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BeneficiaryClaimed {
    pub plan_id: u256,
    pub beneficiary: ContractAddress,
    pub amount: u256,
    pub claimed_at: u64,
    pub claim_code: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct InactivityTriggered {
    pub wallet_address: ContractAddress,
    pub threshold: u64,
    pub triggered_at: u64,
    pub beneficiary_email_hash: ByteArray,
}
```

### 6. Improved Access Control

#### Current Issue
Limited role-based access control and guardian functionality.

#### Suggested Implementation
```cairo
// Add to types.cairo
#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum UserRole {
    Owner,
    Beneficiary,
    Guardian,
    Admin,
    EmergencyContact,
}

// Add to Storage struct
user_roles: Map<u256, Map<ContractAddress, UserRole>>, // plan_id -> user -> role
guardian_permissions: Map<ContractAddress, GuardianPermissions>,
```

#### New Functions
```cairo
// Assign user role
fn assign_user_role(
    ref self: ContractState,
    plan_id: u256,
    user: ContractAddress,
    role: UserRole,
);

// Check user permission
fn has_permission(
    self: @ContractState,
    plan_id: u256,
    user: ContractAddress,
    required_role: UserRole,
) -> bool;

// Guardian override
fn guardian_override(
    ref self: ContractState,
    plan_id: u256,
    action: u8,
    reason: ByteArray,
);
```

### 7. Enhanced Asset Management

#### Current Issue
Limited support for different asset types and conversion mechanisms.

#### Suggested Implementation
```cairo
// Add to types.cairo
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct Asset {
    pub asset_type: AssetType,
    pub amount: u256,
    pub token_address: ContractAddress,
    pub nft_token_id: u256,
    pub nft_contract: ContractAddress,
    pub is_locked: bool,
    pub lock_duration: u64,
}

// Add to Storage struct
plan_assets: Map<u256, Array<Asset>>, // plan_id -> assets
asset_conversions: Map<u256, AssetConversion>, // conversion_id -> conversion
```

#### New Functions
```cairo
// Add asset to plan
fn add_asset_to_plan(
    ref self: ContractState,
    plan_id: u256,
    asset_type: u8,
    amount: u256,
    token_address: ContractAddress,
);

// Convert asset
fn convert_asset(
    ref self: ContractState,
    plan_id: u256,
    from_asset: u8,
    to_asset: u8,
    amount: u256,
    slippage_tolerance: u256,
);

// Lock asset
fn lock_asset(
    ref self: ContractState,
    plan_id: u256,
    asset_index: u8,
    lock_duration: u64,
);
```

### 8. Time-Based Triggers

#### Current Issue
Limited support for time-based plan execution and monitoring.

#### Suggested Implementation
```cairo
// Add to types.cairo
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct TimeTrigger {
    pub trigger_id: u256,
    pub plan_id: u256,
    pub trigger_type: TimeTriggerType,
    pub trigger_time: u64,
    pub is_executed: bool,
    pub executed_at: u64,
}

#[derive(Serde, Drop, Copy, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum TimeTriggerType {
    PlanMaturity,
    InactivityCheck,
    EscrowRelease,
    Notification,
}
```

#### New Functions
```cairo
// Create time trigger
fn create_time_trigger(
    ref self: ContractState,
    plan_id: u256,
    trigger_type: u8,
    trigger_time: u64,
);

// Execute time trigger
fn execute_time_trigger(
    ref self: ContractState,
    trigger_id: u256,
);

// Check pending triggers
fn get_pending_triggers(
    self: @ContractState,
    current_time: u64,
) -> Array<TimeTrigger>;
```

### 9. Enhanced Security Features

#### Current Issue
Basic security with room for improvement.

#### Suggested Implementation
```cairo
// Add to types.cairo
#[derive(Serde, Drop, Clone, starknet::Store, PartialEq)]
pub struct SecuritySettings {
    pub max_beneficiaries: u8,
    pub min_timeframe: u64,
    pub max_timeframe: u64,
    pub require_guardian: bool,
    pub allow_early_execution: bool,
    pub max_asset_amount: u256,
}

// Add to Storage struct
security_settings: SecuritySettings,
suspicious_activity: Map<ContractAddress, SuspiciousActivity>,
```

#### New Functions
```cairo
// Update security settings
fn update_security_settings(
    ref self: ContractState,
    max_beneficiaries: u8,
    min_timeframe: u64,
    max_timeframe: u64,
    require_guardian: bool,
);

// Report suspicious activity
fn report_suspicious_activity(
    ref self: ContractState,
    wallet_address: ContractAddress,
    activity_type: u8,
    description: ByteArray,
);

// Freeze suspicious wallet
fn freeze_suspicious_wallet(
    ref self: ContractState,
    wallet_address: ContractAddress,
);
```

### 10. Gas Optimization

#### Current Issue
Some functions may be gas-intensive.

#### Suggested Implementation
```cairo
// Batch operations
fn batch_add_beneficiaries(
    ref self: ContractState,
    plan_id: u256,
    beneficiaries: Array<ContractAddress>,
    percentages: Array<u8>,
);

// Optimized storage patterns
// Use packed structs where possible
// Minimize storage reads/writes
// Use events for data that doesn't need on-chain storage
```

## Hybrid Architecture Pattern

### Overview
The InheritX platform uses a hybrid architecture that combines on-chain security with off-chain efficiency. This pattern ensures that critical operations are secure and verifiable while maintaining high performance and user experience.

### Architecture Principles

#### 1. **On-Chain as Source of Truth**
- **Critical State**: Asset ownership, plan status, permissions
- **Verification Data**: Hash references, signatures, timestamps
- **Business Rules**: Access control, state transitions, constraints
- **Event Logging**: Immutable audit trail for all operations

#### 2. **Off-Chain for Computation**
- **Complex Calculations**: Mathematical operations, aggregations
- **External Integrations**: APIs, email services, market data
- **User Experience**: Search, filtering, notifications
- **Performance Optimization**: Caching, batching, async processing

#### 3. **Hybrid Validation**
- **Backend Validation**: Input validation, business logic checks
- **On-Chain Verification**: Cryptographic proof verification
- **Cross-Reference Validation**: Ensure consistency between systems
- **Audit Trail**: Complete operation history across both layers

### Data Flow Patterns

#### Pattern 1: Write-Through with Verification
```
1. Backend validates input and performs calculations
2. Backend calls smart contract with verified data
3. Smart contract stores data and emits events
4. Indexer processes events and updates off-chain state
5. Backend confirms operation completion
```

#### Pattern 2: Read-Through with Caching
```
1. Frontend requests data from backend
2. Backend checks cache for recent data
3. If cache miss, backend queries smart contract
4. Backend caches result and returns to frontend
5. Indexer updates cache when new events occur
```

#### Pattern 3: Event-Driven Synchronization
```
1. Smart contract emits event for state change
2. Indexer processes event and updates database
3. Backend receives real-time updates via WebSocket
4. Frontend displays updated information
5. Cache is invalidated and refreshed
```

### Security Considerations

#### 1. **Data Integrity**
- **Hash Verification**: All off-chain data referenced by hashes
- **Signature Validation**: Cryptographic proof of authenticity
- **Timestamp Validation**: Ensure data freshness and ordering
- **Cross-Reference Checks**: Validate consistency across systems

#### 2. **Access Control**
- **Role-Based Permissions**: Granular access control
- **Multi-Signature Requirements**: Critical operations require multiple approvals
- **Time-Based Restrictions**: Operations limited by time constraints
- **Emergency Overrides**: Admin functions for critical situations

#### 3. **Audit and Compliance**
- **Complete Audit Trail**: All operations logged and verifiable
- **Regulatory Compliance**: KYC/AML, GDPR, tax reporting
- **Data Retention**: Automated cleanup and archival policies
- **Monitoring and Alerting**: Real-time security monitoring

## Implementation Priority

### Phase 1 (Critical - Design Flow Foundation)
1. Restructure contract functions to match UI flow steps
2. Implement step-by-step plan creation process
3. Enhanced beneficiary management with asset allocation
4. Basic plan rules and conditions

### Phase 2 (Important - Core Flow Features)
5. Verification and legal settings integration
6. Plan preview and validation system
7. Enhanced plan management and monitoring
8. Comprehensive activity logging

### Phase 3 (Enhancement - Advanced Features)
9. Advanced rules and conditions engine
10. Enhanced security and compliance features
11. Performance optimization and gas efficiency
12. Advanced monitoring and analytics

## Off-Chain Computation Examples

### 1. **KYC Document Processing (Rust Implementation)**
```rust
use tokio::sync::Mutex;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use image::{DynamicImage, ImageBuffer};
use tesseract::Tesseract;
use crate::services::{OCRService, FraudDetectionService, VerificationService};
use crate::smart_contract::SmartContractClient;
use crate::models::{Document, KYCResult, UserType};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KYCProcessingService {
    ocr_service: Arc<OCRService>,
    fraud_detection_service: Arc<FraudDetectionService>,
    verification_service: Arc<VerificationService>,
    smart_contract: Arc<SmartContractClient>,
    processing_cache: Arc<Mutex<HashMap<String, KYCResult>>>,
}

impl KYCProcessingService {
    // Process uploaded documents off-chain
    pub async fn process_kyc_documents(
        &self,
        user_id: &str,
        documents: &[Document],
    ) -> Result<KYCResult, Box<dyn std::error::Error>> {
        // OCR processing for identity documents
        let ocr_results = self.ocr_service.process_documents(documents).await?;
        
        // AI-based fraud detection
        let fraud_score = self.fraud_detection_service.analyze(documents).await?;
        
        // External verification API calls
        let verification_results = self.verification_service.verify(&ocr_results).await?;
        
        // Calculate overall KYC score
        let kyc_score = self.calculate_kyc_score(&ocr_results, fraud_score, &verification_results)?;
        
        // Store results and trigger on-chain update
        let kyc_hash = self.store_kyc_results(user_id, kyc_score).await?;
        self.smart_contract.upload_kyc(&kyc_hash, UserType::Individual).await?;
        
        let result = KYCResult {
            kyc_score,
            kyc_hash,
            status: "pending".to_string(),
        };
        
        // Cache the result
        let mut cache = self.processing_cache.lock().await;
        cache.insert(user_id.to_string(), result.clone());
        
        Ok(result)
    }
    
    // Calculate KYC score based on multiple factors
    fn calculate_kyc_score(
        &self,
        ocr_results: &OCRResults,
        fraud_score: f64,
        verification_results: &VerificationResults,
    ) -> Result<f64, Box<dyn std::error::Error>> {
        let ocr_score = ocr_results.confidence_score;
        let verification_score = verification_results.verification_rate;
        
        // Weighted scoring algorithm
        let final_score = (ocr_score * 0.3) + (verification_score * 0.5) + ((1.0 - fraud_score) * 0.2);
        
        Ok(final_score.min(1.0).max(0.0))
    }
}
```

### 2. **Asset Valuation and Pricing (Rust Implementation)**
```rust
use tokio::sync::Mutex;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use reqwest::Client;
use crate::services::{PriceFeedService, RiskService, NFTService};
use crate::models::{Asset, AssetValuation, AssetType};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AssetValuationService {
    price_feed_service: Arc<PriceFeedService>,
    risk_service: Arc<RiskService>,
    nft_service: Arc<NFTService>,
    http_client: Client,
    valuation_cache: Arc<Mutex<HashMap<String, AssetValuation>>>,
}

impl AssetValuationService {
    // Calculate real-time asset values
    pub async fn calculate_asset_value(&self, asset: &Asset) -> Result<AssetValuation, Box<dyn std::error::Error>> {
        match asset.asset_type {
            AssetType::Token => {
                let price = self.price_feed_service.get_token_price(&asset.address).await?;
                let value = asset.amount * price;
                let volatility = self.risk_service.calculate_volatility(&asset.address).await?;
                
                let valuation = AssetValuation {
                    value,
                    price,
                    volatility,
                    last_updated: Utc::now(),
                    confidence: self.calculate_confidence(volatility),
                };
                
                Ok(valuation)
            }
            AssetType::NFT => {
                let floor_price = self.nft_service.get_floor_price(&asset.collection).await?;
                let rarity_score = self.nft_service.calculate_rarity(asset.token_id).await?;
                let market_demand = self.nft_service.get_market_demand(&asset.collection).await?;
                
                let value = floor_price * rarity_score * market_demand;
                
                let valuation = AssetValuation {
                    value,
                    price: floor_price,
                    volatility: Decimal::ZERO, // NFTs don't have traditional volatility
                    last_updated: Utc::now(),
                    confidence: self.calculate_nft_confidence(rarity_score, market_demand),
                };
                
                Ok(valuation)
            }
        }
    }
    
    // Calculate confidence based on volatility
    fn calculate_confidence(&self, volatility: Decimal) -> f64 {
        // Lower volatility = higher confidence
        let volatility_f64: f64 = volatility.try_into().unwrap_or(1.0);
        (1.0 - volatility_f64).max(0.1).min(1.0)
    }
    
    // Calculate NFT confidence based on rarity and demand
    fn calculate_nft_confidence(&self, rarity_score: Decimal, market_demand: Decimal) -> f64 {
        let rarity_f64: f64 = rarity_score.try_into().unwrap_or(0.5);
        let demand_f64: f64 = market_demand.try_into().unwrap_or(0.5);
        
        // Higher rarity and demand = higher confidence
        (rarity_f64 * 0.6 + demand_f64 * 0.4).max(0.1).min(1.0)
    }
}
```

### 3. **Beneficiary Share Calculations (Rust Implementation)**
```rust
use tokio::sync::Mutex;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use rust_decimal::Decimal;
use chrono::{DateTime, Utc};
use crate::services::{TaxService, DistributionService};
use crate::models::{Beneficiary, Asset, BeneficiaryShare, Relationship, DistributionSchedule};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BeneficiaryCalculationService {
    tax_service: Arc<TaxService>,
    distribution_service: Arc<DistributionService>,
    calculation_cache: Arc<Mutex<HashMap<String, Vec<BeneficiaryShare>>>>,
}

impl BeneficiaryCalculationService {
    // Calculate complex beneficiary distributions
    pub async fn calculate_beneficiary_shares(
        &self,
        plan_id: &str,
        beneficiaries: &[Beneficiary],
        assets: &[Asset],
    ) -> Result<Vec<BeneficiaryShare>, Box<dyn std::error::Error>> {
        let total_value = self.calculate_total_plan_value(assets).await?;
        let mut shares = Vec::new();
        
        for beneficiary in beneficiaries {
            // Calculate base share
            let base_share = (Decimal::from(beneficiary.percentage) / Decimal::from(100)) * total_value;
            
            // Apply age-based adjustments
            let adjusted_share = if beneficiary.age < 18 {
                self.apply_minor_adjustments(base_share, beneficiary.age)?
            } else {
                base_share
            };
            
            // Apply relationship-based adjustments
            let final_share = if beneficiary.relationship == Relationship::Spouse {
                self.apply_spouse_adjustments(adjusted_share, &beneficiary.owner_address)?
            } else {
                adjusted_share
            };
            
            // Apply tax considerations
            let tax_amount = self.tax_service.calculate_tax_liability(final_share, beneficiary).await?;
            let net_share = final_share - tax_amount;
            
            let distribution_schedule = self.distribution_service
                .calculate_distribution_schedule(beneficiary)
                .await?;
            
            let share = BeneficiaryShare {
                address: beneficiary.address.clone(),
                percentage: beneficiary.percentage,
                base_amount: base_share,
                tax_amount,
                net_amount: net_share,
                distribution_schedule,
            };
            
            shares.push(share);
        }
        
        // Cache the results
        let mut cache = self.calculation_cache.lock().await;
        cache.insert(plan_id.to_string(), shares.clone());
        
        Ok(shares)
    }
    
    // Apply minor adjustments based on age
    fn apply_minor_adjustments(&self, base_share: Decimal, age: u8) -> Result<Decimal, Box<dyn std::error::Error>> {
        match age {
            0..=5 => Ok(base_share * Decimal::from(0.8)), // Very young children
            6..=12 => Ok(base_share * Decimal::from(0.9)), // School age children
            13..=17 => Ok(base_share * Decimal::from(0.95)), // Teenagers
            _ => Ok(base_share),
        }
    }
    
    // Apply spouse-specific adjustments
    fn apply_spouse_adjustments(&self, base_share: Decimal, owner_address: &str) -> Result<Decimal, Box<dyn std::error::Error>> {
        // Spouses typically get preferential treatment
        Ok(base_share * Decimal::from(1.1))
    }
}
```

### 4. **Time-Based Trigger Management (Rust Implementation)**
```rust
use tokio::sync::Mutex;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc, Duration};
use tokio_cron_scheduler::{Job, JobScheduler};
use crate::database::Database;
use crate::scheduler::SchedulerService;
use crate::models::{InheritancePlan, TimeTrigger, TriggerType, TriggerAction};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimeTriggerService {
    database: Arc<Database>,
    scheduler_service: Arc<SchedulerService>,
    trigger_cache: Arc<Mutex<HashMap<String, Vec<TimeTrigger>>>>,
}

impl TimeTriggerService {
    // Manage complex time-based operations
    pub async fn schedule_time_triggers(
        &self,
        plan_id: &str,
        plan: &InheritancePlan,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let mut triggers = Vec::new();
        
        // Plan maturity trigger
        triggers.push(TimeTrigger {
            trigger_id: format!("{}_maturity", plan_id),
            plan_id: plan_id.to_string(),
            trigger_type: TriggerType::PlanMaturity,
            execute_at: plan.becomes_active_at,
            action: TriggerAction::EnableClaiming,
            conditions: vec!["kyc_approved".to_string(), "plan_active".to_string()],
            is_executed: false,
            executed_at: None,
        });
        
        // Periodic inactivity checks
        let inactivity_checks = self.calculate_inactivity_check_schedule(plan.inactivity_threshold)?;
        for (i, check) in inactivity_checks.iter().enumerate() {
            triggers.push(TimeTrigger {
                trigger_id: format!("{}_inactivity_{}", plan_id, i),
                plan_id: plan_id.to_string(),
                trigger_type: TriggerType::InactivityCheck,
                execute_at: *check,
                action: TriggerAction::CheckWalletActivity,
                conditions: vec!["plan_active".to_string(), "monitoring_enabled".to_string()],
                is_executed: false,
                executed_at: None,
            });
        }
        
        // Tax reporting triggers
        let tax_triggers = self.calculate_tax_reporting_schedule(plan.created_at)?;
        for (i, trigger_time) in tax_triggers.iter().enumerate() {
            triggers.push(TimeTrigger {
                trigger_id: format!("{}_tax_{}", plan_id, i),
                plan_id: plan_id.to_string(),
                trigger_type: TriggerType::TaxReporting,
                execute_at: *trigger_time,
                action: TriggerAction::GenerateTaxReport,
                conditions: vec!["plan_active".to_string(), "assets_locked".to_string()],
                is_executed: false,
                executed_at: None,
            });
        }
        
        // Store triggers in database
        self.database.store_time_triggers(plan_id, &triggers).await?;
        
        // Schedule execution
        self.scheduler_service.schedule_triggers(&triggers).await?;
        
        // Cache the triggers
        let mut cache = self.trigger_cache.lock().await;
        cache.insert(plan_id.to_string(), triggers);
        
        Ok(())
    }
    
    // Calculate inactivity check schedule
    fn calculate_inactivity_check_schedule(
        &self,
        inactivity_threshold: Duration,
    ) -> Result<Vec<DateTime<Utc>>, Box<dyn std::error::Error>> {
        let mut checks = Vec::new();
        let now = Utc::now();
        
        // Schedule checks every 30 days until threshold is reached
        let mut check_time = now + Duration::days(30);
        while check_time < now + inactivity_threshold {
            checks.push(check_time);
            check_time += Duration::days(30);
        }
        
        Ok(checks)
    }
    
    // Calculate tax reporting schedule
    fn calculate_tax_reporting_schedule(
        &self,
        created_at: DateTime<Utc>,
    ) -> Result<Vec<DateTime<Utc>>, Box<dyn std::error::Error>> {
        let mut triggers = Vec::new();
        let now = Utc::now();
        
        // Schedule tax reports quarterly
        let mut report_time = created_at + Duration::days(90);
        while report_time <= now + Duration::days(365) {
            triggers.push(report_time);
            report_time += Duration::days(90);
        }
        
        Ok(triggers)
    }
}
```

## Testing Strategy (Rust Implementation)

### Unit Tests
- Test each new function individually using `#[cfg(test)]` modules
- Verify access control and permissions with `mockall` for mocking
- Test edge cases and error conditions with `proptest` for property-based testing
- Test off-chain computation logic with `tokio-test` for async testing

### Integration Tests
- Test complete inheritance workflows using `testcontainers` for database testing
- Verify event emission and indexing with `tokio` async test runtime
- Test cross-function interactions with `wiremock` for HTTP mocking
- Test hybrid on-chain/off-chain flows with `starknet-rs` test utilities

### Security Tests
- Penetration testing with `cargo-audit` for dependency vulnerabilities
- Access control verification using `proptest` for fuzzing
- Reentrancy protection testing with concurrent test scenarios
- Off-chain data validation testing with `serde` serialization tests

### Rust-Specific Testing Tools
- **`criterion`**: Benchmarking framework for performance testing
- **`mockall`**: Comprehensive mocking framework for Rust
- **`proptest`**: Property-based testing for edge case discovery
- **`tokio-test`**: Async testing utilities for `tokio` runtime
- **`testcontainers`**: Docker-based integration testing
- **`wiremock`**: HTTP request mocking for external API testing

## Migration Strategy

### Backward Compatibility
- Maintain existing function signatures where possible
- Use upgradeable pattern for major changes
- Provide migration functions for existing data

### Data Migration
- Create migration scripts for existing plans
- Preserve user data and settings
- Test migration on testnet first

## Current Implementation Status

### Smart Contract Functions Implemented
- ✅ `create_plan_basic_info()` - Step 1: Basic plan information creation
- ✅ `set_asset_allocation()` - Step 2: Asset allocation and beneficiary setup
- ✅ `mark_rules_conditions_set()` - Step 3: Rules and conditions validation marker
- ✅ `mark_verification_completed()` - Step 4: Verification completion marker
- ✅ `mark_preview_ready()` - Step 5: Preview generation marker
- ✅ `activate_inheritance_plan()` - Step 6: Plan activation and finalization
- ✅ `get_beneficiary_count()` - Basic beneficiary count retrieval
- ✅ Core inheritance plan management functions
- ✅ Security and access control functions
- ✅ Event emission for backend integration

### Monthly Disbursement Functions Implemented
- ✅ `create_monthly_disbursement_plan()` - Create monthly disbursement plans
- ✅ `execute_monthly_disbursement()` - Execute monthly disbursements
- ✅ `pause_monthly_disbursement()` - Pause disbursement plans
- ✅ `resume_monthly_disbursement()` - Resume paused plans
- ✅ `get_monthly_disbursement_status()` - Get plan status and details
- ✅ Monthly disbursement event emission system

### Beneficiary Verification Functions Implemented ⭐ NEW
- ✅ `verify_beneficiary_identity()` - Verify beneficiary identity during claims
- ✅ `assert_beneficiary_in_plan()` - Internal beneficiary validation
- ✅ Beneficiary identity verification event emission
- ✅ Integration with inheritance claim process

### Backend Functions to Implement
- 🔄 `validate_and_set_plan_rules()` - Complex business logic validation
- 🔄 `validate_verification_and_legal()` - KYC and compliance processing
- 🔄 `generate_plan_preview()` - Comprehensive preview generation
- 🔄 `log_activity()` - Activity logging and analytics
- 🔄 `get_plan_beneficiaries()` - Detailed beneficiary management
- 🔄 Asset valuation and risk assessment services
- 🔄 Compliance and regulatory management
- 🔄 User experience and frontend integration

### Monthly Disbursement Backend Functions to Implement
- 🔄 `create_monthly_disbursement_plan()` - Plan creation with validation and scheduling
- 🔄 `execute_monthly_disbursements()` - Automated disbursement execution
- 🔄 `monitor_monthly_disbursements()` - Real-time monitoring and analytics
- 🔄 `manage_disbursement_schedule()` - Schedule modification and management
- 🔄 `handle_monthly_disbursement_compliance()` - Tax and regulatory compliance
- 🔄 Disbursement automation and cron job management
- 🔄 Real-time disbursement status tracking
- 🔄 Monthly disbursement reporting and analytics

### Integration Points
- ✅ Smart contract events for backend processing
- ✅ Marker functions for backend state updates
- ✅ Hybrid architecture for optimal performance
- 🔄 Backend API endpoints and services
- 🔄 Frontend integration and user experience
- 🔄 External service integrations (KYC, legal, market data)

### Monthly Disbursement Integration Points
- ✅ Smart contract disbursement execution functions
- ✅ Monthly disbursement event emission system
- ✅ Backend disbursement scheduling and automation
- 🔄 Cron job integration for automated execution
- 🔄 Real-time disbursement status monitoring
- 🔄 Tax and compliance service integrations
- 🔄 Disbursement analytics and reporting services

## Conclusion

These improvements will significantly enhance the InheritX smart contract's functionality, security, and user experience by aligning with the UI design flow. The phased implementation approach ensures critical features are delivered first while maintaining system stability.

## Cairo Smart Contract + Rust Backend Architecture Benefits

### Performance & Safety
- **Zero-cost abstractions**: Rust's ownership system provides memory safety without runtime overhead
- **Concurrent programming**: `tokio` async runtime enables high-performance concurrent operations
- **Type safety**: Compile-time guarantees prevent many runtime errors
- **Memory efficiency**: No garbage collection overhead, predictable memory usage

### Ecosystem Advantages
- **Rich crate ecosystem**: Access to production-ready libraries for all major use cases
- **Cargo package manager**: Dependency management with version resolution and security auditing
- **Cross-platform support**: Deploy the same codebase across different operating systems
- **WebAssembly support**: Potential for client-side computation with `wasm-pack`

### Development Experience
- **Excellent tooling**: `rust-analyzer`, `cargo-clippy`, and comprehensive error messages
- **Documentation**: Rich documentation ecosystem with `cargo-doc` and `docs.rs`
- **Testing framework**: Built-in testing support with `cargo test` and testing utilities
- **Error handling**: Comprehensive error handling with `Result<T, E>` and `?` operator

### Production Readiness
- **Performance monitoring**: Integration with `tracing`, `metrics`, and `opentelemetry`
- **Health checks**: Built-in health check endpoints with `axum` or `actix-web`
- **Configuration management**: Environment-based configuration with `config` crate
- **Logging**: Structured logging with `tracing` and `serde` serialization

The Rust-based backend architecture provides a robust foundation for the InheritX platform, combining the security and performance benefits of Rust with the flexibility and scalability of modern async programming patterns.

## Backend Functions Implementation

### Functions Moved from Smart Contract to Backend

The following functions have been moved from the Cairo smart contract to the Rust backend for better performance, maintainability, and user experience:

#### 1. **Plan Rules and Conditions Validation**
- **Function**: `validate_and_set_plan_rules()`
- **Reason**: Complex business logic validation, legal compliance checks, and risk assessment
- **Backend Implementation**: See `docs/BACKEND_IMPLEMENTATION.md` for detailed specifications

#### 2. **Verification and Legal Compliance**
- **Function**: `validate_verification_and_legal()`
- **Reason**: KYC processing, document verification, and regulatory compliance checking
- **Backend Implementation**: See `docs/BACKEND_IMPLEMENTATION.md` for detailed specifications

#### 3. **Plan Preview Generation**
- **Function**: `generate_plan_preview()`
- **Reason**: Complex calculations, risk assessment, and compliance summary generation
- **Backend Implementation**: See `docs/BACKEND_IMPLEMENTATION.md` for detailed specifications

#### 4. **Activity Logging and Analytics**
- **Function**: `log_activity()` and `get_activity_log()`
- **Reason**: Data processing, analytics, and audit trail management
- **Backend Implementation**: See `docs/BACKEND_IMPLEMENTATION.md` for detailed specifications

#### 5. **Beneficiary Management**
- **Function**: `get_plan_beneficiaries()`
- **Reason**: Complex data retrieval and processing operations
- **Backend Implementation**: See `docs/BACKEND_IMPLEMENTATION.md` for detailed specifications

### Smart Contract Integration

The smart contract now provides simple marker functions that the backend calls after completing its validation and processing:

```cairo
// Step 3: Mark rules and conditions set (Backend validates)
fn mark_rules_conditions_set(ref self: ContractState, basic_info_id: u256);

// Step 4: Mark verification completed (Backend validates)
fn mark_verification_completed(ref self: ContractState, basic_info_id: u256);

// Step 5: Mark preview ready (Backend generates preview)
fn mark_preview_ready(ref self: ContractState, basic_info_id: u256);
```

### Benefits of This Architecture

1. **Gas Efficiency**: Complex operations are performed off-chain, reducing gas costs
2. **Better User Experience**: Faster response times and richer functionality
3. **Maintainability**: Business logic can be updated without smart contract upgrades
4. **Scalability**: Backend services can be scaled independently
5. **Integration**: Easier integration with external services and APIs
6. **Compliance**: Better handling of regulatory requirements and legal compliance

### Backend Implementation Guide

A comprehensive backend implementation guide has been created in `docs/BACKEND_IMPLEMENTATION.md` that includes:

- Detailed function specifications
- Database schema design
- API endpoint definitions
- Security considerations
- Performance optimization strategies
- Testing and deployment guidelines

This hybrid approach ensures that the InheritX platform provides the best of both worlds: the security and immutability of blockchain technology with the performance and flexibility of modern backend services. 