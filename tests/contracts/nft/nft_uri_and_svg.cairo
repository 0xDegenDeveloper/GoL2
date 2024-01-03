use starknet::contract_address_const;
use gol2::{
    contracts::{
        gol::{GoL2, IGoL2Dispatcher, IGoL2DispatcherTrait},
        nft::{
            GoL2NFT, IGoL2NFTDispatcher, IGoL2NFTDispatcherTrait, IERC721Metadata,
            IERC721MetadataDispatcher, IERC721MetadataDispatcherTrait
        }
    },
    utils::constants::{INFINITE_GAME_GENESIS, LOW_ARRAY_LEN, HIGH_ARRAY_LEN}
};

use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash, start_warp, stop_warp
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
#[ignore]
fn test_uri_svg() {
    let admin = contract_address_const::<0x0>();
    let user = contract_address_const::<0xbeef>();
    let (gol, nft) = deploy_mocks();
    let nft_meta = IERC721MetadataDispatcher { contract_address: nft.contract_address };
    let gol_erc20 = ERC20ABIDispatcher { contract_address: gol.contract_address };
    let gol_class_hash = get_class_hash(gol.contract_address);
    start_prank(CheatTarget::All(()), admin);
    gol.migrate(gol_class_hash); /// sets marker to 1
    stop_prank(CheatTarget::All(()));
    start_prank(CheatTarget::One(gol.contract_address), user);
    start_warp(CheatTarget::One(gol.contract_address), 222);
    gol.evolve(INFINITE_GAME_GENESIS);
    /// approve nft to spend tokens 
    gol_erc20.approve(nft.contract_address, 1);
    stop_prank(CheatTarget::One(gol.contract_address));
    stop_warp(CheatTarget::One(gol.contract_address));
    start_prank(CheatTarget::One(nft.contract_address), user);
    nft.mint(2);
    stop_prank(CheatTarget::One(nft.contract_address));
    let mut token_uri = nft_meta.token_uri(2); // INFINITE_GAME_GENESIS at generation 1 => acorn
    token_uri.print();
}
