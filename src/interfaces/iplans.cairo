use core::byte_array::ByteArray;
use starknet::ContractAddress;
use crate::base::types::*;

#[starknet::interface]
pub trait IInheritXPlans<TContractState> {
    // ================ INHERITANCE PLAN FUNCTIONS ================

    fn create_inheritance_plan(
        ref self: TContractState,
        // Step 1: Plan Creation Name & Description
        plan_name: ByteArray,
        plan_description: ByteArray,
        // Step 2: Add Beneficiary (name, relationship, email)
        beneficiary_name: ByteArray,
        beneficiary_relationship: ByteArray,
        beneficiary_email: ByteArray,
        beneficiary_address: ContractAddress,
        // Step 3: Asset Allocation
        asset_type: u8,
        asset_amount: u256,
        // Step 4: Rules for Plan Creation (distribution method)
        distribution_method: u8, // 0: Lump Sum, 1: Quarterly, 2: Yearly, 3: Monthly
        claim_code: ByteArray // Single 6-digit claim code
    ) -> u256;


    fn add_beneficiary_to_plan(
        ref self: TContractState,
        plan_id: u256,
        beneficiary: ContractAddress,
        name: ByteArray,
        email: ByteArray,
        relationship: ByteArray,
    );

    fn remove_beneficiary_from_plan(
        ref self: TContractState, plan_id: u256, beneficiary: ContractAddress, reason: ByteArray,
    );

    fn update_beneficiary_percentages(
        ref self: TContractState, plan_id: u256, beneficiary_data: Array<BeneficiaryData>,
    );

    fn get_beneficiary_percentages(self: @TContractState, plan_id: u256) -> Array<BeneficiaryData>;

    fn get_beneficiaries(self: @TContractState, plan_id: u256) -> Array<Beneficiary>;

    // ================ PLAN QUERY FUNCTIONS ================

    fn get_plan_count(self: @TContractState) -> u256;

    fn get_inheritance_plan(self: @TContractState, plan_id: u256) -> PlanDetails;

    fn get_escrow_details(self: @TContractState, plan_id: u256) -> EscrowAccount;

    fn get_inactivity_monitor(
        self: @TContractState, wallet_address: ContractAddress,
    ) -> InactivityMonitor;

    fn get_beneficiary_count(self: @TContractState, basic_info_id: u256) -> u256;
    fn get_plan_name(self: @TContractState, plan_id: u256) -> ByteArray;
    fn get_plan_description(self: @TContractState, plan_id: u256) -> ByteArray;
    fn get_plan_summary(
        self: @TContractState, plan_id: u256,
    ) -> (ByteArray, ByteArray, u256, AssetType, u64);

    // ================ HELPER FUNCTIONS ================

    fn hash_claim_code(self: @TContractState, code: ByteArray) -> ByteArray;

    // ================ PLAN CREATION FLOW FUNCTIONS ================

    fn create_plan_basic_info(
        ref self: TContractState,
        plan_name: ByteArray,
        plan_description: ByteArray,
        owner_email_hash: ByteArray,
        initial_beneficiary: ContractAddress,
        initial_beneficiary_email: ByteArray,
        claim_code: ByteArray,
    ) -> u256;

    fn set_asset_allocation(
        ref self: TContractState,
        basic_info_id: u256,
        beneficiaries: Array<Beneficiary>,
        asset_allocations: Array<AssetAllocation>,
        claim_codes: Array<ByteArray>,
    );

    fn mark_rules_conditions_set(ref self: TContractState, basic_info_id: u256);

    fn mark_verification_completed(ref self: TContractState, basic_info_id: u256);

    fn mark_preview_ready(ref self: TContractState, basic_info_id: u256);

    fn activate_inheritance_plan(
        ref self: TContractState, basic_info_id: u256, activation_confirmation: ByteArray,
    );

    // ================ PLAN MANAGEMENT FUNCTIONS ================

    fn extend_plan_timeframe(ref self: TContractState, plan_id: u256, additional_time: u64);

    fn update_plan_parameters(
        ref self: TContractState,
        plan_id: u256,
        new_security_level: u8,
        new_auto_execute: bool,
        new_guardian: ContractAddress,
    );

    fn update_inactivity_threshold(ref self: TContractState, plan_id: u256, new_threshold: u64);

    // ================ UNIFIED DISTRIBUTION FUNCTIONS ================

    fn create_distribution_plan(
        ref self: TContractState,
        distribution_method: u8, // 0: LumpSum, 1: Quarterly, 2: Yearly, 3: Monthly
        total_amount: u256,
        period_amount: u256,
        start_date: u64,
        end_date: u64,
        beneficiaries: Array<DisbursementBeneficiary>,
    ) -> u256;

    fn execute_distribution(ref self: TContractState, plan_id: u256);

    fn pause_distribution(ref self: TContractState, plan_id: u256, reason: ByteArray);

    fn resume_distribution(ref self: TContractState, plan_id: u256);

    fn get_distribution_status(self: @TContractState, plan_id: u256) -> DistributionPlan;

    // ================ INACTIVITY MONITORING FUNCTIONS ================

    fn create_inactivity_monitor(
        ref self: TContractState,
        wallet_address: ContractAddress,
        threshold: u64,
        beneficiary_email_hash: ByteArray,
        plan_id: u256,
    );

    fn update_wallet_activity(ref self: TContractState, wallet_address: ContractAddress);

    fn check_inactivity_status(self: @TContractState, plan_id: u256) -> bool;

    // ================ SECURITY FUNCTIONS ================

    fn get_security_settings(self: @TContractState) -> SecuritySettings;

    fn update_security_settings(
        ref self: TContractState,
        max_beneficiaries: u8,
        min_timeframe: u64,
        max_timeframe: u64,
        require_guardian: bool,
        allow_early_execution: bool,
        max_asset_amount: u256,
        require_multi_sig: bool,
        multi_sig_threshold: u8,
        emergency_timeout: u64,
    );
}
