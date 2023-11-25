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
            HIGH_ARRAY_LEN, CREATE_CREDIT_REQUIREMENT, GIVE_LIFE_CREDIT_REQUIREMENT
        },
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
fn values() {
    assert(
        INFINITE_GAME_GENESIS == 39132555273291485155644251043342963441664,
        'Wrong INFINITE_GAME_GENESIS'
    );
    assert(DIM == 15, 'Wrong DIM');
    assert(FIRST_ROW_INDEX + FIRST_COL_INDEX == DIM - DIM, 'Wrong FIRST_ROW/COL_INDEX');
    assert(LAST_ROW_INDEX == DIM - 1 && LAST_COL_INDEX == DIM - 1, 'Wrong LAST_ROW/COL_INDEX');
    assert(LAST_ROW_CELL_INDEX == DIM * DIM - DIM, 'Wrong LAST_ROW_CELL_INDEX');
    assert(LAST_COL_CELL_INDEX == DIM - 1, 'Wrong LAST_COL_CELL_INDEX');
    assert(SHIFT == raise_to_power(2, 128), 'Wrong SHIFT');

    /// 225 1's -> 97 1's + 128 1's
    let max_game: u256 = raise_to_power(2, (DIM * DIM).into()) - 1;
    let high = max_game.high;
    let low = max_game.low;

    assert(high.into() == raise_to_power(2, HIGH_ARRAY_LEN.into()) - 1, 'Wrong HIGH_ARRAY_LEN');
    assert(low.into() == raise_to_power(2, LOW_ARRAY_LEN.into()) - 1, 'Wrong LOW_ARRAY_LEN');

    assert(CREATE_CREDIT_REQUIREMENT == 10, 'Wrong CREATE_CREDIT_REQUIREMENT');
    assert(GIVE_LIFE_CREDIT_REQUIREMENT == 1, 'Wrong GIVE_LIFE_CREDIT_RE...');
}
