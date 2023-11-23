use array::ArrayTrait;
use debug::PrintTrait;
use core::integer;
use option::{Option, OptionTrait};
use starknet::ContractAddress;
use traits::{Into, TryInto};
use zeroable::Zeroable;
use snforge_std::{declare, ContractClassTrait};

use gol2::{
    contracts::gol::{IGoL2SafeDispatcher, IGoL2SafeDispatcherTrait},
    utils::{
        math::raise_to_power, constants::{IConstantsSafeDispatcher, IConstantsSafeDispatcherTrait},
        packing::{pack_cells, pack_game, unpack_game, revive_cell}
    }
};

#[test]
fn test_pack_cells() {
    let cells = array![0, 0, 0, 0, 1, 0, 0, 0, 0, 0];
    let packed = pack_cells(cells);
    assert(packed == 16, 'Packed_cells invalid return');
}

#[test]
fn test_unpack_game() {
    let acorn: felt252 = 39132555273291485155644251043342963441664;
    let game: felt252 = 16;
    let unpacked: Array<felt252> = unpack_game(acorn);
    let unpacked_game: Array<felt252> = unpack_game(game);

    assert(unpacked.len() == 225, 'Unpacked acorn incorrect length');
    assert(unpacked_game.len() == 225, 'Unpacked game incorrect length');

    let mut i = 0;
    loop {
        if i >= 225 {
            break ();
        } else {
            let cell = *unpacked.at(i);
            let cell2 = *unpacked_game.at(i);
            if i == 128 || i == 129 || i == 132 || i == 133 || i == 134 || i == 116 || i == 99 {
                assert(cell == 1, 'Acorn cell should be alive');
            } else {
                if i == 4 {
                    assert(cell == 0, 'Acorn cell should be dead');
                    assert(cell2 == 1, 'Game cell should be alive');
                } else {
                    assert(cell == 0, 'Acorn cell should be dead');
                    assert(cell2 == 0, 'Acorn cell should be dead');
                }
            }
        }
        i += 1;
    }
}

#[test]
fn test_pack_game() {
    let mut cell_array: Array<felt252> = array![];
    let mut i: usize = 0;
    loop {
        if i >= 225 {
            break ();
        } else {
            if i == 4 {
                cell_array.append(1);
            } else {
                cell_array.append(0);
            }
        }
        i += 1;
    };

    let packed: felt252 = pack_game(cell_array);
    assert(packed == 16, 'Packed game incorrect');
}

#[test]
fn test_pack_game_acorn() {
    /// Unpacked acorn game state
    let unpacked: Array<felt252> = unpack_game(39132555273291485155644251043342963441664);
    assert(unpacked.clone().len() == 225, 'Unpacked game incorrect length');

    /// Recreate acorn bit array
    let mut acorn: Array<felt252> = array![];
    let mut i: usize = 0;
    loop {
        if i >= 225 {
            break ();
        } else {
            if i == 128 || i == 129 || i == 132 || i == 133 || i == 134 || i == 116 || i == 99 {
                acorn.append(1);
            } else {
                acorn.append(0);
            }

            /// Check unpacked matches acorn (done in this loop to reduce steps)
            assert(*unpacked.at(i) == *acorn.at(i), 'Array mismatch');
            i += 1;
        }
    };
    assert(acorn.len() == 225, 'Acorn incorrect length');
    /// Pack acorn bit array and check against original game state
    assert(pack_game(acorn) == 39132555273291485155644251043342963441664, 'Packed game incorrect');
}

#[test]
fn test_maximum_packed_game() {
    /// 225 cells, all alive
    let mut game: Array<felt252> = array![];
    let mut i: usize = 0;
    loop {
        if i >= 225 {
            break ();
        } else {
            game.append(1);
        }
        i += 1;
    };

    /// Max game state as felt
    let packed_game: felt252 = pack_game(game);
    assert(
        packed_game == 53919893334301279589334030174039261347274288845081144962207220498431,
        'Packed game incorrect'
    );

    /// Max game state as integer
    let packed_game_as_int: u256 = packed_game.into();
    assert(
        packed_game_as_int.low == 340282366920938463463374607431768211455,
        'Packed game incorrect (low)'
    );
    assert(
        packed_game_as_int.high == 158456325028528675187087900671, 'Packed game incorrect (high)'
    );
}

#[test]
fn test_revive_cell() {
    let state: felt252 = 39132555273291485155644251043342963441664;
    /// Revive 0th cell (top left; lowest bit in binary representation)
    let revived: felt252 = revive_cell(0, state);
    assert(revived == state + 1, 'Revived cell incorrect');
    /// Revive 1st cell (top left + 1 to right; 2nd lowest bit in binary representation)
    let revived: felt252 = revive_cell(1, state);
    assert(revived == state + 2, 'Revived cell incorrect');
    /// Revive last cell (bottom right; 225th bit in binary representation)
    let revived: felt252 = revive_cell(224, state);
    assert(revived == state + raise_to_power(2, 224).try_into().unwrap(), 'Revived cell incorrect');
}
