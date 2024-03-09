# The Whitelist

Because _[pre-migration](../migration/README.md)_ snapshots were not stored in the GoL2 contract, we have to use a Merkle Tree to verify a user owns the generation they are trying to mint. We also need to add these snapshot details to the GoL2 contract upon whitelist-minting.

_[What is a Merkle Tree ?](https://decentralizedthoughts.github.io/2020-12-22-what-is-a-merkle-tree/)_

## On-chain:

This is the whitelist minting function in the GoL2NFT contract:

```
fn whitelist_mint(generation: felt252, state: felt252, timestamp: u64, proof: Array<felt252> ) {

        * Step 1

        let leaf = create_leaf_hash(generation, state, timestamp);

        * Step 2

        assert_valid_proof(self.merkle_root.read(), leaf, proof);

        * Step 3

        self.handle_snapshot(generation, get_caller_address(), state, timestamp);

        * Step 4

        self.mint_helper(get_caller_address(), generation.into());
}
```

1.  We create the Poseidon leaf hash for the user, mimicking the off-chain approach discussed below.

2.  We verify that the leaf + proof match the official root hash.

3.  We save the snapshot details to the GoL2 contract.

4.  We mint the user the token and other necessary steps (increment the total supply & number of times this generation's game_state has been minted and charge the mint fee).

## Off-chain:

Using Typescript, the whitelist's root hash was calculated. A bunch of _[these scripts](./example.ts)_ were used to fetch the proofs for each leaf in the tree.

If you were curious, we ran 3 batches of 8 scripts in parallel to speed this process up. Ecah script fetched ~25,000 proofs. The total time it took to fetch all ~500,000 proofs was ~1.5 hours (M3 Pro Chip).
