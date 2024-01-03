use super::super::setup::{MERKLE_ROOT, deploy_mocks, mock_whitelist_setup};
use gol2::{contracts::gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},};
use openzeppelin::{
    access::ownable::{OwnableComponent, interface::{IOwnableDispatcher, IOwnableDispatcherTrait}},
};
use starknet::contract_address_const;
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions
};
use debug::PrintTrait;

#[test]
fn test_owner() {
    let (gol, _) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: gol.contract_address };
    let owner = Owner.owner();
    assert(owner.into() == 'admin', 'Owner should be admin');
}

#[test]
fn test_transfer_ownership() {
    let admin = contract_address_const::<'admin'>();
    start_prank(CheatTarget::All(()), admin);
    let (gol, _) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: gol.contract_address };
    let new_owner = contract_address_const::<'new_owner'>();
    Owner.transfer_ownership(new_owner);
    assert(Owner.owner() == new_owner, 'Owner should be new_owner');
    stop_prank(CheatTarget::All(()));
}

#[test]
#[should_panic(expected: ('New owner is the zero address',))]
fn test_transfer_ownership_to_zero() {
    let (gol, _) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: gol.contract_address };
    let new_owner = contract_address_const::<''>();
    Owner.transfer_ownership(new_owner);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_transfer_ownership_non_owner() {
    let (gol, _) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: gol.contract_address };
    let new_owner = contract_address_const::<'new_owner'>();
    Owner.transfer_ownership(new_owner);
}

#[test]
fn test_renounce_ownership() {
    let (gol, _) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: gol.contract_address };
    let admin = contract_address_const::<'admin'>();
    start_prank(CheatTarget::All(()), admin);
    Owner.renounce_ownership();
    stop_prank(CheatTarget::All(()));
    assert(Owner.owner().is_zero(), 'Owner should be 0');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_renounce_ownership_non_owner() {
    let (gol, _) = deploy_mocks();
    let Owner = IOwnableDispatcher { contract_address: gol.contract_address };
    Owner.renounce_ownership();
}
