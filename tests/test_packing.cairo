use array::ArrayTrait;
use core::integer;
use option::{Option, OptionTrait};
use starknet::ContractAddress;
use traits::{Into, TryInto};
use zeroable::Zeroable;

use gol2::{
    contracts::gol::{IGoL2SafeDispatcher, IGoL2SafeDispatcherTrait},
    utils::{
        math::raise_to_power, constants::{IConstantsSafeDispatcher, IConstantsSafeDispatcherTrait},
        packing::{pack_game, unpack_game, revive_cell}
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

#[test]
fn test_unpack_game() {
    let acorn: felt252 = 39132555273291485155644251043342963441664;
    let cells: felt252 = 16;
    let unpacked: Array<felt252> = unpack_game(acorn);
    let unpacked2: Array<felt252> = unpack_game(cells);

    assert(unpacked.len() == 225, 'Unpacked game incorrect length');
    assert(unpacked2.len() == 225, 'Unpacked game incorrect length');

    let mut i = 0;
    loop {
        if i >= 225 {
            break ();
        } else {
            let cell = *unpacked.at(i);
            let cell2 = *unpacked2.at(i);
            if i == 128 || i == 129 || i == 132 || i == 133 || i == 134 || i == 116 || i == 99 {
                assert(cell == 1, 'Cell should be alive');
            } else {
                if i == 4 {
                    assert(cell == 0, 'Cell should be dead');
                    assert(cell2 == 1, 'Cell should be alive');
                } else {
                    assert(cell == 0, 'Cell should be dead');
                    assert(cell == 0, 'Cell should be dead');
                }
            }
        }
        i += 1;
    }
}

#[test]
fn test_pack_game() {
    /// Tested, works when checked againest non 225 size array
    // let cells: Array<felt252> = array![0, 0, 0, 0, 1, 0, 0, 0, 0, 0];
    // let packed: felt252 = pack_game(cells);
    // assert(packed == 16, 'Packed game incorrect');

    /// Recreate acorn bit array
    let mut game: Array<felt252> = array![];
    let mut i: usize = 0;
    loop {
        if i >= 225 {
            break ();
        } else {
            if i == 128 || i == 129 || i == 132 || i == 133 || i == 134 || i == 116 || i == 99 {
                game.append(1);
            } else {
                game.append(0);
            }
        }
        i += 1;
    };
    assert(game.len() == 225, 'Game incorrect length');

    let packed: felt252 = pack_game(game.clone());
    assert(packed == 39132555273291485155644251043342963441664, 'Packed game incorrect');
}

#[test]
fn test_pack_game_2() {
    /// Recreate acorn bit array
    let mut game: Array<felt252> = array![];
    let unpacked: Array<felt252> = unpack_game(39132555273291485155644251043342963441664);
    assert(unpacked.len() == 225, 'Unpacked game incorrect length');
    let mut i: usize = 0;
    loop {
        if i >= 225 {
            break ();
        } else {
            if i == 128 || i == 129 || i == 132 || i == 133 || i == 134 || i == 116 || i == 99 {
                game.append(1);
            } else {
                game.append(0);
            }
        }

        assert(*game.at(i) == *unpacked.at(i), 'Array mismatch');

        i += 1;
    };
}

#[test]
fn test_maximum_packed_game() {
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

    let packed_game: felt252 = pack_game(game);
    assert(
        packed_game == 53919893334301279589334030174039261347274288845081144962207220498431,
        'Packed game incorrect'
    );

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
    /// revive first cell in array (top left, first cell in array, lowest bit)
    let revived: felt252 = revive_cell(0, state);
    assert(revived == state + 1, 'Revived cell incorrect');
}
