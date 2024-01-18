# The Whitelist

Because pre-[migration](../MIGRATION.md) snapshots were not stored in the GoL2 contract, we need to use a Merkle Tree to verify a user owns the generation they are trying to mint. We also need to add these snapshot details to the GoL2 contract upon whitelist-minting.

**_[What is a Merkle Tree ?](https://decentralizedthoughts.github.io/2020-12-22-what-is-a-merkle-tree/)_**

The following steps were taken to implement this:

## On-chain:

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

> **If any off-chain issues are found in the whitelist, `set_merkle_root()` can be called again by the contract admin with a new root hash.**

## Off-chain:

Using Typescript, a root hash was calculated for [the whitelist](./whitelist.json), along with [each generation's proof](./proofs.json), using [this script](./helpers.ts)

Root Hash: `0x...**` (todo)

> _**Note: The whitelist can be fully public, even using valid proofs, a malicious caller must match the user_id in the whitelist to produce the correct root hash on-chain.**_
