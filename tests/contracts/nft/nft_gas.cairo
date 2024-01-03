use starknet::{contract_address_const, ClassHash, call_contract_syscall};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash, EventFetcher, event_name_hash, Event
};
use gol2::{
    contracts::gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
    utils::{
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, CREATE_CREDIT_REQUIREMENT,
            GIVE_LIFE_CREDIT_REQUIREMENT
        },
        whitelist_pedersen::is_valid_pedersen_merkle, whitelist_poseidon::is_valid_poseidon_merkle
    },
};
use openzeppelin::{
    access::ownable::{OwnableComponent, interface::{IOwnableDispatcher, IOwnableDispatcherTrait}},
    upgrades::{
        UpgradeableComponent,
        interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait},
    },
    token::erc20::{ERC20Component, ERC20ABIDispatcher, ERC20ABIDispatcherTrait},
};
use debug::PrintTrait;
use alexandria_merkle_tree::merkle_tree::{
    Hasher, MerkleTree, pedersen::PedersenHasherImpl, poseidon::PoseidonHasherImpl, MerkleTreeTrait,
    MerkleTreeImpl
};

#[test]
#[ignore]
fn test_merkle_gasses() {
    let proof: Array<felt252> = array![
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901,
        0x1234567890123456789012345678901, // 20 elements ()
    ];

    let proof2 = proof.clone();
    let leaf = 0x1234567890123456789012345678901;
    let root = 0x1234567890123456789012345678901;

    let mut gas_ped = testing::get_available_gas();
    gas::withdraw_gas().unwrap();
    let is_valid = is_valid_pedersen_merkle(root, leaf, proof);
    gas_ped -= testing::get_available_gas();

    let mut gas_pos = testing::get_available_gas();
    gas::withdraw_gas().unwrap();
    let is_valid = is_valid_poseidon_merkle(root, leaf, proof2);
    gas_pos -= testing::get_available_gas();

    let mut a = array!['ped', gas_ped, 'pos', gas_pos];
    loop {
        match a.pop_front() {
            Option::Some(x) => { x.print(); },
            Option::None => { break; },
        }
    };
}
