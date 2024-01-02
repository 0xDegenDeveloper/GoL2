use alexandria_merkle_tree::merkle_tree::{
    Hasher, MerkleTree, pedersen::PedersenHasherImpl, MerkleTreeTrait, MerkleTreeImpl
};

fn verify_poseidon_merkle(root: felt252, leaf: felt252, proof: Array<felt252>) {
    // todo: implement
    let mut merkle_tree: MerkleTree<Hasher> = MerkleTreeImpl::<_, PedersenHasherImpl>::new();
    assert(merkle_tree.verify(root, leaf, proof.span()), 'NFT: invalid proof');
}

