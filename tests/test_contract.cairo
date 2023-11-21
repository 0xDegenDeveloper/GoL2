use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait};

use array::ArrayTrait;
use core::integer;
use option::{Option, OptionTrait};
use traits::{Into, TryInto};
use zeroable::Zeroable;

use debug::PrintTrait;

// use gol2::IHelloStarknetSafeDispatcher;
// use gol2::IHelloStarknetSafeDispatcherTrait;
use gol2::utils::gol::IGoL2SafeDispatcher;
use gol2::utils::gol::IGoL2SafeDispatcherTrait;

fn deploy_contract(name: felt252) -> (ContractAddress, IGoL2SafeDispatcher) {
    let contract = declare(name);
    let params = array![0b1010101010100000000001111111];

    // let contract_address = contract.deploy(@ArrayTrait::new()).unwrap();
    let contract_address = contract.deploy(@params).unwrap();
    let safe_dispatcher = IGoL2SafeDispatcher { contract_address };
    (contract_address, safe_dispatcher)
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

#[test]
fn test_cell_array_from_state() {
    let (contract_address, safe_dispatcher) = deploy_contract('GoL2');
    assert(
        safe_dispatcher
            .get_game_state(0b1010101010100000000001111111, 0)
            .unwrap() == 0b1010101010100000000001111111,
        'Invalid game_state'
    );

    let mut cell_array = safe_dispatcher.get_cell_array(0b1010101010100000000001111111, 0).unwrap();

    loop {
        let cell = cell_array.pop_front();
        if cell.is_none() {
            break ();
        } else {
            let cell = cell.unwrap();
            cell.print();
        }
    };
}
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


