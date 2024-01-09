use alexandria_merkle_tree::merkle_tree::{
    Hasher, MerkleTree, poseidon::PoseidonHasherImpl, MerkleTreeTrait, MerkleTreeImpl
};
use core::poseidon::{poseidon_hash_span, PoseidonTrait};
use debug::PrintTrait;

/// Asserts that the given proof is valid for the given leaf and root.
fn assert_valid_proof(root: felt252, leaf: felt252, proof: Array<felt252>) {
    let mut merkle_tree: MerkleTree<Hasher> = MerkleTreeImpl::<_, PoseidonHasherImpl>::new();
    assert(merkle_tree.verify(root, leaf, proof.span()), 'GoL2NFT: Invalid proof');
}

/// Create a leaf's poseidon hash using the inputs and caller. 
fn create_leaf_hash(generation: felt252, state: felt252, timestamp: u64) -> felt252 {
    poseidon_hash_span(
        array![generation, starknet::get_caller_address().into(), state, timestamp.into()].span()
    )
}

