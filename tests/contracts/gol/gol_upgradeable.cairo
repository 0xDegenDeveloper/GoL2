use starknet::contract_address_const;
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions
};
use gol2::{
    contracts::{
        gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
        test_contract::{ITestTraitDispatcher, ITestTraitDispatcherTrait}
    },
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
    token::erc20::{ERC20Component},
};
use debug::PrintTrait;

/// Setup
fn deploy_contract(name: felt252) -> IGoL2Dispatcher {
    let contract = declare(name);
    let contract_address = contract.deploy(@array!['admin']).unwrap();
    IGoL2Dispatcher { contract_address }
}

#[test]
fn test_upgrade_as_owner() {
    let gol = deploy_contract('GoL2');
    gol.evolve(INFINITE_GAME_GENESIS);

    start_prank(CheatTarget::All(()), contract_address_const::<'admin'>());
    let new_contract = declare('TestContract');
    let Upgrade = IUpgradeableDispatcher { contract_address: gol.contract_address };
    Upgrade.upgrade(new_contract.class_hash);
    stop_prank(CheatTarget::All(()));

    let new_gol = ITestTraitDispatcher { contract_address: gol.contract_address };
    assert(new_gol.x() == 0, 'x should be 0');
    assert(new_gol.total_supply() == 1, 'y should be 0');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_upgrade_as_non_owner() {
    let gol = deploy_contract('GoL2');
    let Upgrade = IUpgradeableDispatcher { contract_address: gol.contract_address };
    Upgrade.upgrade(declare('TestContract').class_hash);
}
