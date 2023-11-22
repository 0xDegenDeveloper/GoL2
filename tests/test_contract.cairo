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
    // let params = array![];

    let contract_address = contract.deploy(@array![]).unwrap();
    let GoL2 = IGoL2SafeDispatcher { contract_address };
    let Constants = IConstantsSafeDispatcher { contract_address };

    (contract_address, GoL2, Constants)
}
/// Tests

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


