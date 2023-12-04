use starknet::{contract_address_const, ClassHash};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions
};
use gol2::{
    contracts::gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
    utils::{
        math::raise_to_power,
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, CREATE_CREDIT_REQUIREMENT,
            GIVE_LIFE_CREDIT_REQUIREMENT
        },
    }
};
use openzeppelin::{
    access::ownable::{OwnableComponent, interface::{IOwnableDispatcher, IOwnableDispatcherTrait}},
    upgrades::{
        UpgradeableComponent,
        interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait}
    },
    token::erc20::{ERC20Component, ERC20ABIDispatcher, ERC20ABIDispatcherTrait},
};
use debug::PrintTrait;

/// Setup
fn deploy_contract(name: felt252) -> IGoL2Dispatcher {
    let contract = declare(name);
    let contract_address = contract.deploy(@array!['admin']).unwrap();
    IGoL2Dispatcher { contract_address }
}

#[starknet::interface]
trait IOldGol<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn totalSupply(self: @TContractState) -> u256;
    fn decimals(self: @TContractState) -> u8;
    fn balanceOf(self: @TContractState, owner: felt252) -> u256;

    fn upgrade(self: @TContractState, new_contract: ClassHash);
}


#[test]
#[fork("GOERLI")]
fn test_upgraded_state() {
    let old_gol_address = contract_address_const::<
        0x06dc4bd1212e67fd05b456a34b24a060c45aad08ab95843c42af31f86c7bd093
    >();
    let user = contract_address_const::<'user'>();

    let old_gol = IOldGolDispatcher { contract_address: old_gol_address };

    let old_name = old_gol.name();
    let old_symbol = old_gol.symbol();
    let old_total_supply = old_gol.totalSupply();
    let old_decimals = old_gol.decimals();
    let old_balance = old_gol.balanceOf(user.into());
    // let old_allowance = old_gol.allowance(user, user);

    /// Upgrade contract 
    let admin = contract_address_const::<
        0x020f8c63faff27a0c5fe8a25dc1635c40c971bf67b8c35c6089a998649dfdfcb
    >();
    start_prank(CheatTarget::All(()), admin);
    let new_contract = declare('GoL2');
    let Upgrade = IUpgradeableDispatcher { contract_address: old_gol_address };
    Upgrade.upgrade(new_contract.class_hash);
    stop_prank(CheatTarget::All(()));

    let new_gol = IGoL2Dispatcher { contract_address: old_gol_address };
    let new_erc20 = ERC20ABIDispatcher { contract_address: old_gol_address };

    let new_name = new_erc20.name();
    let new_symbol = new_erc20.symbol();
    let new_total_supply = new_erc20.totalSupply();
    let new_decimals = new_erc20.decimals();
    let new_balance = new_erc20.balanceOf(user.into());
    // let new_allowance = new_erc20.allowance(user, user);

    assert(old_name == new_name, 'name should be the same');
    assert(old_symbol == new_symbol, 'symbol should be the same');
    assert(old_total_supply == new_total_supply, 'total supply should be the same');
    assert(old_decimals == new_decimals, 'decimals should be the same');
    assert(old_balance == new_balance, 'balance should be the same');
// assert(old_allowance == new_allowance, 'allowance should be the same');
}

