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
                0x192391f83965506f49c94b50d05f9394f3613f5ae60a1e36ba3c80481ad57f7, // poseidon
                0x192391f83965506f49c94b50d05f9394f3613f5ae60a1e36ba3c80481ad57f7 // pedersen
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
    i = 2; // user evolved gens 2-11
    loop {
        if i == 12 {
            break;
        }
        assert(nft_nft.owner_of((i).into()) == user, 'NFT: mint fail');
        i += 1;
    };
}
// test wl mints and then wl gas usages

/// Simulate 2 users evolving game pre-migration
fn set_up_wl_gens(gol: IGoL2Dispatcher) -> (starknet::ContractAddress, starknet::ContractAddress) {
    let user1 = contract_address_const::<
        0x00a138A07fde4cD66998e544665dd322E14AAC17279c6477E63f394a07476001
    >();
    let user2 = contract_address_const::<
        0x00Ab6e726136F0A1AC1d526c7725D845aFe62b67Cf42dCB49B7B9468bf04E6A3
    >();
    let admin = contract_address_const::<0x0>();

    start_prank(CheatTarget::All(()), user1);
    start_warp(CheatTarget::All(()), 222);
    gol.evolve(INFINITE_GAME_GENESIS);
    stop_warp(CheatTarget::All(()));

    start_warp(CheatTarget::All(()), 333);
    gol.evolve(INFINITE_GAME_GENESIS);
    stop_warp(CheatTarget::All(()));
    stop_prank(CheatTarget::All(()));

    start_prank(CheatTarget::All(()), user2);
    start_warp(CheatTarget::All(()), 444);
    gol.evolve(INFINITE_GAME_GENESIS);
    stop_warp(CheatTarget::All(()));

    start_warp(CheatTarget::All(()), 555);
    gol.evolve(INFINITE_GAME_GENESIS);
    stop_warp(CheatTarget::All(()));
    stop_prank(CheatTarget::All(()));

    /// simulate migration 
    start_prank(CheatTarget::All(()), admin);
    start_warp(CheatTarget::All(()), 666);
    gol.migrate(get_class_hash(gol.contract_address)); //pre_migration_generations
    stop_warp(CheatTarget::All(()));
    stop_prank(CheatTarget::All(()));

    (user1, user2)
}

#[test]
fn test_wl_mint() {
    let (gol, nft) = deploy_contract();
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };
    let (user1, user2) = set_up_wl_gens(gol);
    let user1_bal0 = erc20.balance_of(user1); // 2
    let user2_bal0 = erc20.balance_of(user2); // 2
    /// Approve nft contract to spend users tokens
    start_prank(CheatTarget::All(()), user1);
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    start_prank(CheatTarget::All(()), user2);
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    /// Mint token 
    let p2 = array![
        0x4894368e045e09c54726344134ba1645d2eef0481fa3b6d8ff006529b538f5f,
        0x6a600e9592885094781170c2b28e9cd1d60024e44c09c8f35bec356fa387c00,
        0x7d91e4d17bc723ecdf0a6c85955a96fb0c30c5584db2debc70bbc8475dcc7d6,
    ];
    let p3 = array![
        0x3b6749f41d7d0bfc60af31edd1ea08d4c0927f9f105f257060aa07eac4b2389,
        0x580cbad2c307988f8836b8c6eda34ddde8f6e6f5a4c0ca960e72c263926d8f9,
        0x7d91e4d17bc723ecdf0a6c85955a96fb0c30c5584db2debc70bbc8475dcc7d6
    ];
    let p4 = array![
        0x31caf23ec5d1668f16435a9470cc73e1d69d341620b7e83789647b68f531d5f,
        0x580cbad2c307988f8836b8c6eda34ddde8f6e6f5a4c0ca960e72c263926d8f9,
        0x7d91e4d17bc723ecdf0a6c85955a96fb0c30c5584db2debc70bbc8475dcc7d6
    ];
    let p5 = array![0x0, 0x0, 0x1188a4019dd644414b9bbe2f1f84dd52b3bd66cf421d0edd0f14353c9db2638,];

    start_prank(CheatTarget::One(nft.contract_address), user1);
    nft.wl_mint_ped(2, 0x100030006e0000000000000000000000000000, 222, p2);
    nft.wl_mint_ped(3, 0x18004a00740008000000000000000000000000, 333, p3);
    stop_prank(CheatTarget::One(nft.contract_address));

    start_prank(CheatTarget::One(nft.contract_address), user2);
    nft.wl_mint_ped(4, 0x18004800760050000000000000000000000000, 444, p4);
    nft.wl_mint_ped(5, 0x18004800760050000000000000000000000000, 555, p5);
    stop_prank(CheatTarget::One(nft.contract_address));

    let user1_bal1 = erc20.balance_of(user1); // 0
    let user2_bal1 = erc20.balance_of(user2); // 0
    assert(user1_bal0 - user1_bal1 == 2, 'NFT: mint price fail');
    assert(user2_bal0 - user2_bal1 == 2, 'NFT: mint price fail2');
    assert(nft_nft.owner_of(2) == user1, 'NFT: mint fail2');
    assert(nft_nft.owner_of(3) == user1, 'NFT: mint fail3');
    assert(nft_nft.owner_of(4) == user2, 'NFT: mint fail4');
    assert(nft_nft.owner_of(5) == user2, 'NFT: mint fail5');
}

