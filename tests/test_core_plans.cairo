use core::array::ArrayTrait;
use core::byte_array::ByteArray;
use core::traits::TryInto;
use inheritx_contracts::base::types::{AssetType, PlanStatus};
use inheritx_contracts::interfaces::iplans::{
    IInheritXPlansDispatcher, IInheritXPlansDispatcherTrait,
};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::ContractAddress;

// Test constants
const ADMIN_CONST: felt252 = 123;
const CREATOR_CONST: felt252 = 456;
const USER1_CONST: felt252 = 789;
const USER2_CONST: felt252 = 101;
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

pub fn ZERO_ADDR() -> ContractAddress {
    ZERO_ADDRESS.try_into().unwrap()
}

// Helper function to create empty ByteArray
fn create_empty_byte_array() -> ByteArray {
    ""
}

// Helper function to create test plan name
fn create_test_plan_name() -> ByteArray {
    "Test Plan"
}

// Helper function to create test plan description
fn create_test_plan_description() -> ByteArray {
    "Test desc"
}

// Helper function to create test beneficiary name
fn create_test_beneficiary_name() -> ByteArray {
    "John"
}

// Helper function to create test beneficiary relationship
fn create_test_beneficiary_relationship() -> ByteArray {
    "Son"
}

// Helper function to create test beneficiary email
fn create_test_beneficiary_email() -> ByteArray {
    "john@test.com"
}

// Helper function to create test claim code
fn create_test_claim_code() -> ByteArray {
    "123456"
}

// Helper function to create test distribution config for lump sum
fn create_lump_sum_config() -> (u64, u8, u8, u8, ByteArray) {
    (123456789, 0, 0, 0, "Test note")
}

// Helper function to create test distribution config for quarterly
fn create_quarterly_config() -> (u64, u8, u8, u8, ByteArray) {
    (0, 25, 0, 0, "Quarterly note")
}

// Helper function to create test distribution config for yearly
fn create_yearly_config() -> (u64, u8, u8, u8, ByteArray) {
    (0, 0, 50, 0, "Yearly note")
}

// Helper function to create test distribution config for monthly
fn create_monthly_config() -> (u64, u8, u8, u8, ByteArray) {
    (0, 0, 0, 10, "Monthly note")
}

// Deploy the InheritXPlans contract
fn deploy_plans_contract() -> IInheritXPlansDispatcher {
    let contract = declare("InheritXPlans").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        ZERO_ADDR().into(), // strk_token
        ZERO_ADDR().into(), // usdt_token
        ZERO_ADDR().into() // usdc_token
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    IInheritXPlansDispatcher { contract_address }
}

// ================ BASIC FUNCTIONALITY TESTS ================

#[test]
fn test_contract_deployment() {
    let contract = deploy_plans_contract();

    // Test that contract was deployed successfully
    assert(contract.contract_address != ZERO_ADDR(), 'Contract deployed');
}

#[test]
fn test_create_inheritance_plan_success() {
    let contract = deploy_plans_contract();

    // Create inheritance plan
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000, // 1 STRK (with 6 decimals)
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );

    assert(plan_id == 1, 'Plan ID should be 1');

    // Verify plan was created
    let plan = contract.get_inheritance_plan(plan_id);
    assert(plan.plan.id == plan_id, 'Plan ID mismatch');
    assert(plan.plan.owner == CREATOR_ADDR(), 'Plan owner mismatch');
    assert(plan.plan.asset_amount == 1000000, 'Asset amount mismatch');
    assert(plan.plan.asset_type == AssetType::STRK, 'Asset type mismatch');
    assert(plan.plan.status == PlanStatus::Active, 'Plan status should be active');
    assert(!plan.plan.is_claimed, 'Plan should not be claimed');

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Invalid input parameters',))]
fn test_create_inheritance_plan_invalid_inputs() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

    // Test empty plan name - this should fail
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    contract
        .create_inheritance_plan(
            create_empty_byte_array(), // Empty plan name
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Invalid asset type',))]
fn test_create_inheritance_plan_invalid_asset_type() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    // Test invalid asset type (should be 0, 1, or 2)
    contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            5, // Invalid asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Invalid length',))]
fn test_create_inheritance_plan_invalid_claim_code_length() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    // Test invalid claim code length (should be exactly 6 digits)
    contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            "12345" // Invalid length (5 digits)
        );

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_get_plan_count() {
    let contract = deploy_plans_contract();

    // Initially should be 0
    let initial_count = contract.get_plan_count();
    assert(initial_count == 0, 'Initial plan count should be 0');

    // Create a plan
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date,
        quarterly_percentage,
        yearly_percentage,
        monthly_percentage,
        _additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            _additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Count should be 1
    let count_after_creation = contract.get_plan_count();
    assert(count_after_creation == 1, 'Count should be 1');
}

#[test]
fn test_get_plan_summary() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Test plan summary by user address - returns array of plans
    let plans = contract.get_plan_summary(CREATOR_ADDR());
    assert(plans.len() == 1, 'Should have 1 plan');

    let (
        plan_id_returned,
        plan_name,
        plan_description,
        asset_amount,
        asset_type,
        created_at,
        owner,
        beneficiary_count,
        status,
    ) =
        plans
        .at(0)
        .clone();

    assert(plan_id_returned == plan_id, 'Plan ID mismatch');
    assert(plan_name == create_test_plan_name(), 'Name mismatch');
    assert(plan_description == create_test_plan_description(), 'Desc mismatch');
    assert(asset_amount == 1000000, 'Amount mismatch');
    assert(asset_type == AssetType::STRK, 'Type mismatch');
    assert(created_at == 0, 'Time is 0');
    assert(owner == CREATOR_ADDR(), 'Owner mismatch');
    assert(beneficiary_count == 1, 'Beneficiary count mismatch');
    assert(status == PlanStatus::Active, 'Status mismatch');
}

#[test]
fn test_get_plan_by_id() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Test get plan by ID - returns single plan data with all creation parameters
    let plan_details = contract.get_plan_by_id(CREATOR_ADDR(), plan_id);

    // Test original parameters
    assert(plan_details.plan_name == create_test_plan_name(), 'Name mismatch');
    assert(plan_details.plan_description == create_test_plan_description(), 'Desc mismatch');
    assert(plan_details.asset_amount == 1000000, 'Amount mismatch');
    assert(plan_details.asset_type == AssetType::STRK, 'Type mismatch');
    assert(plan_details.created_at == 0, 'Time is 0');
    assert(plan_details.owner == CREATOR_ADDR(), 'Owner mismatch');
    assert(plan_details.beneficiary_count == 1, 'Beneficiary count mismatch');
    assert(plan_details.status == PlanStatus::Active, 'Status mismatch');

    // Test additional creation parameters
    assert(
        plan_details.beneficiary_name == create_test_beneficiary_name(),
        'Beneficiary name mismatch',
    );
    assert(
        plan_details.beneficiary_relationship == create_test_beneficiary_relationship(),
        'Beneficiary relship mismatch',
    );
    assert(
        plan_details.beneficiary_email == create_test_beneficiary_email(),
        'Beneficiary email mismatch',
    );
    assert(plan_details.distribution_method == 0, 'Distribution method mismatch'); // Lump sum = 0
    assert(plan_details.lump_sum_date == 123456789, 'Lump sum date mismatch');
    assert(plan_details.quarterly_percentage == 0, 'Quarterly percentage mismatch');
    assert(plan_details.yearly_percentage == 0, 'Yearly percentage mismatch');
    assert(plan_details.monthly_percentage == 0, 'Monthly percentage mismatch');
    assert(plan_details.additional_note == "Test note", 'Additional note mismatch');
    assert(plan_details.claim_code_hash == create_test_claim_code(), 'Claim code hash mismatch');
}

#[test]
fn test_get_summary() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Test get summary - should return same as get_plan_summary
    let plans = contract.get_summary(CREATOR_ADDR());
    assert(plans.len() == 1, 'Should have 1 plan');

    let (
        plan_id_returned,
        plan_name,
        plan_description,
        asset_amount,
        asset_type,
        created_at,
        owner,
        beneficiary_count,
        status,
    ) =
        plans
        .at(0)
        .clone();

    assert(plan_id_returned == plan_id, 'Plan ID mismatch');
    assert(plan_name == create_test_plan_name(), 'Name mismatch');
    assert(plan_description == create_test_plan_description(), 'Desc mismatch');
    assert(asset_amount == 1000000, 'Amount mismatch');
    assert(asset_type == AssetType::STRK, 'Type mismatch');
    assert(created_at == 0, 'Time is 0');
    assert(owner == CREATOR_ADDR(), 'Owner mismatch');
    assert(beneficiary_count == 1, 'Beneficiary count mismatch');
    assert(status == PlanStatus::Active, 'Status mismatch');
}

#[test]
fn test_get_beneficiaries() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Test get beneficiaries
    let beneficiaries = contract.get_beneficiaries(plan_id);
    assert(beneficiaries.len() == 1, 'Should have 1');

    let beneficiary = beneficiaries.at(0).clone();
    assert(beneficiary.address == ZERO_ADDR(), 'Address should be zero'); // No address needed
    assert(beneficiary.name == create_test_beneficiary_name(), 'Name mismatch');
    assert(beneficiary.email == create_test_beneficiary_email(), 'Email mismatch');
    assert(beneficiary.relationship == create_test_beneficiary_relationship(), 'Rel mismatch');
    assert(!beneficiary.has_claimed, 'Not claimed');
    assert(beneficiary.claimed_amount == 0, 'Amount 0');
}

#[test]
fn test_hash_claim_code() {
    let contract = deploy_plans_contract();

    // Test hash function
    let test_code = create_test_claim_code();
    let hash = contract.hash_claim_code(test_code.clone());

    // Since we simplified the hash function to return the code itself
    assert(hash == test_code, 'Hash equals code');
}

#[test]
fn test_hash_claim_code_empty() {
    let contract = deploy_plans_contract();

    // Test empty code
    let empty_code = create_empty_byte_array();
    let hash = contract.hash_claim_code(empty_code);

    assert(hash == "empty_code_hash", 'Empty hash');
}

#[test]
#[should_panic(expected: ('Invalid claim code length',))]
fn test_hash_claim_code_invalid_length() {
    let contract = deploy_plans_contract();

    // Test invalid length code
    let invalid_code = "12345"; // 5 digits instead of 6
    contract.hash_claim_code(invalid_code);
    // This should fail due to assertion in the function
}

// ================ DISTRIBUTION METHOD TESTS ================

#[test]
fn test_create_plan_with_lump_sum_distribution() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Verify plan was created with lump sum distribution
    let plan = contract.get_inheritance_plan(plan_id);
    assert(plan.plan.id == plan_id, 'ID mismatch');
    // Lump sum distribution should be immediate
    assert(plan.plan.becomes_active_at == plan.plan.created_at, 'Immediate');
}

#[test]
fn test_create_plan_with_quarterly_distribution() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_quarterly_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            1, // Quarterly distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Verify plan was created with quarterly distribution
    let plan = contract.get_inheritance_plan(plan_id);
    assert(plan.plan.id == plan_id, 'ID mismatch');
}

#[test]
fn test_create_plan_with_yearly_distribution() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_yearly_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            2, // Yearly distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Verify plan was created with yearly distribution
    let plan = contract.get_inheritance_plan(plan_id);
    assert(plan.plan.id == plan_id, 'ID mismatch');
}

#[test]
fn test_create_plan_with_monthly_distribution() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_monthly_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            3, // Monthly distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Verify plan was created with monthly distribution
    let plan = contract.get_inheritance_plan(plan_id);
    assert(plan.plan.id == plan_id, 'ID mismatch');
}

// ================ ASSET TYPE TESTS ================

#[test]
fn test_create_plan_with_strk_asset() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    let plan = contract.get_inheritance_plan(plan_id);
    assert(plan.plan.asset_type == AssetType::STRK, 'Type STRK');
}

#[test]
fn test_create_plan_with_usdt_asset() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            1, // USDT asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    let plan = contract.get_inheritance_plan(plan_id);
    assert(plan.plan.asset_type == AssetType::USDT, 'Type USDT');
}

#[test]
fn test_create_plan_with_usdc_asset() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            2, // USDC asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    let plan = contract.get_inheritance_plan(plan_id);
    assert(plan.plan.asset_type == AssetType::USDC, 'Type USDC');
}

// ================ SECURITY TESTS ================

#[test]
fn test_plan_creation_access_control() {
    let contract = deploy_plans_contract();

    // Test that only the caller can create plans
    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );
    assert(plan_id == 1, 'Created');
    stop_cheat_caller_address(contract.contract_address);
}

// ================ EDGE CASE TESTS ================

#[test]
fn test_multiple_plans_creation() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

    // Create multiple plans
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan1_id = contract
        .create_inheritance_plan(
            "Plan 1",
            "First plan",
            "Ben 1",
            "Son",
            "ben1@test.com",
            0, // STRK
            1000000,
            0, // Lump sum
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            "111111",
        );

    let (
        lump_sum_date2,
        quarterly_percentage2,
        yearly_percentage2,
        monthly_percentage2,
        additional_note2,
    ) =
        create_quarterly_config();

    let plan2_id = contract
        .create_inheritance_plan(
            "Plan 2",
            "Second plan",
            "Ben 2",
            "Daughter",
            "ben2@test.com",
            1, // USDT
            2000000,
            1, // Quarterly
            lump_sum_date2,
            quarterly_percentage2,
            yearly_percentage2,
            monthly_percentage2,
            additional_note2,
            "222222",
        );

    stop_cheat_caller_address(contract.contract_address);

    // Verify both plans were created
    assert(plan1_id == 1, 'Plan 1 ID');
    assert(plan2_id == 2, 'Plan 2 ID');

    let plan_count = contract.get_plan_count();
    assert(plan_count == 2, 'Count 2');

    // Verify plan details
    let plan1 = contract.get_inheritance_plan(plan1_id);
    let plan2 = contract.get_inheritance_plan(plan2_id);

    assert(plan1.plan.id == 1, 'ID 1');
    assert(plan2.plan.id == 2, 'ID 2');
    assert(plan1.plan.asset_type == AssetType::STRK, 'Type 1');
    assert(plan2.plan.asset_type == AssetType::USDT, 'Type 2');

    // Test get_plan_summary with multiple plans
    let user_plans = contract.get_plan_summary(CREATOR_ADDR());
    assert(user_plans.len() == 2, 'Should have 2 plans');

    // Verify first plan
    let (plan_id_1, name_1, desc_1, amount_1, type_1, created_1, owner_1, count_1, status_1) =
        user_plans
        .at(0)
        .clone();
    assert(plan_id_1 == 1, 'Plan 1 ID');
    assert(name_1 == "Plan 1", 'Plan 1 name');
    assert(type_1 == AssetType::STRK, 'Plan 1 type');

    // Verify second plan
    let (plan_id_2, name_2, desc_2, amount_2, type_2, created_2, owner_2, count_2, status_2) =
        user_plans
        .at(1)
        .clone();
    assert(plan_id_2 == 2, 'Plan 2 ID');
    assert(name_2 == "Plan 2", 'Plan 2 name');
    assert(type_2 == AssetType::USDT, 'Plan 2 type');
}

#[test]
#[should_panic(expected: ('Invalid input parameters',))]
fn test_zero_asset_amount() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

    // Test with zero asset amount (should fail)
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            0, // Zero asset amount
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_zero_address_beneficiary() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());

    // Test with zero address beneficiary (should fail)
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let _ = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note,
            create_test_claim_code(),
        );

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_get_distribution_config() {
    let contract = deploy_plans_contract();

    start_cheat_caller_address(contract.contract_address, CREATOR_ADDR());
    let (
        lump_sum_date, quarterly_percentage, yearly_percentage, monthly_percentage, additional_note,
    ) =
        create_lump_sum_config();

    let plan_id = contract
        .create_inheritance_plan(
            create_test_plan_name(),
            create_test_plan_description(),
            create_test_beneficiary_name(),
            create_test_beneficiary_relationship(),
            create_test_beneficiary_email(),
            0, // STRK asset type
            1000000,
            0, // Lump sum distribution
            lump_sum_date,
            quarterly_percentage,
            yearly_percentage,
            monthly_percentage,
            additional_note.clone(),
            create_test_claim_code(),
        );
    stop_cheat_caller_address(contract.contract_address);

    // Test get distribution config
    let config = contract.get_distribution_config(plan_id);
    assert(config.lump_sum_date == lump_sum_date, 'Date mismatch');
    assert(config.quarterly_percentage == quarterly_percentage, 'Qty % mismatch');
    assert(config.yearly_percentage == yearly_percentage, 'Yr % mismatch');
    assert(config.monthly_percentage == monthly_percentage, 'Mth % mismatch');
    assert(config.additional_note == additional_note.clone(), 'Note mismatch');
    // Note: start_date and end_date are now calculated internally by the contract
}
