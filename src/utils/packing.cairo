use array::ArrayTrait;
use core::integer;
use option::{Option, OptionTrait};
use starknet::ContractAddress;
use traits::{Into, TryInto};
use zeroable::Zeroable;

use gol2::utils::math::raise_to_power;


/// [0,1,0,...] -> 0b010... -> felt252
/// unneeded, pack_game handles this logic
// fn pack_cell(cells: Array<felt252>) -> felt252 { 
//     let mut result: felt252 = 0;
//     let mut i = 225;
//     let mut mask = 0x1;
//     loop {
//         if i < 1 {
//             break ();
//         }
//         result += *cells.at(i - 1) * mask;
//         mask * 2;
//         i -= 1;
//     };
//     result
// }

/// 'gamestate' -> [0,1,0,...]
fn unpack_game(game: felt252) -> Array<felt252> {
    let game_as_int: u256 = game.into();
    let mut cell_array = array![];
    let mut mask: u256 = 0x1;
    let mut i: usize = 0;
    loop {
        if i >= 225 {
            break ();
        }
        if game_as_int & mask != 0 {
            cell_array.append(1);
        } else {
            cell_array.append(0);
        }
        mask = mask * 2;
        i += 1;
    };
    cell_array
}

fn pack_game(cells: Array<felt252>) -> felt252 {
    let mut result: felt252 = 0;
    let mut i = 0;
    let mut mask = 0x1;
    loop {
        if i >= 225 {
            break ();
        }
        result += *cells.at(i) * mask;
        mask = mask * 2;
        i += 1;
    };
    result
}

fn revive_cell(cell_index: felt252, current_state: felt252) -> felt252 {
    let enabled_bit: u256 = raise_to_power(2, cell_index.try_into().unwrap());
    let state_as_int: u256 = current_state.into();
    let updated: u256 = state_as_int | enabled_bit;
    let packed_game_as_int: u256 = state_as_int + updated;
    packed_game_as_int.try_into().unwrap()
}
