use starknet::contract_address_const;
use gol2::{
    contracts::{
        gol::{GoL2, IGoL2Dispatcher, IGoL2DispatcherTrait},
        nft::{
            GoL2NFT, IGoL2NFTDispatcher, IGoL2NFTDispatcherTrait, IERC721Metadata,
            IERC721MetadataDispatcher, IERC721MetadataDispatcherTrait
        },
    },
    utils::{
        constants::{INFINITE_GAME_GENESIS, LOW_ARRAY_LEN, HIGH_ARRAY_LEN},
        test_contract::{ITestTraitDispatcher, ITestTraitDispatcherTrait}
    }
};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash, start_warp, stop_warp,
};
use openzeppelin::{
    token::{
        erc20::{ERC20Component, ERC20ABIDispatcher, ERC20ABIDispatcherTrait},
        erc721::{ERC721Component, interface::{IERC721, IERC721Dispatcher, IERC721DispatcherTrait}}
    },
    access::ownable::{OwnableComponent, interface::{IOwnableDispatcher, IOwnableDispatcherTrait}},
    upgrades::{
        UpgradeableComponent,
        interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait}
    },
};
use alexandria_math::pow;
use debug::PrintTrait;
use super::super::setup::{MERKLE_ROOT, deploy_mocks, mock_whitelist_setup};

/// Constructor
#[test]
fn test_deploy() {
    let (gol, nft) = deploy_mocks();

    let nft_ownable = IOwnableDispatcher { contract_address: nft.contract_address };
    assert(nft_ownable.owner().into() == 'admin', 'NFT: owner incorrect');

    let nft_meta = IERC721MetadataDispatcher { contract_address: nft.contract_address };
    assert(nft_meta.name() == 'Game of Life NFT', 'NFT: name incorrect');
    assert(nft_meta.symbol() == 'GoL2NFT', 'NFT: symbol incorrect');

    assert(nft.mint_price() == 1, 'NFT: mint price incorrect');
    assert(nft.mint_token_address() == gol.contract_address, 'NFT: mint addr incorrect');
    assert(nft.merkle_root() == MERKLE_ROOT, 'NFT: merkle root incorrect');
}

/// Owner functionns
#[test]
fn test_set_mint_token_and_price_and_merkle_root_owner() {
    let (_, nft) = deploy_mocks();
    let admin = contract_address_const::<'admin'>();

    let new_root = 'new root';
    let new_price = 222_u256;
    let new_addr = contract_address_const::<'new_addr'>();

    start_prank(CheatTarget::All(()), admin);

    nft.set_merkle_root(new_root);
    nft.set_mint_price(new_price);
    nft.set_mint_token_address(new_addr);

    stop_prank(CheatTarget::All(()));

    assert(nft.merkle_root() == new_root, 'NFT: set merkle root fail');
    assert(nft.mint_price() == new_price, 'NFT: set mint price fail');
    assert(nft.mint_token_address() == new_addr, 'NFT: set mint addr fail');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_mint_token_non_owner() {
    let (_, nft) = deploy_mocks();
    let new_addr = starknet::contract_address_const::<'new_addr'>();
    nft.set_mint_token_address(new_addr);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_mint_price_non_owner() {
    let (_, nft) = deploy_mocks();
    let new_price = 222_u256;
    nft.set_mint_price(new_price);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_merkle_root_non_owner() {
    let (_, nft) = deploy_mocks();
    let new_root = 'new root';
    nft.set_merkle_root(new_root);
}

#[test]
fn test_withdraw_owner() {
    let (gol, nft) = deploy_mocks();
    let (user1, user2) = mock_whitelist_setup(gol);
    let user3 = contract_address_const::<'user3'>();
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    /// Give user1 1 gol token by evolving game
    start_prank(CheatTarget::All(()), user1);
    start_warp(CheatTarget::All(()), 222);
    gol.evolve(INFINITE_GAME_GENESIS);
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    stop_warp(CheatTarget::All(()));
    start_prank(CheatTarget::One(nft.contract_address), user1);

    let contract_balance0 = erc20.balance_of(nft.contract_address); // 0
    let user1_balance0 = erc20.balance_of(user1); // 3
    let user3_balance0 = erc20.balance_of(user3); // 0
    assert(
        array![contract_balance0, user1_balance0, user3_balance0] == array![0, 3, 0],
        'NFT: balance 0 fail'
    );
    /// Mint token
    nft.mint(6);
    stop_prank(CheatTarget::One(nft.contract_address));

    let contract_balance1 = erc20.balance_of(nft.contract_address); // 1
    let user1_balance1 = erc20.balance_of(user1); // 3-1=2
    let user3_balance1 = erc20.balance_of(user3); // 0
    assert(
        array![contract_balance1, user1_balance1, user3_balance1] == array![1, 2, 0],
        'NFT: balance 1 fail'
    );
    /// Withdraw
    start_prank(CheatTarget::One(nft.contract_address), contract_address_const::<'admin'>());
    nft.withdraw(gol.contract_address, 1, user3);
    stop_prank(CheatTarget::One(nft.contract_address));

    let contract_balance2 = erc20.balance_of(nft.contract_address); // 0
    let user1_balance2 = erc20.balance_of(user1); // 2
    let user3_balance2 = erc20.balance_of(user3); // 1
    assert(
        array![contract_balance2, user1_balance2, user3_balance2] == array![0, 2, 1],
        'NFT: balance 2 fail'
    );
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_withdraw_non_owner() {
    let (gol, nft) = deploy_mocks();
    let (user1, user2) = mock_whitelist_setup(gol);
    let user3 = contract_address_const::<'user3'>();
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    /// Give user1 1 gol token by evolving game
    start_prank(CheatTarget::All(()), user1);
    start_warp(CheatTarget::All(()), 222);
    gol.evolve(INFINITE_GAME_GENESIS);
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    stop_warp(CheatTarget::All(()));
    start_prank(CheatTarget::One(nft.contract_address), user1);
    /// Mint token
    nft.mint(6);
    stop_prank(CheatTarget::One(nft.contract_address));
    /// Withdraw
    start_prank(CheatTarget::One(nft.contract_address), contract_address_const::<'not admin'>());
    nft.withdraw(gol.contract_address, 1, user3);
    stop_prank(CheatTarget::One(nft.contract_address));
}

/// External functions

/// @dev These tests also cover mint_helper(), so 
/// it is ommitted in the whitelist minting tests.
#[test]
fn test_mint_snapshot_owner() {
    let (gol, nft) = deploy_mocks();
    let (user1, _) = mock_whitelist_setup(gol);
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };
    let nft_meta = IERC721MetadataDispatcher { contract_address: nft.contract_address };
    /// Give user1 10 gol tokens by evolving game 10 times
    start_prank(CheatTarget::All(()), user1);
    start_warp(CheatTarget::All(()), 222);
    let mut i = 0;
    loop {
        if i == 10 {
            break;
        }
        gol.evolve(INFINITE_GAME_GENESIS);
        i += 1;
    };
    let user_bal0 = erc20.balance_of(user1); // 10 + 2 from mock setup
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    stop_warp(CheatTarget::All(()));
    start_prank(CheatTarget::One(nft.contract_address), user1);
    /// Mint tokens (1 token each)
    let mut i = 6; // first 5 gens already evolved during mock setup
    loop {
        if i == 16 {
            break;
        }
        nft.mint(i);
        i += 1;
    };
    stop_prank(CheatTarget::One(nft.contract_address));
    let user_bal1 = erc20.balance_of(user1); // 2 left over from mock setup
    assert(user_bal0 - user_bal1 == 10, 'NFT: mint price fail');
    assert(nft_meta.total_supply() == 10, 'NFT: total supply fail');
    i = 6; // user1 evolved gens 6-15 (including 15)
    loop {
        if i == 16 {
            break;
        }
        assert(nft_nft.owner_of((i).into()) == user1, 'NFT: mint fail');
        let snapshot = gol.view_snapshot((i).into());
        assert(snapshot.user_id == user1, 'NFT: snapshot user_id fail');
        assert(snapshot.timestamp == 222, 'NFT: snapshot timestamp fail');
        assert(
            snapshot.game_state == gol.view_game(INFINITE_GAME_GENESIS, i.into()),
            'NFT: snapshot game_state fail'
        );
        i += 1;
    };
}

#[test]
#[should_panic(expected: ('GoL2NFT: Not snapshot owner',))]
fn test_mint_non_snapshot_owner() {
    let (gol, nft) = deploy_mocks();
    let (user1, user2) = mock_whitelist_setup(gol);
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };
    let nft_meta = IERC721MetadataDispatcher { contract_address: nft.contract_address };
    /// Give user1 1 gol token by evolving game
    start_prank(CheatTarget::All(()), user1);
    start_warp(CheatTarget::All(()), 222);
    gol.evolve(INFINITE_GAME_GENESIS);
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    stop_warp(CheatTarget::All(()));
    start_prank(CheatTarget::One(nft.contract_address), user2);
    /// Mint token
    nft.mint(6);
    stop_prank(CheatTarget::One(nft.contract_address));
}

#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn test_mint_no_approval() {
    let (gol, nft) = deploy_mocks();
    let (user1, user2) = mock_whitelist_setup(gol);
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };
    let nft_meta = IERC721MetadataDispatcher { contract_address: nft.contract_address };
    /// Give user1 1 gol token by evolving game
    start_prank(CheatTarget::All(()), user1);
    start_warp(CheatTarget::All(()), 222);
    gol.evolve(INFINITE_GAME_GENESIS);
    erc20.transfer(user2, 3);
    stop_prank(CheatTarget::All(()));
    stop_warp(CheatTarget::All(()));
    start_prank(CheatTarget::One(nft.contract_address), user1);
    /// Mint token
    nft.mint(6);
    stop_prank(CheatTarget::One(nft.contract_address));
}

#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn test_mint_not_enough_funds() {
    let (gol, nft) = deploy_mocks();
    let (user1, user2) = mock_whitelist_setup(gol);
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };
    let nft_meta = IERC721MetadataDispatcher { contract_address: nft.contract_address };
    /// Give user1 1 gol token by evolving game
    start_prank(CheatTarget::All(()), user1);
    start_warp(CheatTarget::All(()), 222);
    gol.evolve(INFINITE_GAME_GENESIS);
    erc20.transfer(user2, 3);
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    stop_warp(CheatTarget::All(()));
    start_prank(CheatTarget::One(nft.contract_address), user1);
    /// Mint token
    nft.mint(6);
    stop_prank(CheatTarget::One(nft.contract_address));
}
/// @dev WL Tests are in tests::forking tests


