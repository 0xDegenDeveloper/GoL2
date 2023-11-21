use array::ArrayTrait;
use core::integer;
use option::{Option, OptionTrait};
use starknet::ContractAddress;
use traits::{Into, TryInto};
use zeroable::Zeroable;

use gol2::{
    contracts::gol::{IGoL2SafeDispatcher, IGoL2SafeDispatcherTrait},
    utils::{
        math::raise_to_power, constants::{IConstantsSafeDispatcher, IConstantsSafeDispatcherTrait}
    }
};

use snforge_std::{declare, ContractClassTrait};

use debug::PrintTrait;

/// Setup
fn deploy_contract(
    name: felt252
) -> (ContractAddress, IGoL2SafeDispatcher, IConstantsSafeDispatcher) {
    let contract = declare(name);
    let params = array!['initial game state'];
    let contract_address = contract.deploy(@params).unwrap();
    let GoL2 = IGoL2SafeDispatcher { contract_address };
    let Constants = IConstantsSafeDispatcher { contract_address };

    (contract_address, GoL2, Constants)
}

/// Tests
#[test]
fn test_constants_component() {
    let (_, _, Constants) = deploy_contract('GoL2');

    assert(Constants.DIM().unwrap() == 15, 'Invalid DIM');
    assert(Constants.FIRST_ROW_INDEX().unwrap() == 0, 'Invalid FIRST_ROW_INDEX');
    assert(Constants.LAST_ROW_INDEX().unwrap() == 14, 'Invalid LAST_ROW_INDEX');
    assert(Constants.LAST_ROW_CELL_INDEX().unwrap() == 210, 'Invalid LAST_ROW_CELL_INDEX');
    assert(Constants.FIRST_COL_INDEX().unwrap() == 0, 'Invalid FIRST_COL_INDEX');
    assert(Constants.LAST_COL_INDEX().unwrap() == 14, 'Invalid LAST_COL_INDEX');
    assert(Constants.LAST_COL_CELL_INDEX().unwrap() == 14, 'Invalid LAST_COL_CELL_INDEX');
    assert(Constants.SHIFT().unwrap() == raise_to_power(2, 128), 'Invalid SHIFT');
    assert(Constants.LOW_ARRAY_LEN().unwrap() == 128, 'Invalid LOW_ARRAY_LEN');
    assert(Constants.HIGH_ARRAY_LEN().unwrap() == 97, 'Invalid HIGH_ARRAY_LEN');
}
