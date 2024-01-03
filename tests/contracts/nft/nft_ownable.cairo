use super::super::setup::deploy_mocks;
use starknet::contract_address_const;
use gol2::utils::test_contract::{ITestTraitDispatcher, ITestTraitDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash,
};
use openzeppelin::access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};

#[test]
fn test_transfer_ownership_owner() {
    let (_, nft) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: nft.contract_address };
    let admin = contract_address_const::<'admin'>();
    let new_owner = contract_address_const::<'new_owner'>();
    start_prank(CheatTarget::All(()), admin);
    Owner.transfer_ownership(new_owner);
    stop_prank(CheatTarget::All(()));
    assert(Owner.owner() == new_owner, 'Owner should be new_owner');
}

#[test]
#[should_panic(expected: ('New owner is the zero address',))]
fn test_transfer_ownership_to_zero() {
    let (_, nft) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: nft.contract_address };
    let new_owner = contract_address_const::<''>();
    Owner.transfer_ownership(new_owner);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_transfer_ownership_non_owner() {
    let (_, nft) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: nft.contract_address };
    let new_owner = contract_address_const::<'new_owner'>();
    Owner.transfer_ownership(new_owner);
}

#[test]
fn test_renounce_ownership_owner() {
    let (_, nft) = deploy_mocks();
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
    let (_, nft) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: nft.contract_address };
    Owner.renounce_ownership();
}
