use starknet::contract_address_const;
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions
};
use gol2::{
    contracts::gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
    utils::{
        math::raise_to_power,
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, CREATE_CREDIT_REQUIREMENT,
            GIVE_LIFE_CREDIT_REQUIREMENT, INITIAL_ADMIN, BOARD_SQUARED
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
    assert(BOARD_SQUARED == DIM * DIM, 'Wrong BOARD_SQUARED');
    assert(
        INITIAL_ADMIN == 0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973,
        'Wrong INITIAL_ADMIN'
    );
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
fn test_get_snapshot_creator() {
    let gol = deploy_contract('GoL2');
    let user = contract_address_const::<'user'>();
    let user2 = contract_address_const::<'user2'>();
    start_prank(CheatTarget::All(()), user);
    gol.evolve(INFINITE_GAME_GENESIS);
    stop_prank(CheatTarget::All(()));
    start_prank(CheatTarget::All(()), user2);
    gol.evolve(INFINITE_GAME_GENESIS);
    stop_prank(CheatTarget::All(()));

    let creator1 = gol.get_snapshot_creator(1);
    let creator2 = gol.get_snapshot_creator(2);
    let creator3 = gol.get_snapshot_creator(3);
    assert(creator1 == contract_address_const::<''>(), 'Invalid creator1');
    assert(creator2 == user, 'Invalid creator2');
    assert(creator3 == user2, 'Invalid creator3');
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
    let creator10 = gol
        .get_snapshot_creator(10); // evolutions 2-11 were done by creator to get credits above
    let creator11 = gol.get_snapshot_creator(11);
    let creator12 = gol.get_snapshot_creator(12);
    let creator13 = gol.get_snapshot_creator(13);
    assert(creator10 == creator, 'Invalid creator10');
    assert(creator11 == creator, 'Invalid creator11');
    assert(creator12 == contract_address_const::<''>(), 'Invalid creator12');
    assert(creator13 == contract_address_const::<''>(), 'Invalid creator13');
}

#[test]
fn test_evolve() {
    let gol = deploy_contract('GoL2');
    let token = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let mut spy = spy_events(SpyOn::One(gol.contract_address));
    let creator = contract_address_const::<'creator'>();
    let acorn_evolved = 0x100030006e0000000000000000000000000000;
    start_prank(CheatTarget::All(()), creator);

    let bal0 = token.balance_of(creator);
    let sup0 = token.total_supply();

    gol.evolve(INFINITE_GAME_GENESIS);

    let bal1 = token.balance_of(creator);
    let sup1 = token.total_supply();

    assert(bal1 - bal0 == 1, 'Invalid user balance change');
    assert(sup1 - sup0 == 1, 'Invalid contract balance change');

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

