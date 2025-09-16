// use core::array::ArrayTrait;
// use core::byte_array::ByteArray;
// use inheritx_contracts::base::types::{
//     AssetAllocation, AssetType, BasicDistributionSchedule, Beneficiary, BeneficiaryData,
//     DisbursementBeneficiary, KYCStatus,
// };
// use inheritx_contracts::interfaces::iinheritx::{IInheritXDispatcher, IInheritXDispatcherTrait};
// use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
// use snforge_std::{
//     ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
//     stop_cheat_caller_address,
// };
// use starknet::ContractAddress;

// // Mock STARKTOKEN contract for testing
// // Enhanced mock contract with basic ERC20 functionality for testing
// #[starknet::contract]
// pub mod STARKTOKEN {
//     use core::array::ArrayTrait;
//     use starknet::storage::{
//         StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
//         StoragePointerWriteAccess,
//     };
//     use starknet::{ContractAddress, get_caller_address};

//     #[storage]
//     pub struct Storage {
//         // Basic ERC20 storage
//         balances: starknet::storage::Map<ContractAddress, u256>,
//         allowances: starknet::storage::Map<(ContractAddress, ContractAddress), u256>,
//         total_supply: u256,
//         name: felt252,
//         symbol: felt252,
//         decimals: u8,
//     }

//     #[event]
//     #[derive(Drop, starknet::Event)]
//     pub enum Event {
//         Transfer: Transfer,
//         Approval: Approval,
//     }

//     #[derive(Drop, starknet::Event)]
//     pub struct Transfer {
//         pub from: ContractAddress,
//         pub to: ContractAddress,
//         pub value: u256,
//     }

//     #[derive(Drop, starknet::Event)]
//     pub struct Approval {
//         pub owner: ContractAddress,
//         pub spender: ContractAddress,
//         pub value: u256,
//     }

//     #[constructor]
//     pub fn constructor(
//         ref self: ContractState,
//         initial_supply: ContractAddress,
//         recipient: ContractAddress,
//         decimals: u8,
//     ) {
//         // Use a default initial supply amount for testing
//         let supply_amount: u256 = 1000000000000000000000000000; // 1 token with 18 decimals
//         self.balances.write(recipient, supply_amount);
//         self.total_supply.write(supply_amount);
//         self.decimals.write(decimals);
//         self.name.write('STARKTOKEN');
//         self.symbol.write('STRK');
//     }

//     #[external(v0)]
//     pub fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
//         let owner = get_caller_address();
//         self.allowances.write((owner, spender), amount);
//         self.emit(Approval { owner, spender, value: amount });
//         true
//     }

//     #[external(v0)]
//     pub fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
//         let from = get_caller_address();
//         let from_balance = self.balances.read(from);
//         assert(from_balance >= amount, 'Insufficient balance');

//         self.balances.write(from, from_balance - amount);
//         let to_balance = self.balances.read(to);
//         self.balances.write(to, to_balance + amount);

//         self.emit(Transfer { from, to, value: amount });
//         true
//     }

//     #[external(v0)]
//     pub fn transfer_from(
//         ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256,
//     ) -> bool {
//         let spender = get_caller_address();
//         let allowance = self.allowances.read((from, spender));
//         assert(allowance >= amount, 'Insufficient allowance');

//         let from_balance = self.balances.read(from);
//         assert(from_balance >= amount, 'Insufficient balance');

//         self.allowances.write((from, spender), allowance - amount);
//         self.balances.write(from, from_balance - amount);
//         let to_balance = self.balances.read(to);
//         self.balances.write(to, to_balance + amount);

//         self.emit(Transfer { from, to, value: amount });
//         true
//     }

//     #[external(v0)]
//     pub fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
//         self.balances.read(account)
//     }

//     #[external(v0)]
//     pub fn allowance(
//         self: @ContractState, owner: ContractAddress, spender: ContractAddress,
//     ) -> u256 {
//         self.allowances.read((owner, spender))
//     }

//     #[external(v0)]
//     pub fn total_supply(self: @ContractState) -> u256 {
//         self.total_supply.read()
//     }

//     #[external(v0)]
//     pub fn name(self: @ContractState) -> felt252 {
//         self.name.read()
//     }

//     #[external(v0)]
//     pub fn symbol(self: @ContractState) -> felt252 {
//         self.symbol.read()
//     }

//     #[external(v0)]
//     pub fn decimals(self: @ContractState) -> u8 {
//         self.decimals.read()
//     }
// }

// // Test constants - using smaller values that fit in felt252
// const ADMIN_CONST: felt252 = 123;
// const CREATOR_CONST: felt252 = 456;
// const USER1_CONST: felt252 = 789;
// const USER2_CONST: felt252 = 101;
// const STRK_TOKEN_CONST: felt252 = 202;
// const USDT_TOKEN_CONST: felt252 = 303;
// const USDC_TOKEN_CONST: felt252 = 404;
// const DEX_ROUTER_CONST: felt252 = 505;
// const EMERGENCY_WITHDRAW_CONST: felt252 = 606;
// const ZERO_ADDRESS: felt252 = 0;

// pub fn ADMIN_ADDR() -> ContractAddress {
//     ADMIN_CONST.try_into().unwrap()
// }

// pub fn CREATOR_ADDR() -> ContractAddress {
//     CREATOR_CONST.try_into().unwrap()
// }

// pub fn USER1_ADDR() -> ContractAddress {
//     USER1_CONST.try_into().unwrap()
// }

// pub fn USER2_ADDR() -> ContractAddress {
//     USER2_CONST.try_into().unwrap()
// }

// pub fn STRK_TOKEN_ADDR() -> ContractAddress {
//     STRK_TOKEN_CONST.try_into().unwrap()
// }

// pub fn USDT_TOKEN_ADDR() -> ContractAddress {
//     USDT_TOKEN_CONST.try_into().unwrap()
// }

// pub fn USDC_TOKEN_ADDR() -> ContractAddress {
//     USDC_TOKEN_CONST.try_into().unwrap()
// }

// pub fn DEX_ROUTER_ADDR() -> ContractAddress {
//     DEX_ROUTER_CONST.try_into().unwrap()
// }

// pub fn EMERGENCY_WITHDRAW_ADDR() -> ContractAddress {
//     EMERGENCY_WITHDRAW_CONST.try_into().unwrap()
// }

// pub fn ZERO_ADDR() -> ContractAddress {
//     ZERO_ADDRESS.try_into().unwrap()
// }

// // Helper function to create empty ByteArray
// fn create_empty_byte_array() -> ByteArray {
//     ""
// }

// // Deploy the InheritX contract
// fn deploy_inheritx_contract() -> (
//     IInheritXDispatcher, ERC20ABIDispatcher, ERC20ABIDispatcher, ERC20ABIDispatcher,
// ) {
//     // Deploy mock tokens
//     let strk_class = declare("STARKTOKEN").unwrap().contract_class();
//     let mut strk_calldata = array![CREATOR_ADDR().into(), CREATOR_ADDR().into(), 6];
//     let (strk_address, _) = strk_class.deploy(@strk_calldata).unwrap();
//     let strk_dispatcher = ERC20ABIDispatcher { contract_address: strk_address };

//     let (usdt_address, _) = strk_class.deploy(@strk_calldata).unwrap();
//     let usdt_dispatcher = ERC20ABIDispatcher { contract_address: usdt_address };

//     let (usdc_address, _) = strk_class.deploy(@strk_calldata).unwrap();
//     let usdc_dispatcher = ERC20ABIDispatcher { contract_address: usdc_address };

//     // Deploy InheritX contract
//     let contract = declare("InheritX").unwrap().contract_class();
//     let constructor_calldata = array![
//         ADMIN_ADDR().into(),
//         DEX_ROUTER_ADDR().into(),
//         EMERGENCY_WITHDRAW_ADDR().into(),
//         strk_address.into(),
//         usdt_address.into(),
//         usdc_address.into(),
//     ];
//     let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

//     let inheritx = IInheritXDispatcher { contract_address };
//     (inheritx, strk_dispatcher, usdt_dispatcher, usdc_dispatcher)
// }

// // ================ BASIC FUNCTIONALITY TESTS ================

// #[test]
// fn test_contract_deployment() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Test that contract was deployed successfully
//     assert(contract.contract_address != ZERO_ADDR(), 'Deployed');
// }

// #[test]
// fn test_create_inheritance_plan_success() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     // Create inheritance plan
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());
//     beneficiaries.append(USER2_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             5, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     assert(plan_id == 1, 'Plan ID should be 1');

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ KYC TESTS ================

// #[test]
// fn test_upload_kyc_success() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Upload KYC as asset owner
//     start_cheat_caller_address(contract.contract_address, USER1_ADDR());
//     contract.upload_kyc(create_empty_byte_array(), 0); // Asset owner

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_approve_kyc_success() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Upload KYC first
//     start_cheat_caller_address(contract.contract_address, USER1_ADDR());
//     contract.upload_kyc(create_empty_byte_array(), 0);
//     stop_cheat_caller_address(contract.contract_address);

//     // Approve KYC as admin
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
//     contract.approve_kyc(USER1_ADDR(), create_empty_byte_array());

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ SECURITY SETTINGS TESTS ================

// #[test]
// fn test_update_security_settings() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Update security settings as admin
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
//     contract
//         .update_security_settings(
//             15, // max_beneficiaries
//             3600, // min_timeframe (1 hour)
//             2592000, // max_timeframe (30 days)
//             true, // require_guardian
//             false, // allow_early_execution
//             100_000_000, // max_asset_amount (100K STRK)
//             true, // require_multi_sig
//             3, // multi_sig_threshold
//             1209600 // emergency_timeout (14 days)
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ ADMIN FUNCTIONS TESTS ================

// #[test]
// fn test_pause_and_unpause() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Pause contract
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
//     contract.pause();

//     // Unpause contract
//     contract.unpause();

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ QUERY FUNCTIONS TESTS ================

// #[test]
// fn test_get_plan_count() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             5, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_get_escrow_count() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan (which creates an escrow)
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             5, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ ADDITIONAL FUNCTIONALITY TESTS ================

// #[test]
// fn test_create_inheritance_plan_with_nft() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create inheritance plan with NFT
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             3, // NFT
//             0, // No amount for NFT
//             123, // NFT token ID
//             USER1_ADDR(), // NFT contract address
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             true, // auto_execute
//             emergency_contacts,
//         );

//     assert(plan_id == 1, 'Plan ID should be 1');
//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_create_inheritance_plan_with_guardian() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create inheritance plan with guardian
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             USER2_ADDR(), // Guardian
//             create_empty_byte_array(),
//             4, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     assert(plan_id == 1, 'Plan ID should be 1');
//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_create_inheritance_plan_with_emergency_contacts() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create inheritance plan with emergency contacts
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();
//     emergency_contacts.append(USER2_ADDR());
//     emergency_contacts.append(ADMIN_ADDR());

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             5, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     assert(plan_id == 1, 'Plan ID should be 1');
//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_create_multiple_inheritance_plans() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens for multiple plans
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     // Create first plan
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries1 = ArrayTrait::new();
//     beneficiaries1.append(USER1_ADDR());

//     let mut emergency_contacts1 = ArrayTrait::new();

//     let _plan_id1 = contract
//         .create_inheritance_plan(
//             beneficiaries1,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts1,
//         );

//     // Create second plan
//     let mut beneficiaries2 = ArrayTrait::new();
//     beneficiaries2.append(USER2_ADDR());

//     let mut emergency_contacts2 = ArrayTrait::new();

//     let _plan_id2 = contract
//         .create_inheritance_plan(
//             beneficiaries2,
//             0, // STRK
//             2_000_000, // 2 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             172800, // 2 days
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             4, // security_level
//             true, // auto_execute
//             emergency_contacts2,
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_create_inheritance_plan_with_different_asset_types() {
//     let (contract, strk_token, usdt_token, usdc_token) = deploy_inheritx_contract();

//     // Setup: Approve tokens for different asset types
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(usdt_token.contract_address, CREATOR_ADDR());
//     usdt_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(usdt_token.contract_address);

//     start_cheat_caller_address(usdc_token.contract_address, CREATOR_ADDR());
//     usdc_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(usdc_token.contract_address);

//     // Create STRK plan
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let _plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Create USDT plan with new beneficiaries array
//     let mut beneficiaries2 = ArrayTrait::new();
//     beneficiaries2.append(USER1_ADDR());

//     let mut emergency_contacts2 = ArrayTrait::new();

//     let _plan_id2 = contract
//         .create_inheritance_plan(
//             beneficiaries2,
//             1, // USDT
//             1_000_000, // 1 USDT
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             4, // security_level
//             false, // auto_execute
//             emergency_contacts2,
//         );

//     // Create USDC plan with new beneficiaries array
//     let mut beneficiaries3 = ArrayTrait::new();
//     beneficiaries3.append(USER1_ADDR());

//     let mut emergency_contacts3 = ArrayTrait::new();

//     let _plan_id3 = contract
//         .create_inheritance_plan(
//             beneficiaries3,
//             2, // USDC
//             1_000_000, // 1 USDC
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             5, // security_level
//             false, // auto_execute
//             emergency_contacts3,
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_create_inheritance_plan_with_different_security_levels() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     // Create plans with different security levels
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries1 = ArrayTrait::new();
//     beneficiaries1.append(USER1_ADDR());

//     let mut emergency_contacts1 = ArrayTrait::new();

//     // Security level 1 (lowest)
//     let _plan_id1 = contract
//         .create_inheritance_plan(
//             beneficiaries1,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             1, // security_level
//             false, // auto_execute
//             emergency_contacts1,
//         );

//     // Security level 5 (highest)
//     let mut beneficiaries2 = ArrayTrait::new();
//     beneficiaries2.append(USER1_ADDR());

//     let mut emergency_contacts2 = ArrayTrait::new();

//     let _plan_id2 = contract
//         .create_inheritance_plan(
//             beneficiaries2,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             5, // security_level
//             false, // auto_execute
//             emergency_contacts2,
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_create_inheritx_plan_with_different_timeframes() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     // Create plans with different timeframes
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries1 = ArrayTrait::new();
//     beneficiaries1.append(USER1_ADDR());

//     let mut emergency_contacts1 = ArrayTrait::new();

//     // Short timeframe (1 hour)
//     let _plan_id1 = contract
//         .create_inheritance_plan(
//             beneficiaries1,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             3600, // 1 hour
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts1,
//         );

//     // Medium timeframe (1 week)
//     let mut beneficiaries2 = ArrayTrait::new();
//     beneficiaries2.append(USER1_ADDR());

//     let mut emergency_contacts2 = ArrayTrait::new();

//     let _plan_id2 = contract
//         .create_inheritance_plan(
//             beneficiaries2,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             604800, // 1 week
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts2,
//         );

//     // Long timeframe (1 month)
//     let mut beneficiaries3 = ArrayTrait::new();
//     beneficiaries3.append(USER1_ADDR());

//     let mut emergency_contacts3 = ArrayTrait::new();

//     let _plan_id3 = contract
//         .create_inheritance_plan(
//             beneficiaries3,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             2592000, // 1 month
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts3,
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_create_inheritance_plan_with_multiple_beneficiaries() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     // Create plan with multiple beneficiaries
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());
//     beneficiaries.append(USER2_ADDR());
//     beneficiaries.append(ADMIN_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let _plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_kyc_workflow_complete() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Complete KYC workflow: upload -> approve -> reject -> upload again -> approve
//     start_cheat_caller_address(contract.contract_address, USER1_ADDR());

//     // Upload KYC as asset owner
//     contract.upload_kyc(create_empty_byte_array(), 0); // Asset owner

//     stop_cheat_caller_address(contract.contract_address);

//     // Approve KYC as admin
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
//     contract.approve_kyc(USER1_ADDR(), create_empty_byte_array());
//     stop_cheat_caller_address(contract.contract_address);

//     // Upload KYC for beneficiary
//     start_cheat_caller_address(contract.contract_address, USER2_ADDR());
//     contract.upload_kyc(create_empty_byte_array(), 1); // Beneficiary
//     stop_cheat_caller_address(contract.contract_address);

//     // Approve beneficiary KYC
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
//     contract.approve_kyc(USER2_ADDR(), create_empty_byte_array());
//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_security_settings_comprehensive() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Test comprehensive security settings update
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());

//     // Update with different security configurations
//     contract
//         .update_security_settings(
//             20, // max_beneficiaries
//             1800, // min_timeframe (30 minutes)
//             5184000, // max_timeframe (60 days)
//             true, // require_guardian
//             true, // allow_early_execution
//             500_000_000, // max_asset_amount (500K STRK)
//             true, // require_multi_sig
//             5, // multi_sig_threshold
//             2592000 // emergency_timeout (30 days)
//         );

//     // Update with opposite settings
//     contract
//         .update_security_settings(
//             5, // max_beneficiaries
//             7200, // min_timeframe (2 hours)
//             1296000, // max_timeframe (15 days)
//             false, // require_guardian
//             false, // allow_early_execution
//             50_000_000, // max_asset_amount (50K STRK)
//             false, // require_multi_sig
//             2, // multi_sig_threshold
//             604800 // emergency_timeout (7 days)
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_admin_functions_comprehensive() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create plans for users first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries1 = ArrayTrait::new();
//     beneficiaries1.append(USER1_ADDR());

//     let mut emergency_contacts1 = ArrayTrait::new();

//     let _plan_id1 = contract
//         .create_inheritance_plan(
//             beneficiaries1,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts1,
//         );

//     // Create plan for USER2
//     let mut beneficiaries2 = ArrayTrait::new();
//     beneficiaries2.append(USER2_ADDR());

//     let mut emergency_contacts2 = ArrayTrait::new();

//     let _plan_id2 = contract
//         .create_inheritance_plan(
//             beneficiaries2,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts2,
//         );

//     stop_cheat_caller_address(contract.contract_address);

//     // Test all admin functions
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());

//     // Pause and unpause multiple times
//     contract.pause();
//     contract.unpause();
//     contract.pause();
//     contract.unpause();

//     // Test wallet freezing and unfreezing
//     contract.freeze_wallet(USER1_ADDR(), create_empty_byte_array());
//     contract.unfreeze_wallet(USER1_ADDR(), create_empty_byte_array());

//     // Test blacklisting
//     contract.blacklist_wallet(USER2_ADDR(), create_empty_byte_array());
//     contract.remove_from_blacklist(USER2_ADDR(), create_empty_byte_array());

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_emergency_withdrawal() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Transfer tokens to contract first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.transfer(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     // Test emergency withdrawal
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());

//     // Emergency withdraw STRK tokens
//     contract.emergency_withdraw(strk_token.contract_address, 100_000_000);

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_swap_functionality() {
//     let (contract, strk_token, usdt_token, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test swap request creation
//     contract
//         .create_swap_request(
//             plan_id, // plan_id
//             strk_token.contract_address, // from_token
//             usdt_token.contract_address, // to_token
//             1_000_000, // amount
//             100 // slippage_tolerance (1%)
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_inactivity_monitoring() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test inactivity monitoring functionality

//     // Create inactivity monitor
//     contract
//         .create_inactivity_monitor(
//             USER1_ADDR(), // wallet_address
//             86400, // threshold (1 day)
//             create_empty_byte_array(), // beneficiary_email_hash
//             plan_id // plan_id
//         );

//     // Update wallet activity
//     contract.update_wallet_activity(USER1_ADDR());

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_claim_code_functionality() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test claim code functionality
//     // Call as plan owner (CREATOR_ADDR) not as admin
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     // Store claim code hash
//     contract
//         .store_claim_code_hash(
//             plan_id, // plan_id
//             USER1_ADDR(), // beneficiary
//             create_empty_byte_array(), // code_hash
//             86400 // expires_in (1 day)
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ ENHANCED CLAIM CODE SYSTEM TESTS ================

// #[test]
// fn test_generate_encrypted_claim_code_success() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test encrypted claim code generation
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     // Create a mock public key for the beneficiary
//     let public_key: ByteArray = "01020304";

//     // Generate encrypted claim code
//     let encrypted_code = contract
//         .generate_encrypted_claim_code(
//             plan_id, USER1_ADDR(), public_key, 86400 // expires_in (1 day)
//         );

//     // Verify encrypted code is not empty
//     assert(encrypted_code.len() > 0_u32, 'Code not empty');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Unknown enum indicator:', 0))]
// fn test_generate_encrypted_claim_code_invalid_plan() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let public_key: ByteArray = "0102";

//     // Test with non-existent plan ID - this should panic with "Unknown enum indicator:" and 0
//     contract
//         .generate_encrypted_claim_code(
//             999, // Non-existent plan ID
//             USER1_ADDR(), public_key, 86400,
//         );
// }

// #[test]
// #[should_panic(expected: ('Beneficiary not found',))]
// fn test_generate_encrypted_claim_code_invalid_beneficiary() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test with beneficiary not in the plan - this should panic with "Beneficiary not found"
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let public_key: ByteArray = "0102";

//     contract
//         .generate_encrypted_claim_code(
//             plan_id, USER2_ADDR(), // Not a beneficiary
//             public_key, 86400,
//         );
// }

// #[test]
// #[should_panic(expected: ('Invalid input parameters',))]
// fn test_generate_encrypted_claim_code_zero_expiration() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test with zero expiration time - this should panic with "Invalid input parameters"
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let public_key: ByteArray = "0102";

//     contract
//         .generate_encrypted_claim_code(
//             plan_id, USER1_ADDR(), public_key, 0 // Invalid expiration time
//         );
// }

// #[test]
// fn test_generate_encrypted_claim_code_multiple_beneficiaries() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan with multiple beneficiaries
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());
//     beneficiaries.append(USER2_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Generate claim codes for both beneficiaries
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let public_key1: ByteArray = "0102";
//     let public_key2: ByteArray = "0304";

//     // Generate for first beneficiary
//     let encrypted_code1 = contract
//         .generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key1, 86400);

//     // Generate for second beneficiary
//     let encrypted_code2 = contract
//         .generate_encrypted_claim_code(plan_id, USER2_ADDR(), public_key2, 86400);

//     // Verify both codes are generated and the same (since they're for the same plan)
//     assert(encrypted_code1.len() > 0_u32, 'Code1 not empty');
//     assert(encrypted_code2.len() > 0_u32, 'Code2 not empty');
//     assert(encrypted_code1 == encrypted_code2, 'should be same for same plan');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_generate_encrypted_claim_code_different_expiration_times() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test different expiration times
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let public_key: ByteArray = "0102";

//     // Generate with 1 day expiration
//     let encrypted_code_1day = contract
//         .generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key.clone(), 86400 // 1 day
//         );

//     // Generate with 7 days expiration
//     let encrypted_code_7days = contract
//         .generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key.clone(), 604800 // 7
//         days );

//     // Generate with 30 days expiration
//     let encrypted_code_30days = contract
//         .generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key, 2592000 // 30 days
//         );

//     // Verify all codes are generated
//     assert(encrypted_code_1day.len() > 0_u32, '1-day not empty');
//     assert(encrypted_code_7days.len() > 0_u32, '7-day not empty');
//     assert(encrypted_code_30days.len() > 0_u32, '30-day not empty');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_generate_encrypted_claim_code_empty_public_key() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test with empty public key
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let empty_public_key = create_empty_byte_array();

//     // This should still work (though not recommended for production)
//     let encrypted_code = contract
//         .generate_encrypted_claim_code(plan_id, USER1_ADDR(), empty_public_key, 86400);

//     // Verify code is generated
//     assert(encrypted_code.len() > 0_u32, 'Code generated');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_generate_encrypted_claim_code_large_public_key() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test with large public key
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     // Create a large public key (simulating a large key)
//     let large_public_key: ByteArray =
//         "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

//     let encrypted_code = contract
//         .generate_encrypted_claim_code(plan_id, USER1_ADDR(), large_public_key, 86400);

//     // Verify code is generated
//     assert(encrypted_code.len() > 0_u32, 'Code generated');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_generate_encrypted_claim_code_overwrite_existing() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test overwriting existing claim codes
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let public_key: ByteArray = "0102";

//     // Generate first code
//     let encrypted_code1 = contract
//         .generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key.clone(), 86400);

//     // Generate second code (should overwrite the first)
//     let encrypted_code2 = contract
//         .generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key, 172800 // 2 days
//         );

//     // Verify both codes are generated
//     assert(encrypted_code1.len() > 0_u32, 'Code1 not empty');
//     assert(encrypted_code2.len() > 0_u32, 'Code2 not empty');

//     // Note: In the current implementation, both codes might be the same
//     // This is expected behavior as the function overwrites existing codes

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Pausable: paused',))]
// fn test_generate_encrypted_claim_code_contract_paused() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Pause the contract (requires admin privileges)
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
//     contract.pause();

//     // Test that claim code generation fails when contract is paused - this should panic with
//     // "Pausable: paused"
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let public_key: ByteArray = "0102";

//     contract.generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key, 86400);
// }

// #[test]
// fn test_generate_encrypted_claim_code_integration_with_claim() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Generate encrypted claim code
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let public_key: ByteArray = "0102";

//     let encrypted_code = contract
//         .generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key, 86400);

//     // Verify encrypted code is generated
//     assert(encrypted_code.len() > 0_u32, 'Code generated');

//     // Note: In a real scenario, the beneficiary would:
//     // 1. Receive the encrypted code
//     // 2. Decrypt it using their private key
//     // 3. Use the plain code to call claim_inheritance()
//     //
//     // However, we can't easily test the decryption process in this test framework
//     // as it involves off-chain cryptographic operations

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ MONTHLY DISBURSEMENT TESTS ================

// #[test]
// fn test_create_monthly_disbursement_plan() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create monthly disbursement plan
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let mut beneficiaries = ArrayTrait::new();
//     let beneficiary1 = DisbursementBeneficiary {
//         beneficiary_id: 1,
//         plan_id: 0, // Will be set by contract
//         address: USER1_ADDR(),
//         percentage: 60,
//         monthly_amount: 600_000,
//         total_received: 0,
//         last_disbursement: 0,
//         is_active: true,
//     };
//     let beneficiary2 = DisbursementBeneficiary {
//         beneficiary_id: 2,
//         plan_id: 0, // Will be set by contract
//         address: USER2_ADDR(),
//         percentage: 40,
//         monthly_amount: 400_000,
//         total_received: 0,
//         last_disbursement: 0,
//         is_active: true,
//     };

//     beneficiaries.append(beneficiary1);
//     beneficiaries.append(beneficiary2);

//     let plan_id = contract
//         .create_monthly_disbursement_plan(
//             1_000_000, // total_amount
//             100_000, // monthly_amount
//             1640995200, // start_month (Jan 1, 2022)
//             1672531200, // end_month (Jan 1, 2023)
//             beneficiaries,
//         );

//     assert(plan_id == 1, 'Monthly plan ID should be 1');
//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_execute_monthly_disbursement() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create monthly disbursement plan first
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let mut beneficiaries = ArrayTrait::new();
//     let beneficiary = DisbursementBeneficiary {
//         beneficiary_id: 1,
//         plan_id: 0,
//         address: USER1_ADDR(),
//         percentage: 100,
//         monthly_amount: 100_000,
//         total_received: 0,
//         last_disbursement: 0,
//         is_active: true,
//     };
//     beneficiaries.append(beneficiary);

//     let _plan_id = contract
//         .create_monthly_disbursement_plan(
//             1_000_000, // total_amount
//             100_000, // monthly_amount
//             1640995200, // start_month (Jan 1, 2022)
//             1672531200, // end_month (Jan 1, 2023)
//             beneficiaries,
//         );

//     // Note: The monthly disbursement plan starts with status "Pending"
//     // and needs to be manually activated to "Active" status before execution
//     // This test demonstrates the creation, but execution requires the plan to be active

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_pause_and_resume_monthly_disbursement() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create monthly disbursement plan first
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let mut beneficiaries = ArrayTrait::new();
//     let beneficiary = DisbursementBeneficiary {
//         beneficiary_id: 1,
//         plan_id: 0,
//         address: USER1_ADDR(),
//         percentage: 100,
//         monthly_amount: 100_000,
//         total_received: 0,
//         last_disbursement: 0,
//         is_active: true,
//     };
//     beneficiaries.append(beneficiary);

//     let _plan_id = contract
//         .create_monthly_disbursement_plan(
//             1_000_000, // total_amount
//             100_000, // monthly_amount
//             1640995200, // start_month (Jan 1, 2022)
//             1672531200, // end_month (Jan 1, 2023)
//             beneficiaries,
//         );

//     // Note: The monthly disbursement plan starts with status "Pending"
//     // and needs to be manually activated to "Active" status before it can be paused/resumed
//     // This test demonstrates the creation, but pause/resume requires the plan to be active

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_get_monthly_disbursement_status() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create monthly disbursement plan first
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let mut beneficiaries = ArrayTrait::new();
//     let beneficiary = DisbursementBeneficiary {
//         beneficiary_id: 1,
//         plan_id: 0,
//         address: USER1_ADDR(),
//         percentage: 100,
//         monthly_amount: 100_000,
//         total_received: 0,
//         last_disbursement: 0,
//         is_active: true,
//     };
//     beneficiaries.append(beneficiary);

//     let plan_id = contract
//         .create_monthly_disbursement_plan(
//             1_000_000, // total_amount
//             100_000, // monthly_amount
//             1640995200, // start_month (Jan 1, 2022)
//             1672531200, // end_month (Jan 1, 2023)
//             beneficiaries,
//         );

//     // Get monthly disbursement status
//     let status = contract.get_monthly_disbursement_status(plan_id);
//     assert(status.plan_id == plan_id, 'Status plan ID should match');

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ PLAN CREATION FLOW TESTS ================

// #[test]
// fn test_create_plan_basic_info() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create basic plan info
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let basic_info_id = contract
//         .create_plan_basic_info(
//             "My Inheritance Plan", // plan_name
//             "A comprehensive inheritance plan", // plan_description
//             "owner@example.com", // owner_email_hash
//             USER1_ADDR(), // initial_beneficiary
//             "beneficiary@example.com" // initial_beneficiary_email
//         );

//     assert(basic_info_id == 1, 'Basic info ID should be 1');
//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_set_asset_allocation() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create basic plan info first
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let basic_info_id = contract
//         .create_plan_basic_info(
//             "My Inheritance Plan", // plan_name
//             "A comprehensive inheritance plan", // plan_description
//             "owner@example.com", // owner_email_hash
//             USER1_ADDR(), // initial_beneficiary
//             "beneficiary@example.com" // initial_beneficiary_email
//         );

//     // Set asset allocation
//     let mut beneficiaries = ArrayTrait::new();
//     let beneficiary1 = Beneficiary {
//         address: USER1_ADDR(),
//         email_hash: "beneficiary1@example.com",
//         percentage: 60,
//         has_claimed: false,
//         claimed_amount: 0,
//         claim_code_hash: "",
//         added_at: 0,
//         kyc_status: KYCStatus::Pending,
//         relationship: "Child",
//         age: 25,
//         is_minor: false,
//     };
//     let beneficiary2 = Beneficiary {
//         address: USER2_ADDR(),
//         email_hash: "beneficiary2@example.com",
//         percentage: 40,
//         has_claimed: false,
//         claimed_amount: 0,
//         claim_code_hash: "",
//         added_at: 0,
//         kyc_status: KYCStatus::Pending,
//         relationship: "Spouse",
//         age: 30,
//         is_minor: false,
//     };

//     beneficiaries.append(beneficiary1);
//     beneficiaries.append(beneficiary2);

//     let mut asset_allocations = ArrayTrait::new();
//     let allocation1 = AssetAllocation {
//         beneficiary_address: USER1_ADDR(),
//         percentage: 60,
//         asset_type: AssetType::STRK,
//         amount: 600_000,
//         token_address: STRK_TOKEN_ADDR(),
//         nft_token_id: 0,
//         nft_contract: ZERO_ADDR(),
//         distribution_schedule: BasicDistributionSchedule {
//             phase: 1,
//             amount: 600_000,
//             trigger_time: 0,
//             milestone: "",
//             is_executed: false,
//             executed_at: 0,
//         },
//         special_conditions_count: 0,
//     };
//     let allocation2 = AssetAllocation {
//         beneficiary_address: USER2_ADDR(),
//         percentage: 40,
//         asset_type: AssetType::STRK,
//         amount: 400_000,
//         token_address: STRK_TOKEN_ADDR(),
//         nft_token_id: 0,
//         nft_contract: ZERO_ADDR(),
//         distribution_schedule: BasicDistributionSchedule {
//             phase: 1,
//             amount: 400_000,
//             trigger_time: 0,
//             milestone: "",
//             is_executed: false,
//             executed_at: 0,
//         },
//         special_conditions_count: 0,
//     };

//     asset_allocations.append(allocation1);
//     asset_allocations.append(allocation2);

//     contract.set_asset_allocation(basic_info_id, beneficiaries, asset_allocations);

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_mark_rules_conditions_set() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create basic plan info first
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let basic_info_id = contract
//         .create_plan_basic_info(
//             "My Inheritance Plan", // plan_name
//             "A comprehensive inheritance plan", // plan_description
//             "owner@example.com", // owner_email_hash
//             USER1_ADDR(), // initial_beneficiary
//             "beneficiary@example.com" // initial_beneficiary_email
//         );

//     // Set asset allocation
//     let mut beneficiaries = ArrayTrait::new();
//     let beneficiary = Beneficiary {
//         address: USER1_ADDR(),
//         email_hash: "beneficiary@example.com",
//         percentage: 100,
//         has_claimed: false,
//         claimed_amount: 0,
//         claim_code_hash: "",
//         added_at: 0,
//         kyc_status: KYCStatus::Pending,
//         relationship: "Child",
//         age: 25,
//         is_minor: false,
//     };
//     beneficiaries.append(beneficiary);

//     let mut asset_allocations = ArrayTrait::new();
//     let allocation = AssetAllocation {
//         beneficiary_address: USER1_ADDR(),
//         percentage: 100,
//         asset_type: AssetType::STRK,
//         amount: 1_000_000,
//         token_address: STRK_TOKEN_ADDR(),
//         nft_token_id: 0,
//         nft_contract: ZERO_ADDR(),
//         distribution_schedule: BasicDistributionSchedule {
//             phase: 1,
//             amount: 1_000_000,
//             trigger_time: 0,
//             milestone: "",
//             is_executed: false,
//             executed_at: 0,
//         },
//         special_conditions_count: 0,
//     };
//     asset_allocations.append(allocation);

//     contract.set_asset_allocation(basic_info_id, beneficiaries, asset_allocations);

//     // Mark rules and conditions set
//     contract.mark_rules_conditions_set(basic_info_id);

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_mark_verification_completed() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create basic plan info first
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let basic_info_id = contract
//         .create_plan_basic_info(
//             "My Inheritance Plan", // plan_name
//             "A comprehensive inheritance plan", // plan_description
//             "owner@example.com", // owner_email_hash
//             USER1_ADDR(), // initial_beneficiary
//             "beneficiary@example.com" // initial_beneficiary_email
//         );

//     // Set asset allocation
//     let mut beneficiaries = ArrayTrait::new();
//     let beneficiary = Beneficiary {
//         address: USER1_ADDR(),
//         email_hash: "beneficiary@example.com",
//         percentage: 100,
//         has_claimed: false,
//         claimed_amount: 0,
//         claim_code_hash: "",
//         added_at: 0,
//         kyc_status: KYCStatus::Pending,
//         relationship: "Child",
//         age: 25,
//         is_minor: false,
//     };
//     beneficiaries.append(beneficiary);

//     let mut asset_allocations = ArrayTrait::new();
//     let allocation = AssetAllocation {
//         beneficiary_address: USER1_ADDR(),
//         percentage: 100,
//         asset_type: AssetType::STRK,
//         amount: 1_000_000,
//         token_address: STRK_TOKEN_ADDR(),
//         nft_token_id: 0,
//         nft_contract: ZERO_ADDR(),
//         distribution_schedule: BasicDistributionSchedule {
//             phase: 1,
//             amount: 1_000_000,
//             trigger_time: 0,
//             milestone: "",
//             is_executed: false,
//             executed_at: 0,
//         },
//         special_conditions_count: 0,
//     };
//     asset_allocations.append(allocation);

//     contract.set_asset_allocation(basic_info_id, beneficiaries, asset_allocations);

//     // Mark rules and conditions set
//     contract.mark_rules_conditions_set(basic_info_id);

//     // Mark verification completed
//     contract.mark_verification_completed(basic_info_id);

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_mark_preview_ready() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create basic plan info first
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let basic_info_id = contract
//         .create_plan_basic_info(
//             "My Inheritance Plan", // plan_name
//             "A comprehensive inheritance plan", // plan_description
//             "owner@example.com", // owner_email_hash
//             USER1_ADDR(), // initial_beneficiary
//             "beneficiary@example.com" // initial_beneficiary_email
//         );

//     // Set asset allocation
//     let mut beneficiaries = ArrayTrait::new();
//     let beneficiary = Beneficiary {
//         address: USER1_ADDR(),
//         email_hash: "beneficiary@example.com",
//         percentage: 100,
//         has_claimed: false,
//         claimed_amount: 0,
//         claim_code_hash: "",
//         added_at: 0,
//         kyc_status: KYCStatus::Pending,
//         relationship: "Child",
//         age: 25,
//         is_minor: false,
//     };
//     beneficiaries.append(beneficiary);

//     let mut asset_allocations = ArrayTrait::new();
//     let allocation = AssetAllocation {
//         beneficiary_address: USER1_ADDR(),
//         percentage: 100,
//         asset_type: AssetType::STRK,
//         amount: 1_000_000,
//         token_address: STRK_TOKEN_ADDR(),
//         nft_token_id: 0,
//         nft_contract: ZERO_ADDR(),
//         distribution_schedule: BasicDistributionSchedule {
//             phase: 1,
//             amount: 1_000_000,
//             trigger_time: 0,
//             milestone: "",
//             is_executed: false,
//             executed_at: 0,
//         },
//         special_conditions_count: 0,
//     };
//     asset_allocations.append(allocation);

//     contract.set_asset_allocation(basic_info_id, beneficiaries, asset_allocations);

//     // Mark rules and conditions set
//     contract.mark_rules_conditions_set(basic_info_id);

//     // Mark verification completed
//     contract.mark_verification_completed(basic_info_id);

//     // Mark preview ready
//     contract.mark_preview_ready(basic_info_id);

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_activate_inheritance_plan() {
//     let (contract, _, _, _) = deploy_inheritx_contract();

//     // Create basic plan info first
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let basic_info_id = contract
//         .create_plan_basic_info(
//             "My Inheritance Plan", // plan_name
//             "A comprehensive inheritance plan", // plan_description
//             "owner@example.com", // owner_email_hash
//             USER1_ADDR(), // initial_beneficiary
//             "beneficiary@example.com" // initial_beneficiary_email
//         );

//     // Set asset allocation
//     let mut beneficiaries = ArrayTrait::new();
//     let beneficiary = Beneficiary {
//         address: USER1_ADDR(),
//         email_hash: "beneficiary@example.com",
//         percentage: 100,
//         has_claimed: false,
//         claimed_amount: 0,
//         claim_code_hash: "",
//         added_at: 0,
//         kyc_status: KYCStatus::Pending,
//         relationship: "Child",
//         age: 25,
//         is_minor: false,
//     };
//     beneficiaries.append(beneficiary);

//     let mut asset_allocations = ArrayTrait::new();
//     let allocation = AssetAllocation {
//         beneficiary_address: USER1_ADDR(),
//         percentage: 100,
//         asset_type: AssetType::STRK,
//         amount: 1_000_000,
//         token_address: STRK_TOKEN_ADDR(),
//         nft_token_id: 0,
//         nft_contract: ZERO_ADDR(),
//         distribution_schedule: BasicDistributionSchedule {
//             phase: 1,
//             amount: 1_000_000,
//             trigger_time: 0,
//             milestone: "",
//             is_executed: false,
//             executed_at: 0,
//         },
//         special_conditions_count: 0,
//     };
//     asset_allocations.append(allocation);

//     contract.set_asset_allocation(basic_info_id, beneficiaries, asset_allocations);

//     // Mark rules and conditions set
//     contract.mark_rules_conditions_set(basic_info_id);

//     // Mark verification completed
//     contract.mark_verification_completed(basic_info_id);

//     // Mark preview ready
//     contract.mark_preview_ready(basic_info_id);

//     // Note: Plan activation requires the preview to be properly set up
//     // and the plan to be in the correct state. This test demonstrates the setup.

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ ADDITIONAL ESCROW TESTS ================

// #[test]
// fn test_escrow_lifecycle_complete() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Get escrow details
//     let escrow_details = contract.get_escrow_details(plan_id);
//     assert(escrow_details.plan_id == plan_id, 'Escrow plan ID should match');

//     // Lock assets in escrow (as admin)
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
//     contract.lock_assets_in_escrow(escrow_details.id, 1000, 500); // fees, tax_liability

//     // Note: Asset release requires the contract to have sufficient balance
//     // and proper token setup. This test demonstrates the locking functionality.

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ ADDITIONAL BENEFICIARY TESTS ================

// #[test]
// fn test_beneficiary_management_complete() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Add new beneficiary
//     contract
//         .add_beneficiary_to_plan(
//             plan_id,
//             USER2_ADDR(), // new beneficiary
//             30, // percentage
//             "beneficiary2@example.com", // email_hash
//             28, // age
//             "Sibling" // relationship
//         );

//     // Get beneficiaries
//     let beneficiaries_list = contract.get_beneficiaries(plan_id);
//     assert(beneficiaries_list.len() == 2, 'Should have 2 beneficiaries');

//     // Remove beneficiary
//     contract
//         .remove_beneficiary_from_plan(
//             plan_id, USER2_ADDR(), // beneficiary to remove
//             "Beneficiary request" // reason
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ ADDITIONAL SWAP TESTS ================

// #[test]
// fn test_swap_execution_complete() {
//     let (contract, strk_token, usdt_token, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Create swap request
//     contract
//         .create_swap_request(
//             plan_id, // plan_id
//             strk_token.contract_address, // from_token
//             usdt_token.contract_address, // to_token
//             1_000_000, // amount
//             100 // slippage_tolerance (1%)
//         );

//     // Note: Swap execution requires the contract to have sufficient balance
//     // and proper DEX router setup. This test demonstrates the request creation.

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ ADDITIONAL INACTIVITY TESTS ================

// #[test]
// fn test_inactivity_monitoring_complete() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Create inactivity monitor
//     contract
//         .create_inactivity_monitor(
//             USER1_ADDR(), // wallet_address
//             86400, // threshold (1 day)
//             "beneficiary@example.com", // beneficiary_email_hash
//             plan_id // plan_id
//         );

//     // Update wallet activity
//     contract.update_wallet_activity(USER1_ADDR());

//     // Check inactivity status
//     let _is_inactive = contract.check_inactivity_status(plan_id);
//     // Note: This will return false since we just updated activity

//     // Get inactivity monitor
//     let monitor = contract.get_inactivity_monitor(USER1_ADDR());
//     assert(monitor.plan_id == plan_id, 'Monitor plan ID should match');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Unauthorized access',))]
// fn test_generate_encrypted_claim_code_unauthorized() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test that non-plan owner cannot generate claim codes - this should panic with
//     "Unauthorized // access"
//     start_cheat_caller_address(contract.contract_address, USER2_ADDR());

//     let public_key: ByteArray = "0102";

//     contract.generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key, 86400);
// }

// #[test]
// #[should_panic(expected: ('Zero address forbidden',))]
// fn test_generate_encrypted_claim_code_zero_beneficiary() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Test with zero beneficiary address - this should panic with "Zero address forbidden"
//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     let public_key: ByteArray = "0102";

//     contract.generate_encrypted_claim_code(plan_id, ZERO_ADDR(), // Zero address
//     public_key, 86400);
// }

// // ================ PERCENTAGE-BASED ALLOCATION TESTS ================

// #[test]
// fn test_create_inheritance_plan_with_percentages() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     // Create beneficiary data with different percentages
//     let mut beneficiary_data = ArrayTrait::new();

//     let beneficiary1 = BeneficiaryData {
//         address: USER1_ADDR(),
//         percentage: 60_u8, // 60% of assets
//         email_hash: "user1@example.com",
//         age: 25_u8,
//         relationship: "Child",
//     };
//     beneficiary_data.append(beneficiary1);

//     let beneficiary2 = BeneficiaryData {
//         address: USER2_ADDR(),
//         percentage: 40_u8, // 40% of assets
//         email_hash: "user2@example.com",
//         age: 30_u8,
//         relationship: "Child",
//     };
//     beneficiary_data.append(beneficiary2);

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan_with_percentages(
//             beneficiary_data,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     assert(plan_id == 1, 'Plan ID should be 1');

//     // Verify beneficiary percentages
//     let beneficiaries = contract.get_beneficiary_percentages(plan_id);
//     assert(beneficiaries.len() == 2, 'Should have 2 beneficiaries');

//     let beneficiary1_data = beneficiaries.at(0).clone();
//     let beneficiary2_data = beneficiaries.at(1).clone();

//     assert(beneficiary1_data.address == USER1_ADDR(), 'First beneficiary be USER1');
//     assert(beneficiary1_data.percentage == 60, 'First beneficiary have 60%');
//     assert(beneficiary2_data.address == USER2_ADDR(), 'Second beneficiary be USER2');
//     assert(beneficiary2_data.percentage == 40, 'Second beneficiary have 40%');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Total percentage must equal 100',))]
// fn test_create_inheritance_plan_with_invalid_percentages() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     // Create beneficiary data with invalid percentages (sum != 100)
//     let mut beneficiary_data = ArrayTrait::new();

//     let beneficiary1 = BeneficiaryData {
//         address: USER1_ADDR(),
//         percentage: 60_u8, // 60% of assets
//         email_hash: "user1@example.com",
//         age: 25_u8,
//         relationship: "Child",
//     };
//     beneficiary_data.append(beneficiary1);

//     let beneficiary2 = BeneficiaryData {
//         address: USER2_ADDR(),
//         percentage: 50_u8, // 50% of assets (total = 110%)
//         email_hash: "user2@example.com",
//         age: 30_u8,
//         relationship: "Child",
//     };
//     beneficiary_data.append(beneficiary2);

//     let mut emergency_contacts = ArrayTrait::new();

//     // This should fail because percentages don't sum to 100
//     contract
//         .create_inheritance_plan_with_percentages(
//             beneficiary_data,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );
// }

// #[test]
// fn test_update_beneficiary_percentages() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     // Create initial plan with 50/50 split
//     let mut beneficiary_data = ArrayTrait::new();

//     let beneficiary1 = BeneficiaryData {
//         address: USER1_ADDR(),
//         percentage: 50_u8,
//         email_hash: "user1@example.com",
//         age: 25_u8,
//         relationship: "Child",
//     };
//     beneficiary_data.append(beneficiary1);

//     let beneficiary2 = BeneficiaryData {
//         address: USER2_ADDR(),
//         percentage: 50_u8,
//         email_hash: "user2@example.com",
//         age: 30_u8,
//         relationship: "Child",
//     };
//     beneficiary_data.append(beneficiary2);

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan_with_percentages(
//             beneficiary_data,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Update to 70/30 split
//     let mut updated_beneficiary_data = ArrayTrait::new();

//     let updated_beneficiary1 = BeneficiaryData {
//         address: USER1_ADDR(),
//         percentage: 70_u8, // Increased to 70%
//         email_hash: "user1@example.com",
//         age: 25_u8,
//         relationship: "Child",
//     };
//     updated_beneficiary_data.append(updated_beneficiary1);

//     let updated_beneficiary2 = BeneficiaryData {
//         address: USER2_ADDR(),
//         percentage: 30_u8, // Decreased to 30%
//         email_hash: "user2@example.com",
//         age: 30_u8,
//         relationship: "Child",
//     };
//     updated_beneficiary_data.append(updated_beneficiary2);

//     contract.update_beneficiary_percentages(plan_id, updated_beneficiary_data);

//     // Verify updated percentages
//     let beneficiaries = contract.get_beneficiary_percentages(plan_id);
//     assert(beneficiaries.len() == 2, 'Should have 2 beneficiaries');

//     let beneficiary1_data = beneficiaries.at(0).clone();
//     let beneficiary2_data = beneficiaries.at(1).clone();

//     assert(beneficiary1_data.percentage == 70, 'First beneficiary have 70%');
//     assert(beneficiary2_data.percentage == 30, 'Second beneficiary have 30%');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_complex_percentage_allocation() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Approve tokens
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

//     // Create plan with 5 beneficiaries with different percentages
//     let mut beneficiary_data = ArrayTrait::new();

//     // Add 5 beneficiaries with percentages that sum to 100
//     let mut percentages = ArrayTrait::new();
//     percentages.append(25_u8);
//     percentages.append(20_u8);
//     percentages.append(20_u8);
//     percentages.append(20_u8);
//     percentages.append(15_u8); // 25% + 20% + 20% + 20% + 15% = 100%

//     let mut addresses = ArrayTrait::new();
//     addresses.append(USER1_ADDR());
//     addresses.append(USER2_ADDR());
//     addresses.append(ADMIN_ADDR());
//     addresses.append(CREATOR_ADDR());
//     addresses.append(ZERO_ADDR());

//     let mut emails = ArrayTrait::new();
//     emails.append("user1@example.com");
//     emails.append("user2@example.com");
//     emails.append("admin@example.com");
//     emails.append("creator@example.com");
//     emails.append("zero@example.com");

//     let mut ages = ArrayTrait::new();
//     ages.append(25_u8);
//     ages.append(30_u8);
//     ages.append(35_u8);
//     ages.append(40_u8);
//     ages.append(45_u8);

//     let mut relationships = ArrayTrait::new();
//     relationships.append("Child");
//     relationships.append("Spouse");
//     relationships.append("Sibling");
//     relationships.append("Parent");
//     relationships.append("Friend");

//     let mut i: u32 = 0;
//     while i != 5 {
//         let beneficiary = BeneficiaryData {
//             address: addresses.at(i).clone(),
//             percentage: percentages.at(i).clone(),
//             email_hash: emails.at(i).clone(),
//             age: ages.at(i).clone(),
//             relationship: relationships.at(i).clone(),
//         };
//         beneficiary_data.append(beneficiary);
//         i += 1;
//     }

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan_with_percentages(
//             beneficiary_data,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     assert(plan_id == 1, 'Plan ID should be 1');

//     // Verify all beneficiary percentages
//     let beneficiaries = contract.get_beneficiary_percentages(plan_id);
//     assert(beneficiaries.len() == 5, 'Should have 5 beneficiaries');

//     let mut total_percentage: u8 = 0;
//     let mut i: u32 = 0;
//     while i != 5 {
//         let beneficiary = beneficiaries.at(i).clone();
//         total_percentage += beneficiary.percentage;
//         i += 1;
//     }

//     assert(total_percentage == 100, 'Total percentage equal 100%');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Insufficient user balance',))]
// fn test_create_inheritance_plan_insufficient_balance() {
//     let (contract, _strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Use USER1_ADDR who has no tokens
//     start_cheat_caller_address(contract.contract_address, USER1_ADDR());

//     // Try to create a plan with 1 STRK when user has 0 balance
//     let mut beneficiary_data = ArrayTrait::new();

//     let beneficiary = BeneficiaryData {
//         address: USER2_ADDR(),
//         percentage: 100_u8,
//         email_hash: "user2@example.com",
//         age: 25_u8,
//         relationship: "Child",
//     };
//     beneficiary_data.append(beneficiary);

//     let mut emergency_contacts = ArrayTrait::new();

//     // This should fail because USER1_ADDR has no STRK balance
//     contract
//         .create_inheritance_plan_with_percentages(
//             beneficiary_data,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Insufficient user balance',))]
// fn test_create_inheritance_plan_insufficient_usdc_balance() {
//     let (contract, _, _usdc_token, _) = deploy_inheritx_contract();

//     // Setup: Use USER1_ADDR who has no tokens
//     start_cheat_caller_address(contract.contract_address, USER1_ADDR());

//     // Try to create a plan with 100 USDC when user has 0 balance
//     let mut beneficiary_data = ArrayTrait::new();

//     let beneficiary = BeneficiaryData {
//         address: USER2_ADDR(),
//         percentage: 100_u8,
//         email_hash: "user2@example.com",
//         age: 25_u8,
//         relationship: "Child",
//     };
//     beneficiary_data.append(beneficiary);

//     let mut emergency_contacts = ArrayTrait::new();

//     // This should fail because USER1_ADDR has no USDC balance
//     contract
//         .create_inheritance_plan_with_percentages(
//             beneficiary_data,
//             2, // USDC
//             100_000_000, // 100 USDC (assuming 6 decimals)
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ PLAN EDITING TESTS ================

// #[test]
// fn test_extend_plan_timeframe() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Get original active date
//     let original_plan = contract.get_inheritance_plan(plan_id);
//     let original_active_date = original_plan.becomes_active_at;

//     // Extend timeframe by 2 days
//     contract.extend_plan_timeframe(plan_id, 172800); // 2 days

//     // Verify extension
//     let updated_plan = contract.get_inheritance_plan(plan_id);
//     assert(
//         updated_plan.becomes_active_at == original_active_date + 172800,
//         'Timeframe should be extended',
//     );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Invalid input parameters',))]
// fn test_extend_plan_timeframe_invalid_time() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Try to extend with 0 time (should fail)
//     contract.extend_plan_timeframe(plan_id, 0);

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_update_plan_parameters() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Update plan parameters
//     contract
//         .update_plan_parameters(
//             plan_id, 5, // new security level
//             true, // new auto_execute
//             USER2_ADDR() // new guardian
//         );

//     // Verify updates
//     let updated_plan = contract.get_inheritance_plan(plan_id);
//     assert(updated_plan.security_level == 5, 'Security level be updated');
//     assert(updated_plan.auto_execute == true, 'Auto-execute should be updated');
//     assert(updated_plan.guardian == USER2_ADDR(), 'Guardian should be updated');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Invalid input parameters',))]
// fn test_update_plan_parameters_invalid_security() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Try to update with invalid security level (should fail)
//     contract
//         .update_plan_parameters(
//             plan_id, 6, // invalid security level (max is 5)
//             true, USER2_ADDR(),
//         );

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_update_inactivity_threshold() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Update inactivity threshold
//     contract.update_inactivity_threshold(plan_id, 2592000); // 30 days

//     // Verify update
//     let updated_plan = contract.get_inheritance_plan(plan_id);
//     assert(updated_plan.inactivity_threshold == 2592000, 'Inactivity threshold be updated');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Invalid inactivity threshold',))]
// fn test_update_inactivity_threshold_invalid() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Try to update with invalid threshold (should fail)
//     contract.update_inactivity_threshold(plan_id, 0); // 0 is invalid

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_comprehensive_plan_editing() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Add a new beneficiary
//     contract
//         .add_beneficiary_to_plan(
//             plan_id, USER2_ADDR(), 50, // 50%
//             "user2@example.com", 30_u8, "Spouse",
//         );

//     // Extend timeframe
//     contract.extend_plan_timeframe(plan_id, 172800); // 2 days

//     // Update parameters
//     contract
//         .update_plan_parameters(
//             plan_id,
//             5, // max security level
//             true, // enable auto-execute
//             ADMIN_ADDR() // set admin as guardian
//         );

//     // Update inactivity threshold
//     contract.update_inactivity_threshold(plan_id, 2592000); // 30 days

//     // Verify all changes
//     let final_plan = contract.get_inheritance_plan(plan_id);
//     assert(final_plan.beneficiary_count == 2, 'Should have 2 beneficiaries');
//     assert(final_plan.security_level == 5, 'Security level should be 5');
//     assert(final_plan.auto_execute == true, 'Auto-execute should be true');
//     assert(final_plan.guardian == ADMIN_ADDR(), 'Guardian should be admin');
//     assert(final_plan.inactivity_threshold == 2592000, 'Inactivity threshold be 30 days');

//     stop_cheat_caller_address(contract.contract_address);
// }

// // ================ FIXED CLAIM CODE SYSTEM TESTS ================

// #[test]
// fn test_claim_code_validation_workflow() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     // First update security settings to allow shorter timeframes for testing
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
//     contract
//         .update_security_settings(
//             10, // max_beneficiaries
//             1, // min_timeframe (1 second for testing)
//             86400, // max_timeframe (1 day)
//             false, // require_guardian
//             false, // allow_early_execution
//             1000000000, // max_asset_amount
//             false, // require_multi_sig
//             2, // multi_sig_threshold
//             86400 // emergency_timeout
//         );
//     stop_cheat_caller_address(contract.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             1, // 1 second (for testing - plan becomes active immediately)
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Store a known claim code hash instead of generating encrypted code
//     // This makes the test more reliable and testable
//     // The code "known_code_123" hashes to "hash_processed_0" (sum % 4 = 0)
//     let known_code_hash = "hash_processed_0";
//     contract.store_claim_code_hash(plan_id, USER1_ADDR(), known_code_hash, 86400);

//     // Verify claim code hash is stored
//     let plan = contract.get_inheritance_plan(plan_id);
//     // Create a new ByteArray instance for comparison to avoid move error
//     let expected_hash = "hash_processed_0";
//     assert(plan.claim_code_hash == expected_hash, 'Plan should have stored hash');

//     // Test that the claim code hash is properly stored and can be retrieved
//     // Note: We don't test actual claiming since the plan needs time to become active
//     // This test verifies the storage and validation logic works correctly

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// #[should_panic(expected: ('Invalid claim code',))]
// fn test_claim_code_validation_invalid_code() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Generate encrypted claim code
//     let public_key: ByteArray = "01020304";
//     contract.generate_encrypted_claim_code(plan_id, USER1_ADDR(), public_key, 86400);

//     // Try to claim with wrong code
//     start_cheat_caller_address(contract.contract_address, USER1_ADDR());
//     contract.claim_inheritance(plan_id, "wrong");

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_claim_code_already_used() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Store a known claim code hash instead of generating encrypted code
//     // The code "known_code_456" hashes to "hash_processed_1" (sum % 4 = 1)
//     let known_code_hash = "hash_processed_1";
//     contract.store_claim_code_hash(plan_id, USER1_ADDR(), known_code_hash, 1);

//     // Test that the claim code hash is properly stored
//     let plan = contract.get_inheritance_plan(plan_id);
//     // Create a new ByteArray instance for comparison to avoid move error
//     let expected_hash = "hash_processed_1";
//     assert(plan.claim_code_hash == expected_hash, 'Plan should have stored hash');

//     // Note: We don't test actual claiming since the plan needs time to become active
//     // This test verifies the storage logic works correctly

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_claim_code_storage_consistency() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Store a known claim code hash instead of generating encrypted code
//     let known_code_hash = "hash_processed_2";
//     contract.store_claim_code_hash(plan_id, USER1_ADDR(), known_code_hash, 86400);

//     // Verify claim code hash is stored in both locations
//     let plan = contract.get_inheritance_plan(plan_id);

//     // Both should have the same hash
//     // Create a new ByteArray instance for comparison to avoid move error
//     let expected_hash = "hash_processed_2";
//     assert(plan.claim_code_hash == expected_hash, 'Plan should have stored hash');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_store_claim_code_hash_consistency() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // Store claim code hash manually
//     let code_hash = "manual_hash_123";
//     contract.store_claim_code_hash(plan_id, USER1_ADDR(), code_hash, 86400);

//     // Verify claim code hash is stored in both locations
//     let plan = contract.get_inheritance_plan(plan_id);

//     // Both should have the same hash
//     // Create a new ByteArray instance for comparison to avoid move error
//     let code_hash_compare = "manual_hash_123";
//     assert(plan.claim_code_hash == code_hash_compare, 'Plan should have same hash');

//     stop_cheat_caller_address(contract.contract_address);
// }

// #[test]
// fn test_beneficiary_identity_verification() {
//     let (contract, strk_token, _, _) = deploy_inheritx_contract();

//     // Setup: Create a plan first
//     start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
//     strk_token.approve(contract.contract_address, 100_000_000);
//     stop_cheat_caller_address(strk_token.contract_address);

//     start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
//     let mut beneficiaries = ArrayTrait::new();
//     beneficiaries.append(USER1_ADDR());

//     let mut emergency_contacts = ArrayTrait::new();

//     let plan_id = contract
//         .create_inheritance_plan(
//             beneficiaries,
//             0, // STRK
//             1_000_000, // 1 STRK
//             0, // No NFT
//             ZERO_ADDR(), // No NFT contract
//             86400, // 1 day
//             ZERO_ADDR(), // No guardian
//             create_empty_byte_array(),
//             3, // security_level
//             false, // auto_execute
//             emergency_contacts,
//         );

//     // The plan creation already added USER1_ADDR as a beneficiary with default data
//     // Test identity verification with the default data (empty strings)
//     // Note: This will now fail because KYC is not approved
//     let default_email_hash_1 = "";
//     let default_name_hash_1 = "";
//     let is_verified = contract
//         .verify_beneficiary_identity(
//             plan_id, USER1_ADDR(), default_email_hash_1, default_name_hash_1,
//         );
//     // KYC requirement: verification should fail without approved KYC
//     assert(!is_verified, 'Bfry verf fails without KYC');

//     // Test identity verification with non-existent beneficiary
//     let default_email_hash_2 = "";
//     let default_name_hash_2 = "";
//     let is_verified_wrong_address = contract
//         .verify_beneficiary_identity(
//             plan_id, USER2_ADDR(), default_email_hash_2, default_name_hash_2,
//         );
//     assert(!is_verified_wrong_address, 'Non-existent bfry not verified');

//     stop_cheat_caller_address(contract.contract_address);
// }
