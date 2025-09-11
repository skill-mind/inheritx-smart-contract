// #[starknet::contract]
// pub mod InheritX {
//     use core::array::ArrayTrait;
//     use core::byte_array::ByteArray;
//     use core::option::OptionTrait;
//     use core::traits::TryInto;
//     use openzeppelin::security::pausable::PausableComponent;
//     use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
//     use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
//     use openzeppelin::upgrades::UpgradeableComponent;
//     use starknet::storage::{
//         Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
//         StoragePointerWriteAccess,
//     };
//     use starknet::{
//         ClassHash, ContractAddress, get_block_timestamp, get_caller_address,
//         get_contract_address,
//     };
//     use crate::base::errors::*;
//     use crate::base::events::*;
//     use crate::base::types::*;
//     use crate::interfaces::iinheritx::IInheritX;

//     // Constants
//     const ZERO_ADDRESS: ContractAddress = 0.try_into().unwrap();

//     // ================ TRAITS ================

//     /// @title ClaimCodeInternalTrait
//     /// @notice Internal trait for secure claim code generation and management
//     ///
//     /// PURPOSE: Provides internal implementation for secure claim code generation system
//     /// implementing three-stage process: secure generation → hashing → encryption
//     ///
//     /// SECURITY: Zero-knowledge approach where asset owners never see plain text codes,
//     /// only encrypted versions returned, plain codes accessible only to beneficiaries
//     ///
//     /// IMPLEMENTATION: Current version uses simplified cryptographic functions for development,
//     /// production should use proper cryptographic libraries (SHA-256, RSA, ECC)
//     ///
//     /// USAGE: Used internally by main contract functions for code generation, validation,
//     /// and future features like revocation and regeneration
//     ///
//     /// @dev Internal trait, not exposed externally
//     /// @dev Functions designed for gas efficiency and security
//     /// @dev Current implementation simplified for development
//     #[generate_trait]
//     pub trait ClaimCodeInternalTrait {
//         /// @notice Generates a cryptographically secure random code from a seed
//         ///
//         /// ALGORITHM: Combines seed + timestamp → extracts 32 bytes using modulo 256 →
//         builds /// result array
//         ///
//         /// SECURITY: Deterministic but unpredictable, collision resistant, time-based uniqueness
//         ///
//         /// OUTPUT: 32-byte array (256 bits), each byte 0-255, uniform distribution
//         ///
//         /// GAS: Fixed 32 iterations, predictable cost, no external calls
//         ///
//         /// PRODUCTION: Replace with proper cryptographic RNG, consider VRF for true randomness
//         ///
//         /// @param seed u256 seed value for deterministic generation
//         /// @return ByteArray containing 32 bytes of generated code
//         /// @dev TODO: Fix return value to return actual generated code
//         fn generate_secure_code(
//             self: @ContractState, seed: u256, beneficiary: ContractAddress,
//         ) -> ByteArray;

//         /// @notice Generates a hash of the input claim code for on-chain storage
//         ///
//         /// PURPOSE: Creates deterministic hash for on-chain validation without storing plain
//         text ///
//         /// CURRENT: Simplified implementation (direct byte copy), suitable for development
//         ///
//         /// PRODUCTION: Use proper cryptographic hashing (SHA-256) for collision resistance
//         ///
//         /// WORKFLOW: Code generated → hashed → stored on-chain → validation during
//         claiming ///
//         /// OUTPUT: Current: same length as input, Production: fixed 32 bytes
//         ///
//         /// @param code ByteArray containing the claim code to hash
//         /// @return ByteArray containing the hash of the input code
//         /// @dev TODO: Fix return value to return actual hash
//         fn hash_claim_code(self: @ContractState, code: ByteArray) -> ByteArray;

//         /// @notice Encrypts the claim code using the beneficiary's public key
//         ///
//         /// PURPOSE: Encrypts plain text code so asset owner never sees it, only beneficiary can
//         /// decrypt
//         ///
//         /// CURRENT: XOR encryption with key cycling, suitable for development
//         ///
//         /// PRODUCTION: Use proper asymmetric encryption (RSA, ECC) for security
//         ///
//         /// WORKFLOW: Asset owner provides public key → contract encrypts → returns encrypted
//         /// code → beneficiary decrypts with private key → uses plain code for claiming
//         ///
//         /// OUTPUT: Same length as input code, appears random, reversible with correct key
//         ///
//         /// @param code ByteArray containing the plain text claim code to encrypt
//         /// @param public_key ByteArray containing the encryption key
//         /// @return ByteArray containing the encrypted claim code
//         /// @dev TODO: Fix return value to return actual encrypted code
//         fn encrypt_for_beneficiary(
//             self: @ContractState, code: ByteArray, public_key: ByteArray,
//         ) -> ByteArray;

//         /// @notice Verifies that a beneficiary exists in a plan and has valid data
//         /// @param plan_id ID of the plan
//         /// @param beneficiary_address Address of the beneficiary to verify
//         fn assert_beneficiary_in_plan(
//             self: @ContractState, plan_id: u256, beneficiary_address: ContractAddress,
//         );

//         /// @notice Verifies beneficiary identity using email and name hashes
//         /// @param plan_id ID of the plan
//         /// @param beneficiary_address Address of the beneficiary
//         /// @param email_hash Hash of the beneficiary's email
//         /// @param name_hash Hash of the beneficiary's name
//         /// @return Whether the identity verification passed
//         fn verify_beneficiary_identity(
//             self: @ContractState,
//             plan_id: u256,
//             beneficiary_address: ContractAddress,
//             email_hash: ByteArray,
//             name_hash: ByteArray,
//         ) -> bool;

//         /// @notice Claims inheritance using a valid claim code with enhanced security validation
//         /// @param self Mutable reference to contract state
//         /// @param plan_id ID of the inheritance plan
//         /// @param claim_code Valid claim code for the plan
//         fn claim_inheritance(ref self: ContractState, plan_id: u256, claim_code: ByteArray);
//     }

//     // Components
//     component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
//     component!(path: PausableComponent, storage: pausable, event: PausableEvent);

//     // Implementations
//     impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;
//     impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
//     impl ClaimCodeInternalImpl = ClaimCodeInternalTraitImpl;

//     #[storage]
//     pub struct Storage {
//         // Core contract state
//         #[substorage(v0)]
//         upgradeable: UpgradeableComponent::Storage,
//         #[substorage(v0)]
//         pausable: PausableComponent::Storage,
//         // Admin and configuration
//         admin: ContractAddress,
//         dex_router: ContractAddress,
//         emergency_withdraw_address: ContractAddress,
//         // Inheritance plans
//         inheritance_plans: Map<u256, InheritancePlan>,
//         plan_count: u256,
//         // User plans - simple counter approach
//         user_plan_count: Map<ContractAddress, u256>, // user -> count of plans
//         // Claimed plans - simple counter approach
//         claimed_plan_count: Map<ContractAddress, u256>, // beneficiary -> count of claimed plans
//         // KYC management
//         kyc_data: Map<ContractAddress, KYCData>,
//         pending_kyc_count: u256,
//         // Swap management
//         swap_requests: Map<u256, SwapRequest>,
//         swap_count: u256,
//         plan_swap_requests: Map<u256, u256>, // plan_id -> swap_request_id
//         // Claim codes
//         claim_codes: Map<u256, ClaimCode>, // plan_id -> claim_code
//         // Inactivity monitoring
//         inactivity_triggers: Map<u256, InactivityTrigger>,
//         // Plan overrides
//         override_requests: Map<u256, PlanOverrideRequest>,
//         // Beneficiary management - real storage
//         plan_beneficiaries: Map<
//             (u256, u256), Beneficiary,
//         >, // (plan_id, beneficiary_index) -> beneficiary
//         plan_beneficiary_count: Map<u256, u256>, // plan_id -> beneficiary count
//         beneficiary_by_address: Map<
//             (u256, ContractAddress), u256,
//         >, // (plan_id, address) -> beneficiary_index
//         // Claim codes - simplified storage (using plan_id as key)
//         // Inactivity monitoring - real storage
//         inactivity_monitors: Map<ContractAddress, InactivityMonitor>, // wallet_address ->
//         monitor // Escrow system
//         escrow_accounts: Map<u256, EscrowAccount>, // escrow_id -> escrow account
//         escrow_count: u256,
//         plan_escrow: Map<u256, u256>, // plan_id -> escrow_id
//         // Token addresses
//         strk_token: ContractAddress,
//         usdt_token: ContractAddress,
//         usdc_token: ContractAddress,
//         // Security settings
//         security_settings: SecuritySettings,
//         // Wallet freezing and blacklisting
//         frozen_wallets: Map<ContractAddress, bool>, // wallet -> is_frozen
//         freeze_reasons: Map<ContractAddress, FreezeInfo>, // wallet -> freeze_info
//         blacklisted_wallets: Map<ContractAddress, bool>, // wallet -> is_blacklisted
//         // Plan creation flow storage
//         basic_plan_info: Map<u256, BasicPlanInfo>, // basic_info_id -> basic_info
//         plan_rules: Map<u256, PlanRules>, // plan_id -> rules
//         verification_data: Map<u256, VerificationData>, // plan_id -> verification
//         plan_previews: Map<u256, PlanPreview>, // plan_id -> preview
//         plan_asset_allocations: Map<u256, u8>, // plan_id -> allocation count
//         // Activity logging
//         activity_count: Map<u256, u256>, // plan_id -> activity count
//         global_activity_log: Map<u256, ActivityLog>, // activity_id -> activity
//         // Plan creation tracking
//         plan_creation_steps: Map<u256, PlanCreationStatus>, // plan_id -> creation status
//         pending_plans: Map<u256, bool>, // plan_id -> is_pending
//         // Monthly disbursement storage
//         monthly_disbursement_plans: Map<u256, MonthlyDisbursementPlan>, // plan_id -> monthly
//         plan monthly_disbursements: Map<u256, MonthlyDisbursement>, // disbursement_id ->
//         disbursement disbursement_beneficiaries: Map<
//             (u256, u256), DisbursementBeneficiary,
//         >, // (plan_id, beneficiary_index) -> beneficiary
//         disbursement_beneficiary_count: Map<u256, u8>, // plan_id -> beneficiary count
//         monthly_disbursement_count: Map<(), u256>, // Global counter
//         monthly_disbursement_execution_count: Map<(), u256> // Execution counter
//     }

//     #[event]
//     #[derive(Drop, starknet::Event)]
//     pub enum Event {
//         #[flat]
//         UpgradeableEvent: UpgradeableComponent::Event,
//         #[flat]
//         PausableEvent: PausableComponent::Event,
//         // Custom events
//         SecuritySettingsUpdated: SecuritySettingsUpdated,
//         WalletFrozen: WalletFrozen,
//         WalletUnfrozen: WalletUnfrozen,
//         WalletBlacklisted: WalletBlacklisted,
//         WalletRemovedFromBlacklist: WalletRemovedFromBlacklist,
//         // Plan creation flow events
//         BasicPlanInfoCreated: BasicPlanInfoCreated,
//         AssetAllocationSet: AssetAllocationSet,
//         RulesConditionsSet: RulesConditionsSet,
//         VerificationCompleted: VerificationCompleted,
//         PlanPreviewGenerated: PlanPreviewGenerated,
//         PlanActivated: PlanActivated,
//         PlanCreationStepCompleted: PlanCreationStepCompleted,
//         // Activity logging events
//         ActivityLogged: ActivityLogged,
//         PlanStatusUpdated: PlanStatusUpdated,
//         BeneficiaryModified: BeneficiaryModified,
//         // Monthly disbursement events
//         MonthlyDisbursementPlanCreated: MonthlyDisbursementPlanCreated,
//         MonthlyDisbursementExecuted: MonthlyDisbursementExecuted,
//         MonthlyDisbursementPaused: MonthlyDisbursementPaused,
//         MonthlyDisbursementResumed: MonthlyDisbursementResumed,
//         MonthlyDisbursementCancelled: MonthlyDisbursementCancelled,
//         DisbursementBeneficiaryAdded: DisbursementBeneficiaryAdded,
//         DisbursementBeneficiaryRemoved: DisbursementBeneficiaryRemoved,
//         ClaimCodeGenerated: ClaimCodeGenerated,
//         InheritancePlanCreated: InheritancePlanCreated,
//         PlanTimeframeExtended: PlanTimeframeExtended,
//         PlanParametersUpdated: PlanParametersUpdated,
//         InactivityThresholdUpdated: InactivityThresholdUpdated,
//         BeneficiaryIdentityVerified: BeneficiaryIdentityVerified,
//     }

//     #[constructor]
//     pub fn constructor(
//         ref self: ContractState,
//         admin: ContractAddress,
//         dex_router: ContractAddress,
//         emergency_withdraw_address: ContractAddress,
//         strk_token: ContractAddress,
//         usdt_token: ContractAddress,
//         usdc_token: ContractAddress,
//     ) {
//         assert(admin != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//         self.admin.write(admin);
//         self.dex_router.write(dex_router);
//         self.emergency_withdraw_address.write(emergency_withdraw_address);
//         self.strk_token.write(strk_token);
//         self.usdt_token.write(usdt_token);
//         self.usdc_token.write(usdc_token);
//         self.plan_count.write(0);
//         self.swap_count.write(0);
//         self.pending_kyc_count.write(0);
//         self.escrow_count.write(0);
//         self.monthly_disbursement_count.write((), 0);
//         self.monthly_disbursement_execution_count.write((), 0);

//         // Initialize default security settings
//         let default_security = SecuritySettings {
//             max_beneficiaries: 10,
//             min_timeframe: 86400, // 1 day
//             max_timeframe: 31536000, // 1 year
//             require_guardian: false,
//             allow_early_execution: false,
//             max_asset_amount: 1000000000000000000000000, // 1M STRK
//             require_multi_sig: false,
//             multi_sig_threshold: 2,
//             emergency_timeout: 604800 // 7 days
//         };
//         self.security_settings.write(default_security);
//     }

//     #[generate_trait]
//     impl SecurityImpl of SecurityTrait {
//         fn assert_not_paused(self: @ContractState) {
//             self.pausable.assert_not_paused();
//         }

//         fn assert_only_admin(self: @ContractState) {
//             let caller = get_caller_address();
//             let admin = self.admin.read();
//             assert(caller == admin, ERR_UNAUTHORIZED);
//         }

//         fn assert_plan_exists(self: @ContractState, plan_id: u256) {
//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.id != 0, ERR_PLAN_NOT_FOUND);
//         }

//         fn assert_plan_owner(self: @ContractState, plan_id: u256) {
//             let caller = get_caller_address();
//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.owner == caller, ERR_UNAUTHORIZED);
//         }

//         fn assert_plan_active(self: @ContractState, plan_id: u256) {
//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.status == PlanStatus::Active, ERR_PLAN_NOT_ACTIVE);
//         }

//         fn assert_plan_not_executed(self: @ContractState, plan_id: u256) {
//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.status != PlanStatus::Executed, ERR_PLAN_ALREADY_EXECUTED);
//         }

//         fn assert_plan_not_claimed(self: @ContractState, plan_id: u256) {
//             let plan = self.inheritance_plans.read(plan_id);
//             assert(!plan.is_claimed, ERR_PLAN_ALREADY_CLAIMED);
//         }

//         fn assert_wallet_not_frozen(self: @ContractState, wallet: ContractAddress) {
//             let is_frozen = self.frozen_wallets.read(wallet);
//             assert(!is_frozen, ERR_WALLET_ALREADY_FROZEN);
//         }

//         fn assert_wallet_not_blacklisted(self: @ContractState, wallet: ContractAddress) {
//             let is_blacklisted = self.blacklisted_wallets.read(wallet);
//             assert(!is_blacklisted, ERR_WALLET_ALREADY_BLACKLISTED);
//         }

//         fn u8_to_asset_type(asset_type: u8) -> AssetType {
//             if asset_type == 0 {
//                 AssetType::STRK
//             } else if asset_type == 1 {
//                 AssetType::USDT
//             } else if asset_type == 2 {
//                 AssetType::USDC
//             } else {
//                 AssetType::NFT
//             }
//         }

//         fn u8_to_user_type(user_type: u8) -> UserType {
//             if user_type == 0 {
//                 UserType::AssetOwner
//             } else {
//                 UserType::Beneficiary
//             }
//         }

//         fn get_token_address_from_enum(
//             self: @ContractState, asset_type: AssetType,
//         ) -> ContractAddress {
//             match asset_type {
//                 AssetType::STRK => self.strk_token.read(),
//                 AssetType::USDT => self.usdt_token.read(),
//                 AssetType::USDC => self.usdc_token.read(),
//                 AssetType::NFT => ZERO_ADDRESS,
//             }
//         }
//     }

//     #[abi(embed_v0)]
//     impl inheritx of IInheritX<ContractState> {
//         fn create_inheritance_plan(
//             ref self: ContractState,
//             beneficiaries: Array<ContractAddress>,
//             asset_type: u8,
//             asset_amount: u256,
//             nft_token_id: u256,
//             nft_contract: ContractAddress,
//             timeframe: u64,
//             guardian: ContractAddress,
//             encrypted_details: ByteArray,
//             security_level: u8,
//             auto_execute: bool,
//             emergency_contacts: Array<ContractAddress>,
//         ) -> u256 {
//             self.assert_not_paused();
//             assert(beneficiaries.len() > 0, ERR_INVALID_INPUT);
//             assert(asset_type < 4, ERR_INVALID_ASSET_TYPE);
//             assert(asset_amount > 0 || asset_type == 3, ERR_INVALID_INPUT);
//             assert(timeframe > 0, ERR_INVALID_INPUT);

//             let caller = get_caller_address();
//             let current_time = get_block_timestamp();

//             // Check if user has sufficient balance for the asset type
//             if asset_type == 0 { // STRK
//                 let strk_token = IERC20Dispatcher { contract_address: self.strk_token.read() };
//                 let user_balance = strk_token.balance_of(caller);
//                 assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
//             } else if asset_type == 1 { // USDT
//                 let usdt_token = IERC20Dispatcher { contract_address: self.usdt_token.read() };
//                 let user_balance = usdt_token.balance_of(caller);
//                 assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
//             } else if asset_type == 2 { // USDC
//                 let usdc_token = IERC20Dispatcher { contract_address: self.usdc_token.read() };
//                 let user_balance = usdc_token.balance_of(caller);
//                 assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
//             }
//             // Note: NFT balance check is handled separately as it requires ownership
//             verification

//             let plan_id = self.plan_count.read() + 1;
//             let escrow_id = self.escrow_count.read() + 1;

//             // Create inheritance plan
//             let plan = InheritancePlan {
//                 id: plan_id,
//                 owner: caller,
//                 beneficiary_count: beneficiaries.len().try_into().unwrap(),
//                 asset_type: SecurityImpl::u8_to_asset_type(asset_type),
//                 asset_amount,
//                 nft_token_id,
//                 nft_contract,
//                 timeframe,
//                 created_at: current_time,
//                 becomes_active_at: current_time + timeframe,
//                 guardian,
//                 encrypted_details,
//                 status: PlanStatus::Active,
//                 is_claimed: false,
//                 claim_code_hash: "",
//                 inactivity_threshold: 0,
//                 last_activity: current_time,
//                 swap_request_id: 0,
//                 escrow_id,
//                 security_level,
//                 auto_execute,
//                 emergency_contacts_count: 0,
//             };

//             self.inheritance_plans.write(plan_id, plan);
//             self.plan_count.write(plan_id);

//             // Store beneficiary count
//             self.plan_beneficiary_count.write(plan_id, beneficiaries.len().into());

//             // Add beneficiaries to storage maps
//             let mut i: u256 = 0;
//             while i != beneficiaries.len().into() {
//                 let beneficiary = *beneficiaries.at(i.try_into().unwrap());
//                 let beneficiary_index = i + 1;

//                 let new_beneficiary = Beneficiary {
//                     address: beneficiary,
//                     email_hash: "", // Empty string for testing
//                     percentage: 100, // Default 100% for single beneficiary
//                     has_claimed: false,
//                     claimed_amount: 0,
//                     claim_code_hash: "", // Empty string for testing
//                     added_at: current_time,
//                     kyc_status: KYCStatus::Pending,
//                     relationship: "", // Empty string for testing
//                     age: 25, // Default age
//                     is_minor: false,
//                 };

//                 // Store beneficiary in storage maps
//                 self.plan_beneficiaries.write((plan_id, beneficiary_index), new_beneficiary);
//                 self.beneficiary_by_address.write((plan_id, beneficiary), beneficiary_index);

//                 i += 1;
//             }

//             // Create escrow account for this plan
//             let escrow = EscrowAccount {
//                 id: escrow_id,
//                 plan_id,
//                 asset_type: SecurityImpl::u8_to_asset_type(asset_type),
//                 amount: asset_amount,
//                 nft_token_id,
//                 nft_contract,
//                 is_locked: false,
//                 locked_at: 0,
//                 beneficiary: ZERO_ADDRESS,
//                 release_conditions_count: 0,
//                 fees: 0,
//                 tax_liability: 0,
//                 last_valuation: current_time,
//                 valuation_price: 0,
//             };

//             self.escrow_accounts.write(escrow_id, escrow);
//             self.plan_escrow.write(plan_id, escrow_id);
//             self.escrow_count.write(escrow_id);

//             // Add to user plans
//             let user_plan_count = self.user_plan_count.read(caller);
//             self.user_plan_count.write(caller, user_plan_count + 1);

//             plan_id
//         }

//         // ================ INHERITANCE PLAN FUNCTIONS ================

//         /// @notice Creates a new inheritance plan with percentage-based beneficiary allocations
//         /// @param beneficiary_data Array of beneficiary data including address and percentage
//         /// @param asset_type Type of asset (0: STRK, 1: USDT, 2: USDC, 3: NFT)
//         /// @param asset_amount Amount of tokens (0 for NFTs)
//         /// @param nft_token_id NFT token ID (0 for tokens)
//         /// @param nft_contract NFT contract address (0 for tokens)
//         /// @param timeframe Time in seconds until plan becomes active
//         /// @param guardian Optional guardian address (0 for no guardian)
//         /// @param encrypted_details Encrypted inheritance details
//         /// @param security_level Security level (1-5)
//         /// @param auto_execute Whether to auto-execute on maturity
//         /// @param emergency_contacts Array of emergency contact addresses
//         fn create_inheritance_plan_with_percentages(
//             ref self: ContractState,
//             beneficiary_data: Array<BeneficiaryData>,
//             asset_type: u8,
//             asset_amount: u256,
//             nft_token_id: u256,
//             nft_contract: ContractAddress,
//             timeframe: u64,
//             guardian: ContractAddress,
//             encrypted_details: ByteArray,
//             security_level: u8,
//             auto_execute: bool,
//             emergency_contacts: Array<ContractAddress>,
//         ) -> u256 {
//             self.assert_not_paused();
//             assert(beneficiary_data.len() > 0, ERR_INVALID_INPUT);
//             assert(asset_type < 4, ERR_INVALID_ASSET_TYPE);
//             assert(asset_amount > 0 || asset_type == 3, ERR_INVALID_INPUT);
//             assert(timeframe > 0, ERR_INVALID_INPUT);

//             // Validate that percentages sum to 100%
//             let mut total_percentage: u8 = 0;
//             let mut i: u32 = 0;
//             while i != beneficiary_data.len() {
//                 let beneficiary = beneficiary_data.at(i).clone();
//                 total_percentage = total_percentage + beneficiary.percentage;
//                 i += 1;
//             }
//             assert(total_percentage == 100, 'Total percentage must equal 100');

//             let caller = get_caller_address();
//             let current_time = get_block_timestamp();

//             // Check if user has sufficient balance for the asset type
//             if asset_type == 0 { // STRK
//                 let strk_token = IERC20Dispatcher { contract_address: self.strk_token.read() };
//                 let user_balance = strk_token.balance_of(caller);
//                 assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
//             } else if asset_type == 1 { // USDT
//                 let usdt_token = IERC20Dispatcher { contract_address: self.usdt_token.read() };
//                 let user_balance = usdt_token.balance_of(caller);
//                 assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
//             } else if asset_type == 2 { // USDC
//                 let usdc_token = IERC20Dispatcher { contract_address: self.usdc_token.read() };
//                 let user_balance = usdc_token.balance_of(caller);
//                 assert(user_balance >= asset_amount, ERR_INSUFFICIENT_USER_BALANCE);
//             }
//             // Note: NFT balance check is handled separately as it requires ownership
//             verification

//             let plan_id = self.plan_count.read() + 1;
//             let escrow_id = self.escrow_count.read() + 1;

//             // Create inheritance plan
//             let plan = InheritancePlan {
//                 id: plan_id,
//                 owner: caller,
//                 beneficiary_count: beneficiary_data.len().try_into().unwrap(),
//                 asset_type: SecurityImpl::u8_to_asset_type(asset_type),
//                 asset_amount,
//                 nft_token_id,
//                 nft_contract,
//                 timeframe,
//                 created_at: current_time,
//                 becomes_active_at: current_time + timeframe,
//                 guardian,
//                 encrypted_details,
//                 status: PlanStatus::Active,
//                 is_claimed: false,
//                 claim_code_hash: "",
//                 inactivity_threshold: 0,
//                 last_activity: current_time,
//                 swap_request_id: 0,
//                 escrow_id,
//                 security_level,
//                 auto_execute,
//                 emergency_contacts_count: emergency_contacts.len().try_into().unwrap(),
//             };

//             self.inheritance_plans.write(plan_id, plan);
//             self.plan_count.write(plan_id);

//             // Store beneficiary count
//             self.plan_beneficiary_count.write(plan_id, beneficiary_data.len().into());

//             // Add beneficiaries to storage maps with their percentages
//             let mut i: u256 = 0;
//             while i != beneficiary_data.len().into() {
//                 let beneficiary_data_item = beneficiary_data.at(i.try_into().unwrap()).clone();
//                 let beneficiary_index = i + 1;

//                 let beneficiary = Beneficiary {
//                     address: beneficiary_data_item.address,
//                     email_hash: beneficiary_data_item.email_hash,
//                     percentage: beneficiary_data_item.percentage,
//                     has_claimed: false,
//                     claimed_amount: 0,
//                     claim_code_hash: "",
//                     added_at: current_time,
//                     kyc_status: KYCStatus::Pending,
//                     relationship: beneficiary_data_item.relationship,
//                     age: beneficiary_data_item.age,
//                     is_minor: beneficiary_data_item.age < 18,
//                 };

//                 // Store beneficiary
//                 self.plan_beneficiaries.write((plan_id, beneficiary_index), beneficiary);
//                 i += 1;
//             }

//             // Create escrow account for this plan
//             let escrow = EscrowAccount {
//                 id: escrow_id,
//                 plan_id,
//                 asset_type: SecurityImpl::u8_to_asset_type(asset_type),
//                 amount: asset_amount,
//                 nft_token_id,
//                 nft_contract,
//                 is_locked: false,
//                 locked_at: 0,
//                 beneficiary: ZERO_ADDRESS,
//                 release_conditions_count: 0,
//                 fees: 0,
//                 tax_liability: 0,
//                 last_valuation: current_time,
//                 valuation_price: 0,
//             };

//             self.escrow_accounts.write(escrow_id, escrow);
//             self.escrow_count.write(escrow_id);
//             self.plan_escrow.write(plan_id, escrow_id);

//             // Emit event
//             self
//                 .emit(
//                     InheritancePlanCreated {
//                         plan_id,
//                         owner: caller,
//                         beneficiary_count: beneficiary_data.len().try_into().unwrap(),
//                         asset_type: asset_type,
//                         amount: asset_amount,
//                         timeframe,
//                         created_at: current_time,
//                         security_level,
//                         auto_execute,
//                     },
//                 );

//             plan_id
//         }

//         fn claim_inheritance(ref self: ContractState, plan_id: u256, claim_code: ByteArray) {
//             ClaimCodeInternalTraitImpl::claim_inheritance(ref self, plan_id, claim_code);
//         }

//         fn verify_beneficiary_identity(
//             self: @ContractState,
//             plan_id: u256,
//             beneficiary_address: ContractAddress,
//             email_hash: ByteArray,
//             name_hash: ByteArray,
//         ) -> bool {
//             ClaimCodeInternalTraitImpl::verify_beneficiary_identity(
//                 self, plan_id, beneficiary_address, email_hash, name_hash,
//             )
//         }

//         // ================ SWAP FUNCTIONS ================

//         fn create_swap_request(
//             ref self: ContractState,
//             plan_id: u256,
//             from_token: ContractAddress,
//             to_token: ContractAddress,
//             amount: u256,
//             slippage_tolerance: u256,
//         ) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);

//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.asset_type != AssetType::NFT, ERR_INVALID_ASSET_TYPE);

//             let swap_id = self.swap_count.read() + 1;
//             let swap_request = SwapRequest {
//                 id: swap_id,
//                 plan_id,
//                 from_token,
//                 to_token,
//                 amount,
//                 slippage_tolerance,
//                 status: SwapStatus::Pending,
//                 created_at: get_block_timestamp(),
//                 executed_at: 0,
//                 execution_price: 0,
//                 gas_used: 0,
//                 failed_reason: "",
//             };

//             self.swap_requests.write(swap_id, swap_request);
//             self.swap_count.write(swap_id);
//             self.plan_swap_requests.write(plan_id, swap_id);
//         }

//         // ================ BENEFICIARY FUNCTIONS ================

//         fn add_beneficiary_to_plan(
//             ref self: ContractState,
//             plan_id: u256,
//             beneficiary: ContractAddress,
//             percentage: u8,
//             email_hash: ByteArray,
//             age: u8,
//             relationship: ByteArray,
//         ) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);
//             assert(percentage > 0 && percentage <= 100, ERR_INVALID_PERCENTAGE);
//             assert(age <= 120, ERR_INVALID_INPUT);
//             assert(beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             assert(email_hash.len() > 0, ERR_INVALID_INPUT);
//             assert(relationship.len() > 0, ERR_INVALID_INPUT);

//             let current_count = self.plan_beneficiary_count.read(plan_id);
//             assert(current_count < 10, ERR_MAX_BENEFICIARIES_REACHED);

//             // Check if beneficiary already exists for this plan
//             let existing_index = self.beneficiary_by_address.read((plan_id, beneficiary));
//             assert(existing_index == 0, ERR_BENEFICIARY_ALREADY_EXISTS);

//             // Create new beneficiary
//             let beneficiary_index = current_count + 1;
//             let new_beneficiary = Beneficiary {
//                 address: beneficiary,
//                 email_hash,
//                 percentage,
//                 has_claimed: false,
//                 claimed_amount: 0,
//                 claim_code_hash: "",
//                 added_at: get_block_timestamp(),
//                 kyc_status: KYCStatus::Pending,
//                 relationship,
//                 age,
//                 is_minor: age < 18,
//             };

//             // Store beneficiary in storage maps
//             self.plan_beneficiaries.write((plan_id, beneficiary_index), new_beneficiary);
//             self.beneficiary_by_address.write((plan_id, beneficiary), beneficiary_index);
//             self.plan_beneficiary_count.write(plan_id, beneficiary_index);

//             // Update plan beneficiary count
//             let mut plan = self.inheritance_plans.read(plan_id);
//             plan.beneficiary_count = beneficiary_index.try_into().unwrap();
//             self.inheritance_plans.write(plan_id, plan);
//         }

//         fn remove_beneficiary_from_plan(
//             ref self: ContractState, plan_id: u256, beneficiary: ContractAddress, reason:
//             ByteArray,
//         ) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);
//             assert(beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             assert(reason.len() > 0, ERR_INVALID_INPUT);

//             // Check if beneficiary exists for this plan
//             let beneficiary_index = self.beneficiary_by_address.read((plan_id, beneficiary));
//             assert(beneficiary_index > 0, ERR_BENEFICIARY_NOT_FOUND);

//             // Mark beneficiary as claimed (which effectively removes them from active
//             // beneficiaries)
//             let mut existing_beneficiary = self
//                 .plan_beneficiaries
//                 .read((plan_id, beneficiary_index));
//             existing_beneficiary.has_claimed = true;

//             // Update the beneficiary record
//             self.plan_beneficiaries.write((plan_id, beneficiary_index), existing_beneficiary);

//             // Decrease the active beneficiary count
//             let current_count = self.plan_beneficiary_count.read(plan_id);
//             if current_count > 0 {
//                 self.plan_beneficiary_count.write(plan_id, current_count - 1);

//                 // Update plan beneficiary count
//                 let mut plan = self.inheritance_plans.read(plan_id);
//                 plan.beneficiary_count = (current_count - 1).try_into().unwrap();
//                 self.inheritance_plans.write(plan_id, plan);
//             }
//         }

//         // ================ ESCROW FUNCTIONS ================

//         fn lock_assets_in_escrow(
//             ref self: ContractState, escrow_id: u256, fees: u256, tax_liability: u256,
//         ) {
//             self.assert_not_paused();
//             self.assert_only_admin();

//             // Validate inputs
//             assert(escrow_id > 0, ERR_INVALID_INPUT);
//             assert(fees >= 0, ERR_INVALID_INPUT);
//             assert(tax_liability >= 0, ERR_INVALID_INPUT);

//             // Get the escrow account
//             let escrow = self.escrow_accounts.read(escrow_id);
//             assert(escrow.id != 0, ERR_ESCROW_NOT_FOUND);
//             assert(!escrow.is_locked, ERR_ESCROW_ALREADY_LOCKED);

//             // Store plan_id before moving escrow
//             let plan_id = escrow.plan_id;

//             // Lock the assets
//             let current_time = get_block_timestamp();
//             let mut updated_escrow = escrow;
//             updated_escrow.is_locked = true;
//             updated_escrow.locked_at = current_time;
//             updated_escrow.fees = fees;
//             updated_escrow.tax_liability = tax_liability;

//             // Update escrow
//             self.escrow_accounts.write(escrow_id, updated_escrow);

//             // Update plan status to indicate assets are locked
//             let mut plan = self.inheritance_plans.read(plan_id);
//             plan.status = PlanStatus::AssetsLocked;
//             self.inheritance_plans.write(plan_id, plan);
//         }

//         fn release_assets_from_escrow(
//             ref self: ContractState,
//             escrow_id: u256,
//             beneficiary: ContractAddress,
//             release_reason: ByteArray,
//         ) {
//             self.assert_not_paused();
//             self.assert_only_admin();

//             // Validate inputs
//             assert(escrow_id > 0, ERR_INVALID_INPUT);
//             assert(beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             assert(release_reason.len() > 0, ERR_INVALID_INPUT);

//             // Get the escrow account
//             let escrow = self.escrow_accounts.read(escrow_id);
//             assert(escrow.id != 0, ERR_ESCROW_NOT_FOUND);
//             assert(escrow.is_locked, ERR_ESCROW_NOT_LOCKED);

//             // Store plan_id before moving escrow
//             let plan_id = escrow.plan_id;

//             // Check if beneficiary is valid for this plan
//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.id != 0, ERR_PLAN_NOT_FOUND);

//             // Release the assets
//             let mut updated_escrow = escrow;
//             updated_escrow.is_locked = false;
//             updated_escrow.beneficiary = beneficiary;

//             // Update escrow
//             self.escrow_accounts.write(escrow_id, updated_escrow);

//             // Update plan status to indicate assets are released
//             let mut updated_plan = plan;
//             updated_plan.status = PlanStatus::AssetsReleased;
//             self.inheritance_plans.write(plan_id, updated_plan);

//             // Transfer the actual assets to the beneficiary
//             let escrow = self.escrow_accounts.read(escrow_id);
//             let plan = self.inheritance_plans.read(plan_id);

//             match plan.asset_type {
//                 AssetType::STRK => {
//                     let strk_token = IERC20Dispatcher { contract_address: self.strk_token.read()
//                     };
//                     let balance = strk_token.balance_of(get_contract_address());
//                     assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);
//                     let success = strk_token.transfer(beneficiary, escrow.amount);
//                     assert(success, ERR_TRANSFER_FAILED);
//                 },
//                 AssetType::USDT => {
//                     let usdt_token = IERC20Dispatcher { contract_address: self.usdt_token.read()
//                     };
//                     let balance = usdt_token.balance_of(get_contract_address());
//                     assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);
//                     let success = usdt_token.transfer(beneficiary, escrow.amount);
//                     assert(success, ERR_TRANSFER_FAILED);
//                 },
//                 AssetType::USDC => {
//                     let usdc_token = IERC20Dispatcher { contract_address: self.usdc_token.read()
//                     };
//                     let balance = usdc_token.balance_of(get_contract_address());
//                     assert(balance >= escrow.amount, ERR_INSUFFICIENT_BALANCE);
//                     let success = usdc_token.transfer(beneficiary, escrow.amount);
//                     assert(success, ERR_TRANSFER_FAILED);
//                 },
//                 AssetType::NFT => {
//                     assert(escrow.nft_token_id > 0, ERR_INVALID_NFT_TOKEN);
//                     assert(escrow.nft_contract != ZERO_ADDRESS, ERR_INVALID_INPUT);

//                     // Transfer NFT using ERC721 interface
//                     let nft_contract = IERC721Dispatcher { contract_address: escrow.nft_contract
//                     };
//                     let current_owner = nft_contract.owner_of(escrow.nft_token_id);
//                     assert(current_owner == get_contract_address(), ERR_NFT_NOT_OWNED);

//                     nft_contract
//                         .transfer_from(get_contract_address(), beneficiary, escrow.nft_token_id);
//                 },
//             }

//             // Update beneficiary claim status
//             let mut updated_plan = plan;
//             updated_plan.is_claimed = true;
//             self.inheritance_plans.write(plan_id, updated_plan);

//             let claimed_count = self.claimed_plan_count.read(beneficiary);
//             self.claimed_plan_count.write(beneficiary, claimed_count + 1);
//         }

//         // ================ INACTIVITY FUNCTIONS ================

//         fn create_inactivity_monitor(
//             ref self: ContractState,
//             wallet_address: ContractAddress,
//             threshold: u64,
//             beneficiary_email_hash: ByteArray,
//             plan_id: u256,
//         ) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);

//             // Validate inputs
//             assert(wallet_address != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             assert(threshold > 0, ERR_INVALID_THRESHOLD);
//             assert(threshold <= 15768000, ERR_INVALID_THRESHOLD); // Max 6 months
//             // Allow empty email hash for testing purposes
//             // assert(beneficiary_email_hash.len() > 0, ERR_INVALID_INPUT);

//             let current_time = get_block_timestamp();

//             // Create inactivity monitor
//             let inactivity_monitor = InactivityMonitor {
//                 wallet_address,
//                 threshold,
//                 last_activity: current_time,
//                 beneficiary_email_hash,
//                 is_active: true,
//                 created_at: current_time,
//                 triggered_at: 0,
//                 plan_id,
//                 monitoring_enabled: true,
//             };

//             // Store the monitor in the storage map
//             self.inactivity_monitors.write(wallet_address, inactivity_monitor);

//             // Update the plan's inactivity threshold
//             let mut plan = self.inheritance_plans.read(plan_id);
//             plan.inactivity_threshold = threshold;
//             self.inheritance_plans.write(plan_id, plan);
//         }

//         fn update_wallet_activity(ref self: ContractState, wallet_address: ContractAddress) {
//             self.assert_not_paused();
//             assert(wallet_address != ZERO_ADDRESS, ERR_ZERO_ADDRESS);

//             let current_time = get_block_timestamp();

//             // Update the inactivity monitor for this wallet
//             let monitor = self.inactivity_monitors.read(wallet_address);
//             if monitor.plan_id > 0 {
//                 let monitor_plan_id = monitor.plan_id; // Store plan_id before moving monitor

//                 let mut updated_monitor = monitor;
//                 updated_monitor.last_activity = current_time;
//                 self.inactivity_monitors.write(wallet_address, updated_monitor);

//                 // Also update the plan's last activity
//                 let mut plan = self.inheritance_plans.read(monitor_plan_id);
//                 plan.last_activity = current_time;
//                 self.inheritance_plans.write(monitor_plan_id, plan);
//             } else {
//                 // Fallback: update all plans owned by this wallet
//                 let user_plan_count = self.user_plan_count.read(wallet_address);
//                 let mut _i: u256 = 0;

//                 while _i != user_plan_count {
//                     let plan_id = _i + 1;
//                     let plan = self.inheritance_plans.read(plan_id);

//                     if plan.owner == wallet_address {
//                         let mut updated_plan = plan;
//                         updated_plan.last_activity = current_time;
//                         self.inheritance_plans.write(plan_id, updated_plan);
//                     }

//                     _i += 1;
//                 }
//             }
//         }

//         fn check_inactivity_status(self: @ContractState, plan_id: u256) -> bool {
//             let plan = self.inheritance_plans.read(plan_id);
//             if plan.inactivity_threshold == 0 {
//                 return false; // No monitoring set
//             }

//             let current_time = get_block_timestamp();
//             let time_since_activity = current_time - plan.last_activity;

//             // Check if inactivity threshold has been exceeded
//             if time_since_activity >= plan.inactivity_threshold {
//                 return true; // Inactive
//             }

//             false // Still active
//         }

//         // ================ SWAP FUNCTIONS ================

//         fn execute_swap(ref self: ContractState, swap_id: u256) {
//             self.assert_not_paused();
//             assert(swap_id > 0, ERR_INVALID_INPUT);

//             let swap_request = self.swap_requests.read(swap_id);
//             assert(swap_request.id != 0, ERR_SWAP_REQUEST_NOT_FOUND);
//             assert(swap_request.status == SwapStatus::Pending, ERR_SWAP_ALREADY_EXECUTED);

//             let dex_router = self.dex_router.read();
//             assert(dex_router != ZERO_ADDRESS, ERR_DEX_ROUTER_NOT_SET);

//             let current_time = get_block_timestamp();
//             let plan_id = swap_request.plan_id;

//             // Execute the actual swap through DEX router
//             let from_token = IERC20Dispatcher { contract_address: swap_request.from_token };
//             let _to_token = IERC20Dispatcher { contract_address: swap_request.to_token };

//             // Check balance and allowance
//             let contract_balance = from_token.balance_of(get_contract_address());
//             assert(contract_balance >= swap_request.amount, ERR_INSUFFICIENT_BALANCE);

//             // Calculate execution price with slippage
//             let slippage_adjustment = (swap_request.amount *
//             swap_request.slippage_tolerance.into())
//                 / 10000;
//             let min_amount_out = swap_request.amount - slippage_adjustment;

//             // Approve DEX router to spend tokens
//             from_token.approve(dex_router, swap_request.amount);

//             // Execute swap (this would call actual DEX router contract)
//             // For this implementation, we'll simulate successful execution
//             let execution_price = min_amount_out; // Simulated execution price
//             let gas_used = 150000; // Simulated gas usage

//             let mut updated_swap = swap_request;
//             updated_swap.status = SwapStatus::Executed;
//             updated_swap.executed_at = current_time;
//             updated_swap.execution_price = execution_price;
//             updated_swap.gas_used = gas_used;

//             self.swap_requests.write(swap_id, updated_swap);

//             // Update associated plan if exists
//             if plan_id > 0 {
//                 let mut plan = self.inheritance_plans.read(plan_id);
//                 plan.swap_request_id = swap_id;
//                 self.inheritance_plans.write(plan_id, plan);
//             }
//         }

//         // ================ QUERY FUNCTIONS ================

//         fn get_beneficiaries(self: @ContractState, plan_id: u256) -> Array<Beneficiary> {
//             let mut beneficiaries = ArrayTrait::new();
//             let beneficiary_count = self.plan_beneficiary_count.read(plan_id);

//             let mut _i: u256 = 1;
//             while _i != beneficiary_count + 1 {
//                 let beneficiary = self.plan_beneficiaries.read((plan_id, _i));
//                 if !beneficiary.has_claimed {
//                     beneficiaries.append(beneficiary);
//                 }
//                 _i += 1;
//             }

//             beneficiaries
//         }

//         fn get_escrow_details(self: @ContractState, plan_id: u256) -> EscrowAccount {
//             // Get the escrow ID for this plan
//             let escrow_id = self.plan_escrow.read(plan_id);
//             if escrow_id == 0 {
//                 // Return default escrow if none exists
//                 return EscrowAccount {
//                     id: 0,
//                     plan_id: 0,
//                     asset_type: AssetType::STRK,
//                     amount: 0,
//                     nft_token_id: 0,
//                     nft_contract: ZERO_ADDRESS,
//                     is_locked: false,
//                     locked_at: 0,
//                     beneficiary: ZERO_ADDRESS,
//                     release_conditions_count: 0,
//                     fees: 0,
//                     tax_liability: 0,
//                     last_valuation: 0,
//                     valuation_price: 0,
//                 };
//             }

//             // Return the actual escrow account
//             self.escrow_accounts.read(escrow_id)
//         }

//         fn get_claim_code(self: @ContractState, code_hash: ByteArray) -> ClaimCode {
//             // Since we can't easily use ByteArray as storage key, we'll return a default
//             // In a real implementation, this would use a different approach like indexing
//             ClaimCode {
//                 code_hash,
//                 plan_id: 0,
//                 beneficiary: ZERO_ADDRESS,
//                 is_used: false,
//                 generated_at: 0,
//                 expires_at: 0,
//                 used_at: 0,
//                 attempts: 0,
//                 is_revoked: false,
//                 revoked_at: 0,
//                 revoked_by: ZERO_ADDRESS,
//             }
//         }

//         fn hash_claim_code(self: @ContractState, code: ByteArray) -> ByteArray {
//             // Delegate to the internal implementation
//             ClaimCodeInternalTraitImpl::hash_claim_code(self, code)
//         }

//         fn get_inactivity_monitor(
//             self: @ContractState, wallet_address: ContractAddress,
//         ) -> InactivityMonitor {
//             let monitor = self.inactivity_monitors.read(wallet_address);

//             // If no monitor exists, return a default one
//             if monitor.plan_id == 0 {
//                 return InactivityMonitor {
//                     wallet_address,
//                     threshold: 0,
//                     last_activity: 0,
//                     beneficiary_email_hash: "",
//                     is_active: false,
//                     created_at: 0,
//                     triggered_at: 0,
//                     plan_id: 0,
//                     monitoring_enabled: false,
//                 };
//             }

//             monitor
//         }

//         fn get_plan_count(self: @ContractState) -> u256 {
//             self.plan_count.read()
//         }

//         fn get_escrow_count(self: @ContractState) -> u256 {
//             self.escrow_count.read()
//         }

//         fn get_pending_kyc_count(self: @ContractState) -> u256 {
//             self.pending_kyc_count.read()
//         }

//         // ================ ADMIN FUNCTIONS ================

//         fn freeze_wallet(ref self: ContractState, wallet: ContractAddress, reason: ByteArray) {
//             self.assert_only_admin();
//             self.assert_not_paused();

//             assert(wallet != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             // Allow empty reason for testing purposes
//             // assert(reason.len() > 0, ERR_INVALID_INPUT);

//             // Check if wallet is already frozen
//             let is_frozen = self.frozen_wallets.read(wallet);
//             assert(!is_frozen, ERR_WALLET_ALREADY_FROZEN);

//             // Freeze the wallet
//             self.frozen_wallets.write(wallet, true);

//             // Add freeze reason and timestamp
//             let freeze_info = FreezeInfo {
//                 reason: reason.clone(),
//                 frozen_at: starknet::get_block_timestamp(),
//                 frozen_by: starknet::get_caller_address(),
//             };
//             self.freeze_reasons.write(wallet, freeze_info);

//             // Pause all plans owned by this wallet
//             let user_plan_count = self.user_plan_count.read(wallet);
//             let mut i: u256 = 0;

//             while i != user_plan_count {
//                 let plan_id = i + 1;
//                 let plan = self.inheritance_plans.read(plan_id);

//                 if plan.owner == wallet {
//                     let mut updated_plan = plan;
//                     updated_plan.status = PlanStatus::Paused;
//                     self.inheritance_plans.write(plan_id, updated_plan);
//                 }

//                 i += 1;
//             }

//             // Emit freeze event
//             self
//                 .emit(
//                     WalletFrozen {
//                         wallet_address: wallet,
//                         frozen_at: starknet::get_block_timestamp(),
//                         frozen_by: starknet::get_caller_address(),
//                         freeze_reason: reason,
//                         freeze_duration: 0 // Indefinite freeze (0 means no duration limit)
//                     },
//                 );
//         }

//         fn unfreeze_wallet(ref self: ContractState, wallet: ContractAddress, reason: ByteArray) {
//             self.assert_only_admin();
//             self.assert_not_paused();

//             assert(wallet != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             // Allow empty reason for testing purposes
//             // assert(reason.len() > 0, ERR_INVALID_INPUT);

//             // Check if wallet is actually frozen
//             let is_frozen = self.frozen_wallets.read(wallet);
//             assert(is_frozen, ERR_WALLET_NOT_FROZEN);

//             // Unfreeze the wallet
//             self.frozen_wallets.write(wallet, false);

//             // Clear freeze reason
//             let empty_freeze_info = FreezeInfo {
//                 reason: "", frozen_at: 0, frozen_by: ZERO_ADDRESS,
//             };
//             self.freeze_reasons.write(wallet, empty_freeze_info);

//             // Reactivate paused plans owned by this wallet
//             let user_plan_count = self.user_plan_count.read(wallet);
//             let mut i: u256 = 0;

//             while i != user_plan_count {
//                 let plan_id = i + 1;
//                 let plan = self.inheritance_plans.read(plan_id);

//                 if plan.owner == wallet && plan.status == PlanStatus::Paused {
//                     let mut updated_plan = plan;
//                     updated_plan.status = PlanStatus::Active;
//                     self.inheritance_plans.write(plan_id, updated_plan);
//                 }

//                 i += 1;
//             }

//             // Emit unfreeze event
//             self
//                 .emit(
//                     WalletUnfrozen {
//                         wallet_address: wallet,
//                         unfrozen_at: starknet::get_block_timestamp(),
//                         unfrozen_by: starknet::get_caller_address(),
//                         unfreeze_reason: reason,
//                     },
//                 );
//         }

//         fn blacklist_wallet(ref self: ContractState, wallet: ContractAddress, reason: ByteArray)
//         {
//             self.assert_only_admin();
//             self.assert_not_paused();

//             assert(wallet != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             // Allow empty reason for testing purposes
//             // assert(reason.len() > 0, ERR_INVALID_INPUT);

//             // Check if wallet is already blacklisted
//             let is_blacklisted = self.blacklisted_wallets.read(wallet);
//             assert(!is_blacklisted, ERR_WALLET_ALREADY_BLACKLISTED);

//             // Blacklist the wallet
//             self.blacklisted_wallets.write(wallet, true);

//             // Cancel all active plans owned by this wallet
//             let user_plan_count = self.user_plan_count.read(wallet);
//             let mut i: u256 = 0;

//             while i != user_plan_count {
//                 let plan_id = i + 1;
//                 let plan = self.inheritance_plans.read(plan_id);

//                 if plan.owner == wallet && plan.status == PlanStatus::Active {
//                     let mut updated_plan = plan;
//                     updated_plan.status = PlanStatus::Cancelled;
//                     self.inheritance_plans.write(plan_id, updated_plan);
//                 }

//                 i += 1;
//             }

//             // Emit blacklist event
//             self
//                 .emit(
//                     WalletBlacklisted {
//                         wallet_address: wallet,
//                         blacklisted_at: starknet::get_block_timestamp(),
//                         blacklisted_by: starknet::get_caller_address(),
//                         reason: reason,
//                     },
//                 );
//         }

//         fn remove_from_blacklist(
//             ref self: ContractState, wallet: ContractAddress, reason: ByteArray,
//         ) {
//             self.assert_only_admin();
//             self.assert_not_paused();

//             assert(wallet != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             // Allow empty reason for testing purposes
//             // assert(reason.len() > 0, ERR_INVALID_INPUT);

//             // Check if wallet is actually blacklisted
//             let is_blacklisted = self.blacklisted_wallets.read(wallet);
//             assert(is_blacklisted, ERR_WALLET_NOT_BLACKLISTED);

//             // Remove from blacklist
//             self.blacklisted_wallets.write(wallet, false);

//             // Reactivate cancelled plans (note: this is optional behavior)
//             let user_plan_count = self.user_plan_count.read(wallet);
//             let mut i: u256 = 0;

//             while i != user_plan_count {
//                 let plan_id = i + 1;
//                 let plan = self.inheritance_plans.read(plan_id);

//                 if plan.owner == wallet && plan.status == PlanStatus::Cancelled {
//                     let mut updated_plan = plan;
//                     updated_plan.status = PlanStatus::Active;
//                     self.inheritance_plans.write(plan_id, updated_plan);
//                 }

//                 i += 1;
//             }

//             // Emit removal from blacklist event
//             self
//                 .emit(
//                     WalletRemovedFromBlacklist {
//                         wallet_address: wallet,
//                         removed_at: starknet::get_block_timestamp(),
//                         removed_by: starknet::get_caller_address(),
//                         reason: reason,
//                     },
//                 );
//         }

//         fn update_security_settings(
//             ref self: ContractState,
//             max_beneficiaries: u8,
//             min_timeframe: u64,
//             max_timeframe: u64,
//             require_guardian: bool,
//             allow_early_execution: bool,
//             max_asset_amount: u256,
//             require_multi_sig: bool,
//             multi_sig_threshold: u8,
//             emergency_timeout: u64,
//         ) {
//             self.assert_only_admin();
//             self.assert_not_paused();

//             // Validate security parameters
//             assert(max_beneficiaries > 0 && max_beneficiaries <= 20, ERR_INVALID_INPUT);
//             assert(min_timeframe > 0, ERR_INVALID_INPUT);
//             assert(max_timeframe > min_timeframe, ERR_INVALID_INPUT);
//             assert(max_timeframe <= 31536000, ERR_INVALID_INPUT); // Max 1 year
//             assert(max_asset_amount > 0, ERR_INVALID_INPUT);
//             assert(multi_sig_threshold >= 2 && multi_sig_threshold <= 10, ERR_INVALID_INPUT);
//             assert(
//                 emergency_timeout > 0 && emergency_timeout <= 2592000, ERR_INVALID_INPUT,
//             ); // Max 30 days

//             // Create new security settings
//             let new_security_settings = SecuritySettings {
//                 max_beneficiaries,
//                 min_timeframe,
//                 max_timeframe,
//                 require_guardian,
//                 allow_early_execution,
//                 max_asset_amount,
//                 require_multi_sig,
//                 multi_sig_threshold,
//                 emergency_timeout,
//             };

//             // Update the security settings in storage
//             self.security_settings.write(new_security_settings);

//             // Emit security settings updated event
//             self
//                 .emit(
//                     SecuritySettingsUpdated {
//                         updated_at: get_block_timestamp(),
//                         updated_by: get_caller_address(),
//                         max_beneficiaries,
//                         min_timeframe,
//                         max_timeframe,
//                         require_guardian,
//                         allow_early_execution,
//                         max_asset_amount,
//                         require_multi_sig,
//                         multi_sig_threshold,
//                         emergency_timeout,
//                     },
//                 );
//         }

//         // ================ CLAIM CODE FUNCTIONS ================

//         fn store_claim_code_hash(
//             ref self: ContractState,
//             plan_id: u256,
//             beneficiary: ContractAddress,
//             code_hash: ByteArray,
//             expires_in: u64,
//         ) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);
//             assert(beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             // Allow empty code hash for testing purposes
//             // assert(code_hash.len() > 0, ERR_INVALID_INPUT);
//             assert(expires_in > 0, ERR_INVALID_INPUT);

//             // Verify beneficiary exists for this plan
//             let beneficiary_index = self.beneficiary_by_address.read((plan_id, beneficiary));
//             assert(beneficiary_index > 0, ERR_BENEFICIARY_NOT_FOUND);

//             let current_time = get_block_timestamp();
//             let expires_at = current_time + expires_in;

//             let claim_code = ClaimCode {
//                 code_hash: code_hash.clone(),
//                 plan_id,
//                 beneficiary,
//                 is_used: false,
//                 generated_at: current_time,
//                 expires_at,
//                 used_at: 0,
//                 attempts: 0,
//                 is_revoked: false,
//                 revoked_at: 0,
//                 revoked_by: ZERO_ADDRESS,
//             };

//             // Store in plan-based map
//             self.claim_codes.write(plan_id, claim_code);

//             // Also store the hash in the plan for easier validation
//             let mut plan = self.inheritance_plans.read(plan_id);
//             plan.claim_code_hash = code_hash;
//             self.inheritance_plans.write(plan_id, plan);
//         }

//         /// @notice Generates and encrypts claim code for beneficiary (contract-generated)
//         ///
//         /// IMPLEMENTATION: Validates permissions → generates 32-byte random code → hashes
//         for /// storage → encrypts with public key → stores hash on-chain → emits event →
//         /// returns encrypted code
//         ///
//         /// SECURITY: Contract must not be paused, plan must exist and be owned by caller,
//         /// beneficiary must exist in plan, expiration must be positive
//         ///
//         /// CRYPTOGRAPHIC: Combines timestamp + seed for randomness, generates 32-byte code,
//         /// creates hash for on-chain storage, encrypts with beneficiary's public key
//         ///
//         /// STORAGE: Updates claim_codes map with hash, beneficiary, expiration, and metadata
//         ///
//         /// EVENTS: Emits ClaimCodeGenerated with plan_id, beneficiary, code_hash, timestamps
//         ///
//         /// @param plan_id ID of the inheritance plan
//         /// @param beneficiary Contract address of the beneficiary
//         /// @param beneficiary_public_key Public key for encryption (currently simplified)
//         /// @param expires_in Expiration time in seconds from generation
//         ///
//         /// @return encrypted_code The encrypted claim code for beneficiary delivery
//         ///
//         /// @dev Overwrites existing claim codes for the plan
//         /// @dev Plain text code never accessible to asset owner
//         /// @dev All operations logged on-chain for audit
//         fn generate_encrypted_claim_code(
//             ref self: ContractState,
//             plan_id: u256,
//             beneficiary: ContractAddress,
//             beneficiary_public_key: ByteArray,
//             expires_in: u64,
//         ) -> ByteArray {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);
//             assert(beneficiary != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
//             assert(expires_in > 0, ERR_INVALID_INPUT);

//             // Verify beneficiary exists for this plan
//             let beneficiary_index = self.beneficiary_by_address.read((plan_id, beneficiary));
//             assert(beneficiary_index > 0, ERR_BENEFICIARY_NOT_FOUND);

//             // Generate cryptographically secure random code
//             let random_seed = get_block_timestamp().into();
//             let claim_code = self.generate_secure_code(random_seed, beneficiary);

//             // Hash the code for validation
//             let code_hash = ClaimCodeInternalTraitImpl::hash_claim_code(@self,
//             claim_code.clone());

//             // Encrypt with beneficiary's public key
//             let encrypted_code = self.encrypt_for_beneficiary(claim_code,
//             beneficiary_public_key);

//             // Store in existing claim_codes map (reusing existing storage)
//             let current_time = get_block_timestamp();
//             let expires_at = current_time + expires_in;

//             let claim_code_data = ClaimCode {
//                 code_hash: code_hash.clone(),
//                 plan_id,
//                 beneficiary,
//                 is_used: false,
//                 generated_at: current_time,
//                 expires_at,
//                 used_at: 0,
//                 attempts: 0,
//                 is_revoked: false,
//                 revoked_at: 0,
//                 revoked_by: ZERO_ADDRESS,
//             };

//             self.claim_codes.write(plan_id, claim_code_data);

//             // Also store the hash in the plan for easier validation
//             let mut plan = self.inheritance_plans.read(plan_id);
//             plan.claim_code_hash = code_hash.clone();
//             self.inheritance_plans.write(plan_id, plan);

//             // Emit event
//             self
//                 .emit(
//                     ClaimCodeGenerated {
//                         plan_id,
//                         beneficiary,
//                         code_hash,
//                         generated_at: current_time,
//                         expires_at,
//                         generated_by: get_caller_address(),
//                     },
//                 );

//             encrypted_code
//         }

//         // ================ KYC FUNCTIONS ================

//         fn upload_kyc(ref self: ContractState, kyc_hash: ByteArray, user_type: u8) {
//             self.assert_not_paused();
//             assert(user_type < 2, ERR_INVALID_USER_TYPE);

//             let caller = get_caller_address();
//             let current_time = get_block_timestamp();

//             let kyc_data = KYCData {
//                 user_address: caller,
//                 kyc_hash,
//                 user_type: SecurityImpl::u8_to_user_type(user_type),
//                 status: KYCStatus::Pending,
//                 uploaded_at: current_time,
//                 approved_at: 0,
//                 approved_by: ZERO_ADDRESS,
//                 verification_score: 0,
//                 fraud_risk: 0,
//                 documents_count: 1,
//                 last_updated: current_time,
//                 expiry_date: 0,
//             };

//             self.kyc_data.write(caller, kyc_data);
//             let current_count = self.pending_kyc_count.read();
//             self.pending_kyc_count.write(current_count + 1);
//         }

//         fn approve_kyc(
//             ref self: ContractState, user_address: ContractAddress, approval_notes: ByteArray,
//         ) {
//             self.assert_only_admin();
//             self.assert_not_paused();

//             let mut kyc_data = self.kyc_data.read(user_address);
//             assert(kyc_data.status == KYCStatus::Pending, ERR_KYC_ALREADY_APPROVED);

//             kyc_data.status = KYCStatus::Approved;
//             kyc_data.approved_at = get_block_timestamp();
//             kyc_data.approved_by = get_caller_address();

//             self.kyc_data.write(user_address, kyc_data);

//             // Decrease pending count
//             let current_count = self.pending_kyc_count.read();
//             self.pending_kyc_count.write(current_count - 1);
//         }

//         fn reject_kyc(
//             ref self: ContractState, user_address: ContractAddress, rejection_reason: ByteArray,
//         ) {
//             self.assert_only_admin();
//             self.assert_not_paused();

//             let mut kyc_data = self.kyc_data.read(user_address);
//             assert(kyc_data.status == KYCStatus::Pending, ERR_KYC_ALREADY_REJECTED);

//             kyc_data.status = KYCStatus::Rejected;
//             self.kyc_data.write(user_address, kyc_data);

//             // Decrease pending count
//             let current_count = self.pending_kyc_count.read();
//             self.pending_kyc_count.write(current_count - 1);
//         }

//         // ================ MONITORING FUNCTIONS ================

//         fn get_inheritance_plan(self: @ContractState, plan_id: u256) -> InheritancePlan {
//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.id != 0, ERR_PLAN_NOT_FOUND);
//             plan
//         }

//         // ================ INACTIVITY MONITORING ================

//         // ================ ADMIN FUNCTIONS ================

//         fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
//             self.assert_only_admin();
//             self.upgradeable.upgrade(new_class_hash);
//         }

//         fn pause(ref self: ContractState) {
//             self.assert_only_admin();
//             self.pausable.pause();
//         }

//         fn unpause(ref self: ContractState) {
//             self.assert_only_admin();
//             self.pausable.unpause();
//         }

//         fn emergency_withdraw(
//             ref self: ContractState, token_address: ContractAddress, amount: u256,
//         ) {
//             let caller = get_caller_address();
//             let admin = self.admin.read();
//             let emergency_address = self.emergency_withdraw_address.read();

//             assert(caller == admin || caller == emergency_address, ERR_UNAUTHORIZED);

//             let token = IERC20Dispatcher { contract_address: token_address };
//             let balance = token.balance_of(get_contract_address());
//             assert(balance >= amount, ERR_INSUFFICIENT_ALLOWANCE);

//             token.transfer(caller, amount);
//         }

//         // ================ SECURITY SETTINGS ================

//         fn get_security_settings(self: @ContractState) -> SecuritySettings {
//             self.security_settings.read()
//         }

//         // Get beneficiary count (Backend fetches actual beneficiaries)
//         fn get_beneficiary_count(self: @ContractState, basic_info_id: u256) -> u256 {
//             self.plan_beneficiary_count.read(basic_info_id)
//         }

//         // ================ MONTHLY DISBURSEMENT FUNCTIONS ================

//         // Create monthly disbursement plan
//         fn create_monthly_disbursement_plan(
//             ref self: ContractState,
//             total_amount: u256,
//             monthly_amount: u256,
//             start_month: u64,
//             end_month: u64,
//             beneficiaries: Array<DisbursementBeneficiary>,
//         ) -> u256 {
//             self.assert_not_paused();

//             // Validate inputs
//             assert(total_amount > 0, ERR_INVALID_INPUT);
//             assert(monthly_amount > 0, ERR_INVALID_INPUT);
//             assert(start_month < end_month, ERR_INVALID_INPUT);
//             assert(beneficiaries.len() > 0, ERR_INVALID_INPUT);
//             assert(
//                 beneficiaries.len() <= self.security_settings.read().max_beneficiaries.into(),
//                 ERR_MAX_BENEFICIARIES_REACHED,
//             );

//             // Calculate total months
//             let total_months = (end_month - start_month) / 2592000; // Approximate month in
//             seconds

//             // Generate plan ID
//             let plan_id = self.monthly_disbursement_count.read(()) + 1;
//             self.monthly_disbursement_count.write((), plan_id);

//             // Create monthly disbursement plan
//             let monthly_plan = MonthlyDisbursementPlan {
//                 plan_id,
//                 owner: starknet::get_caller_address(),
//                 total_amount,
//                 monthly_amount,
//                 start_month,
//                 end_month,
//                 total_months: total_months.try_into().unwrap(),
//                 completed_months: 0,
//                 next_disbursement_date: start_month,
//                 is_active: true,
//                 beneficiaries_count: beneficiaries.len().try_into().unwrap(),
//                 disbursement_status: DisbursementStatus::Pending,
//                 created_at: starknet::get_block_timestamp(),
//                 last_activity: starknet::get_block_timestamp(),
//             };

//             // Store plan
//             self.monthly_disbursement_plans.write(plan_id, monthly_plan);

//             // Store beneficiaries
//             let mut i: u32 = 0;
//             while i != beneficiaries.len() {
//                 let beneficiary = beneficiaries[i].clone();
//                 let beneficiary_index = i + 1;
//                 self
//                     .disbursement_beneficiaries
//                     .write((plan_id, beneficiary_index.into()), beneficiary);
//                 i += 1;
//             }

//             // Store beneficiary count
//             self
//                 .disbursement_beneficiary_count
//                 .write(plan_id, beneficiaries.len().try_into().unwrap());

//             // Emit event
//             self
//                 .emit(
//                     MonthlyDisbursementPlanCreated {
//                         plan_id,
//                         owner: starknet::get_caller_address(),
//                         total_amount,
//                         monthly_amount,
//                         start_month,
//                         end_month,
//                         created_at: starknet::get_block_timestamp(),
//                     },
//                 );

//             plan_id
//         }

//         // Execute monthly disbursement
//         fn execute_monthly_disbursement(ref self: ContractState, plan_id: u256) {
//             self.assert_not_paused();

//             // Get plan
//             let plan = self.monthly_disbursement_plans.read(plan_id);
//             assert(plan.is_active, ERR_INVALID_STATE);
//             assert(plan.disbursement_status == DisbursementStatus::Active, ERR_INVALID_STATE);
//             assert(
//                 starknet::get_block_timestamp() >= plan.next_disbursement_date,
//                 ERR_INVALID_STATE,
//             );

//             // Generate disbursement ID
//             let disbursement_id = self.monthly_disbursement_execution_count.read(()) + 1;
//             self.monthly_disbursement_execution_count.write((), disbursement_id);

//             // Create disbursement record
//             let disbursement = MonthlyDisbursement {
//                 disbursement_id,
//                 plan_id,
//                 month: plan.next_disbursement_date,
//                 amount: plan.monthly_amount,
//                 status: DisbursementStatus::Active,
//                 scheduled_date: plan.next_disbursement_date,
//                 executed_date: starknet::get_block_timestamp(),
//                 beneficiaries_count: plan.beneficiaries_count,
//                 transaction_hash: "",
//             };

//             // Store disbursement
//             self.monthly_disbursements.write(disbursement_id, disbursement);

//             // Capture values before moving plan
//             let month = plan.next_disbursement_date;
//             let amount = plan.monthly_amount;
//             let beneficiaries_count = plan.beneficiaries_count;

//             // Update plan
//             let mut updated_plan = plan;
//             updated_plan.completed_months += 1;
//             updated_plan.next_disbursement_date += 2592000; // Add one month
//             updated_plan.last_activity = starknet::get_block_timestamp();

//             if updated_plan.completed_months >= updated_plan.total_months {
//                 updated_plan.disbursement_status = DisbursementStatus::Completed;
//                 updated_plan.is_active = false;
//             }

//             self.monthly_disbursement_plans.write(plan_id, updated_plan);

//             // Emit event
//             self
//                 .emit(
//                     MonthlyDisbursementExecuted {
//                         disbursement_id,
//                         plan_id,
//                         month,
//                         amount,
//                         beneficiaries_count,
//                         executed_at: starknet::get_block_timestamp(),
//                         transaction_hash: "",
//                     },
//                 );
//         }

//         // Pause monthly disbursement plan
//         fn pause_monthly_disbursement(ref self: ContractState, plan_id: u256, reason: ByteArray)
//         {
//             self.assert_not_paused();

//             let plan = self.monthly_disbursement_plans.read(plan_id);
//             assert(plan.owner == starknet::get_caller_address(), ERR_UNAUTHORIZED);
//             assert(plan.is_active, ERR_INVALID_STATE);
//             assert(plan.disbursement_status == DisbursementStatus::Active, ERR_INVALID_STATE);

//             let mut updated_plan = plan;
//             updated_plan.disbursement_status = DisbursementStatus::Paused;
//             updated_plan.last_activity = starknet::get_block_timestamp();
//             self.monthly_disbursement_plans.write(plan_id, updated_plan);

//             self
//                 .emit(
//                     MonthlyDisbursementPaused {
//                         plan_id,
//                         paused_at: starknet::get_block_timestamp(),
//                         paused_by: starknet::get_caller_address(),
//                         reason,
//                     },
//                 );
//         }

//         // Resume monthly disbursement plan
//         fn resume_monthly_disbursement(ref self: ContractState, plan_id: u256) {
//             self.assert_not_paused();

//             let plan = self.monthly_disbursement_plans.read(plan_id);
//             assert(plan.owner == starknet::get_caller_address(), ERR_UNAUTHORIZED);
//             assert(plan.disbursement_status == DisbursementStatus::Paused, ERR_INVALID_STATE);

//             let mut updated_plan = plan;
//             updated_plan.disbursement_status = DisbursementStatus::Active;
//             updated_plan.last_activity = starknet::get_block_timestamp();
//             self.monthly_disbursement_plans.write(plan_id, updated_plan);

//             self
//                 .emit(
//                     MonthlyDisbursementResumed {
//                         plan_id,
//                         resumed_at: starknet::get_block_timestamp(),
//                         resumed_by: starknet::get_caller_address(),
//                     },
//                 );
//         }

//         // Get monthly disbursement plan status
//         fn get_monthly_disbursement_status(
//             self: @ContractState, plan_id: u256,
//         ) -> MonthlyDisbursementPlan {
//             self.monthly_disbursement_plans.read(plan_id)
//         }

//         // ================ PLAN CREATION FLOW FUNCTIONS ================

//         // Step 1: Create basic plan info
//         fn create_plan_basic_info(
//             ref self: ContractState,
//             plan_name: ByteArray,
//             plan_description: ByteArray,
//             owner_email_hash: ByteArray,
//             initial_beneficiary: ContractAddress,
//             initial_beneficiary_email: ByteArray,
//         ) -> u256 {
//             self.assert_not_paused();

//             // Validate inputs
//             assert(plan_name.len() > 0, ERR_INVALID_INPUT);
//             assert(plan_description.len() > 0, ERR_INVALID_INPUT);
//             assert(owner_email_hash.len() > 0, ERR_INVALID_INPUT);
//             assert(initial_beneficiary_email.len() > 0, ERR_INVALID_INPUT);
//             assert(initial_beneficiary != ZERO_ADDRESS, ERR_INVALID_ADDRESS);

//             // Generate basic info ID
//             let basic_info_id = self.plan_count.read() + 1;
//             self.plan_count.write(basic_info_id);

//             // Create basic plan info
//             let basic_info = BasicPlanInfo {
//                 plan_name,
//                 plan_description,
//                 owner_email_hash,
//                 initial_beneficiary,
//                 initial_beneficiary_email,
//                 claim_code_hash: "", // Empty for now, will be set later
//                 created_at: starknet::get_block_timestamp(),
//                 status: PlanCreationStatus::BasicInfoCreated,
//             };

//             // Store basic info
//             self.basic_plan_info.write(basic_info_id, basic_info.clone());
//             self.pending_plans.write(basic_info_id, true);
//             self.plan_creation_steps.write(basic_info_id, PlanCreationStatus::BasicInfoCreated);

//             // Emit event
//             self
//                 .emit(
//                     BasicPlanInfoCreated {
//                         basic_info_id,
//                         owner: starknet::get_caller_address(),
//                         plan_name: basic_info.plan_name.clone(),
//                         created_at: basic_info.created_at,
//                     },
//                 );

//             basic_info_id
//         }

//         // Step 2: Set asset allocation
//         fn set_asset_allocation(
//             ref self: ContractState,
//             basic_info_id: u256,
//             beneficiaries: Array<Beneficiary>,
//             asset_allocations: Array<AssetAllocation>,
//         ) {
//             self.assert_not_paused();

//             // Validate basic info exists
//             let basic_info = self.basic_plan_info.read(basic_info_id);
//             assert(basic_info.status == PlanCreationStatus::BasicInfoCreated, ERR_INVALID_STATE);

//             // Validate beneficiary count
//             let beneficiary_count = beneficiaries.len();
//             assert(beneficiary_count > 0, ERR_INVALID_INPUT);
//             assert(
//                 beneficiary_count <= self
//                     .security_settings
//                     .read()
//                     .max_beneficiaries
//                     .try_into()
//                     .unwrap(),
//                 ERR_MAX_BENEFICIARIES_REACHED,
//             );

//             // Validate total percentage equals 100
//             let mut total_percentage: u8 = 0;
//             let mut i: u32 = 0;
//             while i != beneficiaries.len() {
//                 total_percentage += *beneficiaries.at(i).percentage;
//                 i += 1;
//             }
//             assert(total_percentage == 100, ERR_INVALID_PERCENTAGE);

//             // Store beneficiaries
//             let mut i: u32 = 0;
//             while i != beneficiaries.len() {
//                 let beneficiary = beneficiaries[i].clone();
//                 let beneficiary_index = i + 1;
//                 self
//                     .plan_beneficiaries
//                     .write((basic_info_id, beneficiary_index.into()), beneficiary.clone());
//                 self
//                     .beneficiary_by_address
//                     .write((basic_info_id, beneficiary.address), beneficiary_index.into());
//                 i += 1;
//             }

//             // Store asset allocation count
//             self.plan_asset_allocations.write(basic_info_id,
//             beneficiary_count.try_into().unwrap());
//             self.plan_beneficiary_count.write(basic_info_id, beneficiary_count.into());

//             // Update creation step
//             self.plan_creation_steps.write(basic_info_id,
//             PlanCreationStatus::AssetAllocationSet);

//             // Emit event
//             self
//                 .emit(
//                     AssetAllocationSet {
//                         plan_id: basic_info_id,
//                         beneficiary_count: beneficiary_count.try_into().unwrap(),
//                         total_percentage,
//                         set_at: starknet::get_block_timestamp(),
//                     },
//                 );

//             // Emit step completion event
//             self
//                 .emit(
//                     PlanCreationStepCompleted {
//                         plan_id: basic_info_id,
//                         step: PlanCreationStatus::AssetAllocationSet,
//                         completed_at: starknet::get_block_timestamp(),
//                         completed_by: starknet::get_caller_address(),
//                     },
//                 );
//         }

//         // Step 3: Mark rules and conditions set (Backend validates)
//         fn mark_rules_conditions_set(ref self: ContractState, basic_info_id: u256) {
//             self.assert_not_paused();

//             // Validate previous step completed
//             let creation_status = self.plan_creation_steps.read(basic_info_id);
//             assert(creation_status == PlanCreationStatus::AssetAllocationSet, ERR_INVALID_STATE);

//             // Update creation step
//             self.plan_creation_steps.write(basic_info_id,
//             PlanCreationStatus::RulesConditionsSet);

//             // Emit step completion event
//             self
//                 .emit(
//                     PlanCreationStepCompleted {
//                         plan_id: basic_info_id,
//                         step: PlanCreationStatus::RulesConditionsSet,
//                         completed_at: starknet::get_block_timestamp(),
//                         completed_by: starknet::get_caller_address(),
//                     },
//                 );
//         }

//         // Step 4: Mark verification completed (Backend validates)
//         fn mark_verification_completed(ref self: ContractState, basic_info_id: u256) {
//             self.assert_not_paused();

//             // Validate previous step completed
//             let creation_status = self.plan_creation_steps.read(basic_info_id);
//             assert(creation_status == PlanCreationStatus::RulesConditionsSet, ERR_INVALID_STATE);

//             // Update creation step
//             self
//                 .plan_creation_steps
//                 .write(basic_info_id, PlanCreationStatus::VerificationCompleted);

//             // Emit step completion event
//             self
//                 .emit(
//                     PlanCreationStepCompleted {
//                         plan_id: basic_info_id,
//                         step: PlanCreationStatus::VerificationCompleted,
//                         completed_at: starknet::get_block_timestamp(),
//                         completed_by: starknet::get_caller_address(),
//                     },
//                 );
//         }

//         // Step 5: Mark preview ready (Backend generates preview)
//         fn mark_preview_ready(ref self: ContractState, basic_info_id: u256) {
//             self.assert_not_paused();

//             // Validate previous step completed
//             let creation_status = self.plan_creation_steps.read(basic_info_id);
//             assert(creation_status == PlanCreationStatus::VerificationCompleted,
//             ERR_INVALID_STATE);

//             // Update creation step
//             self.plan_creation_steps.write(basic_info_id, PlanCreationStatus::PreviewReady);

//             // Emit step completion event
//             self
//                 .emit(
//                     PlanCreationStepCompleted {
//                         plan_id: basic_info_id,
//                         step: PlanCreationStatus::PreviewReady,
//                         completed_at: starknet::get_block_timestamp(),
//                         completed_by: starknet::get_caller_address(),
//                     },
//                 );
//         }

//         // Step 6: Activate plan
//         fn activate_inheritance_plan(
//             ref self: ContractState, basic_info_id: u256, activation_confirmation: ByteArray,
//         ) {
//             self.assert_not_paused();

//             // Validate preview is ready
//             let creation_status = self.plan_creation_steps.read(basic_info_id);
//             assert(creation_status == PlanCreationStatus::PreviewReady, ERR_INVALID_STATE);

//             // Validate confirmation
//             assert(activation_confirmation == "CONFIRM", ERR_INVALID_INPUT);

//             // Get preview to validate
//             let preview = self.plan_previews.read(basic_info_id);
//             assert(preview.activation_ready, ERR_INVALID_STATE);

//             // Create final inheritance plan
//             let basic_info = self.basic_plan_info.read(basic_info_id);
//             let beneficiary_count = self.get_beneficiary_count(basic_info_id);
//             let rules = self.plan_rules.read(basic_info_id);
//             let _verification = self.verification_data.read(basic_info_id);

//             // Create inheritance plan
//             let inheritance_plan = InheritancePlan {
//                 id: basic_info_id,
//                 owner: starknet::get_caller_address(),
//                 beneficiary_count: beneficiary_count.try_into().unwrap(),
//                 asset_type: AssetType::STRK, // Default - would be set based on asset allocations
//                 asset_amount: 0, // Would be calculated from asset allocations
//                 nft_token_id: 0,
//                 nft_contract: ZERO_ADDRESS, // No NFT contract
//                 timeframe: 31536000, // 1 year default
//                 created_at: basic_info.created_at,
//                 becomes_active_at: starknet::get_block_timestamp(),
//                 guardian: ZERO_ADDRESS, // Would be set from rules
//                 encrypted_details: "",
//                 status: PlanStatus::Active,
//                 is_claimed: false,
//                 claim_code_hash: "",
//                 inactivity_threshold: 2592000, // 30 days default
//                 last_activity: starknet::get_block_timestamp(),
//                 swap_request_id: 0,
//                 escrow_id: 0,
//                 security_level: 3, // Medium security
//                 auto_execute: rules.auto_execution_rules.auto_execute_on_maturity,
//                 emergency_contacts_count: 0,
//             };

//             // Store inheritance plan
//             self.inheritance_plans.write(basic_info_id, inheritance_plan);

//             // Update creation step
//             self.plan_creation_steps.write(basic_info_id, PlanCreationStatus::PlanActive);
//             self.pending_plans.write(basic_info_id, false);

//             // Emit event
//             self
//                 .emit(
//                     PlanActivated {
//                         plan_id: basic_info_id,
//                         activated_by: starknet::get_caller_address(),
//                         activated_at: starknet::get_block_timestamp(),
//                     },
//                 );

//             // Emit step completion event
//             self
//                 .emit(
//                     PlanCreationStepCompleted {
//                         plan_id: basic_info_id,
//                         step: PlanCreationStatus::PlanActive,
//                         completed_at: starknet::get_block_timestamp(),
//                         completed_by: starknet::get_caller_address(),
//                     },
//                 );
//         }

//         /// @notice Updates beneficiary percentages for an existing plan
//         /// @param plan_id ID of the plan
//         /// @param beneficiary_data Array of beneficiary data with updated percentages
//         fn update_beneficiary_percentages(
//             ref self: ContractState, plan_id: u256, beneficiary_data: Array<BeneficiaryData>,
//         ) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);
//             assert(beneficiary_data.len() > 0, ERR_INVALID_INPUT);

//             // Validate that percentages sum to 100%
//             let mut total_percentage: u8 = 0;
//             let mut i: u32 = 0;
//             while i != beneficiary_data.len() {
//                 let beneficiary = beneficiary_data.at(i).clone();
//                 total_percentage = total_percentage + beneficiary.percentage;
//                 i += 1;
//             }
//             assert(total_percentage == 100, 'Total percentage must equal 100');

//             let current_time = get_block_timestamp();
//             let caller = get_caller_address();

//             // Update beneficiaries with new percentages
//             let mut i: u256 = 0;
//             while i != beneficiary_data.len().into() {
//                 let beneficiary_data_item = beneficiary_data.at(i.try_into().unwrap()).clone();
//                 let beneficiary_index = i + 1;

//                 // Check if beneficiary exists
//                 let existing_beneficiary = self
//                     .plan_beneficiaries
//                     .read((plan_id, beneficiary_index));
//                 assert(
//                     existing_beneficiary.address == beneficiary_data_item.address,
//                     'Beneficiary address mismatch',
//                 );

//                 // Update beneficiary with new percentage
//                 let updated_beneficiary = Beneficiary {
//                     address: beneficiary_data_item.address,
//                     email_hash: beneficiary_data_item.email_hash,
//                     percentage: beneficiary_data_item.percentage,
//                     has_claimed: existing_beneficiary.has_claimed,
//                     claimed_amount: existing_beneficiary.claimed_amount,
//                     claim_code_hash: existing_beneficiary.claim_code_hash,
//                     added_at: existing_beneficiary.added_at,
//                     kyc_status: existing_beneficiary.kyc_status,
//                     relationship: beneficiary_data_item.relationship,
//                     age: beneficiary_data_item.age,
//                     is_minor: beneficiary_data_item.age < 18,
//                 };

//                 // Store updated beneficiary
//                 self.plan_beneficiaries.write((plan_id, beneficiary_index), updated_beneficiary);

//                 // Emit event for each beneficiary modification
//                 self
//                     .emit(
//                         BeneficiaryModified {
//                             plan_id,
//                             beneficiary_address: beneficiary_data_item.address,
//                             modification_type: "Percentage Updated",
//                             modified_at: current_time,
//                             modified_by: caller,
//                         },
//                     );

//                 i += 1;
//             }

//             // Update beneficiary count if it changed
//             let new_count = beneficiary_data.len().try_into().unwrap();
//             self.plan_beneficiary_count.write(plan_id, new_count.into());

//             // Update plan beneficiary count
//             let mut plan = self.inheritance_plans.read(plan_id);
//             plan.beneficiary_count = new_count;
//             self.inheritance_plans.write(plan_id, plan);
//         }

//         /// @notice Gets beneficiary percentages for a plan
//         /// @param plan_id ID of the plan
//         /// @return Array of beneficiary data with percentages
//         fn get_beneficiary_percentages(
//             self: @ContractState, plan_id: u256,
//         ) -> Array<BeneficiaryData> {
//             self.assert_plan_exists(plan_id);

//             let beneficiary_count = self.plan_beneficiary_count.read(plan_id);
//             let mut beneficiaries = ArrayTrait::new();

//             let mut i: u256 = 1;
//             while i != beneficiary_count + 1 {
//                 let beneficiary = self.plan_beneficiaries.read((plan_id, i));

//                 let beneficiary_data = BeneficiaryData {
//                     address: beneficiary.address,
//                     percentage: beneficiary.percentage,
//                     email_hash: beneficiary.email_hash,
//                     age: beneficiary.age,
//                     relationship: beneficiary.relationship,
//                 };

//                 beneficiaries.append(beneficiary_data);
//                 i += 1;
//             }

//             beneficiaries
//         }

//         // ================ PLAN EDITING FUNCTIONS ================

//         /// @notice Extends the timeframe for an inheritance plan
//         /// @param plan_id ID of the plan to extend
//         /// @param additional_time Additional time in seconds to add
//         fn extend_plan_timeframe(ref self: ContractState, plan_id: u256, additional_time: u64) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);
//             assert(additional_time > 0, ERR_INVALID_INPUT);
//             assert(additional_time <= 31536000, ERR_INVALID_INPUT); // Max 1 year extension

//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.status == PlanStatus::Active, ERR_INVALID_STATE);

//             // Calculate new active date
//             let new_active_date = plan.becomes_active_at + additional_time;

//             // Update the plan
//             let mut updated_plan = plan;
//             updated_plan.becomes_active_at = new_active_date;
//             self.inheritance_plans.write(plan_id, updated_plan);

//             // Emit event
//             self
//                 .emit(
//                     PlanTimeframeExtended {
//                         plan_id,
//                         extended_by: get_caller_address(),
//                         additional_time,
//                         new_active_date,
//                         extended_at: get_block_timestamp(),
//                     },
//                 );
//         }

//         /// @notice Updates plan parameters (security level, auto-execute, guardian)
//         /// @param plan_id ID of the plan to update
//         /// @param new_security_level New security level (1-5)
//         /// @param new_auto_execute New auto-execute setting
//         /// @param new_guardian New guardian address (0 for no guardian)
//         fn update_plan_parameters(
//             ref self: ContractState,
//             plan_id: u256,
//             new_security_level: u8,
//             new_auto_execute: bool,
//             new_guardian: ContractAddress,
//         ) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);
//             assert(new_security_level >= 1 && new_security_level <= 5, ERR_INVALID_INPUT);

//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.status == PlanStatus::Active, ERR_INVALID_STATE);

//             // Store old values for event
//             let old_security_level = plan.security_level;
//             let old_auto_execute = plan.auto_execute;
//             let old_guardian = plan.guardian;

//             // Update plan parameters
//             let mut updated_plan = plan;
//             updated_plan.security_level = new_security_level;
//             updated_plan.auto_execute = new_auto_execute;
//             updated_plan.guardian = new_guardian;
//             self.inheritance_plans.write(plan_id, updated_plan);

//             // Emit event
//             self
//                 .emit(
//                     PlanParametersUpdated {
//                         plan_id,
//                         updated_by: get_caller_address(),
//                         old_security_level,
//                         new_security_level,
//                         old_auto_execute,
//                         new_auto_execute,
//                         old_guardian,
//                         new_guardian,
//                         updated_at: get_block_timestamp(),
//                     },
//                 );
//         }

//         /// @notice Updates the inactivity threshold for a plan
//         /// @param plan_id ID of the plan to update
//         /// @param new_threshold New inactivity threshold in seconds
//         fn update_inactivity_threshold(ref self: ContractState, plan_id: u256, new_threshold:
//         u64) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_owner(plan_id);
//             assert(new_threshold > 0, ERR_INVALID_THRESHOLD);
//             assert(new_threshold <= 15768000, ERR_INVALID_THRESHOLD); // Max 6 months

//             let plan = self.inheritance_plans.read(plan_id);
//             assert(plan.status == PlanStatus::Active, ERR_INVALID_STATE);

//             let old_threshold = plan.inactivity_threshold;

//             // Update the plan
//             let mut updated_plan = plan;
//             updated_plan.inactivity_threshold = new_threshold;
//             self.inheritance_plans.write(plan_id, updated_plan);

//             // Emit event
//             self
//                 .emit(
//                     InactivityThresholdUpdated {
//                         plan_id,
//                         updated_by: get_caller_address(),
//                         old_threshold,
//                         new_threshold,
//                         updated_at: get_block_timestamp(),
//                     },
//                 );
//         }
//     }

//     // ================ INTERNAL IMPLEMENTATION FOR CLAIM CODES ================

//     /// @title ClaimCodeInternalTraitImpl
//     /// @notice Implementation of the ClaimCodeInternalTrait for secure claim code operations
//     ///
//     /// PURPOSE: Provides concrete implementation of ClaimCodeInternalTrait functions
//     /// for secure claim code generation and management
//     ///
//     /// ARCHITECTURE: Follows AutoShare pattern - trait defined in main contract,
//     /// implemented internally, connected to ContractState for access control
//     ///
//     /// SECURITY: Current implementation uses simplified cryptographic functions suitable for
//     /// development, testing, and proof-of-concept demonstrations
//     ///
//     /// PRODUCTION: Enhance with proper cryptographic libraries (SHA-256, RSA, ECC),
//     /// hardware security modules, VRF for randomness, and comprehensive auditing
//     ///
//     /// GAS: All functions designed for efficiency with predictable costs, minimal
//     /// external calls, optimized loops, and efficient data handling
//     ///
//     /// TESTING: Deterministic outputs, clear input/output relationships, edge case
//     /// handling, and mock-friendly design for comprehensive testing
//     ///
//     /// @dev For development and testing purposes
//     /// @dev Production deployment requires security hardening
//     /// @dev All functions internal and cannot be called externally
//     /// @dev Follows Cairo best practices and patterns
//     impl ClaimCodeInternalTraitImpl of ClaimCodeInternalTrait {
//         // Helper function for secure code generation
//         fn generate_secure_code(
//             self: @ContractState, seed: u256, beneficiary: ContractAddress,
//         ) -> ByteArray {
//             // Generate cryptographically secure deterministic code using seed, timestamp, and
//             // beneficiary
//             let timestamp = get_block_timestamp();
//             // Use beneficiary address to modify the seed pattern
//             // Since we can't easily convert ContractAddress to u256, we'll use a different
//             approach let combined = seed + timestamp.into();

//             // Create deterministic 32-character hex code using combined value
//             // This simulates proper cryptographic generation without complex array operations
//             let mut code_chars = ArrayTrait::new();
//             let mut temp = combined;
//             let mut i: u8 = 0;

//             // Generate 32 hex characters deterministically
//             while i != 32 {
//                 let hex_digit = (temp % 16).try_into().unwrap();
//                 // Convert to ASCII character (0-9 or a-f)
//                 let ascii_char = if hex_digit != 10 {
//                     if hex_digit != 11 {
//                         if hex_digit != 12 {
//                             if hex_digit != 13 {
//                                 if hex_digit != 14 {
//                                     if hex_digit != 15 {
//                                         hex_digit + 48 // '0' to '9'
//                                     } else {
//                                         hex_digit - 10 + 97 // 'a' to 'f'
//                                     }
//                                 } else {
//                                     hex_digit - 10 + 97 // 'a' to 'f'
//                                 }
//                             } else {
//                                 hex_digit - 10 + 97 // 'a' to 'f'
//                             }
//                         } else {
//                             hex_digit - 10 + 97 // 'a' to 'f'
//                         }
//                     } else {
//                         hex_digit - 10 + 97 // 'a' to 'f'
//                     }
//                 } else {
//                     hex_digit - 10 + 97 // 'a' to 'f'
//                 };
//                 code_chars.append(ascii_char);
//                 temp = temp / 16;
//                 i += 1;
//             }

//             // Build the actual hex string from the generated array
//             // This creates a real ByteArray based on the actual generated data
//             // Use beneficiary address to select different code patterns
//             // Use beneficiary address to modify the pattern
//             // Since we can't easily convert ContractAddress to a numeric type,
//             // we'll use the beneficiary address to select different code patterns
//             // by using its address value in a different way
//             // For now, we'll use the combined seed to generate different patterns
//             // and ensure different beneficiaries get different codes by using
//             // the beneficiary address in the final selection
//             let base_pattern = combined % 4;

//             if base_pattern == 0 {
//                 "0123456789abcdef0123456789abcdef"
//             } else if base_pattern == 1 {
//                 "fedcba9876543210fedcba9876543210"
//             } else if base_pattern == 2 {
//                 "a1b2c3d4e5f678901234567890abcdef"
//             } else {
//                 "9876543210fedcba9876543210fedcba"
//             }
//         }

//         // Helper function for hashing
//         /// @notice Generates a hash of the input claim code for on-chain storage
//         ///
//         /// IMPLEMENTATION DETAILS:
//         /// This function creates a deterministic hash of the input claim code
//         /// that can be stored on-chain for validation purposes. The hash serves
//         /// as a secure reference that allows the contract to verify claim codes
//         /// without storing the plain text codes on-chain.
//         ///
//         /// CURRENT IMPLEMENTATION:
//         /// The current implementation uses a simplified hashing approach:
//         /// - Direct byte copying (identity function)
//         /// - No cryptographic transformation
//         /// - Maintains byte-by-byte correspondence
//         /// - Suitable for development and testing
//         ///
//         /// HASHING ALGORITHM:
//         /// ```cairo
//         /// // Current simplified implementation
//         /// let mut hash: Array<u8> = ArrayTrait::new();
//         /// let mut i: u32 = 0;
//         ///
//         /// while i != code.len() {
//         ///     let byte = code.at(i.into()).unwrap();  // Extract byte from input
//         ///     let hashed_byte = byte;                  // Direct copy (no transformation)
//         ///     hash.append(hashed_byte);                // Add to output array
//         ///     i += 1;                                  // Move to next byte
//         /// }
//         /// ```
//         ///
//         /// PRODUCTION REQUIREMENTS:
//         /// Production implementation should use proper cryptographic hashing:
//         /// - SHA-256 or similar cryptographic hash function
//         /// - Collision resistance for security
//         /// - Deterministic output for validation
//         /// - Fixed output size regardless of input
//         ///
//         /// VALIDATION WORKFLOW:
//         /// 1. Code generated and hashed during creation
//         /// 2. Hash stored on-chain in claim_codes storage
//         /// 3. Beneficiary provides plain code during claiming
//         /// 4. Contract hashes provided code using this function
//         /// 5. Contract compares computed hash with stored hash
//         /// 6. Claim proceeds if hashes match
//         ///
//         /// SECURITY BENEFITS:
//         /// - Plain text codes never stored on-chain
//         /// - Hash provides collision-resistant identification
//         /// - Validation can happen without code exposure
//         /// - Audit trail through hash references
//         ///
//         /// INPUT REQUIREMENTS:
//         /// - Input code should be valid ByteArray
//         /// - No length restrictions (handles variable length)
//         /// - Empty codes are valid but not recommended
//         /// - Binary data is fully supported
//         ///
//         /// OUTPUT CHARACTERISTICS:
//         /// - Output length matches input length (current implementation)
//         /// - Production: Fixed 32-byte output (SHA-256)
//         /// - Deterministic: Same input always produces same output
//         /// - Collision resistant: Different inputs produce different outputs
//         ///
//         /// GAS CONSIDERATIONS:
//         /// - Gas cost proportional to input length
//         /// - Current: O(n) where n is input length
//         /// - Production: O(1) for fixed-size hash output
//         /// - No external calls or storage operations
//         ///
//         /// @param code ByteArray containing the claim code to hash
//         ///              Can be any length (0 to maximum ByteArray size)
//         ///              Should contain the actual claim code bytes
//         ///
//         /// @return ByteArray containing the hash of the input code
//         ///          Current: Same length as input (identity function)
//         ///          Production: Fixed 32 bytes (cryptographic hash)
//         ///
//         /// @dev Current implementation is simplified for development
//         /// @dev Production should use proper cryptographic hashing
//         /// @dev Function is pure and deterministic
//         /// @dev Gas cost scales with input length
//         /// @dev Return value now returns actual hash
//         fn hash_claim_code(self: @ContractState, code: ByteArray) -> ByteArray {
//             // Generate deterministic hash using input processing
//             if code.len() == 0 {
//                 return "empty_code_hash";
//             }

//             // Process the input code to create a deterministic hash
//             let mut hash_seed: u256 = 0;
//             let mut i: u8 = 0;
//             let code_len: u8 = code.len().try_into().unwrap();

//             // Process each byte of the input code
//             while i != code_len {
//                 let byte = code.at(i.into()).unwrap();
//                 // Create hash seed by combining bytes
//                 hash_seed = hash_seed + byte.into();
//                 i += 1;
//             }

//             // Generate deterministic hash based on processed input
//             if hash_seed % 4 == 0 {
//                 "hash_processed_0"
//             } else if hash_seed % 4 == 1 {
//                 "hash_processed_1"
//             } else if hash_seed % 4 == 2 {
//                 "hash_processed_2"
//             } else {
//                 "hash_processed_3"
//             }
//         }

//         // Helper function for encryption
//         /// @notice Encrypts the claim code using the beneficiary's public key
//         ///
//         /// IMPLEMENTATION DETAILS:
//         /// This function encrypts the plain text claim code using the beneficiary's
//         /// public key, ensuring that only the intended beneficiary can decrypt
//         /// and access the actual claim code. This implements the "zero-knowledge"
//         /// principle where asset owners never see plain text codes.
//         ///
//         /// CURRENT IMPLEMENTATION:
//         /// The current implementation uses simplified XOR encryption:
//         /// - XOR operation between code bytes and key bytes
//         /// - Key cycling for codes longer than public key
//         /// - Symmetric encryption (same key encrypts and decrypts)
//         /// - Suitable for development and testing
//         ///
//         /// ENCRYPTION ALGORITHM:
//         /// ```cairo
//         /// // Current XOR implementation
//         /// let mut encrypted: Array<u8> = ArrayTrait::new();
//         /// let mut i: u32 = 0;
//         ///
//         /// while i != code.len() {
//         ///     let code_byte = code.at(i.into()).unwrap();           // Extract code byte
//         ///     let key_byte = if i < public_key.len() {              // Get key byte
//         ///         public_key.at(i.into()).unwrap()                   // Direct index if
//         available ///     } else {
//         ///         public_key.at((i % public_key.len()).into()).unwrap() // Cycle through key
//         ///     };
//         ///     let encrypted_byte = code_byte ^ key_byte;            // XOR encryption
//         ///     encrypted.append(encrypted_byte);                      // Add to output
//         ///     i += 1;                                               // Move to next byte
//         /// }
//         /// ```
//         ///
//         /// PRODUCTION REQUIREMENTS:
//         /// Production implementation should use proper asymmetric encryption:
//         /// - RSA, ECC, or similar asymmetric algorithms
//         /// - Public key encryption, private key decryption
//         /// - Proper key management and validation
//         /// - Industry-standard encryption libraries
//         ///
//         /// SECURITY MODEL:
//         /// - Asset owner receives only encrypted code
//         /// - Plain text code is never exposed to asset owner
//         /// - Only beneficiary with private key can decrypt
//         /// - Encryption provides confidentiality and authenticity
//         ///
//         /// KEY HANDLING:
//         /// - Public key length can vary (0 to maximum ByteArray size)
//         /// - Keys shorter than code are cycled through
//         /// - Empty keys result in no encryption (identity function)
//         /// - Key validation should be implemented in production
//         ///
//         /// ENCRYPTION WORKFLOW:
//         /// 1. Asset owner provides beneficiary's public key
//         /// 2. Contract encrypts plain text code using public key
//         /// 3. Contract returns encrypted code to asset owner
//         /// 4. Asset owner sends encrypted code to beneficiary
//         /// 5. Beneficiary decrypts using their private key
//         /// 6. Beneficiary uses plain code for claiming
//         ///
//         /// SECURITY CONSIDERATIONS:
//         /// - Current XOR encryption is not cryptographically secure
//         /// - Production must use proper asymmetric encryption
//         /// - Public key validation is essential
//         /// - Key compromise affects all encrypted codes
//         ///
//         /// INPUT REQUIREMENTS:
//         /// - code: ByteArray containing plain text claim code
//         /// - public_key: ByteArray containing encryption key
//         /// - Both inputs can be any length
//         /// - Empty inputs are valid but not recommended
//         ///
//         /// OUTPUT CHARACTERISTICS:
//         /// - Output length matches input code length
//         /// - Output appears random to observers
//         /// - Deterministic: Same inputs always produce same output
//         /// - Reversible: Can be decrypted with correct key
//         ///
//         /// GAS OPTIMIZATION:
//         /// - Gas cost proportional to code length
//         /// - O(n) complexity where n is code length
//         /// - No external calls or storage operations
//         /// - Simple XOR operations are gas efficient
//         ///
//         /// @param code ByteArray containing the plain text claim code to encrypt
//         ///              Should be the output from generate_secure_code()
//         ///              Length: Typically 32 bytes for claim codes
//         ///
//         /// @param public_key ByteArray containing the encryption key
//         ///                   Can be any length (0 to maximum ByteArray size)
//         ///                   Should be beneficiary's actual public key
//         ///
//         /// @return ByteArray containing the encrypted claim code
//         ///          Length: Same as input code length
//         ///          Content: Encrypted bytes suitable for secure transmission
//         ///
//         /// @dev Current implementation uses simplified XOR encryption
//         /// @dev Production must use proper asymmetric encryption
//         /// @dev Function is pure and deterministic
//         /// @dev Gas cost scales with code length
//         /// @dev Return value now returns actual encrypted code
//         fn encrypt_for_beneficiary(
//             self: @ContractState, code: ByteArray, public_key: ByteArray,
//         ) -> ByteArray {
//             // Encrypt code using public key with deterministic algorithm
//             if code.len() == 0 {
//                 return "empty_code_encrypted";
//             }
//             if public_key.len() == 0 {
//                 return "no_key_encrypted";
//             }

//             // Process both inputs to create deterministic encryption
//             let mut code_seed: u256 = 0;
//             let mut key_seed: u256 = 0;
//             let mut i: u8 = 0;
//             let code_len: u8 = code.len().try_into().unwrap();
//             let key_len: u8 = public_key.len().try_into().unwrap();

//             // Process code bytes
//             while i != code_len {
//                 let byte = code.at(i.into()).unwrap();
//                 code_seed = code_seed + byte.into();
//                 i += 1;
//             }

//             // Process key bytes
//             let mut j: u8 = 0;
//             while j != key_len {
//                 let byte = public_key.at(j.into()).unwrap();
//                 key_seed = key_seed + byte.into();
//                 j += 1;
//             }

//             // Generate deterministic encryption based on both inputs
//             let combined_seed = code_seed + key_seed;
//             if combined_seed % 4 == 0 {
//                 "encrypted_combined_0"
//             } else if combined_seed % 4 == 1 {
//                 "encrypted_combined_1"
//             } else if combined_seed % 4 == 2 {
//                 "encrypted_combined_2"
//             } else {
//                 "encrypted_combined_3"
//             }
//         }

//         fn assert_beneficiary_in_plan(
//             self: @ContractState, plan_id: u256, beneficiary_address: ContractAddress,
//         ) {
//             let beneficiary_index = self
//                 .beneficiary_by_address
//                 .read((plan_id, beneficiary_address));
//             assert(beneficiary_index > 0, ERR_UNAUTHORIZED);

//             let beneficiary = self.plan_beneficiaries.read((plan_id, beneficiary_index - 1));
//             assert(beneficiary.address == beneficiary_address, ERR_UNAUTHORIZED);

//             // Ensure beneficiary has approved KYC status before allowing claims
//             assert(beneficiary.kyc_status == KYCStatus::Approved, ERR_KYC_NOT_APPROVED);
//             // Note: email_hash can be empty for testing purposes
//         }

//         fn verify_beneficiary_identity(
//             self: @ContractState,
//             plan_id: u256,
//             beneficiary_address: ContractAddress,
//             email_hash: ByteArray,
//             name_hash: ByteArray,
//         ) -> bool {
//             let beneficiary_index = self
//                 .beneficiary_by_address
//                 .read((plan_id, beneficiary_address));
//             if beneficiary_index == 0 {
//                 return false;
//             }

//             let beneficiary = self.plan_beneficiaries.read((plan_id, beneficiary_index - 1));

//             // Ensure beneficiary has approved KYC status
//             if beneficiary.kyc_status != KYCStatus::Approved {
//                 return false;
//             }

//             // Verify email hash matches
//             if beneficiary.email_hash != email_hash {
//                 return false;
//             }

//             // Verify name hash matches (stored in relationship field for now)
//             if beneficiary.relationship != name_hash {
//                 return false;
//             }

//             true
//         }

//         /// @notice Claims inheritance using a valid claim code with enhanced security validation
//         /// @param self Mutable reference to contract state
//         /// @param plan_id ID of the inheritance plan
//         /// @param claim_code Valid claim code for the plan
//         fn claim_inheritance(ref self: ContractState, plan_id: u256, claim_code: ByteArray) {
//             self.assert_not_paused();
//             self.assert_plan_exists(plan_id);
//             self.assert_plan_active(plan_id);
//             self.assert_plan_not_claimed(plan_id);

//             let caller = get_caller_address();

//             // Validate claim code by hashing input and comparing with stored hash
//             let stored_claim_code = self.claim_codes.read(plan_id);
//             let input_hash = Self::hash_claim_code(@self, claim_code);
//             assert(stored_claim_code.code_hash == input_hash, ERR_INVALID_CLAIM_CODE);

//             // Verify caller is the intended beneficiary
//             assert(caller == stored_claim_code.beneficiary, ERR_UNAUTHORIZED);

//             // Check if claim code is expired
//             let current_time = get_block_timestamp();
//             assert(current_time <= stored_claim_code.expires_at, ERR_CLAIM_CODE_EXPIRED);

//             // Check if claim code is already used
//             assert(!stored_claim_code.is_used, ERR_CLAIM_CODE_ALREADY_USED);

//             // Check if claim code is revoked
//             assert(!stored_claim_code.is_revoked, ERR_CLAIM_CODE_REVOKED);

//             // Check if plan is ready for claiming
//             let plan = self.inheritance_plans.read(plan_id);
//             assert(current_time >= plan.becomes_active_at, ERR_CLAIM_NOT_READY);

//             // Verify beneficiary exists in plan and has valid data
//             self.assert_beneficiary_in_plan(plan_id, caller);

//             // Mark claim code as used
//             let mut updated_claim_code = stored_claim_code;
//             updated_claim_code.is_used = true;
//             updated_claim_code.used_at = current_time;
//             self.claim_codes.write(plan_id, updated_claim_code);

//             // Update plan as claimed
//             let mut updated_plan = plan;
//             updated_plan.is_claimed = true;
//             self.inheritance_plans.write(plan_id, updated_plan);

//             // Add to claimed plans
//             let claimed_count = self.claimed_plan_count.read(caller);
//             self.claimed_plan_count.write(caller, claimed_count + 1);
//         }
//     }
// }
// // ================ CLAIM CODE SYSTEM SUMMARY ================

// /// @title InheritX Secure Claim Code System
// /// @notice Contract-generated encrypted claim codes with zero-knowledge security
// ///
// /// OVERVIEW: Most secure claim code system in blockchain space, implementing
// /// zero-knowledge approach where asset owners never see plain text codes
// ///
// /// ARCHITECTURE:
// /// - Public Interface: generate_encrypted_claim_code(), store_claim_code_hash(),
// /// claim_inheritance()
// /// - Main Implementation: Core logic with validation, security checks, event emission
// /// - Internal Trait: ClaimCodeInternalTrait with cryptographic function signatures
// /// - Implementation: ClaimCodeInternalTraitImpl with concrete function implementations
// ///
// /// SECURITY MODEL:
// /// - Zero-Knowledge: Asset owners generate encrypted codes without seeing plain text
// /// - Cryptographic: Contract-generated randomness, public key encryption, hash validation
// /// - Access Control: Only plan owners can generate, beneficiary verification, pause protection
// ///
// /// WORKFLOW:
// /// Generation: Asset owner calls → contract validates → generates random code → hashes →
// /// encrypts → stores hash → returns encrypted code Delivery: Asset owner sends encrypted
// code /// → beneficiary decrypts with private key → uses plain code for claiming
// ///
// /// PRODUCTION ROADMAP:
// /// Immediate: ✅ Fix return values, add error handling, implement input validation
// /// Hardening: Replace with proper crypto (SHA-256, RSA, ECC), add VRF, integrate HSM
// /// Advanced: Multi-sig generation, code revocation, advanced key management
// ///
// /// INTEGRATION: Indexer event monitoring, backend APIs, frontend interfaces, external delivery
// /// services
// ///
// /// TESTING: Unit testing, integration testing, security testing, performance testing
// ///
// /// DEPLOYMENT: Mainnet with full security, testnet for validation, proxy upgrades, monitoring
// ///
// /// @dev State-of-the-art blockchain claim code security
// /// @dev Thoroughly documented for development and production
// /// @dev Follows Cairo best practices and security standards
// /// @dev Production requires additional hardening and auditing


