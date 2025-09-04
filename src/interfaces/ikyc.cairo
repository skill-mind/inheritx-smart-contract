use core::byte_array::ByteArray;
use starknet::{ClassHash, ContractAddress};
use crate::base::types::*;

#[starknet::interface]
pub trait IInheritXKYC<TContractState> {
    // ================ KYC FUNCTIONS ================

    fn upload_kyc(ref self: TContractState, kyc_hash: ByteArray, user_type: u8);

    fn approve_kyc(
        ref self: TContractState, user_address: ContractAddress, approval_notes: ByteArray,
    );

    fn reject_kyc(
        ref self: TContractState, user_address: ContractAddress, rejection_reason: ByteArray,
    );

    fn get_kyc_data(self: @TContractState, user_address: ContractAddress) -> KYCData;

    fn get_pending_kyc_count(self: @TContractState) -> u256;

    fn verify_beneficiary_identity(
        self: @TContractState,
        plan_id: u256,
        beneficiary_address: ContractAddress,
        email_hash: ByteArray,
        name_hash: ByteArray,
    ) -> bool;

    // ================ ADMIN FUNCTIONS ================

    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);

    fn pause(ref self: TContractState);

    fn unpause(ref self: TContractState);
}
