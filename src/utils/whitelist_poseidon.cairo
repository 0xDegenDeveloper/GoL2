use alexandria_merkle_tree::merkle_tree::{
    Hasher, MerkleTree, poseidon::PoseidonHasherImpl, MerkleTreeTrait, MerkleTreeImpl
};

fn verify_poseidon_merkle(root: felt252, leaf: felt252, proof: Array<felt252>) {
    // todo: implement
    let mut merkle_tree: MerkleTree<Hasher> = MerkleTreeImpl::<_, PoseidonHasherImpl>::new();
    assert(merkle_tree.verify(root, leaf, proof.span()), 'NFT: invalid proof');
}

fn is_valid_poseidon_merkle(root: felt252, leaf: felt252, proof: Array<felt252>) -> bool {
    let mut merkle_tree: MerkleTree<Hasher> = MerkleTreeImpl::<_, PoseidonHasherImpl>::new();
    merkle_tree.verify(root, leaf, proof.span())
}

