use starknet::{contract_address_const, ClassHash, call_contract_syscall};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash, EventFetcher, event_name_hash, Event
};
use gol2::{
    contracts::gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
    utils::constants::{
        INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
        FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, CREATE_CREDIT_REQUIREMENT,
        GIVE_LIFE_CREDIT_REQUIREMENT
    },
};
use openzeppelin::{
    access::ownable::{OwnableComponent, interface::{IOwnableDispatcher, IOwnableDispatcherTrait}},
    upgrades::{
        UpgradeableComponent,
        interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait},
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
    /// Read
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn totalSupply(self: @TContractState) -> u256;
    fn decimals(self: @TContractState) -> u8;
    fn balanceOf(self: @TContractState, owner: felt252) -> u256;
    fn allowance(self: @TContractState, owner: felt252, spender: felt252) -> u256;
    fn view_game(self: @TContractState, game_id: felt252, generation: felt252) -> felt252;
    fn get_current_generation(self: @TContractState, game_id: felt252) -> felt252;
    /// Write
    fn migrate(self: @TContractState, new_class_hash: ClassHash);
    fn transfer(self: @TContractState, to: felt252, value: u256);
    fn transferFrom(self: @TContractState, from: felt252, to: felt252, value: u256);
    fn approve(self: @TContractState, spender: felt252, value: u256);
    fn increaseAllowance(self: @TContractState, spender: felt252, added_value: u256);
    fn decreaseAllowance(self: @TContractState, spender: felt252, subtracted_value: u256);
    fn upgrade(self: @TContractState, implementation_hash: felt252);
    fn create(self: @TContractState, game_state: felt252);
    fn evolve(ref self: TContractState, game_id: felt252);
    fn give_life_to_cell(ref self: TContractState, cell_index: felt252);
}

fn get_old_gol() -> IOldGolDispatcher {
    IOldGolDispatcher {
        contract_address: contract_address_const::<
            0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
        >()
    }
}

fn upgrade(OldGol: IOldGolDispatcher) -> IGoL2Dispatcher {
    let new_gol_hash = declare('GoL2').class_hash;
    /// Gol admin address
    start_prank(
        CheatTarget::All(()),
        contract_address_const::<
            0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973
        >()
    );
    OldGol.upgrade(new_gol_hash.into());
    OldGol.migrate(new_gol_hash);
    stop_prank(CheatTarget::All(()));
    IGoL2Dispatcher { contract_address: OldGol.contract_address }
}


#[test]
#[fork("MAINNET")]
#[ignore]
fn evolve() {
    let user = contract_address_const::<'user'>();
    let OldGol = get_old_gol();

    /// Get gas cost pre-mirgration
    start_prank(CheatTarget::One(OldGol.contract_address), user);
    OldGol.evolve(INFINITE_GAME_GENESIS);
    let mut old_gas = testing::get_available_gas();
    gas::withdraw_gas().unwrap();
    OldGol.evolve(INFINITE_GAME_GENESIS);
    old_gas -= testing::get_available_gas();
    stop_prank(CheatTarget::One(OldGol.contract_address));

    /// Upgrade gol
    let NewGol = upgrade(OldGol);

    /// Get gas cost post-mirgration
    start_prank(CheatTarget::One(NewGol.contract_address), user);
    NewGol.evolve(INFINITE_GAME_GENESIS); // complete first write (cheaper)
    let mut new_gas = testing::get_available_gas();
    gas::withdraw_gas().unwrap();
    NewGol.evolve(INFINITE_GAME_GENESIS);
    new_gas -= testing::get_available_gas();
    stop_prank(CheatTarget::One(NewGol.contract_address));

    let mut gases = array!['evolve', 'old', old_gas, 'new', new_gas];

    loop {
        match gases.pop_front() {
            Option::Some(gas) => { gas.print(); },
            Option::None => { break; }
        }
    }
}


#[test]
#[fork("MAINNET")]
#[ignore]
// todo: get gas of syscalls somehow ? 
fn evolve_with_storage() {
    let user = contract_address_const::<'user'>();
    let NewGol = upgrade(get_old_gol());

    /// Get gas cost for classic evolve
    start_prank(CheatTarget::All(()), user);
    let mut old_gas = testing::get_available_gas();
    gas::withdraw_gas().unwrap();
    NewGol.evolve(INFINITE_GAME_GENESIS);
    old_gas -= testing::get_available_gas();

    /// Get gas cost for storage evolve
    let mut new_gas = testing::get_available_gas();
    NewGol.evolve_with_storage(INFINITE_GAME_GENESIS); // complete first write (cheaper)
    gas::withdraw_gas().unwrap();
    NewGol.evolve_with_storage(INFINITE_GAME_GENESIS);
    new_gas -= testing::get_available_gas();

    stop_prank(CheatTarget::All(()));

    let mut gases = array!['evol_new', 'no store', old_gas, 'w/stor', new_gas];

    loop {
        match gases.pop_front() {
            Option::Some(gas) => { gas.print(); },
            Option::None => { break; }
        }
    }
}

#[test]
#[fork("MAINNET")]
#[ignore]
fn create() {
    let user = contract_address_const::<'user'>();
    let OldGol = get_old_gol();

    /// Get user tokens to create
    start_prank(CheatTarget::One(OldGol.contract_address), user);
    let mut evolves = 0;
    loop {
        if evolves == 20 {
            break;
        }
        OldGol.evolve(INFINITE_GAME_GENESIS);
        evolves += 1;
    };
    /// Get gas cost pre-mirgration
    let mut old_gas = testing::get_available_gas();
    gas::withdraw_gas().unwrap();
    OldGol.create(INFINITE_GAME_GENESIS + 1);
    old_gas -= testing::get_available_gas();
    stop_prank(CheatTarget::All(()));

    /// Upgrade gol
    let NewGol = upgrade(OldGol);

    /// Get gas cost post-mirgration
    start_prank(CheatTarget::All(()), user);
    let mut new_gas = testing::get_available_gas();
    gas::withdraw_gas().unwrap();
    NewGol.create(INFINITE_GAME_GENESIS + 2);
    new_gas -= testing::get_available_gas();
    stop_prank(CheatTarget::All(()));

    let mut gases = array!['create', 'old', old_gas, 'new', new_gas];

    loop {
        match gases.pop_front() {
            Option::Some(gas) => { gas.print(); },
            Option::None => { break; }
        }
    }
}

#[test]
#[fork("MAINNET")]
#[ignore]
fn give_life_to_cell() {
    let user = contract_address_const::<'user'>();
    let OldGol = get_old_gol();

    /// Get user tokens to create
    start_prank(CheatTarget::One(OldGol.contract_address), user);
    let mut evolves = 0;
    loop {
        if evolves == 2 {
            break;
        }
        OldGol.evolve(INFINITE_GAME_GENESIS);
        evolves += 1;
    };

    /// Get gas cost pre-mirgration
    let mut old_gas = testing::get_available_gas();
    gas::withdraw_gas().unwrap();
    OldGol.give_life_to_cell(0);
    old_gas -= testing::get_available_gas();
    stop_prank(CheatTarget::All(()));

    /// Upgrade gol
    let NewGol = upgrade(OldGol);

    /// Get gas cost post-mirgration
    start_prank(CheatTarget::All(()), user);
    let mut new_gas = testing::get_available_gas();
    gas::withdraw_gas().unwrap();
    NewGol.give_life_to_cell(1);
    new_gas -= testing::get_available_gas();
    stop_prank(CheatTarget::All(()));

    let mut gases = array!['add life', 'old', old_gas, 'new', new_gas];

    loop {
        match gases.pop_front() {
            Option::Some(gas) => { gas.print(); },
            Option::None => { break; }
        }
    }
}

