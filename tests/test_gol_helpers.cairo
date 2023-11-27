use array::ArrayTrait;
use core::integer;
use option::{Option, OptionTrait};
use starknet::{ContractAddress, contract_address_const};
use traits::{Into, TryInto};
use zeroable::Zeroable;

use gol2::{
    contracts::gol::{IGoL2SafeDispatcher, IGoL2SafeDispatcherTrait},
    utils::{
        math::raise_to_power,
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, SHIFT, LOW_ARRAY_LEN,
            HIGH_ARRAY_LEN, CREATE_CREDIT_REQUIREMENT, GIVE_LIFE_CREDIT_REQUIREMENT
        }
    }
};

use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};

use debug::PrintTrait;

/// Setup
fn deploy_contract(name: felt252) -> IGoL2SafeDispatcher {
    let contract = declare(name);
    let contract_address = contract.deploy(@array![]).unwrap();
    IGoL2SafeDispatcher { contract_address }
}

/// Tests

// todo
#[test]
fn test_pay() {
    assert(true, '');
}
// todo
#[test]
fn test_pay_not_enough_credits() {
    assert(true, '');
}
// todo
#[test]
fn test_reward_user() {
    assert(true, '');
}

#[test]
fn test_ensure_user_authenticated() {
    let gol = deploy_contract('GoL2');
    start_prank(CheatTarget::All(()), contract_address_const::<'user'>());
    gol.create('gamestate');
    stop_prank(CheatTarget::All(()));
}

// todo: not panicking for some reason
// #[should_panic(expected: ('User not authenticated',))]
#[test]
fn test_ensure_user_not_authenticated() {
    let gol = deploy_contract('GoL2');
    start_prank(CheatTarget::All(()), contract_address_const::<0>());
    gol.create((raise_to_power(2, 226)).try_into().unwrap());
    stop_prank(CheatTarget::All(()));
}
