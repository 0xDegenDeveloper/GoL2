use array::ArrayTrait;
use core::integer;
use option::{Option, OptionTrait};
use starknet::ContractAddress;
use traits::{Into, TryInto};
use zeroable::Zeroable;

use gol2::{
    contracts::gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
    utils::{
        math::raise_to_power,
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, SHIFT, LOW_ARRAY_LEN,
            HIGH_ARRAY_LEN, CREATE_CREDIT_REQUIREMENT, GIVE_LIFE_CREDIT_REQUIREMENT
        }
    }
};

use starknet::{contract_address_const};

use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions
};


use debug::PrintTrait;

/// Setup
fn deploy_contract(name: felt252) -> IGoL2Dispatcher {
    let contract = declare(name);
    let contract_address = contract.deploy(@array![]).unwrap();
    IGoL2Dispatcher { contract_address }
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

#[test]
fn test_view_game() {
    let gol = deploy_contract('GoL2');
    start_prank(CheatTarget::All(()), contract_address_const::<'creator'>());
    gol.create(INFINITE_GAME_GENESIS);
    let game_state: felt252 = gol.view_game(INFINITE_GAME_GENESIS, 1);
    let game_state2: felt252 = gol.view_game(INFINITE_GAME_GENESIS, 2);
    assert(game_state == INFINITE_GAME_GENESIS, 'Invalid game_state');
    assert(game_state2 == 0, 'Invalid game_state');
    stop_prank(CheatTarget::All(()));
}

#[test]
fn test_get_current_generation() {
    let gol = deploy_contract('GoL2');
    start_prank(CheatTarget::All(()), contract_address_const::<'creator'>());
    gol.create(INFINITE_GAME_GENESIS);
    let gen: felt252 = gol.get_current_generation(INFINITE_GAME_GENESIS);
    assert(gen == 1, 'Invalid game_state');
    stop_prank(CheatTarget::All(()));
}

/// todo: test erc20 balance change
#[test]
fn test_create() {
    let gol = deploy_contract('GoL2');
    let creator = contract_address_const::<'creator'>();
    start_prank(CheatTarget::All(()), creator);

    //  let user_bal0 = ERC20.balance_of(creator);
    // let contract_bal0 = ERC20.balance_of(erc20.contract_address);

    let mut spy = spy_events(SpyOn::One(gol.contract_address));

    gol.create(INFINITE_GAME_GENESIS);

    //  let user_bal1 = ERC20.balance_of(creator);
    // let contract_bal1 = ERC20.balance_of(erc20.contract_address);
    // assert(user_bal0 - user_bal1 == CREATE_CREDIT_REQUIREMENT, 'Invalid user balance change');
    // assert(contract_bal1 - contract_bal0 == CREATE_CREDIT_REQUIREMENT, 'Invalid contract balance change'); // might need to check supply instead

    spy
        .assert_emitted(
            @array![
                (
                    gol.contract_address,
                    GoL2::Event::GameCreated(
                        GoL2::GameCreated {
                            user_id: creator,
                            game_id: INFINITE_GAME_GENESIS,
                            state: INFINITE_GAME_GENESIS,
                        }
                    )
                )
            ]
        );

    stop_prank(CheatTarget::All(()));
}

/// todo: test erc20 balance change
#[test]
fn test_evolve() {
    let gol = deploy_contract('GoL2');
    let creator = contract_address_const::<'creator'>();
    let acorn_evolved = 0x100030006e0000000000000000000000000000;
    start_prank(CheatTarget::All(()), creator);

    /// let user_bal0 = ERC20.balance_of(creator);
    /// let contract_bal0 = ERC20.balance_of(erc20.contract_address);

    let mut spy = spy_events(SpyOn::One(gol.contract_address));

    gol.create(INFINITE_GAME_GENESIS);
    gol.evolve(INFINITE_GAME_GENESIS);

    /// let user_bal1 = ERC20.balance_of(creator);
    /// let contract_bal1 = ERC20.balance_of(erc20.contract_address);
    /// assert(user_bal1 - user_bal1 == 1, 'Invalid user balance change');
    /// assert(contract_bal0 - contract_bal1 == 1, 'Invalid contract balance change'); // might need to check supply instead

    assert(gol.view_game(INFINITE_GAME_GENESIS, 1) == INFINITE_GAME_GENESIS, 'Invalid game_state');
    assert(gol.view_game(INFINITE_GAME_GENESIS, 2) == acorn_evolved, 'Invalid game_state');
    assert(gol.get_current_generation(INFINITE_GAME_GENESIS) == 2, 'Invalid generation');

    spy
        .assert_emitted(
            @array![
                (
                    gol.contract_address,
                    GoL2::Event::GameEvolved(
                        GoL2::GameEvolved {
                            user_id: creator,
                            game_id: INFINITE_GAME_GENESIS,
                            generation: 2,
                            state: acorn_evolved,
                        }
                    )
                )
            ]
        );

    stop_prank(CheatTarget::All(()));
}

/// todo: test erc20 balance change
#[test]
fn test_give_life_to_cell() {
    let gol = deploy_contract('GoL2');
    let creator = contract_address_const::<'creator'>();
    let acorn_evolved = 0x100030006e0000000000000000000000000000;
    start_prank(CheatTarget::All(()), creator);

    /// let user_bal0 = ERC20.balance_of(creator);
    /// let contract_bal0 = ERC20.balance_of(erc20.contract_address);

    let mut spy = spy_events(SpyOn::One(gol.contract_address));

    gol.create(INFINITE_GAME_GENESIS);
    gol.give_life_to_cell(0);

    /// let user_bal1 = ERC20.balance_of(creator);
    /// let contract_bal1 = ERC20.balance_of(erc20.contract_address);
    /// assert(user_bal1 - user_bal1 == GIVE_LIFE_CREDIT_REQUIREMENT, 'Invalid user balance change');
    /// assert(contract_bal0 - contract_bal1 == GIVE_LIFE_CREDIT_REQUIREMENT, 'Invalid contract balance change'); // might need to check supply instead

    assert(
        gol.view_game(INFINITE_GAME_GENESIS, 1) == INFINITE_GAME_GENESIS + 1, 'Invalid game_state'
    );
    assert(gol.view_game(INFINITE_GAME_GENESIS, 2) == 0, 'Invalid game_state');
    assert(gol.get_current_generation(INFINITE_GAME_GENESIS) == 1, 'Invalid generation');

    spy
        .assert_emitted(
            @array![
                (
                    gol.contract_address,
                    GoL2::Event::CellRevived(
                        GoL2::CellRevived {
                            user_id: creator,
                            generation: 1,
                            cell_index: 0,
                            state: INFINITE_GAME_GENESIS + 1,
                        }
                    )
                )
            ]
        );

    stop_prank(CheatTarget::All(()));
}
