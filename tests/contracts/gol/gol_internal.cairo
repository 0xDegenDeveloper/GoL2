use starknet::contract_address_const;
use gol2::{
    contracts::gol::{GoL2, IGoL2Dispatcher, IGoL2DispatcherTrait},
    utils::{math::raise_to_power, constants::INFINITE_GAME_GENESIS}
};

use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget,};
use openzeppelin::token::erc20::{ERC20Component, ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use debug::PrintTrait;

#[test]
fn test_assert_game_exists() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::create_new_game(ref state, INFINITE_GAME_GENESIS, caller);
    GoL2::HelperImpl::assert_game_exists(@state, INFINITE_GAME_GENESIS, 1);
}

#[test]
#[should_panic(expected: ('Game has not been started',))]
fn test_assert_game_exists_not_started() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::assert_game_exists(@state, INFINITE_GAME_GENESIS, 1);
}

#[test]
#[should_panic(expected: ('Generation does not exist yet',))]
fn test_assert_game_exists_not_evolved_yet() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::create_new_game(ref state, INFINITE_GAME_GENESIS, caller);
    GoL2::HelperImpl::assert_game_exists(@state, INFINITE_GAME_GENESIS, 2);
}

#[test]
fn test_assert_game_does_not_exist() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::assert_game_does_not_exist(@state, INFINITE_GAME_GENESIS);
}

#[test]
#[should_panic(expected: ('Game already exists',))]
fn test_assert_game_does_not_exist_already_started() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::create_new_game(ref state, INFINITE_GAME_GENESIS, caller);
    GoL2::HelperImpl::assert_game_does_not_exist(@state, INFINITE_GAME_GENESIS);
}

#[test]
fn test_assert_valid_cell_index() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::assert_valid_cell_index(@state, 0);
    GoL2::HelperImpl::assert_valid_cell_index(@state, 1);
    GoL2::HelperImpl::assert_valid_cell_index(@state, 224);
}

#[test]
#[should_panic(expected: ('Cell index out of range',))]
fn test_assert_valid_cell_index_out_of_range() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::assert_valid_cell_index(@state, 225);
}

#[test]
fn test_assert_valid_new_game() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::assert_valid_new_game(@state, 0);
    GoL2::HelperImpl::assert_valid_new_game(@state, 1);
    GoL2::HelperImpl::assert_valid_new_game(
        @state, (raise_to_power(2, 225) - 1).try_into().unwrap()
    );
}

#[test]
#[should_panic(expected: ('Game size too big',))]
fn test_assert_valid_new_game_too_big() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::assert_valid_new_game(@state, (raise_to_power(2, 225)).try_into().unwrap());
}

// todo
#[test]
fn test_reward_user() {
    let user = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    let mut comp = ERC20Component::HasComponent::get_component_mut(ref state);
    let bal0 = ERC20Component::ERC20::balance_of(@comp, user);
    let sup0 = ERC20Component::ERC20::total_supply(@comp);
    GoL2::HelperImpl::reward_user(ref state, user);
    let bal1 = ERC20Component::ERC20::balance_of(@comp, user);
    let sup1 = ERC20Component::ERC20::total_supply(@comp);
    assert(bal1 - bal0 == 1, 'Balance should be correct');
    assert(sup1 - sup0 == 1, 'Total supply should be correct');
}

// todo
#[test]
fn test_pay() {
    let user = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    let mut comp = ERC20Component::HasComponent::get_component_mut(ref state);

    GoL2::HelperImpl::reward_user(ref state, user);
    GoL2::HelperImpl::reward_user(ref state, user);
    GoL2::HelperImpl::reward_user(ref state, user);

    let bal1 = ERC20Component::ERC20::balance_of(@comp, user);
    let sup1 = ERC20Component::ERC20::total_supply(@comp);

    GoL2::HelperImpl::pay(ref state, user, 1);
    GoL2::HelperImpl::pay(ref state, user, 1);

    let bal2 = ERC20Component::ERC20::balance_of(@comp, user);
    let sup2 = ERC20Component::ERC20::total_supply(@comp);

    assert(bal1 - bal2 == 2, 'Balance should be correct');
    assert(sup1 - sup2 == 2, 'Total supply should be correct');
}

// todo
#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn test_pay_not_enough_credits() {
    let user = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    let mut comp = ERC20Component::HasComponent::get_component_mut(ref state);

    GoL2::HelperImpl::reward_user(ref state, user);
    GoL2::HelperImpl::reward_user(ref state, user);

    GoL2::HelperImpl::pay(ref state, user, 3)
}


#[test]
fn test_ensure_user_authenticated() {
    let mut state = GoL2::contract_state_for_testing();
    let user = contract_address_const::<'user'>();
    start_prank(CheatTarget::All(()), user);
    let caller = GoL2::HelperImpl::ensure_user(@state);
    assert(caller == user, 'User should be ensured');
    stop_prank(CheatTarget::All(()));
}

#[test]
#[should_panic(expected: ('User not authenticated',))]
fn test_ensure_user_not_authenticated() {
    let mut state = GoL2::contract_state_for_testing();
    start_prank(CheatTarget::All(()), contract_address_const::<0>());
    let caller = GoL2::HelperImpl::ensure_user(@state);
    stop_prank(CheatTarget::All(()));
}

#[test]
fn test_get_game() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::create_new_game(ref state, INFINITE_GAME_GENESIS, caller);
    let game_state = GoL2::HelperImpl::get_game(@state, INFINITE_GAME_GENESIS, 1);
    let generation = GoL2::HelperImpl::get_generation(@state, INFINITE_GAME_GENESIS);
    assert(game_state == INFINITE_GAME_GENESIS, 'Genesis should be correct');
}

#[test]
fn test_get_generation() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::create_new_game(ref state, INFINITE_GAME_GENESIS, caller);
    let generation = GoL2::HelperImpl::get_generation(@state, INFINITE_GAME_GENESIS);
    assert(generation == 1, 'Generation should be correct');
}

#[test]
fn test_get_last_state() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::create_new_game(ref state, INFINITE_GAME_GENESIS, caller);
    let (generation, game_state) = GoL2::HelperImpl::get_last_state(@state);
    assert(game_state == INFINITE_GAME_GENESIS, 'Genesis should be correct');
    assert(generation == 1, 'Generation should be correct');
}

#[test]
fn test_evolve_game() {
    let acorn = 0x7300100008000000000000000000000000;
    let acorn_evolution = 0x100030006e0000000000000000000000000000;
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::create_new_game(ref state, acorn, caller);

    let (generation, packed_game) = GoL2::HelperImpl::evolve_game(ref state, acorn, caller);

    assert(generation == 2, 'Generation should be correct');
    assert(packed_game == acorn_evolution, 'Game should be correct');
}

#[test]
fn test_activate_cell() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::create_new_game(ref state, INFINITE_GAME_GENESIS, caller);

    GoL2::HelperImpl::activate_cell(ref state, 1, caller, 0, INFINITE_GAME_GENESIS);
    let (generation, packed_game) = GoL2::HelperImpl::get_last_state(@state);

    assert(generation == 1, 'Generation should be correct');
    assert(packed_game == INFINITE_GAME_GENESIS + 1, 'State should be correct');
}

#[test]
#[should_panic(expected: ('No changes made to game',))]
fn test_activate_cell_no_changes() {
    let caller = contract_address_const::<'user'>();
    let mut state = GoL2::contract_state_for_testing();
    GoL2::HelperImpl::create_new_game(ref state, INFINITE_GAME_GENESIS, caller);
    GoL2::HelperImpl::activate_cell(ref state, 1, caller, 99, INFINITE_GAME_GENESIS);
}

