#[starknet::contract]
pub mod STARKTOKEN {
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::{
        ContractAddress, contract_address_const, get_caller_address, get_contract_address,
    };

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v1)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        initial_supply: ContractAddress,
        recipient: ContractAddress,
        decimals: u8,
    ) {
        self.erc20.initializer("STARKTOKEN", "STRK", decimals, initial_supply, recipient);
    }

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20ABIImpl = ERC20ABIDispatcher<ContractState>;
}
