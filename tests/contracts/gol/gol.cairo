use starknet::contract_address_const;
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, start_warp, stop_warp, CheatTarget,
    spy_events, SpyOn, EventSpy, EventAssertions
};
use gol2::{
    contracts::gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
    utils::{
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, CREATE_CREDIT_REQUIREMENT,
            GIVE_LIFE_CREDIT_REQUIREMENT, LOW_ARRAY_LEN, HIGH_ARRAY_LEN, BOARD_SQUARED
        },
    }
};
use openzeppelin::token::erc20::{ERC20Component, ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use debug::PrintTrait;

/// Setup
fn deploy_contract(name: felt252) -> IGoL2Dispatcher {
    let contract = declare(name);
    let contract_address = contract.deploy(@array!['admin']).unwrap();
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
    assert(CREATE_CREDIT_REQUIREMENT == 10, 'Wrong CREATE_CREDIT_REQUIREMENT');
    assert(GIVE_LIFE_CREDIT_REQUIREMENT == 1, 'Wrong GIVE_LIFE_CREDIT_RE...');
    assert(FIRST_ROW_INDEX + FIRST_COL_INDEX == DIM - DIM, 'Wrong FIRST_ROW/COL_INDEX');
    assert(LAST_ROW_INDEX == DIM - 1 && LAST_COL_INDEX == DIM - 1, 'Wrong LAST_ROW/COL_INDEX');
    assert(LAST_ROW_CELL_INDEX == DIM * DIM - DIM, 'Wrong LAST_ROW_CELL_INDEX');
    assert(LAST_COL_CELL_INDEX == DIM - 1, 'Wrong LAST_COL_CELL_INDEX');
    assert(LOW_ARRAY_LEN == 128, 'Wrong LOW_ARRAY_LEN');
    assert(HIGH_ARRAY_LEN == 97, 'Wrong HIGH_ARRAY_LEN');
    assert(BOARD_SQUARED == DIM * DIM, 'Wrong BOARD_SQUARED');
}

#[test]
fn test_view_game() {
    let gol = deploy_contract('GoL2');
    let gamestate = gol.view_game(INFINITE_GAME_GENESIS, 1);
    let gamestate2 = gol.view_game(INFINITE_GAME_GENESIS, 2);
    assert(gamestate == INFINITE_GAME_GENESIS, 'Invalid gamestate');
    assert(gamestate2 == 0, 'Invalid gamestate2');
}

#[test]
fn test_get_current_generation() {
    let gol = deploy_contract('GoL2');
    let gen = gol.get_current_generation(INFINITE_GAME_GENESIS);
    assert(gen == 1, 'Invalid game_state');
}


#[test]
fn test_create() {
    let gol = deploy_contract('GoL2');
    let token = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let creator = contract_address_const::<'creator'>();
    let mut spy = spy_events(SpyOn::One(gol.contract_address));
    start_prank(CheatTarget::All(()), creator);

    let mut i = 10;
    loop {
        if i == 0 {
            break ();
        }
        gol.evolve(INFINITE_GAME_GENESIS);
        i -= 1;
    };

    let bal0 = token.balance_of(creator);
    let sup0 = token.total_supply();

    gol.create('gamestate');

    let bal1 = token.balance_of(creator);
    let sup1 = token.total_supply();

    assert(
        (bal0 - bal1).try_into().unwrap() == CREATE_CREDIT_REQUIREMENT,
        'Invalid user balance change'
    );
    assert(
        (sup0 - sup1).try_into().unwrap() == CREATE_CREDIT_REQUIREMENT,
        'Invalid contract balance change'
    );
    assert(gol.view_game('gamestate', 1) == 'gamestate', 'Invalid game_state');

    spy
        .assert_emitted(
            @array![
                (
                    gol.contract_address,
                    GoL2::Event::GameCreated(
                        GoL2::GameCreated {
                            user_id: creator, game_id: 'gamestate', state: 'gamestate',
                        }
                    )
                )
            ]
        );

    stop_prank(CheatTarget::All(()));

    /// test that no snapshots recorded for non INFINITE_GAME_GENESIS
    let caller = contract_address_const::<'caller'>();
    start_prank(CheatTarget::All(()), caller);
    gol.evolve('gamestate');
    stop_prank(CheatTarget::All(()));
}

#[test]
fn test_evolve() {
    let gol = deploy_contract('GoL2');
    let token = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let mut spy = spy_events(SpyOn::One(gol.contract_address));
    let creator = contract_address_const::<'creator'>();
    let acorn_evolved = 0x100030006e0000000000000000000000000000;

    let bal0 = token.balance_of(creator);
    let sup0 = token.total_supply();

    start_prank(CheatTarget::All(()), creator);
    start_warp(CheatTarget::All(()), 222);
    gol.evolve(INFINITE_GAME_GENESIS);
    // testing that a snapshot is the initial evolution, and does not matter if cells are brought to life during this generation
    // todo: if reviving cells count as a snapshot then adjust
    gol.give_life_to_cell(0);
    gol.evolve(INFINITE_GAME_GENESIS);
    stop_prank(CheatTarget::All(()));
    stop_warp(CheatTarget::All(()));

    let bal1 = token.balance_of(creator);
    let sup1 = token.total_supply();

    assert(bal1 - bal0 == 1, 'Invalid user balance change');
    assert(sup1 - sup0 == 1, 'Invalid contract balance change');

    let snapshot = gol.view_snapshot(2);
    assert(snapshot.user_id == creator, 'Invalid snapshot user_id');
    assert(snapshot.game_state == acorn_evolved, 'Invalid snapshot state');
    assert(snapshot.timestamp == 222, 'Invalid snapshot gen');

    assert(gol.view_game(INFINITE_GAME_GENESIS, 1) == INFINITE_GAME_GENESIS, 'Invalid game_state');
    assert(gol.view_game(INFINITE_GAME_GENESIS, 2) == acorn_evolved + 1, 'Invalid game_state');
    assert(gol.get_current_generation(INFINITE_GAME_GENESIS) == 3, 'Invalid generation');

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

#[test]
fn test_give_life_to_cell() {
    let gol = deploy_contract('GoL2');
    let token = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let acorn_evolved = 0x100030006e0000000000000000000000000000;
    let mut spy = spy_events(SpyOn::One(gol.contract_address));
    let creator = contract_address_const::<'creator'>();
    start_prank(CheatTarget::All(()), creator);

    gol.evolve(INFINITE_GAME_GENESIS);

    let bal0 = token.balance_of(creator);
    let sup0 = token.total_supply();

    gol.give_life_to_cell(3);

    let bal1 = token.balance_of(creator);
    let sup1 = token.total_supply();

    assert(bal0 - bal1 == GIVE_LIFE_CREDIT_REQUIREMENT.into(), 'Invalid user balance change');
    assert(sup0 - sup1 == GIVE_LIFE_CREDIT_REQUIREMENT.into(), 'Invalid contract balance change');

    assert(gol.view_game(INFINITE_GAME_GENESIS, 1) == INFINITE_GAME_GENESIS, 'Invalid game_state');
    assert(gol.view_game(INFINITE_GAME_GENESIS, 2) == acorn_evolved + 8, 'Invalid game_state');
    assert(gol.get_current_generation(INFINITE_GAME_GENESIS) == 2, 'Invalid generation');

    spy
        .assert_emitted(
            @array![
                (
                    gol.contract_address,
                    GoL2::Event::CellRevived(
                        GoL2::CellRevived {
                            user_id: creator,
                            generation: 2,
                            cell_index: 3,
                            state: acorn_evolved + 8,
                        }
                    )
                )
            ]
        );
    stop_prank(CheatTarget::All(()));
}

