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
#[ignore]
fn test_uri_svg() {
    let (gol, nft) = deploy_contract();
    let nft_meta = IERC721MetadataDispatcher { contract_address: nft.contract_address };
    let mut token_uri = nft_meta.token_uri(1); // INFINITE_GAME_GENESIS at generation 1 => acorn
    loop {
        match token_uri.pop_front() {
            Option::Some(el) => { el.print(); },
            Option::None => { break; }
        }
    };
}
