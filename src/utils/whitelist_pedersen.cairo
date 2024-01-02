use alexandria_merkle_tree::merkle_tree::{
    Hasher, MerkleTree, pedersen::PedersenHasherImpl, MerkleTreeTrait, MerkleTreeImpl
};

/// Verify a merkle proof for a pedersen merkle tree
fn verify_pedersen_merkle(root: felt252, leaf: felt252, proof: Array<felt252>) {
    let mut merkle_tree: MerkleTree<Hasher> = MerkleTreeTrait::new();
    assert(merkle_tree.verify(root, leaf, proof.span()), 'NFT: invalid proof');
}

