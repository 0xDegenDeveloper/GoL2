# Migration

<details>

1. [Overview](#overview)
2. [Changes](#changes)

   - [Additional Functions and Storage Variables](#additional-functions-and-storage-variables)
   - [Logic](#logic)

3. [Breakdown](#breakdown)
4. [Migration & Deployment](#migration--deployment)

</details>

## Overview

The purpose of this migration was to upgrade the current GoL2 contract form Cairo 0 to Cairo 1, and to add additional logic/storage vars for snapshot minting. More on the NFTs _[here](../src/README.md#gol2nft)_.

In the pre-migrated contract, snapshot details (who/when) were not stored on-chain, they were fired through events, only the generation and game-state were stored. To overcome this, the new version of the contract now stores snapshot details in the contract during each infinite game evolution. A Merkle Tree was constructed using all pre-migration event data to verify pre-migration snapshot ownership (details _[here](../whitelist/README.md)_).

When a user successfully whitelist mints a pre-migration generation, the snapshot details are then added to the GoL2 contract. Other changes from the migration are discussed below:

## Changes

### Additional Functions and Storage Variables

The following elements were added in the Cairo 1 version of the contract:

- Storage vars:

```
is_migrated: bool,

snapshots: LegacyMap<felt252, Snapshot>,

snapshotter: ContractAddress,

migration_generation_marker: felt252,
```

- Functions:

```
/// Reads

fn snapshotter() -> ContractAddress;

fn view_snapshot(generation: felt252) -> Snapshot


/// Writes

fn initializer();

fn migrate(new_class_hash: ClassHash);

fn set_snapshotter(user: ContractAddress);

fn add_snapshot(
        generation: felt252, user_id: ContractAddress,
        game_state: felt252, timestamp: u64
    ) -> bool;
```

### Logic

In Cairo 0 there was no looping or u256 primatives, and was a much lower-level language in general. The upgraded contract takes advantage of these lacking features; now there are no recursive functions and the game state can easily be converted from felt252 to u256 & back, making the packing/unpacking logic simpler.

## Breakdown

The previous GoL2 contract implemented [OpenZeppelin's proxy](https://github.com/OpenZeppelin/cairo-contracts/blob/release-0.2.0/src/openzeppelin/upgrades/Proxy.cairo) set up to allow for future contract upgrades. In the Cairo 1, we can upgrade a contract's implementation hash directly with a syscall, omitting the need for a proxy setup. This makes migrating the previous contract a 2-step process:

### Step 1:

We need to upgrade the proxy contract's implementation hash to the updated version via:

```
GoL2::upgrade(new_class_hash: felt252)
```

At this point, the GoL2 contract's logic & interface have been updated to the new implementation, but it is still using a proxy setup to delegate calls.

### Step 2:

To remove this proxy setup, we will call:

```
GoL2::migrate(new_class_hash: felt252)
```

This will call `replace_class_syscall(new_class_hash)`, finalizing the contract to its upgradeable, non-proxy, Cairo 1 implementation. This process is done in a single multicall, more details below.

## Migration & Deployment

### Testing

To test the contracts you will need _[scarb (>= 2.3.1)](https://docs.swmansion.com/scarb/)_ and _[starknet-foundry (>= 0.12.0)](https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html)_.

Run the test suite via:

```
snforge test
```

### Migration Walkthrough

This repo provides a migration & deployment walkthrough for either a local Katana node, the Goerli testnet, or Mainnet.

To start, copy the contents from the _.env.example_ file and paste them into a new file named _.env_ (in the same root directory).

- Replace the **WALLET_ADDRESS** & **PRIVATE_KEY** fields with your details.

- Replace **ENVIRONMENT** with the environment you wish to run in. The options are "KATANA" | "GOERLI" | "MAINNET".

Make sure you have _[node](https://nodejs.org/en/download)_ installed (we are using v16.13.1 but the actual minimum version is not known at this time).

Install the dependencies:

```
npm install
```

### Katana

If you wish to skip directly to Goerli & Mainnnet deployment, skip these steps.

First install Katana:

```
curl -L https://install.dojoengine.org | bash
```

> Official installation guide _[here](https://book.dojoengine.org/getting-started/quick-start.html)_

Once Katana is installed, run a Goerli fork in a background terminal:

```
katana --rpc-url https://starknet-testnet.public.blastapi.io/rpc/v0.5
```

> **_NOTE:_** The reason we are running a Goerli fork and not a clean Katana node is to use the official Cairo 0 implementation hashes (proxy & GoL2), and not re-declare them ourselves.

The steps for Goerli and Katana are the same, just make sure you adjust your _.env_ file **ENVIRONMENT** variable appropriately.

### Goerli

Make sure you adjust your _.env_ file **ENVIRONMENT** variable to "GOERLI" | "KATANA".

- Deploy a Cairo 0 GoL2 instance with your wallet as the admin and evolve the game 3 times:

```
npm run mock
```

- Migrate the contract from Cairo 0 to 1:

```
npm run migrate <freshly deployed GoL2 contract address>
```

- Deploy a GoL2NFT contract linked to the GoL2 contract:

```
npm run nft <same GoL2 contract address>
```

- Generate a mock whitelist for the 3 pre-migration evolutions mentioned above:

```
npm run mock_whitelist <freshly deployed GoL2NFT contract address>
```

- Set the whitelist root hash in the GoL2NFT contract, and give it an allowance for spending your tokens (for mint fees).

```
npm run mint_helper <same GoL2NFT contract address> <mock root hash>
```

To test that whitelist minting is working as expected (Goerli), visit your GoL2NFT contract on a block-explorer, and look for the `whitelist_mint()` write function. Use these values, along with the outputted proofs to succesfully whitelist mint:

```
generation: 2,

state: 0x100030006e0000000000000000000000000000,

timestamp: 2222,

----------------------------------------------------------------

generation: 3,

state: 0x18004a00740008000000000000000000000000,

timestamp: 3333,

----------------------------------------------------------------

generation: 4,

state: 0x18004800760050000000000000000000000000,

timestamp: 4444,
```

Now that your GoL2 contract has been migrated, evolve the infinite game once again. Do this by calling the evolve function for this game_id:

```
0x7300100008000000000000000000000000
```

If the migration & deployment were successful, the first post-migration evolution will start at generation 5. To mint this snapshot, go back to the GoL2NFT contract, and pass `5` into the `mint()` function.

### Mainnet

Make sure you adjust your _.env_ file **ENVIRONMENT** variable to "MAINNET", and check that the wallet address and private key are the ones for the admin wallet.

> The wallet address for admin is: 0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973

- Migrate the contract from Cairo 0 to 1:

```
npm run migrate 0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
```

- Deploy the GoL2NFT contract linked to the GoL2 contract:

```
npm run nft 0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
```
