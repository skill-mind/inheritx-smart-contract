use core::byte_array::ByteArray;
use starknet::{ClassHash, ContractAddress};
use crate::base::types::*;

#[starknet::interface]
pub trait IInheritXClaim<TContractState> {
    // ================ CLAIM CODE FUNCTIONS ================

    fn store_claim_code_hash(
        ref self: TContractState,
        plan_id: u256,
        beneficiary: ContractAddress,
        code_hash: ByteArray,
        expires_in: u64,
    );

    fn generate_encrypted_claim_code(
        ref self: TContractState,
        plan_id: u256,
        beneficiary: ContractAddress,
        beneficiary_public_key: ByteArray,
        expires_in: u64,
    ) -> ByteArray;

    fn claim_inheritance(ref self: TContractState, plan_id: u256, claim_code: ByteArray);

    fn verify_beneficiary_identity(
        self: @TContractState,
        plan_id: u256,
        beneficiary_address: ContractAddress,
        email_hash: ByteArray,
        name_hash: ByteArray,
    ) -> bool;

    fn get_claim_code(self: @TContractState, code_hash: ByteArray) -> ClaimCode;

    fn hash_claim_code(self: @TContractState, code: ByteArray) -> ByteArray;

    // ================ ADMIN FUNCTIONS ================

    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);

    fn pause(ref self: TContractState);

    fn unpause(ref self: TContractState);
}
