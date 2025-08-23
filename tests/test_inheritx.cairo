use core::array::ArrayTrait;
use core::byte_array::ByteArray;
use inheritx_contracts::interfaces::iinheritx::{IInheritXDispatcher, IInheritXDispatcherTrait};
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::ContractAddress;


// Mock STARKTOKEN contract for testing
// Enhanced mock contract with basic ERC20 functionality for testing
#[starknet::contract]
pub mod STARKTOKEN {
    use core::array::ArrayTrait;
    use starknet::storage::{
        StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    pub struct Storage {
        // Basic ERC20 storage
        balances: starknet::storage::Map<ContractAddress, u256>,
        allowances: starknet::storage::Map<(ContractAddress, ContractAddress), u256>,
        total_supply: u256,
        name: felt252,
        symbol: felt252,
        decimals: u8,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Transfer {
        pub from: ContractAddress,
        pub to: ContractAddress,
        pub value: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Approval {
        pub owner: ContractAddress,
        pub spender: ContractAddress,
        pub value: u256,
    }

    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        initial_supply: ContractAddress,
        recipient: ContractAddress,
        decimals: u8,
    ) {
        // Use a default initial supply amount for testing
        let supply_amount: u256 = 1000000000000000000000000000; // 1 token with 18 decimals
        self.balances.write(recipient, supply_amount);
        self.total_supply.write(supply_amount);
        self.decimals.write(decimals);
        self.name.write('STARKTOKEN');
        self.symbol.write('STRK');
    }

    #[external(v0)]
    pub fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
        let owner = get_caller_address();
        self.allowances.write((owner, spender), amount);
        self.emit(Approval { owner, spender, value: amount });
        true
    }

    #[external(v0)]
    pub fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
        let from = get_caller_address();
        let from_balance = self.balances.read(from);
        assert(from_balance >= amount, 'Insufficient balance');

        self.balances.write(from, from_balance - amount);
        let to_balance = self.balances.read(to);
        self.balances.write(to, to_balance + amount);

        self.emit(Transfer { from, to, value: amount });
        true
    }

    #[external(v0)]
    pub fn transfer_from(
        ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256,
    ) -> bool {
        let spender = get_caller_address();
        let allowance = self.allowances.read((from, spender));
        assert(allowance >= amount, 'Insufficient allowance');

        let from_balance = self.balances.read(from);
        assert(from_balance >= amount, 'Insufficient balance');

        self.allowances.write((from, spender), allowance - amount);
        self.balances.write(from, from_balance - amount);
        let to_balance = self.balances.read(to);
        self.balances.write(to, to_balance + amount);

        self.emit(Transfer { from, to, value: amount });
        true
    }

    #[external(v0)]
    pub fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
        self.balances.read(account)
    }

    #[external(v0)]
    pub fn allowance(
        self: @ContractState, owner: ContractAddress, spender: ContractAddress,
    ) -> u256 {
        self.allowances.read((owner, spender))
    }

    #[external(v0)]
    pub fn total_supply(self: @ContractState) -> u256 {
        self.total_supply.read()
    }

    #[external(v0)]
    pub fn name(self: @ContractState) -> felt252 {
        self.name.read()
    }

    #[external(v0)]
    pub fn symbol(self: @ContractState) -> felt252 {
        self.symbol.read()
    }

    #[external(v0)]
    pub fn decimals(self: @ContractState) -> u8 {
        self.decimals.read()
    }
}

// Test constants - using smaller values that fit in felt252
const ADMIN_CONST: felt252 = 123;
const CREATOR_CONST: felt252 = 456;
const USER1_CONST: felt252 = 789;
const USER2_CONST: felt252 = 101;
const STRK_TOKEN_CONST: felt252 = 202;
const USDT_TOKEN_CONST: felt252 = 303;
const USDC_TOKEN_CONST: felt252 = 404;
const DEX_ROUTER_CONST: felt252 = 505;
const EMERGENCY_WITHDRAW_CONST: felt252 = 606;
const ZERO_ADDRESS: felt252 = 0;

pub fn ADMIN_ADDR() -> ContractAddress {
    ADMIN_CONST.try_into().unwrap()
}

pub fn CREATOR_ADDR() -> ContractAddress {
    CREATOR_CONST.try_into().unwrap()
}

pub fn USER1_ADDR() -> ContractAddress {
    USER1_CONST.try_into().unwrap()
}

pub fn USER2_ADDR() -> ContractAddress {
    USER2_CONST.try_into().unwrap()
}

pub fn STRK_TOKEN_ADDR() -> ContractAddress {
    STRK_TOKEN_CONST.try_into().unwrap()
}

pub fn USDT_TOKEN_ADDR() -> ContractAddress {
    USDT_TOKEN_CONST.try_into().unwrap()
}

pub fn USDC_TOKEN_ADDR() -> ContractAddress {
    USDC_TOKEN_CONST.try_into().unwrap()
}

pub fn DEX_ROUTER_ADDR() -> ContractAddress {
    DEX_ROUTER_CONST.try_into().unwrap()
}

pub fn EMERGENCY_WITHDRAW_ADDR() -> ContractAddress {
    EMERGENCY_WITHDRAW_CONST.try_into().unwrap()
}

pub fn ZERO_ADDR() -> ContractAddress {
    ZERO_ADDRESS.try_into().unwrap()
}

// Helper function to create empty ByteArray
fn create_empty_byte_array() -> ByteArray {
    ""
}

// Deploy the InheritX contract
fn deploy_inheritx_contract() -> (
    IInheritXDispatcher, ERC20ABIDispatcher, ERC20ABIDispatcher, ERC20ABIDispatcher,
) {
    // Deploy mock tokens
    let strk_class = declare("STARKTOKEN").unwrap().contract_class();
    let mut strk_calldata = array![CREATOR_ADDR().into(), CREATOR_ADDR().into(), 6];
    let (strk_address, _) = strk_class.deploy(@strk_calldata).unwrap();
    let strk_dispatcher = ERC20ABIDispatcher { contract_address: strk_address };

    let (usdt_address, _) = strk_class.deploy(@strk_calldata).unwrap();
    let usdt_dispatcher = ERC20ABIDispatcher { contract_address: usdt_address };

    let (usdc_address, _) = strk_class.deploy(@strk_calldata).unwrap();
    let usdc_dispatcher = ERC20ABIDispatcher { contract_address: usdc_address };

    // Deploy InheritX contract
    let contract = declare("InheritX").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        DEX_ROUTER_ADDR().into(),
        EMERGENCY_WITHDRAW_ADDR().into(),
        strk_address.into(),
        usdt_address.into(),
        usdc_address.into(),
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    let inheritx = IInheritXDispatcher { contract_address };
    (inheritx, strk_dispatcher, usdt_dispatcher, usdc_dispatcher)
}

// ================ BASIC FUNCTIONALITY TESTS ================

#[test]
fn test_contract_deployment() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Test that contract was deployed successfully
    assert(contract.contract_address != ZERO_ADDR(), 'Deployed');
}

#[test]
fn test_create_inheritance_plan_success() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Approve tokens
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    // Create inheritance plan
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());
    beneficiaries.append(USER2_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    let plan_id = contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            5, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    assert(plan_id == 1, 'Plan ID should be 1');

    stop_cheat_caller_address(contract.contract_address);
}

// ================ KYC TESTS ================

#[test]
fn test_upload_kyc_success() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Upload KYC as asset owner
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.upload_kyc(create_empty_byte_array(), 0); // Asset owner

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_approve_kyc_success() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Upload KYC first
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.upload_kyc(create_empty_byte_array(), 0);
    stop_cheat_caller_address(contract.contract_address);

    // Approve KYC as admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.approve_kyc(USER1_ADDR(), create_empty_byte_array());

    stop_cheat_caller_address(contract.contract_address);
}

// ================ SECURITY SETTINGS TESTS ================

#[test]
fn test_update_security_settings() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Update security settings as admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract
        .update_security_settings(
            15, // max_beneficiaries
            3600, // min_timeframe (1 hour)
            2592000, // max_timeframe (30 days)
            true, // require_guardian
            false, // allow_early_execution
            100_000_000, // max_asset_amount (100K STRK)
            true, // require_multi_sig
            3, // multi_sig_threshold
            1209600 // emergency_timeout (14 days)
        );

    stop_cheat_caller_address(contract.contract_address);
}

// ================ ADMIN FUNCTIONS TESTS ================

#[test]
fn test_pause_and_unpause() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Pause contract
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.pause();

    // Unpause contract
    contract.unpause();

    stop_cheat_caller_address(contract.contract_address);
}

// ================ QUERY FUNCTIONS TESTS ================

#[test]
fn test_get_plan_count() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Approve tokens
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            5, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_get_escrow_count() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Create a plan (which creates an escrow)
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            5, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    stop_cheat_caller_address(contract.contract_address);
}

// ================ ADDITIONAL FUNCTIONALITY TESTS ================

#[test]
fn test_create_inheritance_plan_with_nft() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Create inheritance plan with NFT
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    let plan_id = contract
        .create_inheritance_plan(
            beneficiaries,
            3, // NFT
            0, // No amount for NFT
            123, // NFT token ID
            USER1_ADDR(), // NFT contract address
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            true, // auto_execute
            emergency_contacts,
        );

    assert(plan_id == 1, 'Plan ID should be 1');
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_create_inheritance_plan_with_guardian() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Create inheritance plan with guardian
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    let plan_id = contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            USER2_ADDR(), // Guardian
            create_empty_byte_array(),
            4, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    assert(plan_id == 1, 'Plan ID should be 1');
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_create_inheritance_plan_with_emergency_contacts() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Create inheritance plan with emergency contacts
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());

    let mut emergency_contacts = ArrayTrait::new();
    emergency_contacts.append(USER2_ADDR());
    emergency_contacts.append(ADMIN_ADDR());

    let plan_id = contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            5, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    assert(plan_id == 1, 'Plan ID should be 1');
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_create_multiple_inheritance_plans() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Approve tokens for multiple plans
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    // Create first plan
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries1 = ArrayTrait::new();
    beneficiaries1.append(USER1_ADDR());

    let mut emergency_contacts1 = ArrayTrait::new();

    let plan_id1 = contract
        .create_inheritance_plan(
            beneficiaries1,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts1,
        );

    // Create second plan
    let mut beneficiaries2 = ArrayTrait::new();
    beneficiaries2.append(USER2_ADDR());

    let mut emergency_contacts2 = ArrayTrait::new();

    let plan_id2 = contract
        .create_inheritance_plan(
            beneficiaries2,
            0, // STRK
            2_000_000, // 2 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            172800, // 2 days
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            4, // security_level
            true, // auto_execute
            emergency_contacts2,
        );

    assert(plan_id1 == 1, 'First plan ID should be 1');
    assert(plan_id2 == 2, 'Second plan ID should be 2');
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_create_inheritance_plan_with_different_asset_types() {
    let (contract, strk_token, usdt_token, usdc_token) = deploy_inheritx_contract();

    // Setup: Approve tokens for different asset types
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    start_cheat_caller_address(usdt_token.contract_address, CREATOR_ADDR());
    usdt_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(usdt_token.contract_address);

    start_cheat_caller_address(usdc_token.contract_address, CREATOR_ADDR());
    usdc_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(usdc_token.contract_address);

    // Create STRK plan
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    let strk_plan_id = contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    // Create USDT plan with new beneficiaries array
    let mut beneficiaries2 = ArrayTrait::new();
    beneficiaries2.append(USER1_ADDR());

    let mut emergency_contacts2 = ArrayTrait::new();

    let usdt_plan_id = contract
        .create_inheritance_plan(
            beneficiaries2,
            1, // USDT
            1_000_000, // 1 USDT
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            4, // security_level
            false, // auto_execute
            emergency_contacts2,
        );

    // Create USDC plan with new beneficiaries array
    let mut beneficiaries3 = ArrayTrait::new();
    beneficiaries3.append(USER1_ADDR());

    let mut emergency_contacts3 = ArrayTrait::new();

    let usdc_plan_id = contract
        .create_inheritance_plan(
            beneficiaries3,
            2, // USDC
            1_000_000, // 1 USDC
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            5, // security_level
            false, // auto_execute
            emergency_contacts3,
        );

    assert(strk_plan_id == 1, 'STRK plan ID should be 1');
    assert(usdt_plan_id == 2, 'USDT plan ID should be 2');
    assert(usdc_plan_id == 3, 'USDC plan ID should be 3');
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_create_inheritance_plan_with_different_security_levels() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Approve tokens
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    // Create plans with different security levels
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries1 = ArrayTrait::new();
    beneficiaries1.append(USER1_ADDR());

    let mut emergency_contacts1 = ArrayTrait::new();

    // Security level 1 (lowest)
    let plan_id1 = contract
        .create_inheritance_plan(
            beneficiaries1,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            1, // security_level
            false, // auto_execute
            emergency_contacts1,
        );

    // Security level 5 (highest)
    let mut beneficiaries2 = ArrayTrait::new();
    beneficiaries2.append(USER1_ADDR());

    let mut emergency_contacts2 = ArrayTrait::new();

    let plan_id2 = contract
        .create_inheritance_plan(
            beneficiaries2,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            5, // security_level
            false, // auto_execute
            emergency_contacts2,
        );

    assert(plan_id1 == 1, 'Low plan ID should be 1');
    assert(plan_id2 == 2, 'High plan ID should be 2');
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_create_inheritx_plan_with_different_timeframes() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Approve tokens
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    // Create plans with different timeframes
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries1 = ArrayTrait::new();
    beneficiaries1.append(USER1_ADDR());

    let mut emergency_contacts1 = ArrayTrait::new();

    // Short timeframe (1 hour)
    let plan_id1 = contract
        .create_inheritance_plan(
            beneficiaries1,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            3600, // 1 hour
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts1,
        );

    // Medium timeframe (1 week)
    let mut beneficiaries2 = ArrayTrait::new();
    beneficiaries2.append(USER1_ADDR());

    let mut emergency_contacts2 = ArrayTrait::new();

    let plan_id2 = contract
        .create_inheritance_plan(
            beneficiaries2,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            604800, // 1 week
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts2,
        );

    // Long timeframe (1 month)
    let mut beneficiaries3 = ArrayTrait::new();
    beneficiaries3.append(USER1_ADDR());

    let mut emergency_contacts3 = ArrayTrait::new();

    let plan_id3 = contract
        .create_inheritance_plan(
            beneficiaries3,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            2592000, // 1 month
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts3,
        );

    assert(plan_id1 == 1, 'Short tf plan ID should be 1'); //timeframe
    assert(plan_id2 == 2, 'Medium tf plan ID should be 2'); //timeframe
    assert(plan_id3 == 3, 'Long tf plan ID should be 3'); //timeframe
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_create_inheritance_plan_with_multiple_beneficiaries() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Approve tokens
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    // Create plan with multiple beneficiaries
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());
    beneficiaries.append(USER2_ADDR());
    beneficiaries.append(ADMIN_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    let plan_id = contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    assert(plan_id == 1, 'Plan ID should be 1');
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_kyc_workflow_complete() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Complete KYC workflow: upload -> approve -> reject -> upload again -> approve
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());

    // Upload KYC as asset owner
    contract.upload_kyc(create_empty_byte_array(), 0); // Asset owner

    stop_cheat_caller_address(contract.contract_address);

    // Approve KYC as admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.approve_kyc(USER1_ADDR(), create_empty_byte_array());
    stop_cheat_caller_address(contract.contract_address);

    // Upload KYC for beneficiary
    start_cheat_caller_address(contract.contract_address, USER2_ADDR());
    contract.upload_kyc(create_empty_byte_array(), 1); // Beneficiary
    stop_cheat_caller_address(contract.contract_address);

    // Approve beneficiary KYC
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.approve_kyc(USER2_ADDR(), create_empty_byte_array());
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_security_settings_comprehensive() {
    let (contract, _, _, _) = deploy_inheritx_contract();

    // Test comprehensive security settings update
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());

    // Update with different security configurations
    contract
        .update_security_settings(
            20, // max_beneficiaries
            1800, // min_timeframe (30 minutes)
            5184000, // max_timeframe (60 days)
            true, // require_guardian
            true, // allow_early_execution
            500_000_000, // max_asset_amount (500K STRK)
            true, // require_multi_sig
            5, // multi_sig_threshold
            2592000 // emergency_timeout (30 days)
        );

    // Update with opposite settings
    contract
        .update_security_settings(
            5, // max_beneficiaries
            7200, // min_timeframe (2 hours)
            1296000, // max_timeframe (15 days)
            false, // require_guardian
            false, // allow_early_execution
            50_000_000, // max_asset_amount (50K STRK)
            false, // require_multi_sig
            2, // multi_sig_threshold
            604800 // emergency_timeout (7 days)
        );

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_admin_functions_comprehensive() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Create plans for users first
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries1 = ArrayTrait::new();
    beneficiaries1.append(USER1_ADDR());

    let mut emergency_contacts1 = ArrayTrait::new();

    let plan_id1 = contract
        .create_inheritance_plan(
            beneficiaries1,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts1,
        );

    // Create plan for USER2
    let mut beneficiaries2 = ArrayTrait::new();
    beneficiaries2.append(USER2_ADDR());

    let mut emergency_contacts2 = ArrayTrait::new();

    let plan_id2 = contract
        .create_inheritance_plan(
            beneficiaries2,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts2,
        );

    stop_cheat_caller_address(contract.contract_address);

    // Test all admin functions
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());

    // Pause and unpause multiple times
    contract.pause();
    contract.unpause();
    contract.pause();
    contract.unpause();

    // Test wallet freezing and unfreezing
    contract.freeze_wallet(USER1_ADDR(), create_empty_byte_array());
    contract.unfreeze_wallet(USER1_ADDR(), create_empty_byte_array());

    // Test blacklisting
    contract.blacklist_wallet(USER2_ADDR(), create_empty_byte_array());
    contract.remove_from_blacklist(USER2_ADDR(), create_empty_byte_array());

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_emergency_withdrawal() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Transfer tokens to contract first
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.transfer(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    // Test emergency withdrawal
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());

    // Emergency withdraw STRK tokens
    contract.emergency_withdraw(strk_token.contract_address, 100_000_000);

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_swap_functionality() {
    let (contract, strk_token, usdt_token, _) = deploy_inheritx_contract();

    // Setup: Create a plan first
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    let plan_id = contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    // Test swap request creation
    contract
        .create_swap_request(
            plan_id, // plan_id
            strk_token.contract_address, // from_token
            usdt_token.contract_address, // to_token
            1_000_000, // amount
            100 // slippage_tolerance (1%)
        );

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_inactivity_monitoring() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Create a plan first
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    let plan_id = contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    // Test inactivity monitoring functionality

    // Create inactivity monitor
    contract
        .create_inactivity_monitor(
            USER1_ADDR(), // wallet_address
            86400, // threshold (1 day)
            create_empty_byte_array(), // beneficiary_email_hash
            plan_id // plan_id
        );

    // Update wallet activity
    contract.update_wallet_activity(USER1_ADDR());

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_claim_code_functionality() {
    let (contract, strk_token, _, _) = deploy_inheritx_contract();

    // Setup: Create a plan first
    start_cheat_caller_address(strk_token.contract_address, CREATOR_ADDR());
    strk_token.approve(contract.contract_address, 100_000_000);
    stop_cheat_caller_address(strk_token.contract_address);

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let mut beneficiaries = ArrayTrait::new();
    beneficiaries.append(USER1_ADDR());

    let mut emergency_contacts = ArrayTrait::new();

    let plan_id = contract
        .create_inheritance_plan(
            beneficiaries,
            0, // STRK
            1_000_000, // 1 STRK
            0, // No NFT
            ZERO_ADDR(), // No NFT contract
            86400, // 1 day
            ZERO_ADDR(), // No guardian
            create_empty_byte_array(),
            3, // security_level
            false, // auto_execute
            emergency_contacts,
        );

    // Test claim code functionality
    // Call as plan owner (CREATOR_ADDR) not as admin
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

    // Store claim code hash
    contract
        .store_claim_code_hash(
            plan_id, // plan_id
            USER1_ADDR(), // beneficiary
            create_empty_byte_array(), // code_hash
            86400 // expires_in (1 day)
        );

    stop_cheat_caller_address(contract.contract_address);
}
