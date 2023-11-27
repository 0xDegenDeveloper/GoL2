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
        }
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

/// Tests
#[test]
fn test_constants() {
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
// #[test]
// fn test_view_game() {
//     let (_, GoL2, _) = deploy_contract('GoL2');

//     'testing'.print();

//     /// acorn as felt
//     let f = 39132555273291485155644251043342963441664;

//     let f_int: u256 = f.into();
//     'acorn felt'.print();
//     f.print();
//     'acorn int low'.print();
//     f_int.low.print(); // 0x1000...
//     'acorn int high'.print();
//     f_int.high.print(); // 0x73...

//     let mut cell_array = array![];
//     let mut mask: u256 = 0x1;
//     let mut i: usize = 0;

//     loop {
//         if i >= 225 {
//             break ();
//         }
//         if f_int & mask != 0 {
//             cell_array.append(1);
//         } else {
//             cell_array.append(0);
//         }
//         mask = mask * 2;
//         i += 1;
//     };

//     let mut i: usize = 0;
//     'cell_array'.print();
//     loop {
//         if i >= 225 {
//             break ();
//         }
//         let cell = *cell_array.at(i);
//         cell.print();
//         i += 1;
//     };
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


