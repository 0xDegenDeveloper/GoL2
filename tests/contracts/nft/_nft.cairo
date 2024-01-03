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

// const MERKLE_ROOT: felt252 = 0x192391f83965506f49c94b50d05f9394f3613f5ae60a1e36ba3c80481ad57f7;

fn deploy_contract() -> (IGoL2Dispatcher, IGoL2NFTDispatcher) {
    let gol_contract = declare('GoL2');
    let nft_contract = declare('GoL2NFT');

    let gol_address = gol_contract.deploy(@array!['admin']).unwrap();
    let nft_address = nft_contract
        .deploy(
            @array![
                'admin', // owner
                'Game of Life NFT', // name
                'GoL2NFT', // symbol
                gol_address.into(), // gol addr
                gol_address.into(), // mint token address
                1, //price.low
                0, //price.high
                MERKLE_ROOT, // poseidon root
                MERKLE_ROOT // pedersen root
            ]
        )
        .unwrap();
    (
        IGoL2Dispatcher { contract_address: gol_address },
        IGoL2NFTDispatcher { contract_address: nft_address }
    )
}

/// Simulate users evolving game pre-migration to match example whitelist
fn simulate_migration(
    gol: IGoL2Dispatcher
) -> (starknet::ContractAddress, starknet::ContractAddress) {
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
    // todo: ped vs pos
    assert(nft.merkle_root() == MERKLE_ROOT, 'NFT: merkle root incorrect');

    mock_whitelist_setup(gol);
    assert(gol.migration_generation_marker() == 5, 'GOL: marker incorrect');
}

/// Owner functionns
#[test]
fn test_set_mint_token_and_price_and_merkle_root_owner() {
    let (_, nft) = deploy_contract();
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
fn test_set_merkle_root_non_owner() {
    let (_, nft) = deploy_contract();
    let new_root = 'new root';
    nft.set_merkle_root(new_root);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_mint_price_non_owner() {
    let (_, nft) = deploy_contract();
    let new_price = 222_u256;
    nft.set_mint_price(new_price);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_mint_token_non_owner() {
    let (_, nft) = deploy_contract();
    let new_addr = starknet::contract_address_const::<'new_addr'>();
    nft.set_mint_token_address(new_addr);
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
        let snapshot = nft.view_snapshot((i).into());
        assert(snapshot.user_id == user1, 'NFT: snapshot user_id fail');
        assert(snapshot.timestamp == 222, 'NFT: snapshot timestamp fail');
        assert(
            snapshot.game_state == gol.view_game(INFINITE_GAME_GENESIS, i.into()),
            'NFT: snapshot game_state fail'
        );
        assert(nft.game_state_copies(snapshot.game_state) == 1, 'NFT: game_state_copies fail');
        i += 1;
    };
}

/// @dev This test is also testing mint_helper(), so 
/// these tests are ommitted in the WL minting tests below.
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

// todo: ped vs pos (ped now)
#[test]
fn test_wl_mint() {
    let (gol, nft) = deploy_mocks();
    let (user1, user2) = mock_whitelist_setup(gol);
    let erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let nft_nft = IERC721Dispatcher { contract_address: nft.contract_address };
    let user1_bal0 = erc20.balance_of(user1); // 2
    let user2_bal0 = erc20.balance_of(user2); // 2
    /// Approve nft contract to spend users tokens
    start_prank(CheatTarget::All(()), user1);
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    start_prank(CheatTarget::All(()), user2);
    erc20.approve(nft.contract_address, 100);
    stop_prank(CheatTarget::All(()));
    /// Pedersen proofs for tokens 2, 3, 4, 5 (1 is owned by admin)
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
// test false proof mints


