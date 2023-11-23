use array::ArrayTrait;
use debug::PrintTrait;
use core::integer;
use option::{Option, OptionTrait};
use starknet::ContractAddress;
use traits::{Into, TryInto};
use zeroable::Zeroable;
use gol2::utils::math::raise_to_power;

/// The game board is a 15x15 grid of cells:
/// | 0 | 1 | 2 | 3 | 4 |...|14 |
/// |15 |16 |17 |18 |19 |...|29 |
/// |...|...|...|...|...|...|...|
/// |210|211|212|213|214|...|224|

/// Cells can be alive or dead, imagined as a bit array:
/// [0, 0, 1, 1, 0, 1, 0, 1, ..., 1] 
///  ^-- 0th cell is dead         ^-- 224th cell is alive

/// This bit array represents a 225 bit integer, which is stored in the contract as a felt252
/// Cell array: [1, 1, 1, 0, 0, 0,..., 0, 0] translates to binary: 0b00...000111, which is felt: 7

fn pack_cells(cells: Array<felt252>) -> felt252 {
    let mut result: felt252 = 0;
    let mut i = 0;
    let mut mask = 0x1;
    let len = cells.clone().len();
    loop {
        if i >= len {
            break ();
        }
        result += *cells.at(i) * mask;
        mask *= 2;
        i += 1;
    };
    result
}


/// Creates a cell array from a game state
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
        mask *= 2;
        i += 1;
    };
    cell_array
}

/// Creates a game state from a cell array
fn pack_game(cells: Array<felt252>) -> felt252 {
    pack_cells(cells)
}


/// * move to game logic module (& tests)
/// Toggles a cell index alive, returns new game state
fn revive_cell(cell_index: felt252, current_state: felt252) -> felt252 {
    let enabled_bit: u256 = raise_to_power(2, cell_index.try_into().unwrap());
    let state_as_int: u256 = current_state.into();
    let updated: u256 = state_as_int | enabled_bit;
    updated.try_into().unwrap()
}
