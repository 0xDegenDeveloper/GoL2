use starknet::{contract_address_const, ClassHash, call_contract_syscall, ContractAddress};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash, EventFetcher, event_name_hash, Event
};
use gol2::{
    contracts::{
        gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
        nft::{IGoL2NFTDispatcher, IGoL2NFTDispatcherTrait,}
    },
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
    token::{
        erc20::{ERC20Component, ERC20ABIDispatcher, ERC20ABIDispatcherTrait},
        erc721::{ERC721Component, interface::{IERC721, IERC721Dispatcher, IERC721DispatcherTrait}}
    },
};
use core::{poseidon::{poseidon_hash_span, PoseidonTrait}};

use debug::PrintTrait;
use super::super::contracts::setup::{deploy_mocks, mock_whitelist_setup, MERKLE_ROOT};

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

fn deploy_nft(gol: IGoL2Dispatcher) -> IGoL2NFTDispatcher {
    let nft = declare('GoL2NFT');
    let nft_address = nft
        .deploy(
            @array![
                get_admin_address().into(), // owner
                'Game of Life NFT', // name
                'GoL2NFT', // symbol
                gol.contract_address.into(), // gol addr
                gol.contract_address.into(), // mint token address
                1, //price.low
                0, //price.high
                /// this hash is for a poseidon tree in ./whitelist/fork_whitelist.json
                0x0595d834a768d680188fce9858f850eeaf8926f86b54238e30fecc53f6317962, // poseidon root
            ]
        )
        .unwrap();

    IGoL2NFTDispatcher { contract_address: nft_address }
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

/// Snapshot & Whitelist tests:
/// These tests need to use snapshotters which is only possible with fork tests.
/// The migration utilizes the `Proxy_admin` storage var that only exists
/// in the cairo0 instance of the contract.
/// Doing this with mocks is not possible because the owner of the contract
/// will be 0x0, and you cannot call .only_owner() using the 0x0 address.
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
    let marker = gol.migration_generation_marker();
    start_prank(CheatTarget::One(gol.contract_address), user);
    assert(
        gol.add_snapshot(marker, user, game_state, timestamp), 'Call fail'
    ); // last one allowed to be added manually
    assert(gol.add_snapshot(marker - 1, user, game_state, timestamp), 'Call fail');
    let s = GoL2::Snapshot { user_id: user, game_state, timestamp };
    let s1 = gol.view_snapshot(marker);
    let s2 = gol.view_snapshot(marker - 1);
    assert(s1.user_id == s.user_id, 'Snapshot not added');
    assert(s1.game_state == s.game_state, 'Snapshot not added');
    assert(s1.timestamp == s.timestamp, 'Snapshot not added');
    assert(s2.user_id == s.user_id, 'Snapshot not added');
    assert(s2.game_state == s.game_state, 'Snapshot not added');
    assert(s2.timestamp == s.timestamp, 'Snapshot not added');
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
fn test_add_snapshot_for_0_generation() {
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
fn test_add_snapshot_for_non_pre_migration() {
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

/// Whitelist

// todo: test snapshot added to gol
#[test]
#[fork("MAINNET")]
fn test_whitelist_mint() {
    let (gol, admin, _) = do_migration();
    let nft = deploy_nft(gol);

    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };

    /// spoof balance 
    start_prank(CheatTarget::One(gol.contract_address), admin);
    gol.evolve(INFINITE_GAME_GENESIS);
    gol.evolve(INFINITE_GAME_GENESIS);
    gol.evolve(INFINITE_GAME_GENESIS);
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 3);
    let user_bal0 = erc20.balance_of(admin); // 3
    /// Poseidon proofs for tokens 1, 2, 3
    let p1 = array![
        0x034a52adb2632dbf7214c10d9495fe423f6a43a8b72f2db428d769bbba8b428e,
        0x01eb30fc6beea707d5fa1d9218d2096e65c5c35f73b7c170bb2eee7811fb5201,
        0x01b1e46a9c846a98713182ed39bdb475512a756aee2a6382551686a11a192e27
    ];
    let p2 = array![
        0x01e30c6b953ecedbd1f9c82e98f89a7f690c927368182e1d01d40c3491448a97,
        0x01eb30fc6beea707d5fa1d9218d2096e65c5c35f73b7c170bb2eee7811fb5201,
        0x01b1e46a9c846a98713182ed39bdb475512a756aee2a6382551686a11a192e27
    ];
    let p3 = array![
        0x0,
        0x01fb7169b936dd880cb7ebc50e932a495a60e0084cdab94a681040cb4006e1a0,
        0x03266c210b30bff10f3415fecc52fc809b3858ba5100d00e58420ff6f52c15dd
    ];
    /// Set GoL2NFT as a snapshotter 
    gol.set_snapshotter(nft.contract_address, true);
    stop_prank(CheatTarget::One(gol.contract_address));
    /// Whitelist mint
    start_prank(CheatTarget::One(nft.contract_address), admin);
    nft.whitelist_mint(1, 0x7300100008000000000000000000000000, 1663268697, p1);
    nft.whitelist_mint(2, 0x100030006e0000000000000000000000000000, 1663315027, p2);
    nft.whitelist_mint(3, 0x18004a00740008000000000000000000000000, 1663315027, p3);
    stop_prank(CheatTarget::One(nft.contract_address));
    assert(user_bal0 - erc20.balance_of(admin) == 3, 'NFT: mint price fail');
    assert(nft_nft.owner_of(1) == admin, 'NFT: mint fail1');
    assert(nft_nft.owner_of(2) == admin, 'NFT: mint fail2');
    assert(nft_nft.owner_of(3) == admin, 'NFT: mint fail3');

    let snapshot1 = gol.view_snapshot(1);
    let snapshot2 = gol.view_snapshot(2);
    let snapshot3 = gol.view_snapshot(3);

    assert(snapshot1.user_id == admin, 'Snapshot not added');
    assert(snapshot1.game_state == 0x7300100008000000000000000000000000, 'Snapshot not added');
    assert(snapshot1.timestamp == 1663268697, 'Snapshot not added');
    assert(snapshot2.user_id == admin, 'Snapshot not added');
    assert(snapshot2.game_state == 0x100030006e0000000000000000000000000000, 'Snapshot not added');
    assert(snapshot2.timestamp == 1663315027, 'Snapshot not added');
    assert(snapshot3.user_id == admin, 'Snapshot not added');
    assert(snapshot3.game_state == 0x18004a00740008000000000000000000000000, 'Snapshot not added');
    assert(snapshot3.timestamp == 1663315027, 'Snapshot not added');
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('GoL2NFT: Invalid proof',))]
fn test_whitelist_mint_false_proof() {
    let (gol, admin, _) = do_migration();
    let nft = deploy_nft(gol);

    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };

    /// Spoof balance 
    start_prank(CheatTarget::One(gol.contract_address), admin);
    gol.evolve(INFINITE_GAME_GENESIS);
    gol.evolve(INFINITE_GAME_GENESIS);
    gol.evolve(INFINITE_GAME_GENESIS);
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 3);
    let user_bal0 = erc20.balance_of(admin); // 3
    /// Poseidon proofs for tokens 1, 2, 3
    let p1 = array![
        0x034a52adb2632dbf7214c10d9495fe423f6a43a8b72f2db428d769bbba8b428e,
        0x01eb30fc6beea707d5fa1d9218d2096e65c5c35f73b7c170bb2eee7811fb5201,
        0x01b1e46a9c846a98713182ed39bdb475512a756aee2a6382551686a11a192e27,
        0xbeef
    ];
    /// Set GoL2NFT as a snapshotter 
    gol.set_snapshotter(nft.contract_address, true);
    stop_prank(CheatTarget::One(gol.contract_address));
    /// Whitelist mint
    start_prank(CheatTarget::One(nft.contract_address), admin);
    nft.whitelist_mint(1, 0x7300100008000000000000000000000000, 1663268697, p1);
    stop_prank(CheatTarget::One(nft.contract_address));
}

#[test]
#[fork("MAINNET")]
#[should_panic(expected: ('GoL2NFT: Invalid proof',))]
fn test_whitelist_mint_false_caller() {
    let (gol, admin, _) = do_migration();
    let nft = deploy_nft(gol);
    let not_admin = contract_address_const::<'not admin'>();

    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };

    /// Spoof balance 
    start_prank(CheatTarget::One(gol.contract_address), admin);
    gol.evolve(INFINITE_GAME_GENESIS);
    gol.evolve(INFINITE_GAME_GENESIS);
    gol.evolve(INFINITE_GAME_GENESIS);
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 3);
    let user_bal0 = erc20.balance_of(admin); // 3
    /// Poseidon proofs for tokens 1, 2, 3
    let p1 = array![
        0x034a52adb2632dbf7214c10d9495fe423f6a43a8b72f2db428d769bbba8b428e,
        0x01eb30fc6beea707d5fa1d9218d2096e65c5c35f73b7c170bb2eee7811fb5201,
        0x01b1e46a9c846a98713182ed39bdb475512a756aee2a6382551686a11a192e27,
    ];
    /// Set GoL2NFT as a snapshotter 
    gol.set_snapshotter(nft.contract_address, true);
    stop_prank(CheatTarget::One(gol.contract_address));
    /// Whitelist mint
    start_prank(CheatTarget::One(nft.contract_address), not_admin);
    nft.whitelist_mint(1, 0x7300100008000000000000000000000000, 1663268697, p1);
    stop_prank(CheatTarget::One(nft.contract_address));
}
