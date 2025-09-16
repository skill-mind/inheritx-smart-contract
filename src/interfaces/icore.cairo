use core::byte_array::ByteArray;
use starknet::{ClassHash, ContractAddress};
use crate::base::types::*;

#[starknet::interface]
pub trait IInheritXCore<TContractState> {
    // ================ INHERITANCE PLAN FUNCTIONS ================

    fn create_inheritance_plan(
        ref self: TContractState,
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
    ) -> u256;

    fn create_inheritance_plan_with_percentages(
        ref self: TContractState,
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

    // ================ SWAP FUNCTIONS ================

    fn create_swap_request(
        ref self: TContractState,
        plan_id: u256,
        from_token: ContractAddress,
        to_token: ContractAddress,
        amount: u256,
        slippage_tolerance: u256,
    );

    fn execute_swap(ref self: TContractState, swap_id: u256);

    // ================ BENEFICIARY FUNCTIONS ================

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

    // ================ ESCROW FUNCTIONS ================

    fn lock_assets_in_escrow(
        ref self: TContractState, escrow_id: u256, fees: u256, tax_liability: u256,
    );

    fn release_assets_from_escrow(
        ref self: TContractState,
        escrow_id: u256,
        beneficiary: ContractAddress,
        release_reason: ByteArray,
    );

    // ================ INACTIVITY FUNCTIONS ================

    fn create_inactivity_monitor(
        ref self: TContractState,
        wallet_address: ContractAddress,
        threshold: u64,
        beneficiary_email_hash: ByteArray,
        plan_id: u256,
    );

    fn update_wallet_activity(ref self: TContractState, wallet_address: ContractAddress);

    fn check_inactivity_status(self: @TContractState, plan_id: u256) -> bool;

    // ================ QUERY FUNCTIONS ================

    fn get_beneficiaries(self: @TContractState, plan_id: u256) -> Array<Beneficiary>;

    fn get_escrow_details(self: @TContractState, plan_id: u256) -> EscrowAccount;

    fn get_inactivity_monitor(
        self: @TContractState, wallet_address: ContractAddress,
    ) -> InactivityMonitor;

    fn get_plan_count(self: @TContractState) -> u256;

    fn get_escrow_count(self: @TContractState) -> u256;

    fn get_inheritance_plan(self: @TContractState, plan_id: u256) -> InheritancePlan;

    // ================ ADMIN FUNCTIONS ================

    fn freeze_wallet(ref self: TContractState, wallet: ContractAddress, reason: ByteArray);

    fn unfreeze_wallet(ref self: TContractState, wallet: ContractAddress, reason: ByteArray);

    fn blacklist_wallet(ref self: TContractState, wallet: ContractAddress, reason: ByteArray);

    fn remove_from_blacklist(ref self: TContractState, wallet: ContractAddress, reason: ByteArray);

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

    fn get_security_settings(self: @TContractState) -> SecuritySettings;

    fn emergency_withdraw(ref self: TContractState, token_address: ContractAddress, amount: u256);

    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);

    fn pause(ref self: TContractState);

    fn unpause(ref self: TContractState);

    // ================ MONTHLY DISBURSEMENT FUNCTIONS ================

    fn create_monthly_disbursement_plan(
        ref self: TContractState,
        total_amount: u256,
        monthly_amount: u256,
        start_month: u64,
        end_month: u64,
        beneficiaries: Array<DisbursementBeneficiary>,
    ) -> u256;

    fn execute_monthly_disbursement(ref self: TContractState, plan_id: u256);

    fn pause_monthly_disbursement(ref self: TContractState, plan_id: u256, reason: ByteArray);

    fn resume_monthly_disbursement(ref self: TContractState, plan_id: u256);

    fn get_distribution_status(self: @TContractState, plan_id: u256) -> DistributionPlan;

    // ================ PLAN CREATION FLOW FUNCTIONS ================

    fn create_plan_basic_info(
        ref self: TContractState,
        plan_name: ByteArray,
        plan_description: ByteArray,
        owner_email_hash: ByteArray,
        initial_beneficiary: ContractAddress,
        initial_beneficiary_email: ByteArray,
    ) -> u256;

    fn set_asset_allocation(
        ref self: TContractState,
        basic_info_id: u256,
        beneficiaries: Array<Beneficiary>,
        asset_allocations: Array<AssetAllocation>,
    );

    fn mark_rules_conditions_set(ref self: TContractState, basic_info_id: u256);

    fn mark_verification_completed(ref self: TContractState, basic_info_id: u256);

    fn mark_preview_ready(ref self: TContractState, basic_info_id: u256);

    fn activate_inheritance_plan(
        ref self: TContractState, basic_info_id: u256, activation_confirmation: ByteArray,
    );

    // ================ PLAN EDITING FUNCTIONS ================

    fn extend_plan_timeframe(ref self: TContractState, plan_id: u256, additional_time: u64);

    fn update_plan_parameters(
        ref self: TContractState,
        plan_id: u256,
        new_security_level: u8,
        new_auto_execute: bool,
        new_guardian: ContractAddress,
    );

    fn update_inactivity_threshold(ref self: TContractState, plan_id: u256, new_threshold: u64);

    fn get_beneficiary_count(self: @TContractState, basic_info_id: u256) -> u256;

    // ================ FEE MANAGEMENT FUNCTIONS ================

    fn update_fee_config(
        ref self: TContractState, new_fee_percentage: u256, new_fee_recipient: ContractAddress,
    );

    fn get_fee_config(self: @TContractState) -> FeeConfig;

    fn calculate_fee(self: @TContractState, amount: u256) -> u256;

    fn collect_fee(
        ref self: TContractState, plan_id: u256, beneficiary: ContractAddress, gross_amount: u256,
    ) -> u256;

    // ================ WITHDRAWAL FUNCTIONS ================

    fn create_withdrawal_request(
        ref self: TContractState,
        plan_id: u256,
        asset_type: u8,
        withdrawal_type: u8,
        amount: u256,
        nft_token_id: u256,
        nft_contract: ContractAddress,
    ) -> u256;

    fn approve_withdrawal_request(ref self: TContractState, request_id: u256);

    fn process_withdrawal_request(ref self: TContractState, request_id: u256);

    fn reject_withdrawal_request(ref self: TContractState, request_id: u256, reason: ByteArray);

    fn cancel_withdrawal_request(ref self: TContractState, request_id: u256, reason: ByteArray);

    fn get_withdrawal_request(self: @TContractState, request_id: u256) -> WithdrawalRequest;

    fn get_beneficiary_withdrawal_requests(
        self: @TContractState, beneficiary: ContractAddress, limit: u256,
    ) -> Array<u256>;

    // ================ STATISTICS AND QUERY FUNCTIONS ================

    fn get_total_fees_collected(self: @TContractState) -> u256;

    fn get_plan_fees_collected(self: @TContractState, plan_id: u256) -> u256;

    fn get_withdrawal_request_count(self: @TContractState) -> u256;

    fn get_beneficiary_withdrawal_count(
        self: @TContractState, beneficiary: ContractAddress,
    ) -> u256;

    fn is_fee_active(self: @TContractState) -> bool;

    fn get_fee_percentage(self: @TContractState) -> u256;

    fn get_fee_recipient(self: @TContractState) -> ContractAddress;

    fn toggle_fee_collection(ref self: TContractState, is_active: bool);

    fn update_fee_limits(ref self: TContractState, new_min_fee: u256, new_max_fee: u256);
}
