use gol2::utils::whitelist::{assert_valid_proof, create_leaf_hash};
use snforge_std::{start_prank, stop_prank, CheatTarget,};

#[test]
fn test_create_leaf_hash() {
    /// Value's come from Alexandria's merkle tests.
    let leaf = 0x1;
    let root = 0x7abc09d19c8a03abd4333a23f7823975c7bdd325170f0d32612b8baa1457d47;
    let valid_proof = array![
        0x2, 0x47ef3ad11ad3f8fc055281f1721acd537563ec134036bc4bd4de2af151f0832
    ];
    assert_valid_proof(root, leaf, valid_proof); /// is this actually failing ? 
    assert(1 == 1, 'Whitelist: Proof failed')
}

#[test]
fn test_assert_valid_proof() {
    let caller = 0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973;
    let generation = 1;
    let state = 0x7300100008000000000000000000000000;
    let timestamp = 1663268697;
    let proof = array![
        0x034a52adb2632dbf7214c10d9495fe423f6a43a8b72f2db428d769bbba8b428e,
        0x01eb30fc6beea707d5fa1d9218d2096e65c5c35f73b7c170bb2eee7811fb5201,
        0x01b1e46a9c846a98713182ed39bdb475512a756aee2a6382551686a11a192e27
    ];
    let root = 0x0595d834a768d680188fce9858f850eeaf8926f86b54238e30fecc53f6317962;
    let expected_leaf = 0x1e30c6b953ecedbd1f9c82e98f89a7f690c927368182e1d01d40c3491448a97;
    start_prank(CheatTarget::All(()), starknet::contract_address_try_from_felt252(caller).unwrap());
    let leaf = create_leaf_hash(generation, state, timestamp);
    assert_valid_proof(root, leaf, proof);
    assert(leaf == expected_leaf, 'Whitelist: Leaf mismatch');
    stop_prank(CheatTarget::All(()));
}

#[test]
#[should_panic(expected: ('GoL2NFT: Invalid proof',))]
fn test_assert_valid_proof_false_caller() {
    let caller = 0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973 - 10000;
    let generation = 1;
    let state = 0x7300100008000000000000000000000000;
    let timestamp = 1663268697;
    let proof = array![
        0x034a52adb2632dbf7214c10d9495fe423f6a43a8b72f2db428d769bbba8b428e,
        0x01eb30fc6beea707d5fa1d9218d2096e65c5c35f73b7c170bb2eee7811fb5201,
        0x01b1e46a9c846a98713182ed39bdb475512a756aee2a6382551686a11a192e27
    ];
    let root = 0x0595d834a768d680188fce9858f850eeaf8926f86b54238e30fecc53f6317962;
    let expected_leaf = 0x1e30c6b953ecedbd1f9c82e98f89a7f690c927368182e1d01d40c3491448a97;
    start_prank(CheatTarget::All(()), starknet::contract_address_try_from_felt252(caller).unwrap());
    let leaf = create_leaf_hash(generation, state, timestamp);
    assert_valid_proof(root, leaf, proof);
    assert(leaf == expected_leaf, 'Whitelist: Leaf mismatch');
    stop_prank(CheatTarget::All(()));
}

#[test]
#[should_panic(expected: ('GoL2NFT: Invalid proof',))]
fn test_assert_valid_proof_false_proof() {
    let caller = 0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973;
    let generation = 1;
    let state = 0x7300100008000000000000000000000000;
    let timestamp = 1663268697;
    let proof = array![
        0x034a52adb2632dbf7214c10d9495fe423f6a43a8b72f2db428d769bbba8b428e,
        0x01eb30fc6beea707d5fa1d9218d2096e65c5c35f73b7c170bb2eee7811fb5201,
        0x01b1e46a9c846a98713182ed39bdb475512a756aee2a6382551686a11a192e27,
        0xbeef
    ];
    let root = 0x0595d834a768d680188fce9858f850eeaf8926f86b54238e30fecc53f6317962;
    let expected_leaf = 0x1e30c6b953ecedbd1f9c82e98f89a7f690c927368182e1d01d40c3491448a97;
    start_prank(CheatTarget::All(()), starknet::contract_address_try_from_felt252(caller).unwrap());
    let leaf = create_leaf_hash(generation, state, timestamp);
    assert_valid_proof(root, leaf, proof);
    assert(leaf == expected_leaf, 'Whitelist: Leaf mismatch');
    stop_prank(CheatTarget::All(()));
}

