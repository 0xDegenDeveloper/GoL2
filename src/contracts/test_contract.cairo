use starknet::ContractAddress;

#[starknet::interface]
trait ITestTrait<TContractState> {
    fn total_supply(self: @TContractState) -> u256;
    fn x(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod TestContract {
    use debug::PrintTrait;

    use starknet::{get_caller_address, ContractAddress, ClassHash};
    #[constructor]
    fn constructor(ref self: ContractState) {}
    #[storage]
    struct Storage {
        ERC20_total_supply: u256,
        x: felt252,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}
    #[external(v0)]
    impl TestImpl of super::ITestTrait<ContractState> {
        fn total_supply(self: @ContractState) -> u256 {
            self.ERC20_total_supply.read()
        }
        fn x(self: @ContractState) -> felt252 {
            self.x.read()
        }
    }
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState) {
            self.x.write(123);
        }
    }
}

