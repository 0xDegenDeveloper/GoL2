use super::super::setup::deploy_mocks;
use starknet::contract_address_const;
use gol2::utils::test_contract::{ITestTraitDispatcher, ITestTraitDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash,
};
use openzeppelin::{
    upgrades::interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait},
};

// todo: test event
#[test]
fn test_upgrade_owner() {
    let (_, nft) = deploy_mocks();
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
    let (_, nft) = deploy_mocks();
    let hash_init = get_class_hash(nft.contract_address);
    let test_hash = declare('TestContract').class_hash;

    IUpgradeableDispatcher { contract_address: nft.contract_address }.upgrade(test_hash);
    let new_nft = ITestTraitDispatcher { contract_address: nft.contract_address };
    let upgraded_hash = get_class_hash(nft.contract_address);
}
