## Table of contents

- [Overview](#overview)
- [On-chain Metadata](#onchain-meta)
- [Whitelist](#whitelist)
  - [Implementation](#impl)
    - [On-chain](#onchain)
    - [Off-chain](#offchain)

## Overview <a name="overview"></a>

Along with migrating the GoL2 contract to Cairo 1, we also wrote the GoL2NFT contract requested by the Yuki team. This contract is for users to mint the snapshots they own (in the infinite game) as NFTs. This contract generates token URI (JSON & SVG data) on-chain.

Pre migration, snapshot details were not stored in the contract, only the generation & gamestate were. The user and timestamp are available by indexing all of the pre-migration `game_evolved` events where the `game_id` is that for infinite mode.

Post migration, the GoL2 contract stores all infinite mode snapshots in contract. There are two mint functions to handle each case; `whitelist_mint()` for pre-migration snapshots, and `mint()` for post-migration snapshots.

## On-chain Metadata <a name="onchain-meta"></a>

This contract generates all token URI data on-chain, see details [here](./tests/contracts/nft/uri/README.md)

To see an example, start by running this command to generate the JSON URI:

`npm run test_uri`.

> _**This command runs `python3 ./tests/contracts/nft/uri/nft_uri_and_svg.py`. You may need to use a different python command other than `python3` to run the script depending on your machine.**_

`Test passed!` means the test matches the expected output; to view it for yourself see below:

### Step 1:

Paste the URI into your browser to view the JSON data as marketplaces _**should**_; it will look like this:

`data:application/json,{"name":"GoL2%20%231","description"...,{"trait_type":"Generation","value":2}]}`.

_**This should be identical to this [sample json](./tests/contracts/nft/uri/example.json).**_

### Step 2:

To see the image, find the "image" field in this browser JSON and copy the data. Paste this text into the browser to see the image. It should look like this:

`data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org...width=%225%22/%3E%3C/g%3E%3C/svg%3E`.

> NOTE: This step is crucial because the special characters in the SVG URL are double encoded. When the JSON is resolved by the browser, the first layer of encoding is decoded. Pasting this resolved 'image' data into the browser then decodes the second set of special characters, ensuring the SVG renders correctly. The resulting SVG should match this [svg file](./tests/contracts/nft/uri/example.svg).

## Whitelist

Because pre-migration snapshots were not stored in the GoL2 contract, we need to use a Merkle Tree to verify a user owns the generation they are trying to mint. We also need to add these snapshot details to the GoL2 contract upon whitelist-minting.

**_[What is a Merkle Tree ?](https://decentralizedthoughts.github.io/2020-12-22-what-is-a-merkle-tree/)_**

### Implementation <a name="impl"></a>

The following steps are taken to implement this:

#### On-chain<a name="onchain"></a>

The NFT contract has the following mint function for pre-migration generations:

```
fn whitelist_mint(
        generation: felt252,
        state: felt252,
        timestamp: u64,
        proof: Array<felt252>
    ) {
        /// Step 1:
        let leaf = create_leaf_hash(generation, state, timestamp);

        /// Step 2:
        assert_valid_proof(self.merkle_root.read(), leaf, proof);

        /// Step 3:
        self.handle_snapshot(generation, get_caller_address(), state, timestamp);

        /// Step 4:
        self.mint_helper(get_caller_address(), generation.into());
    }
```

This function takes the details of the snapshot being minted and the user's proof as input.

##### Step 1:

We create the Poseidon leaf hash for the user, mimicking the off-chain approach discussed in the [Off-chain](#offchain) section.

##### Step 2:

We verify that the leaf + proof match the official root hash.

##### Step 3:

We save the snapshot details to the GoL2 contract.

##### Step 4:

We mint the user the token and other necessary steps (increment the total supply & number of times this generation's game_state has been minted and charge the mint fee).

_**Whitelist minting can be setup after deployment if it needs to be. To do this, we would just deploy the NFT contract with the constructor argument `_merkle_root` set to `0x0`. Then, the contract admin will call `set_merkle_root(new_root: felt252)` with the whitelist's root hash once finalized.**_

_**If any off-chain issues are found in the whitelist, `set_merkle_root()` can be called again by the contract admin with a new root hash.**_

#### Off-chain<a name="offchain"></a>

This directory contains helper functions to create the whitelist, root hash and proofs. When a user whitelist-mints a token, they will need to pass their snapshot details and proof to the contract.

There can be either a service that holds the Merkle Tree and generates proofs upon client request (returning the snapshot details & proof), or all proofs & snapshot details can be generated & stored before hand then fetched by the client upon request.

> _**Note: The whitelist can be fully public, even using valid proofs, a malicious caller must match the user_id in the whitelist to produce the correct root hash on-chain.**_

##### Demo

The finalized whitelist should match the format of this example [whitelist](/whitelist/fork_whitelist.json).

This [script](/whitelist/helpers.ts) contains functions for generating a whitelist, root hash, and proofs.

To demonstrate these helper functions using the example [whitelist](/whitelist/fork_whitelist.json), start by making sure you have ts-node installed, the following command should install it:

```
npm install -g ts-node typescript '@types/node'
```

then install the dependencies by running:

```
npm install
```

finally run:

```
ts-node whitelist/helpers.ts
```

to see the output.
