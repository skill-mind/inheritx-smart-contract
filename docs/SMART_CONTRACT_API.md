# InheritX Smart Contract API Documentation

## Overview

The InheritX smart contract is a comprehensive inheritance management system built on Starknet that provides secure, on-chain asset management with advanced beneficiary allocation features. This document outlines the complete API including the newly implemented percentage-based allocation and balance validation functionality.

## Contract Information

- **Contract Name**: InheritX
- **Network**: Starknet
- **Language**: Cairo
- **Version**: 2.0.0
- **Status**: ✅ Production Ready (with enhanced features)

## Core Functions

### 1. Inheritance Plan Management

#### Create Inheritance Plan (Basic)
```cairo
fn create_inheritance_plan(
    ref self: ContractState,
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
) -> u256
```

**Description**: Creates a basic inheritance plan with equal beneficiary distribution (100% per beneficiary).

**Parameters**:
- `beneficiaries`: Array of beneficiary addresses
- `asset_type`: Asset type (0: STRK, 1: USDT, 2: USDC, 3: NFT)
- `asset_amount`: Amount of tokens (0 for NFTs)
- `nft_token_id`: NFT token ID (0 for tokens)
- `nft_contract`: NFT contract address (0 for tokens)
- `timeframe`: Time in seconds until plan becomes active
- `guardian`: Optional guardian address (0 for no guardian)
- `encrypted_details`: Encrypted inheritance details
- `security_level`: Security level (1-5)
- `auto_execute`: Whether to auto-execute on maturity
- `emergency_contacts`: Array of emergency contact addresses

**Returns**: `u256` - The created plan ID

**Security Features**:
- ✅ Balance validation (prevents creation with insufficient funds)
- ✅ Pause check
- ✅ Input validation
- ✅ Asset type validation

#### Create Inheritance Plan with Percentages ⭐ NEW
```cairo
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
) -> u256
```

**Description**: Creates an inheritance plan with custom percentage allocations for each beneficiary.

**Parameters**:
- `beneficiary_data`: Array of `BeneficiaryData` structs with percentages
- Other parameters same as basic creation

**Returns**: `u256` - The created plan ID

**Security Features**:
- ✅ Balance validation (prevents creation with insufficient funds)
- ✅ Percentage validation (total must equal 100%)
- ✅ Pause check
- ✅ Input validation
- ✅ Asset type validation

### 2. Beneficiary Management

#### Update Beneficiary Percentages ⭐ NEW
```cairo
fn update_beneficiary_percentages(
    ref self: ContractState,
    plan_id: u256,
    beneficiary_data: Array<BeneficiaryData>,
)
```

**Description**: Updates beneficiary percentages for an existing plan.

**Parameters**:
- `plan_id`: ID of the plan to update
- `beneficiary_data`: New beneficiary data with updated percentages

**Security Features**:
- ✅ Plan ownership validation
- ✅ Percentage validation (total must equal 100%)
- ✅ Plan existence validation
- ✅ Pause check

#### Get Beneficiary Percentages ⭐ NEW
```cairo
fn get_beneficiary_percentages(
    self: @ContractState,
    plan_id: u256,
) -> Array<BeneficiaryData>
```

**Description**: Retrieves beneficiary data with their allocated percentages for a given plan.

**Parameters**:
- `plan_id`: ID of the plan

**Returns**: `Array<BeneficiaryData>` - Array of beneficiary data with percentages

### 3. Plan Editing Functions ⭐ NEW

#### Extend Plan Timeframe
```cairo
fn extend_plan_timeframe(
    ref self: ContractState,
    plan_id: u256,
    additional_time: u64,
)
```

**Description**: Extends the timeframe for an inheritance plan by adding additional time to the active date.

**Parameters**:
- `plan_id`: ID of the plan to extend
- `additional_time`: Additional time in seconds to add (max 1 year)

**Security Features**:
- ✅ Plan existence validation
- ✅ Plan ownership validation
- ✅ Plan status validation (must be Active)
- ✅ Pause check
- ✅ Input validation (additional_time > 0 and ≤ 1 year)

#### Update Plan Parameters
```cairo
fn update_plan_parameters(
    ref self: ContractState,
    plan_id: u256,
    new_security_level: u8,
    new_auto_execute: bool,
    new_guardian: ContractAddress,
)
```

**Description**: Updates plan parameters including security level, auto-execute setting, and guardian address.

**Parameters**:
- `plan_id`: ID of the plan to update
- `new_security_level`: New security level (1-5)
- `new_auto_execute`: New auto-execute setting
- `new_guardian`: New guardian address (0 for no guardian)

**Security Features**:
- ✅ Plan existence validation
- ✅ Plan ownership validation
- ✅ Plan status validation (must be Active)
- ✅ Pause check
- ✅ Input validation (security level 1-5)

#### Update Inactivity Threshold
```cairo
fn update_inactivity_threshold(
    ref self: ContractState,
    plan_id: u256,
    new_threshold: u64,
)
```

**Description**: Updates the inactivity threshold for a plan, which determines how long of inactivity triggers automatic execution.

**Parameters**:
- `plan_id`: ID of the plan to update
- `new_threshold`: New inactivity threshold in seconds (max 6 months)

**Security Features**:
- ✅ Plan existence validation
- ✅ Plan ownership validation
- ✅ Plan status validation (must be Active)
- ✅ Pause check
- ✅ Input validation (threshold > 0 and ≤ 6 months)

### 4. Claim Code Management ⭐ ENHANCED

**Note**: The contract supports both legacy encrypted claim codes and the new enhanced hash-based validation system. The hash-based system is recommended for new implementations due to improved security and performance.

#### Generate Encrypted Claim Code (Legacy System)
```cairo
fn generate_encrypted_claim_code(
    ref self: ContractState,
    plan_id: u256,
    beneficiary: ContractAddress,
    public_key: ByteArray,
    expires_in: u64,
) -> ByteArray
```

**Description**: Generates an encrypted claim code for a specific beneficiary (legacy system).

**Parameters**:
- `plan_id`: ID of the inheritance plan
- `beneficiary`: Address of the beneficiary
- `public_key`: Beneficiary's public key for encryption
- `expires_in`: Time in seconds until code expires

**Returns**: `ByteArray` - Encrypted claim code

**Security Features**:
- ✅ Plan existence validation
- ✅ Plan ownership validation
- ✅ Beneficiary validation
- ✅ Pause check
- ✅ Zero address validation

#### Store Claim Code Hash ⭐ NEW (Recommended)
```cairo
fn store_claim_code_hash(
    ref self: ContractState,
    plan_id: u256,
    beneficiary: ContractAddress,
    code_hash: ByteArray,
    timeframe: u64,
)
```

**Description**: Stores a pre-generated claim code hash for manual claim code management (recommended approach).

**Parameters**:
- `plan_id`: ID of the inheritance plan
- `beneficiary`: Address of the beneficiary
- `code_hash`: Pre-generated hash of the claim code
- `timeframe`: Time in seconds until code expires

**Security Features**:
- ✅ Plan existence validation
- ✅ Plan ownership validation
- ✅ Beneficiary validation
- ✅ Pause check
- ✅ Hash validation
- ✅ **Enhanced Security**: ⭐ NEW
  - Hash-based validation system
  - Time-based expiration controls
  - Usage tracking and revocation
  - Multi-layer security validation

#### Hash Claim Code ⭐ NEW
```cairo
fn hash_claim_code(
    self: @ContractState,
    code: ByteArray,
) -> ByteArray
```

**Description**: Generates a hash of a claim code for validation purposes.

**Parameters**:
- `code`: The claim code to hash

**Returns**: `ByteArray` - Hash of the claim code

**Use Cases**:
- Off-chain claim code generation
- Hash verification and validation
- Security testing and validation

### 5. Plan Execution and Management

#### Claim Inheritance ⭐ ENHANCED
```cairo
fn claim_inheritance(
    ref self: ContractState,
    plan_id: u256,
    claim_code: ByteArray,
) -> bool
```

**Description**: Claims inheritance using a valid claim code with enhanced security validation.

**Parameters**:
- `plan_id`: ID of the inheritance plan
- `claim_code`: Valid claim code for the plan

**Returns**: `bool` - Success status

**Security Features**:
- ✅ Plan existence validation
- ✅ **Enhanced Claim Code Validation**: ⭐ NEW
  - Hash-based verification
  - Time-based expiration checks
  - Usage status validation
  - Revocation status checks
- ✅ Plan status validation
- ✅ Time validation (plan must be active)
- ✅ Pause check
- ✅ **Multi-Layer Security**: ⭐ NEW
  - Claim code hash matching
  - Expiration time validation
  - Usage tracking
  - Revocation protection

## Data Structures

### BeneficiaryData ⭐ NEW
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

### InheritancePlan
```cairo
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
    pub escrow_id: u256,
    pub security_level: u8,
    pub auto_execute: bool,
    pub emergency_contacts_count: u8
}
```

## Events

### Core Events
```cairo
event InheritancePlanCreated {
    plan_id: u256,
    owner: ContractAddress,
    beneficiary_count: u8,
    asset_type: u8,
    amount: u256,
    timeframe: u64,
    created_at: u64,
    security_level: u8,
    auto_execute: bool
}

event BeneficiaryModified {
    plan_id: u256,
    beneficiary_address: ContractAddress,
    modification_type: ByteArray,
    modified_at: u64,
    modified_by: ContractAddress,
    old_value: ByteArray,
    new_value: ByteArray
}

event PlanTimeframeExtended {
    plan_id: u256,
    extended_by: ContractAddress,
    additional_time: u64,
    new_active_date: u64,
    extended_at: u64
}

event PlanParametersUpdated {
    plan_id: u256,
    updated_by: ContractAddress,
    old_security_level: u8,
    new_security_level: u8,
    old_auto_execute: bool,
    new_auto_execute: bool,
    old_guardian: ContractAddress,
    new_guardian: ContractAddress,
    updated_at: u64
}

event InactivityThresholdUpdated {
    plan_id: u256,
    updated_by: ContractAddress,
    old_threshold: u64,
    new_threshold: u64,
    updated_at: u64
}

event ClaimCodeGenerated {
    plan_id: u256,
    beneficiary: ContractAddress,
    generated_at: u64,
    expires_at: u64,
    encrypted_code: ByteArray
}

event ClaimCodeStored {
    plan_id: u256,
    beneficiary: ContractAddress,
    code_hash: ByteArray,
    stored_at: u64,
    expires_at: u64
}

event ClaimCodeUsed {
    plan_id: u256,
    beneficiary: ContractAddress,
    used_at: u64,
    claim_code_hash: ByteArray
}

event ClaimCodeExpired {
    plan_id: u256,
    beneficiary: ContractAddress,
    expired_at: u64,
    claim_code_hash: ByteArray
}

event ClaimCodeRevoked {
    plan_id: u256,
    beneficiary: ContractAddress,
    revoked_at: u64,
    claim_code_hash: ByteArray,
    revoked_by: ContractAddress
}
```

## Error Codes

### New Error Constants
```cairo
pub const ERR_INSUFFICIENT_USER_BALANCE: felt252 = 'Insufficient user balance';
pub const ERR_INVALID_PERCENTAGE: felt252 = 'Invalid percentage';
pub const ERR_DUPLICATE_BENEFICIARY: felt252 = 'Duplicate beneficiary address';
pub const ERR_CLAIM_CODE_EXPIRED: felt252 = 'Claim code expired';
pub const ERR_CLAIM_CODE_REVOKED: felt252 = 'Claim code revoked';
pub const ERR_CLAIM_NOT_READY: felt252 = 'Claim not ready yet';
```

### Complete Error List
- `ERR_UNAUTHORIZED`: Unauthorized access
- `ERR_ZERO_ADDRESS`: Zero address forbidden
- `ERR_CONTRACT_PAUSED`: Contract is paused
- `ERR_INVALID_INPUT`: Invalid input parameters
- `ERR_PLAN_NOT_FOUND`: Inheritance plan not found
- `ERR_INSUFFICIENT_BALANCE`: Insufficient balance
- `ERR_INSUFFICIENT_USER_BALANCE`: Insufficient user balance for plan creation ⭐ NEW
- `ERR_INVALID_ASSET_TYPE`: Invalid asset type
- `ERR_INVALID_CLAIM_CODE`: Invalid claim code
- `ERR_CLAIM_CODE_ALREADY_USED`: Claim code already used
- `ERR_CLAIM_CODE_EXPIRED`: Claim code expired ⭐ NEW
- `ERR_CLAIM_CODE_REVOKED`: Claim code revoked ⭐ NEW
- `ERR_CLAIM_NOT_READY`: Claim not ready yet ⭐ NEW
- `ERR_INVALID_PERCENTAGE`: Invalid percentage ⭐ NEW
- `ERR_DUPLICATE_BENEFICIARY`: Duplicate beneficiary address ⭐ NEW

## Security Features

### 1. Balance Validation ⭐ NEW
- **On-chain validation** of user token balances before plan creation
- **Prevents** creation of plans with insufficient funds
- **Supports** STRK, USDT, and USDC balance checking
- **Real-time** balance verification

### 2. Percentage Validation ⭐ NEW
- **Ensures** beneficiary allocations sum to exactly 100%
- **Prevents** over-allocation or under-allocation
- **Validates** individual percentages (0-100 range)
- **Enforces** data integrity

### 3. Access Control
- **Plan ownership** validation for modifications
- **Admin-only** functions for critical operations
- **Guardian** oversight for complex plans
- **Emergency** contact management

### 4. Data Integrity
- **Immutable** plan creation
- **Audit trail** for all modifications
- **Event logging** for all operations
- **State validation** for consistency

### 5. Enhanced Claim Code System ⭐ NEW
- **Hash-Based Validation**: Secure cryptographic verification of claim codes
- **Time-Based Security**: Configurable expiration and activation controls
- **Usage Tracking**: Prevents duplicate usage and tracks claim history
- **Revocation Support**: Admin-controlled claim code invalidation
- **Multi-Layer Protection**: Multiple validation layers for enhanced security
- **Off-Chain Generation**: Secure off-chain claim code creation with on-chain validation
- **Event Logging**: Comprehensive audit trail for all claim code operations

## Usage Examples

### Example 1: Create Plan with 60/40 Split
```cairo
// Create beneficiary data
let mut beneficiary_data = ArrayTrait::new();

let beneficiary1 = BeneficiaryData {
    address: USER1_ADDR(),
    percentage: 60_u8,
    email_hash: "user1@example.com",
    age: 25_u8,
    relationship: "Child",
};
beneficiary_data.append(beneficiary1);

let beneficiary2 = BeneficiaryData {
    address: USER2_ADDR(),
    percentage: 40_u8,
    email_hash: "user2@example.com",
    age: 30_u8,
    relationship: "Spouse",
};
beneficiary_data.append(beneficiary2);

// Create plan
let plan_id = contract.create_inheritance_plan_with_percentages(
    beneficiary_data,
    0, // STRK
    1_000_000, // 1 STRK
    0, // No NFT
    ZERO_ADDR(), // No NFT contract
    86400, // 1 day
    ZERO_ADDR(), // No guardian
    "",
    3, // security_level
    false, // auto_execute
    emergency_contacts,
);
```

### Example 2: Update Beneficiary Percentages
```cairo
// Update to 70/30 split
let mut updated_data = ArrayTrait::new();
updated_data.append(BeneficiaryData {
    address: USER1_ADDR(),
    percentage: 70_u8,
    email_hash: "user1@example.com",
    age: 25_u8,
    relationship: "Child",
});
updated_data.append(BeneficiaryData {
    address: USER2_ADDR(),
    percentage: 30_u8,
    email_hash: "user2@example.com",
    age: 30_u8,
    relationship: "Spouse",
});

contract.update_beneficiary_percentages(plan_id, updated_data);
```

### Example 3: Extend Plan Timeframe
```cairo
// Extend plan by 1 week
contract.extend_plan_timeframe(plan_id, 604800); // 7 days = 604800 seconds
```

### Example 4: Update Plan Parameters
```cairo
// Update plan with higher security and guardian
contract.update_plan_parameters(
    plan_id,
    5, // maximum security level
    true, // enable auto-execute
    GUARDIAN_ADDR(), // set guardian
);
```

### Example 5: Update Inactivity Threshold
```cairo
// Set inactivity threshold to 2 months
contract.update_inactivity_threshold(plan_id, 5184000); // 60 days = 5184000 seconds
```

### Example 6: Comprehensive Plan Management
```cairo
// Create plan
let plan_id = contract.create_inheritance_plan_with_percentages(/* ... */);

// Add beneficiary
contract.add_beneficiary_to_plan(plan_id, NEW_BENEFICIARY, 25, "email", 30, "Friend");

// Extend timeframe
contract.extend_plan_timeframe(plan_id, 2592000); // 30 days

// Update security settings
contract.update_plan_parameters(plan_id, 5, true, GUARDIAN_ADDR());

// Update inactivity monitoring
contract.update_inactivity_threshold(plan_id, 2592000); // 30 days
```

## Gas Optimization

### Efficient Operations
- **Batch operations** for multiple beneficiaries
- **Optimized storage** patterns
- **Minimal external calls** during plan creation
- **Efficient validation** algorithms

### Gas Costs (Estimated)
- **Plan Creation**: ~50,000 gas
- **Percentage Update**: ~30,000 gas
- **Claim Code Generation**: ~25,000 gas
- **Plan Execution**: ~40,000 gas
- **Extend Timeframe**: ~20,000 gas ⭐ NEW
- **Update Parameters**: ~25,000 gas ⭐ NEW
- **Update Inactivity Threshold**: ~20,000 gas ⭐ NEW

## Testing

### Test Coverage
- ✅ **Unit Tests**: All functions tested individually
- ✅ **Integration Tests**: End-to-end workflow testing
- ✅ **Edge Cases**: Boundary conditions and error scenarios
- ✅ **Security Tests**: Access control and validation testing

### Test Scenarios
- **Balance Validation**: Insufficient balance scenarios
- **Percentage Validation**: Invalid percentage combinations
- **Access Control**: Unauthorized operation attempts
- **Data Integrity**: Invalid input handling

## Migration Guide

### From Previous Version
1. **No breaking changes** for existing plans
2. **New functions** are additive
3. **Enhanced validation** improves security
4. **Backward compatibility** maintained

### Upgrade Path
1. **Deploy** new contract version
2. **Verify** existing plans remain functional
3. **Test** new percentage-based features
4. **Migrate** to new functions gradually

## Support and Maintenance

### Development Status
- **Active Development**: ✅ Yes
- **Bug Fixes**: ✅ Regular updates
- **Feature Requests**: ✅ Open for suggestions
- **Security Audits**: ✅ Ongoing

### Contact Information
- **GitHub**: [Repository Link]
- **Documentation**: [Docs Link]
- **Issues**: [Issue Tracker]
- **Discussions**: [Community Forum]

---

**Last Updated**: December 2024
**Version**: 2.0.0
**Status**: Production Ready 