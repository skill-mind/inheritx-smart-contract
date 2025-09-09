#[starknet::contract]
pub mod InheritXKYC {
    use core::array::ArrayTrait;
    use core::byte_array::ByteArray;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ClassHash, ContractAddress, get_block_timestamp, get_caller_address};
    use crate::base::errors::*;
    use crate::base::events::*;
    use crate::base::types::*;
    use crate::interfaces::ikyc::IInheritXKYC;

    // Constants
    const ZERO_ADDRESS: ContractAddress = 0.try_into().unwrap();

    // ================ TRAITS ================

    #[generate_trait]
    pub trait KYCSecurityTrait {
        fn assert_not_paused(self: @ContractState);
        fn assert_only_admin(self: @ContractState);
        fn u8_to_user_type(user_type: u8) -> UserType;
    }

    // Components
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);

    // Implementations
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        // Core contract state
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        // Admin and configuration
        admin: ContractAddress,
        // KYC management
        kyc_data: Map<ContractAddress, KYCData>,
        pending_kyc_count: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        // KYC events
        KYCUploaded: KYCUploaded,
        KYCApproved: KYCApproved,
        KYCRejected: KYCRejected,
        BeneficiaryIdentityVerified: BeneficiaryIdentityVerified,
    }

    #[constructor]
    pub fn constructor(ref self: ContractState, admin: ContractAddress) {
        assert(admin != ZERO_ADDRESS, ERR_ZERO_ADDRESS);
        self.admin.write(admin);
        self.pending_kyc_count.write(0);
    }

    impl SecurityImpl of KYCSecurityTrait {
        fn assert_not_paused(self: @ContractState) {
            self.pausable.assert_not_paused();
        }

        fn assert_only_admin(self: @ContractState) {
            let caller = get_caller_address();
            let admin = self.admin.read();
            assert(caller == admin, ERR_UNAUTHORIZED);
        }

        fn u8_to_user_type(user_type: u8) -> UserType {
            if user_type == 0 {
                UserType::AssetOwner
            } else {
                UserType::Beneficiary
            }
        }
    }

    #[abi(embed_v0)]
    impl InheritXKYC of IInheritXKYC<ContractState> {
        fn upload_kyc(ref self: ContractState, kyc_hash: ByteArray, user_type: u8) {
            self.assert_not_paused();
            assert(user_type < 2, ERR_INVALID_USER_TYPE);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            let kyc_data = KYCData {
                user_address: caller,
                kyc_hash: kyc_hash.clone(),
                user_type: SecurityImpl::u8_to_user_type(user_type),
                status: KYCStatus::Pending,
                uploaded_at: current_time,
                approved_at: 0,
                approved_by: ZERO_ADDRESS,
                verification_score: 0,
                fraud_risk: 0,
                documents_count: 1,
                last_updated: current_time,
                expiry_date: 0,
            };

            self.kyc_data.write(caller, kyc_data);
            let current_count = self.pending_kyc_count.read();
            self.pending_kyc_count.write(current_count + 1);

            // Emit KYCUploaded event
            self
                .emit(
                    KYCUploaded {
                        user_address: caller,
                        kyc_hash: kyc_hash,
                        user_type: user_type,
                        uploaded_at: current_time,
                        documents_count: 1,
                        verification_score: 0,
                        fraud_risk: 0,
                    },
                );
        }

        fn approve_kyc(
            ref self: ContractState, user_address: ContractAddress, approval_notes: ByteArray,
        ) {
            self.assert_only_admin();
            self.assert_not_paused();

            let mut kyc_data = self.kyc_data.read(user_address);
            assert(kyc_data.status == KYCStatus::Pending, ERR_KYC_ALREADY_APPROVED);

            kyc_data.status = KYCStatus::Approved;
            kyc_data.approved_at = get_block_timestamp();
            kyc_data.approved_by = get_caller_address();

            self.kyc_data.write(user_address, kyc_data);

            // Decrease pending count
            let current_count = self.pending_kyc_count.read();
            self.pending_kyc_count.write(current_count - 1);

            // Read the data again to avoid move issues
            let approved_kyc_data = self.kyc_data.read(user_address);
            // Emit KYCApproved event
            self
                .emit(
                    KYCApproved {
                        user_address,
                        approved_by: get_caller_address(),
                        approved_at: approved_kyc_data.approved_at,
                        approval_notes,
                        final_verification_score: approved_kyc_data.verification_score,
                    },
                );
        }

        fn reject_kyc(
            ref self: ContractState, user_address: ContractAddress, rejection_reason: ByteArray,
        ) {
            self.assert_only_admin();
            self.assert_not_paused();

            let mut kyc_data = self.kyc_data.read(user_address);
            assert(kyc_data.status == KYCStatus::Pending, ERR_KYC_ALREADY_REJECTED);

            kyc_data.status = KYCStatus::Rejected;
            self.kyc_data.write(user_address, kyc_data);

            // Decrease pending count
            let current_count = self.pending_kyc_count.read();
            self.pending_kyc_count.write(current_count - 1);

            // Read the data again to avoid move issues
            let rejected_kyc_data = self.kyc_data.read(user_address);
            // Emit KYCRejected event
            self
                .emit(
                    KYCRejected {
                        user_address,
                        rejected_by: get_caller_address(),
                        rejected_at: get_block_timestamp(),
                        rejection_reason,
                        fraud_risk_score: rejected_kyc_data.fraud_risk,
                    },
                );
        }

        fn get_kyc_data(self: @ContractState, user_address: ContractAddress) -> KYCData {
            self.kyc_data.read(user_address)
        }

        fn get_pending_kyc_count(self: @ContractState) -> u256 {
            self.pending_kyc_count.read()
        }

        fn emit_beneficiary_identity_verified(
            ref self: ContractState,
            plan_id: u256,
            beneficiary_address: ContractAddress,
            verification_method: ByteArray,
            verification_score: u8,
        ) {
            self.assert_not_paused();

            // Emit BeneficiaryIdentityVerified event
            self
                .emit(
                    BeneficiaryIdentityVerified {
                        plan_id,
                        beneficiary: beneficiary_address,
                        verified_at: get_block_timestamp(),
                        verification_method,
                        verification_score,
                    },
                );
        }

        fn verify_beneficiary_identity(
            self: @ContractState,
            plan_id: u256,
            beneficiary_address: ContractAddress,
            email_hash: ByteArray,
            name_hash: ByteArray,
        ) -> bool {
            let kyc_data = self.kyc_data.read(beneficiary_address);

            // Ensure beneficiary has approved KYC status
            if kyc_data.status != KYCStatus::Approved {
                return false;
            }

            // Verify email hash matches (simplified for this example)
            if kyc_data.kyc_hash != email_hash {
                return false;
            }

            // Note: BeneficiaryIdentityVerified event should be emitted by the calling contract
            // since this is a view function and cannot emit events

            true
        }

        // ================ ADMIN FUNCTIONS ================

        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.assert_only_admin();
            self.upgradeable.upgrade(new_class_hash);
        }

        fn pause(ref self: ContractState) {
            self.assert_only_admin();
            self.pausable.pause();
        }

        fn unpause(ref self: ContractState) {
            self.assert_only_admin();
            self.pausable.unpause();
        }
    }
}
