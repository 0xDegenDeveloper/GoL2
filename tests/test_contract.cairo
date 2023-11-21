use array::ArrayTrait;
use core::integer;
use option::{Option, OptionTrait};
use starknet::ContractAddress;
use traits::{Into, TryInto};
use zeroable::Zeroable;

use gol2::contracts::gol::IGoL2SafeDispatcher;
use gol2::contracts::gol::IGoL2SafeDispatcherTrait;
use gol2::utils::constants::IConstantsSafeDispatcher;
use gol2::utils::constants::IConstantsSafeDispatcherTrait;

use snforge_std::{declare, ContractClassTrait};

use debug::PrintTrait;

/// Helpers

fn deploy_contract(
    name: felt252
) -> (ContractAddress, IGoL2SafeDispatcher, IConstantsSafeDispatcher) {
    let contract = declare(name);
    let params = array![0b1010101010100000000001111111];

    let contract_address = contract.deploy(@params).unwrap();
    let GoL2 = IGoL2SafeDispatcher { contract_address };
    let Constants = IConstantsSafeDispatcher { contract_address };

    (contract_address, GoL2, Constants)
}

fn raise_to_power(base: u128, exponent: u128) -> u256 {
    let mut result: u256 = 1;
    let mut i = 0;
    loop {
        if i >= exponent {
            break ();
        } else {
            result = result * base.into();
            i = i + 1;
        }
    };
    result
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
// #[test]
// fn test_constructor() {
//     let (contract_address, safe_dispatcher) = deploy_contract('GoL2');
//     assert(safe_dispatcher.DIM().unwrap() == 15, 'Invalid DIM');
// }

// #[test]
// fn test_game_state() {
//     let (contract_address, safe_dispatcher) = deploy_contract('GoL2');
//     assert(safe_dispatcher.get_game_state(0x9, 0).unwrap() == 0x9, 'Invalid game_state');
// }

// #[test]
// fn test_cell_array_from_state() {
//     let (contract_address, safe_dispatcher) = deploy_contract('GoL2');
//     assert(
//         safe_dispatcher
//             .get_game_state(0b1010101010100000000001111111, 0)
//             .unwrap() == 0b1010101010100000000001111111,
//         'Invalid game_state'
//     );

//     let mut cell_array = safe_dispatcher.get_cell_array(0b1010101010100000000001111111, 0).unwrap();

//     loop {
//         let cell = cell_array.pop_front();
//         if cell.is_none() {
//             break ();
//         } else {
//             let cell = cell.unwrap();
//             cell.print();
//         }
//     };
// }

// #[test]
// fn test_cannot_increase_balance_with_zero_value() {
//     let contract_address = deploy_contract('HelloStarknet');

//     let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

//     let balance_before = safe_dispatcher.get_balance().unwrap();
//     assert(balance_before == 0, 'Invalid balance');

//     match safe_dispatcher.increase_balance(0) {
//         Result::Ok(_) => panic_with_felt252('Should have panicked'),
//         Result::Err(panic_data) => {
//             assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
//         }
//     };
// }


