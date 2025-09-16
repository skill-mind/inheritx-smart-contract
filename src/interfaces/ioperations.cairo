use core::byte_array::ByteArray;
use starknet::{ClassHash, ContractAddress};
use crate::base::types::*;

#[starknet::interface]
pub trait IInheritXOperations<TContractState> {
    // ================ SWAP FUNCTIONS ================

    fn swap_tokens(
        ref self: TContractState,
        from_token: ContractAddress,
        to_token: ContractAddress,
        amount: u256,
        min_amount_out: u256,
    ) -> u256;

    fn create_swap_request(
        ref self: TContractState,
        plan_id: u256,
        from_token: ContractAddress,
        to_token: ContractAddress,
        amount: u256,
        slippage_tolerance: u256,
    );

    fn execute_swap(ref self: TContractState, swap_id: u256);

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

    // ================ SECURITY FUNCTIONS ================

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

    // ================ FEE FUNCTIONS ================

    fn update_fee_config(
        ref self: TContractState, new_fee_percentage: u256, new_fee_recipient: ContractAddress,
    );

    fn get_fee_config(self: @TContractState) -> FeeConfig;

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

    // ================ EMERGENCY FUNCTIONS ================

    fn emergency_withdraw(ref self: TContractState, token_address: ContractAddress, amount: u256);

    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);

    fn pause(ref self: TContractState);

    fn unpause(ref self: TContractState);

    // ================ QUERY FUNCTIONS ================

    fn get_swap_request(self: @TContractState, swap_id: u256) -> SwapRequest;

    fn get_escrow_account(self: @TContractState, escrow_id: u256) -> EscrowAccount;

    fn get_withdrawal_request(self: @TContractState, request_id: u256) -> WithdrawalRequest;

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
