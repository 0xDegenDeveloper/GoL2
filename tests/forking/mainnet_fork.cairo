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

/// Setup
fn deploy_contract(name: felt252) -> IGoL2Dispatcher {
    let contract = declare(name);
    let contract_address = contract.deploy(@array!['admin']).unwrap();
    IGoL2Dispatcher { contract_address }
}

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

#[test]
#[fork("MAINNET")]
fn test_migrate() {
    let user = contract_address_const::<'user'>();
    let old_gol_address = contract_address_const::<
        0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
    >();
    let admin = contract_address_const::<
        0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973
    >();

    /// Get old contract & class_hash
    let OldGol = IOldGolDispatcher { contract_address: old_gol_address };
    let old_hash = get_class_hash(OldGol.contract_address);

    /// Upgrade the proxy contract's impl hash
    let new_gol_hash = declare('GoL2').class_hash;
    start_prank(CheatTarget::All(()), admin);
    OldGol.upgrade(new_gol_hash.into());
    /// Migrate contract using syscall
    let mut spy = spy_events(SpyOn::One(old_gol_address));
    OldGol.migrate(new_gol_hash);
    stop_prank(CheatTarget::All(()));

    spy
        .assert_emitted(
            @array![
                (
                    old_gol_address,
                    OwnableComponent::Event::OwnershipTransferred(
                        OwnableComponent::OwnershipTransferred {
                            previous_owner: contract_address_const::<''>(), new_owner: admin
                        }
                    )
                )
            ]
        );

    /// New contract
    let updated_hash = get_class_hash(OldGol.contract_address);
    assert(old_hash != updated_hash, 'Class hash not changed');
    assert(updated_hash == new_gol_hash, 'Contract not upgraded correctly');
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Contract already migrated',))]
fn test_migrate_again() {
    let user = contract_address_const::<'user'>();
    let old_gol_address = contract_address_const::<
        0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
    >();
    let admin = contract_address_const::<
        0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973
    >();

    let OldGol = IOldGolDispatcher { contract_address: old_gol_address };

    /// Upgrade the proxy contract's impl hash
    let new_gol_hash = declare('GoL2').class_hash;
    start_prank(CheatTarget::All(()), admin);
    OldGol.upgrade(new_gol_hash.into());
    /// Migrate contract using syscall
    OldGol.migrate(new_gol_hash);
    OldGol.migrate(new_gol_hash);
    stop_prank(CheatTarget::All(()));
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Caller is not admin',))]
fn test_migrate_not_admin() {
    let user = contract_address_const::<'user'>();
    let old_gol_address = contract_address_const::<
        0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
    >();
    let admin = contract_address_const::<
        0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973
    >();
    let not_admin = contract_address_const::<'not admin'>();

    let OldGol = IOldGolDispatcher { contract_address: old_gol_address };

    /// Upgrade the proxy contract's impl hash
    let new_gol_hash = declare('GoL2').class_hash;
    start_prank(CheatTarget::All(()), admin);
    OldGol.upgrade(new_gol_hash.into());
    stop_prank(CheatTarget::All(()));
    /// Migrate contract using syscall
    start_prank(CheatTarget::All(()), not_admin);
    OldGol.migrate(new_gol_hash);
    stop_prank(CheatTarget::All(()));
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('Caller is not admin',))]
fn test_upgrade_not_admin() {
    let user = contract_address_const::<'user'>();
    let old_gol_address = contract_address_const::<
        0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
    >();
    let admin = contract_address_const::<
        0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973
    >();
    let not_admin = contract_address_const::<'not admin'>();

    let OldGol = IOldGolDispatcher { contract_address: old_gol_address };

    /// Upgrade the proxy contract's impl hash
    let new_gol_hash = declare('GoL2').class_hash;
    start_prank(CheatTarget::All(()), admin);
    OldGol.upgrade(new_gol_hash.into());
    stop_prank(CheatTarget::All(()));
    /// Migrate contract using syscall
    start_prank(CheatTarget::All(()), not_admin);
    OldGol.migrate(new_gol_hash);
    stop_prank(CheatTarget::All(()));
}

#[test]
#[fork("MAINNET")]
fn test_post_migration_state() {
    let user = contract_address_const::<'user'>();
    let user2 = contract_address_const::<'user2'>();
    let old_gol_address = contract_address_const::<
        0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
    >();
    let admin = contract_address_const::<
        0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973
    >();

    let OldGol = IOldGolDispatcher { contract_address: old_gol_address };

    /// Give user some tokens
    let mut i = 100;
    start_prank(CheatTarget::All(()), user);
    loop {
        if i == 0 {
            break ();
        }
        OldGol.evolve(INFINITE_GAME_GENESIS);
        i -= 1;
    };

    /// Set fake allowances
    let user2 = contract_address_const::<'user2'>();
    let fake_allowance = 100;
    OldGol.approve(user2.into(), fake_allowance);
    stop_prank(CheatTarget::All(()));

    /// ERC20
    let old_name = OldGol.name();
    let old_symbol = OldGol.symbol();
    let old_total_supply = OldGol.totalSupply();
    let old_decimals = OldGol.decimals();
    let old_balance = OldGol.balanceOf(user.into());
    let old_allowance = OldGol.allowance(user.into(), user2.into()); // owner, spender
    /// Game
    let old_generation = OldGol.get_current_generation(INFINITE_GAME_GENESIS);
    let old_view_game = OldGol
        .view_game(INFINITE_GAME_GENESIS, old_generation - 100); // before loop messes with things

    /// Migrate
    let new_gol_hash = declare('GoL2').class_hash;
    start_prank(CheatTarget::All(()), admin);
    OldGol.upgrade(new_gol_hash.into());
    OldGol.migrate(new_gol_hash);
    stop_prank(CheatTarget::All(()));

    let NewGol = IGoL2Dispatcher { contract_address: old_gol_address };
    let NewERC20 = ERC20ABIDispatcher { contract_address: old_gol_address };

    /// ERC20
    let new_name = NewERC20.name();
    let new_symbol = NewERC20.symbol();
    let new_total_supply = NewERC20.total_supply();
    let new_decimals = NewERC20.decimals();
    let new_balance = NewERC20.balance_of(user.into());
    let new_allowance = NewERC20.allowance(user.into(), user2.into());
    /// Game
    let new_generation = NewGol.get_current_generation(INFINITE_GAME_GENESIS);
    let new_view_game = NewGol.view_game(INFINITE_GAME_GENESIS, new_generation);
    /// ERC20
    let new_name = NewERC20.name();
    let new_symbol = NewERC20.symbol();
    let new_total_supply = NewERC20.total_supply();
    let new_decimals = NewERC20.decimals();
    let new_balance = NewERC20.balance_of(user.into());
    let new_allowance = NewERC20.allowance(user.into(), user2.into());
    /// Game
    let new_generation = NewGol.get_current_generation(INFINITE_GAME_GENESIS);
    let new_view_game = NewGol
        .view_game(INFINITE_GAME_GENESIS, new_generation - 100); // before loop messes with things

    assert(old_name == new_name, 'name should be the same');
    assert(old_symbol == new_symbol, 'symbol should be the same');
    assert(old_total_supply == new_total_supply, 'total supply should be the same');
    assert(old_decimals == new_decimals, 'decimals should be the same');
    assert(old_balance == new_balance, 'balance should be the same');
    assert(old_generation == new_generation, 'generation should be the same');
    assert(old_view_game == new_view_game, 'view game should be the same');
    assert(old_allowance == new_allowance, 'allowance should be the same');
}

#[test]
#[fork("MAINNET")]
fn test_post_migration_envoking() {
    let user = contract_address_const::<'user'>();
    let user2 = contract_address_const::<'user2'>();
    let old_gol_address = contract_address_const::<
        0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
    >();
    let admin = contract_address_const::<
        0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973
    >();

    let OldGol = IOldGolDispatcher { contract_address: old_gol_address };

    /// Give user some tokens
    let mut i = 100;
    start_prank(CheatTarget::All(()), user);
    loop {
        if i == 0 {
            break ();
        }
        OldGol.evolve(INFINITE_GAME_GENESIS);
        i -= 1;
    };

    /// Set fake allowances
    let user2 = contract_address_const::<'user2'>();
    let fake_allowance = 100;
    OldGol.approve(user2.into(), fake_allowance);
    stop_prank(CheatTarget::All(()));

    /// Migrate
    let new_gol_hash = declare('GoL2').class_hash;
    start_prank(CheatTarget::All(()), admin);
    OldGol.upgrade(new_gol_hash.into());
    OldGol.migrate(new_gol_hash);
    stop_prank(CheatTarget::All(()));

    let NewGol = IGoL2Dispatcher { contract_address: old_gol_address };
    let NewERC20 = ERC20ABIDispatcher { contract_address: old_gol_address };

    let new_name = NewERC20.name();
    let new_symbol = NewERC20.symbol();
    let new_total_supply = NewERC20.total_supply();
    let new_decimals = NewERC20.decimals();
    let new_balance = NewERC20.balance_of(user.into());
    let new_allowance = NewERC20.allowance(user.into(), user2.into());
    let new_generation = NewGol.get_current_generation(INFINITE_GAME_GENESIS);
    let new_view_game = NewGol.view_game(INFINITE_GAME_GENESIS, new_generation);

    /// Token functionality
    let amount = 10;
    start_prank(CheatTarget::All(()), user2);
    NewERC20.transfer_from(user, user2, amount);
    NewERC20.transfer(user, amount / 2);
    stop_prank(CheatTarget::All(()));
    assert(NewERC20.balance_of(user) == new_balance - amount / 2, 'transfer fails');
    assert(NewERC20.balance_of(user2) == amount / 2, 'transfer fails');
    // Allowance
    start_prank(CheatTarget::All(()), user);
    NewERC20.increase_allowance(user2, 100);
    NewERC20.decrease_allowance(user2, 99);
    assert(NewERC20.allowance(user, user2) == new_allowance - amount + 1, 'allowance fails');
    /// Game functionality (includes minting/burning)
    start_prank(CheatTarget::All(()), user);
    let bal_init = NewERC20.balance_of(user);
    NewGol.create('gamestate'); // cost is CREATE_CREDIT_REQUIREMENT
    NewGol.evolve('gamestate'); // reward is 1
    NewGol.give_life_to_cell(0); // reward is GIVE_LIFE_CREDIT_REQUIREMENT
    stop_prank(CheatTarget::All(()));
    assert(
        NewGol.get_current_generation(INFINITE_GAME_GENESIS) == new_generation, 'give life fails0'
    );
    assert(NewGol.get_current_generation('gamestate') == 2, 'evolve fails');
    assert(
        NewGol.view_game(INFINITE_GAME_GENESIS, new_generation) == new_view_game + 1,
        'give life fails1'
    );
    assert(NewERC20.balance_of(user) == bal_init - 10, 'mintig/burning off');
    assert(NewERC20.total_supply() == new_total_supply - 10, 'mintig/burning off');
}

