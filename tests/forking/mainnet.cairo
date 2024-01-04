use starknet::{contract_address_const, ClassHash, call_contract_syscall};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash, EventFetcher, event_name_hash, Event
};
use gol2::{
    contracts::gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
    utils::constants::{
        INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
        FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, CREATE_CREDIT_REQUIREMENT,
        GIVE_LIFE_CREDIT_REQUIREMENT
    },
};
use openzeppelin::{
    access::ownable::{OwnableComponent, interface::{IOwnableDispatcher, IOwnableDispatcherTrait}},
    upgrades::{
        UpgradeableComponent,
        interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait},
    },
    token::erc20::{ERC20Component, ERC20ABIDispatcher, ERC20ABIDispatcherTrait},
};
use debug::PrintTrait;
use super::super::contracts::setup::{deploy_mocks, mock_whitelist_setup};


#[starknet::interface]
trait IOldGol<TContractState> {
    /// Read
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn totalSupply(self: @TContractState) -> u256;
    fn decimals(self: @TContractState) -> u8;
    fn balanceOf(self: @TContractState, owner: felt252) -> u256;
    fn allowance(self: @TContractState, owner: felt252, spender: felt252) -> u256;
    fn view_game(self: @TContractState, game_id: felt252, generation: felt252) -> felt252;
    fn get_current_generation(self: @TContractState, game_id: felt252) -> felt252;
    fn migration_generation_marker(self: @TContractState) -> felt252;
    /// Write
    fn migrate(self: @TContractState, new_class_hash: ClassHash);
    fn transfer(self: @TContractState, to: felt252, value: u256);
    fn transferFrom(self: @TContractState, from: felt252, to: felt252, value: u256);
    fn approve(self: @TContractState, spender: felt252, value: u256);
    fn increaseAllowance(self: @TContractState, spender: felt252, added_value: u256);
    fn decreaseAllowance(self: @TContractState, spender: felt252, subtracted_value: u256);
    fn upgrade(self: @TContractState, implementation_hash: felt252);
    fn create(self: @TContractState, game_state: felt252);
    fn evolve(ref self: TContractState, game_id: felt252);
    fn give_life_to_cell(ref self: TContractState, cell_index: felt252);
}

/// Setup
fn get_gol_address() -> starknet::ContractAddress {
    contract_address_const::<0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0>()
}

fn get_admin_address() -> starknet::ContractAddress {
    contract_address_const::<0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973>()
}

// as admin
fn do_migration() -> (IGoL2Dispatcher, starknet::ContractAddress, starknet::ClassHash) {
    do_migration_as(get_admin_address())
}

// proxy call is from admin, migrate call is from user
fn do_migration_as(
    user: starknet::ContractAddress
) -> (IGoL2Dispatcher, starknet::ContractAddress, starknet::ClassHash) {
    let gol_address = get_gol_address();
    let old_gol = IOldGolDispatcher { contract_address: gol_address };
    /// Pt1: Upgrade the proxy contract's impl hash
    let new_gol_hash = declare('GoL2').class_hash;
    start_prank(CheatTarget::All(()), get_admin_address());
    old_gol.upgrade(new_gol_hash.into());
    stop_prank(CheatTarget::All(()));
    /// Pt2: Migrate contract using syscall
    start_prank(CheatTarget::All(()), user);
    old_gol.migrate(new_gol_hash);
    stop_prank(CheatTarget::All(()));
    (IGoL2Dispatcher { contract_address: gol_address }, user, new_gol_hash)
}

/// Tests

#[test]
#[fork("MAINNET")]
fn test_migrate() {
    let gol_address = get_gol_address();
    let old_hash = get_class_hash(gol_address);
    let mut spy = spy_events(SpyOn::One(gol_address));
    let (gol, admin, new_class_hash) = do_migration();
    spy
        .assert_emitted(
            @array![
                (
                    gol_address,
                    OwnableComponent::Event::OwnershipTransferred(
                        OwnableComponent::OwnershipTransferred {
                            previous_owner: contract_address_const::<''>(), new_owner: admin
                        }
                    )
                )
            ]
        );

    /// New contract
    let updated_hash = get_class_hash(gol_address);
    assert(old_hash != updated_hash, 'Class hash not changed');
    assert(updated_hash == new_class_hash, 'Contract not upgraded correctly');
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Contract already migrated',))]
fn test_migrate_again() {
    let (gol, admin, _) = do_migration();
    start_prank(CheatTarget::All(()), admin);
    gol.migrate(get_class_hash(gol.contract_address));
    stop_prank(CheatTarget::All(()));
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Caller is not prev admin',))]
fn test_migrate_not_admin() {
    do_migration_as(contract_address_const::<'not admin'>());
}

#[test]
#[fork("MAINNET")]
fn test_post_migration_state() {
    let user = contract_address_const::<'user'>();
    let user2 = contract_address_const::<'user2'>();
    let old_gol = IOldGolDispatcher { contract_address: get_gol_address() };

    /// Init balances
    let mut i = 100;
    start_prank(CheatTarget::All(()), user);
    loop {
        if i == 0 {
            break ();
        }
        old_gol.evolve(INFINITE_GAME_GENESIS);
        i -= 1;
    };

    /// Init allowances
    let user2 = contract_address_const::<'user2'>();
    let fake_allowance = 100;
    old_gol.approve(user2.into(), fake_allowance);
    stop_prank(CheatTarget::All(()));

    /// old state
    let (old_name, old_symbol, old_total_supply, old_decimals, old_balance, old_allowance) = (
        old_gol.name(),
        old_gol.symbol(),
        old_gol.totalSupply(),
        old_gol.decimals(),
        old_gol.balanceOf(user.into()),
        old_gol.allowance(user.into(), user2.into())
    );
    let old_generation = old_gol.get_current_generation(INFINITE_GAME_GENESIS);
    let old_view_game = old_gol
        .view_game(INFINITE_GAME_GENESIS, old_generation - 100); // before loop messes with things
    /// Migrate
    let (new_gol, _, _) = do_migration();
    let new_erc20 = ERC20ABIDispatcher { contract_address: get_gol_address() };
    /// new state
    let (new_name, new_symbol, new_total_supply, new_decimals, new_balance, new_allowance) = (
        new_erc20.name(),
        new_erc20.symbol(),
        new_erc20.total_supply(),
        new_erc20.decimals(),
        new_erc20.balance_of(user.into()),
        new_erc20.allowance(user.into(), user2.into())
    );
    let new_generation = new_gol.get_current_generation(INFINITE_GAME_GENESIS);
    let new_view_game = new_gol.view_game(INFINITE_GAME_GENESIS, new_generation - 100);
    let migration_generation_marker = new_gol.migration_generation_marker();
    assert(old_name == new_name, 'name should be the same');
    assert(old_symbol == new_symbol, 'symbol should be the same');
    assert(old_total_supply == new_total_supply, 'total supply should be the same');
    assert(old_decimals == new_decimals, 'decimals should be the same');
    assert(old_balance == new_balance, 'balance should be the same');
    assert(old_generation == new_generation, 'generation should be the same');
    assert(old_view_game == new_view_game, 'view game should be the same');
    assert(old_allowance == new_allowance, 'allowance should be the same');
    assert(migration_generation_marker == new_generation, 'migration gens saved wrong');
    assert(migration_generation_marker != 0, 'migration gens saved wrong');
}

#[test]
#[fork("MAINNET")]
fn test_post_migration_envoking() {
    let user = contract_address_const::<'user'>();
    let user2 = contract_address_const::<'user2'>();
    let old_gol = IOldGolDispatcher { contract_address: get_gol_address() };

    /// Init balances
    let mut i = 100;
    start_prank(CheatTarget::All(()), user);
    loop {
        if i == 0 {
            break ();
        }
        old_gol.evolve(INFINITE_GAME_GENESIS);
        i -= 1;
    };

    /// Init allowances
    let user2 = contract_address_const::<'user2'>();
    let fake_allowance = 100;
    old_gol.approve(user2.into(), fake_allowance);
    stop_prank(CheatTarget::All(()));

    /// Migrate
    let (new_gol, _, _) = do_migration();
    let new_erc20 = ERC20ABIDispatcher { contract_address: get_gol_address() };

    let new_total_supply = new_erc20.total_supply();
    let new_balance = new_erc20.balance_of(user.into());
    let new_allowance = new_erc20.allowance(user.into(), user2.into());
    let new_generation = new_gol.get_current_generation(INFINITE_GAME_GENESIS);
    let new_view_game = new_gol.view_game(INFINITE_GAME_GENESIS, new_generation);

    /// Token functionality
    let amount = 10;
    start_prank(CheatTarget::All(()), user2);
    new_erc20.transfer_from(user, user2, amount);
    new_erc20.transfer(user, amount / 2);
    stop_prank(CheatTarget::All(()));
    assert(new_erc20.balance_of(user) == new_balance - amount / 2, 'transfer fails');
    assert(new_erc20.balance_of(user2) == amount / 2, 'transfer fails');
    // Allowance
    start_prank(CheatTarget::All(()), user);
    new_erc20.increase_allowance(user2, 100);
    new_erc20.decrease_allowance(user2, 99);
    assert(new_erc20.allowance(user, user2) == new_allowance - amount + 1, 'allowance fails');
    /// Game functionality (includes minting/burning)
    start_prank(CheatTarget::All(()), user);
    let bal_init = new_erc20.balance_of(user);
    new_gol.create('gamestate'); // cost is CREATE_CREDIT_REQUIREMENT
    new_gol.evolve('gamestate'); // reward is 1
    new_gol.give_life_to_cell(0); // reward is GIVE_LIFE_CREDIT_REQUIREMENT
    stop_prank(CheatTarget::All(()));
    assert(
        new_gol.get_current_generation(INFINITE_GAME_GENESIS) == new_generation, 'give life fails0'
    );
    assert(new_gol.get_current_generation('gamestate') == 2, 'evolve fails');
    assert(
        new_gol.view_game(INFINITE_GAME_GENESIS, new_generation) == new_view_game + 1,
        'give life fails1'
    );
    assert(new_erc20.balance_of(user) == bal_init - 10, 'mintig/burning off');
    assert(new_erc20.total_supply() == new_total_supply - 10, 'mintig/burning off');
}

/// Snapshot tests:
/// need to be here because migration utilizes the `Proxy_admin` storage var slot.
/// only exists in cairo0 version of the code.
#[test]
#[fork("MAINNET")]
fn test_is_snapshotter() {
    let (gol, _, _) = do_migration();
    let caller = contract_address_const::<'caller'>();
    assert(gol.is_snapshotter(caller) == false, 'Invalid snapshotter init');
}

#[test]
#[fork("MAINNET")]
fn test_set_snapshotter_owner() {
    let (gol, admin, _) = do_migration();
    let caller = contract_address_const::<'caller'>();
    start_prank(CheatTarget::One(gol.contract_address), admin);
    gol.set_snapshotter(caller, true);
    assert(gol.is_snapshotter(caller) == true, 'Invalid snapshotter set');
    gol.set_snapshotter(caller, false);
    assert(gol.is_snapshotter(caller) == false, 'Invalid snapshotter unset');
    stop_prank(CheatTarget::One(gol.contract_address));
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_snapshotter_non_owner() {
    let (gol, _, _) = do_migration();
    let caller = contract_address_const::<'caller'>();
    start_prank(CheatTarget::One(gol.contract_address), caller);
    gol.set_snapshotter(caller, true);
    stop_prank(CheatTarget::One(gol.contract_address));
}

#[test]
#[fork("MAINNET")]
fn test_add_snapshot_with_permit() {
    let (gol, admin, _) = do_migration();
    let user = contract_address_const::<'user'>();
    // set permit
    start_prank(CheatTarget::One(gol.contract_address), admin);
    gol.set_snapshotter(user, true);
    stop_prank(CheatTarget::One(gol.contract_address));
    // add snapshot
    let game_state = 'random';
    let timestamp = 123;
    start_prank(CheatTarget::One(gol.contract_address), user);
    gol
        .add_snapshot(
            gol.migration_generation_marker(), user, game_state, timestamp
        ); // last one allowed to be added manually
    gol.add_snapshot(gol.migration_generation_marker() - 1, user, game_state, timestamp);
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('GoL2: caller non snapshotter',))]
fn test_add_snapshot_no_permit() {
    let (gol, _, _) = do_migration();
    let user = contract_address_const::<'user'>();
    let game_state = 'random';
    let timestamp = 123;

    start_prank(CheatTarget::One(gol.contract_address), user);
    gol.add_snapshot(3, user, game_state, timestamp);
    stop_prank(CheatTarget::One(gol.contract_address));
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('GoL2: not from pre-migration',))]
fn test_add_snapshot_0_generation() {
    let (gol, admin, _) = do_migration();
    let user = contract_address_const::<'user'>();
    // set permit
    start_prank(CheatTarget::One(gol.contract_address), admin);
    gol.set_snapshotter(user, true);
    stop_prank(CheatTarget::One(gol.contract_address));
    // add snapshot
    let game_state = 'random';
    let timestamp = 123;
    start_prank(CheatTarget::One(gol.contract_address), user);
    gol.add_snapshot(0, user, game_state, timestamp);
    stop_prank(CheatTarget::One(gol.contract_address));
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('GoL2: not from pre-migration',))]
fn test_add_snapshot_non_pre_migration() {
    let (gol, admin, _) = do_migration();
    let user = contract_address_const::<'user'>();
    // set permit
    start_prank(CheatTarget::One(gol.contract_address), admin);
    gol.set_snapshotter(user, true);
    stop_prank(CheatTarget::One(gol.contract_address));
    // add snapshot
    let game_state = 'random';
    let timestamp = 123;
    start_prank(CheatTarget::One(gol.contract_address), user);
    gol.add_snapshot(gol.migration_generation_marker() + 1, user, game_state, timestamp);
    stop_prank(CheatTarget::One(gol.contract_address));
}

