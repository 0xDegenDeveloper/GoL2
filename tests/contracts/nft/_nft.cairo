use starknet::contract_address_const;
use gol2::{
    contracts::{
        gol::{GoL2, IGoL2Dispatcher, IGoL2DispatcherTrait},
        nft::{
            GoL2NFT, IGoL2NFTDispatcher, IGoL2NFTDispatcherTrait, IERC721Metadata,
            IERC721MetadataDispatcher, IERC721MetadataDispatcherTrait
        },
        test_contract::{ITestTraitDispatcher, ITestTraitDispatcherTrait}
    },
    utils::constants::{INFINITE_GAME_GENESIS, LOW_ARRAY_LEN, HIGH_ARRAY_LEN}
};

use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash,
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

fn deploy_contract() -> (IGoL2Dispatcher, IGoL2NFTDispatcher) {
    let gol_contract = declare('GoL2');
    let nft_contract = declare('GoL2NFT');

    let gol_address = gol_contract.deploy(@array!['admin']).unwrap();
    let nft_address = nft_contract
        .deploy(
            @array![
                'admin',
                'Game of Life NFT',
                'GoL2NFT',
                gol_address.into(),
                gol_address.into(),
                1, //u256.low
                0, //u256.high
            ]
        )
        .unwrap();
    (
        IGoL2Dispatcher { contract_address: gol_address },
        IGoL2NFTDispatcher { contract_address: nft_address }
    )
}


/// Constructor
#[test]
fn test_deployment() {
    let (gol, nft) = deploy_contract();
    let nft_meta = IERC721MetadataDispatcher { contract_address: nft.contract_address };
    let nft_ownable = IOwnableDispatcher { contract_address: nft.contract_address };
    assert(nft_ownable.owner().into() == 'admin', 'GoL2: owner incorrect');
    assert(nft_meta.name() == 'Game of Life NFT', 'NFT: name incorrect');
    assert(nft_meta.symbol() == 'GoL2NFT', 'NFT: symbol incorrect');
    assert(nft.mint_token_address() == gol.contract_address, 'NFT: mint addr incorrect');
    assert(nft.mint_price() == 1, 'NFT: mint price incorrect');
}

/// Owner functionns
#[test]
fn test_set_mint_token_address() {
    let (_, nft) = deploy_contract();
    let admin = starknet::contract_address_const::<'admin'>();
    let new_addr = starknet::contract_address_const::<'new_addr'>();
    start_prank(CheatTarget::All(()), admin);
    nft.set_mint_token_address(new_addr);
    assert(nft.mint_token_address() == new_addr, 'NFT: set mint addr fail');
    stop_prank(CheatTarget::All(()));
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_mint_token_address_non_owner() {
    let (_, nft) = deploy_contract();
    let new_addr = starknet::contract_address_const::<'new_addr'>();
    nft.set_mint_token_address(new_addr);
}

#[test]
fn test_set_mint_price() {
    let (_, nft) = deploy_contract();
    let admin = starknet::contract_address_const::<'admin'>();
    let new_price = 222_u256;
    start_prank(CheatTarget::All(()), admin);
    nft.set_mint_price(new_price);
    assert(nft.mint_price() == new_price, 'NFT: set mint price fail');
    stop_prank(CheatTarget::All(()));
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_mint_price_non_owner() {
    let (_, nft) = deploy_contract();
    let new_price = 222_u256;
    nft.set_mint_price(new_price);
}

#[test]
fn test_upgrade() {
    let (_, nft) = deploy_contract();
    let hash_init = get_class_hash(nft.contract_address);
    let test_hash = declare('TestContract').class_hash;

    start_prank(CheatTarget::All(()), contract_address_const::<'admin'>());
    IUpgradeableDispatcher { contract_address: nft.contract_address }.upgrade(test_hash);
    let new_nft = ITestTraitDispatcher { contract_address: nft.contract_address };
    let upgraded_hash = get_class_hash(nft.contract_address);

    assert(hash_init != upgraded_hash, 'Hash not changed');
    assert(upgraded_hash == test_hash, 'Hash upgrade incorrect');
    assert(new_nft.x() == 123, 'Initializer failed');
    stop_prank(CheatTarget::All(()));
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_upgrade_non_owner() {
    let (_, nft) = deploy_contract();
    let hash_init = get_class_hash(nft.contract_address);
    let test_hash = declare('TestContract').class_hash;

    IUpgradeableDispatcher { contract_address: nft.contract_address }.upgrade(test_hash);
    let new_nft = ITestTraitDispatcher { contract_address: nft.contract_address };
    let upgraded_hash = get_class_hash(nft.contract_address);
}

#[test]
fn test_transfer_ownership() {
    let admin = contract_address_const::<'admin'>();
    start_prank(CheatTarget::All(()), admin);

    let (_, nft) = deploy_contract();
    let Owner = IOwnableDispatcher { contract_address: nft.contract_address };

    let new_owner = contract_address_const::<'new_owner'>();

    Owner.transfer_ownership(new_owner);

    assert(Owner.owner() == new_owner, 'Owner should be new_owner');

    stop_prank(CheatTarget::All(()));
}

#[test]
#[should_panic(expected: ('New owner is the zero address',))]
fn test_transfer_ownership_to_zero() {
    let (_, nft) = deploy_contract();
    let Owner = IOwnableDispatcher { contract_address: nft.contract_address };
    let new_owner = contract_address_const::<''>();
    Owner.transfer_ownership(new_owner);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_transfer_ownership_non_owner() {
    let (_, nft) = deploy_contract();
    let Owner = IOwnableDispatcher { contract_address: nft.contract_address };
    let new_owner = contract_address_const::<'new_owner'>();
    Owner.transfer_ownership(new_owner);
}

#[test]
fn test_renounce_ownership() {
    let (_, nft) = deploy_contract();
    let Owner = IOwnableDispatcher { contract_address: nft.contract_address };
    let admin = contract_address_const::<'admin'>();
    start_prank(CheatTarget::All(()), admin);
    Owner.renounce_ownership();
    stop_prank(CheatTarget::All(()));
    assert(Owner.owner().is_zero(), 'Owner should be 0');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_renounce_ownership_non_owner() {
    let (_, nft) = deploy_contract();
    let Owner = IOwnableDispatcher { contract_address: nft.contract_address };
    Owner.renounce_ownership();
}

/// External functions
#[test]
fn test_mint() {
    let (gol, nft) = deploy_contract();
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };
    /// Give user 10 tokens and evolve game 10 times
    let user = contract_address_const::<'user'>();
    let user2 = contract_address_const::<'user2'>();
    start_prank(CheatTarget::All(()), user);
    let mut i = 0;
    loop {
        if i == 10 {
            break;
        }
        gol.evolve(INFINITE_GAME_GENESIS);
        i += 1;
    };
    let user_bal0 = erc20.balance_of(user); // 10
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    start_prank(CheatTarget::One(nft.contract_address), user);
    /// Mint tokens (1 token each)
    let mut i = 2; // first gen was already evolved
    loop {
        if i == 12 {
            break;
        }
        nft.mint(i);
        i += 1;
    };
    stop_prank(CheatTarget::One(nft.contract_address));
    let user_bal1 = erc20.balance_of(user); // 0
    assert(user_bal0 - user_bal1 == 10, 'NFT: mint price fail');
    assert(nft.total_supply() == 10, 'NFT: supply fail');
    i = 2; // user evolved gens 2-11
    loop {
        if i == 12 {
            break;
        }
        assert(nft_nft.owner_of((i).into()) == user, 'NFT: mint fail');
        let state_at_gen = gol.view_game(INFINITE_GAME_GENESIS, i);
        assert(
            nft.board_state_to_token_id(state_at_gen) == i.into(), 'NFT: state to token id map fail'
        );
        i += 1;
    };
}

#[test]
#[should_panic(expected: ('NFT: board state already minted',))]
fn test_mint_duplicate_board_state() {
    let (gol, nft) = deploy_contract();
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };
    /// Give user tokens 
    let user = contract_address_const::<'user'>();
    start_prank(CheatTarget::All(()), user);
    gol.evolve(INFINITE_GAME_GENESIS);
    gol.evolve(INFINITE_GAME_GENESIS);
    /// Approve nft contract to spend users tokens
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    /// Mint tokens 
    start_prank(CheatTarget::One(nft.contract_address), user);
    nft.mint(1);
    nft.mint(1);
    stop_prank(CheatTarget::One(nft.contract_address));
}

