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

const MERKLE_ROOT: felt252 = 0x192391f83965506f49c94b50d05f9394f3613f5ae60a1e36ba3c80481ad57f7;

fn deploy_mocks() -> (IGoL2Dispatcher, IGoL2NFTDispatcher) {
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
fn mock_whitelist_setup(
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

