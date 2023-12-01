use gol2::utils::{math::raise_to_power, constants::DIM};

/// The game board is a 15x15 grid of cells:
///   0   1   2   3   4  ... 14  
///  15  16  17  18  19  ... 29  
///  ... ... ... ... ... ... ...
///  210 211 212 213 214 ... 224 

/// Cells can be alive or dead, imagined as a bit array:
/// [1, 1, 1, 0, 0, 0, 0, 0, ..., 0] 
///  ^0th cell is alive           ^224th cell is dead

/// This bit array represents a 225 bit integer, which is stored in the contract as a felt252
/// Cell array: [1, 1, 1, 0, 0, 0,..., 0, 0] translates to binary: 0b00...000111, which is felt: 7

/// Translates a bit array into a felt252
fn pack_cells(cells: Array<felt252>) -> felt252 {
    let mut mask = 0x1;
    let mut result = 0;
    let mut i = 0;
    let stop = cells.len();

    loop {
        if i >= stop {
            break result;
        }
        result += *cells.at(i) * mask;
        mask *= 2;
        i += 1;
    }
}


/// Creates a cell array from a game state
fn unpack_game(game: felt252) -> Array<felt252> {
    let game_as_int: u256 = game.into();
    assert(game_as_int < raise_to_power(2, (DIM * DIM).into()), 'Invalid game state (too large)');
    let mut cell_array = array![];
    let mut mask: u256 = 0x1;
    let mut i: usize = 0;
    let end = DIM * DIM;
    loop {
        if i >= end {
            break ();
        }
        cell_array.append(if game_as_int & mask != 0 {
            1
        } else {
            0
        });
        mask *= 2;
        i += 1;
    };
    cell_array
}

/// Creates a game state from a cell array
fn pack_game(cells: Array<felt252>) -> felt252 {
    assert(cells.len() == DIM * DIM, 'Invalid cell array length');
    pack_cells(cells)
}

/// Toggles a cell index alive, returns the new game state
fn revive_cell(cell_index: felt252, current_state: felt252) -> felt252 {
    let enabled_bit: u256 = raise_to_power(2, cell_index.try_into().unwrap());
    let state_as_int: u256 = current_state.into();
    let updated: u256 = state_as_int | enabled_bit;
    updated.try_into().unwrap()
}
