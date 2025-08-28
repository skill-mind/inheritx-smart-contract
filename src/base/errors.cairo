// ================ GENERAL ERRORS ================
pub const ERR_UNAUTHORIZED: felt252 = 'Unauthorized access';
pub const ERR_ZERO_ADDRESS: felt252 = 'Zero address forbidden';
pub const ERR_CONTRACT_PAUSED: felt252 = 'Contract is paused';
pub const ERR_INVALID_INPUT: felt252 = 'Invalid input parameters';

// ================ INHERITANCE PLAN ERRORS ================
pub const ERR_PLAN_NOT_FOUND: felt252 = 'Inheritance plan not found';
pub const ERR_PLAN_ALREADY_EXISTS: felt252 = 'Plan already exists';
pub const ERR_PLAN_NOT_ACTIVE: felt252 = 'Plan is not active';
pub const ERR_PLAN_ALREADY_EXECUTED: felt252 = 'Plan already executed';
pub const ERR_PLAN_ALREADY_CLAIMED: felt252 = 'Plan already claimed';
pub const ERR_INVALID_TIMEFRAME: felt252 = 'Invalid timeframe';
pub const ERR_INVALID_BENEFICIARIES: felt252 = 'Invalid beneficiaries';
pub const ERR_INSUFFICIENT_BALANCE: felt252 = 'Insufficient balance';
pub const ERR_INSUFFICIENT_USER_BALANCE: felt252 = 'Insufficient user balance';
pub const ERR_INVALID_ASSET_TYPE: felt252 = 'Invalid asset type';

// ================ CLAIM ERRORS ================
pub const ERR_INVALID_CLAIM_CODE: felt252 = 'Invalid claim code';
pub const ERR_CLAIM_CODE_ALREADY_USED: felt252 = 'Claim code already used';
pub const ERR_CLAIM_NOT_READY: felt252 = 'Claim not ready yet';
pub const ERR_NOT_BENEFICIARY: felt252 = 'Not a beneficiary';

// ================ SWAP ERRORS ================
pub const ERR_SWAP_REQUEST_NOT_FOUND: felt252 = 'Swap request not found';
pub const ERR_SWAP_ALREADY_EXECUTED: felt252 = 'Swap already executed';
pub const ERR_INSUFFICIENT_SLIPPAGE: felt252 = 'Insufficient slippage tolerance';
pub const ERR_DEX_ROUTER_NOT_SET: felt252 = 'DEX router not set';
pub const ERR_SWAP_FAILED: felt252 = 'Swap operation failed';

// ================ KYC ERRORS ================
pub const ERR_KYC_NOT_FOUND: felt252 = 'KYC data not found';
pub const ERR_KYC_ALREADY_APPROVED: felt252 = 'KYC already approved';
pub const ERR_KYC_ALREADY_REJECTED: felt252 = 'KYC already rejected';
pub const ERR_KYC_NOT_APPROVED: felt252 = 'KYC not approved';
pub const ERR_INVALID_USER_TYPE: felt252 = 'Invalid user type';

// ================ INACTIVITY ERRORS ================
pub const ERR_INACTIVITY_NOT_TRIGGERED: felt252 = 'Inactivity not triggered';
pub const ERR_INVALID_THRESHOLD: felt252 = 'Invalid inactivity threshold';
pub const ERR_ACTIVITY_TOO_RECENT: felt252 = 'Activity too recent';

// ================ OVERRIDE ERRORS ================
pub const ERR_OVERRIDE_REQUEST_NOT_FOUND: felt252 = 'Override request not found';
pub const ERR_OVERRIDE_NOT_APPROVED: felt252 = 'Override not approved';
pub const ERR_OVERRIDE_ALREADY_EXISTS: felt252 = 'Override request already exists';

// ================ TOKEN ERRORS ================
pub const ERR_INSUFFICIENT_ALLOWANCE: felt252 = 'Insufficient allowance';
pub const ERR_TRANSFER_FAILED: felt252 = 'Token transfer failed';
pub const ERR_APPROVAL_FAILED: felt252 = 'Token approval failed';

// ================ ADMIN ERRORS ================
pub const ERR_ADMIN_ONLY: felt252 = 'Admin only function';
pub const ERR_INVALID_CLASS_HASH: felt252 = 'Invalid class hash';
pub const ERR_EMERGENCY_WITHDRAW_FAILED: felt252 = 'Emergency withdrawal failed';

// ================ VALIDATION ERRORS ================
pub const ERR_INVALID_PERCENTAGE: felt252 = 'Invalid percentage';
pub const ERR_DUPLICATE_BENEFICIARY: felt252 = 'Duplicate beneficiary address';
pub const ERR_INVALID_ENCRYPTED_DATA: felt252 = 'Invalid encrypted data';
pub const ERR_INVALID_GUARDIAN: felt252 = 'Invalid guardian address';
pub const ERR_BENEFICIARY_NOT_FOUND: felt252 = 'Beneficiary not found';

// ================ ESCROW ERRORS ================
pub const ERR_ESCROW_NOT_FOUND: felt252 = 'Escrow account not found';
pub const ERR_ESCROW_ALREADY_LOCKED: felt252 = 'Assets already locked in escrow';
pub const ERR_ESCROW_NOT_LOCKED: felt252 = 'Assets not locked in escrow';

// ================ ADDITIONAL ERRORS ================
pub const ERR_MAX_BENEFICIARIES_REACHED: felt252 = 'Max beneficiaries reached';
pub const ERR_BENEFICIARY_ALREADY_EXISTS: felt252 = 'Beneficiary already exists';
pub const ERR_NFT_NOT_OWNED: felt252 = 'NFT not owned by contract';
pub const ERR_INVALID_NFT_TOKEN: felt252 = 'Invalid NFT token';

// ================ WALLET SECURITY ERRORS ================
pub const ERR_WALLET_ALREADY_FROZEN: felt252 = 'Wallet already frozen';
pub const ERR_WALLET_NOT_FROZEN: felt252 = 'Wallet not frozen';
pub const ERR_WALLET_ALREADY_BLACKLISTED: felt252 = 'Wallet already blacklisted';
pub const ERR_WALLET_NOT_BLACKLISTED: felt252 = 'Wallet not blacklisted';

// Plan creation flow errors
pub const ERR_INVALID_ADDRESS: felt252 = 'Invalid address';
pub const ERR_INVALID_STATE: felt252 = 'Invalid state';
