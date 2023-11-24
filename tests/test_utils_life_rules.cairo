use array::ArrayTrait;
use core::integer;
use option::{Option, OptionTrait};
use starknet::ContractAddress;
use traits::{Into, TryInto};
use zeroable::Zeroable;

use gol2::{
    contracts::gol::{IGoL2SafeDispatcher, IGoL2SafeDispatcherTrait},
    utils::{
        math::raise_to_power,
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, SHIFT, LOW_ARRAY_LEN,
            HIGH_ARRAY_LEN
        },
        life_rules::{get_adjacent}
    }
};

use snforge_std::{declare, ContractClassTrait};

use debug::PrintTrait;

/// Setup
fn deploy_contract(name: felt252) -> IGoL2SafeDispatcher {
    let contract = declare(name);
    let contract_address = contract.deploy(@array![]).unwrap();
    IGoL2SafeDispatcher { contract_address }
}

#[test]
fn test_get_adjacent() {
    let (l, r, u, d, lu, ru, ld, rd) = get_adjacent(16);
}
