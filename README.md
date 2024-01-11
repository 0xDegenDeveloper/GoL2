# Game of Life

An interactive implementation of Conway's Game of Life as a contract on Starknet, written in Cairo.

> **_Originally written in Cairo 0 and now migrated to Cairo 1; for more details about this migration see [here](./docs/MIGRATION.md#overview)_**.

## Table of contents

<details>

- [Contracts](#contracts)

  - [GoL2](#gol2)

  - [GoL2NFT](#gol2nft)

- [Whitelist](#whitelist)

- [Migration](#migration)

- [Dev](#dev)

</details>

## Contracts <a name="contracts"></a>

### GoL2 <a name="gol2"></a>

<details>

- [Overview](#gol2-overview)
- [Architecture](#gol2-architecture)
  - [Structs](#gol2-structs)
  - [Storage vars](#gol2-storage-vars)
  - [Events](#gol2-events)
- [Interface](#gol2-interface)

#### GoL2 Overview: <a name="gol2-overview"></a>

<details>

This is an ERC-20 contract that also handles the logic and storage for both game modes:

##### Infinite:

- One never ending game allowing any player to evolve the game to its next state, by doing so the player is minted 1 credit token (ERC-20). These credit tokens can be used to revive a cell in this game, or create a new game.

- When a player evolves this game, a snapshot of this event is stored for the [GoL2NFT](#gol2nft) contract to use.

- All created games cost 10 credit tokens and are [creator](#creator) mode games.

##### Creator:

- To create a new game, a player specifies which cells are initially alive (this game_state is the game_id and must be unique). These creator mode games can be evolved by anyone (minting the player 1 credit token as well), but cannot have their cells revived like the infinite game can.

</details>

#### GoL2 Architecture: <a name="gol2-architecture"></a>

<details>

##### GoL2 Structs: <a name="gol2-structs"></a>

```
/// Used to store details about each evolution of the infinite game.

Snapshot {
user_id: ContractAddress - Address of the player that evolved this generation.
game_state: felt252 - State the game was evolved to.
timestamp: u64 - Unix block timestamp when this snapshot was taken.
}

```

##### GoL2 Storage vars: <a name="gol2-storage-vars"></a>

```
/// Mapping for game_id -> generation -> state.

stored_game: LegacyMap<(felt252, felt252), felt252>
```

```
/// Mapping for game_id -> generation.

current_generation: LegacyMap<felt252, felt252>,
```

```
/// Has the contract been migrated to Cairo 1 yet ?

is_migrated: bool,
```

```
/// Mapping for generations -> Snapshots.

snapshots: LegacyMap<felt252, Snapshot>,
```

```
/// Mapping for user -> snapshotter status.
/// @dev Snapshotters are allowed to manually add
/// snapshots to the contract (intended for the NFT
/// contract to handle pre-migration generations).

is_snapshotter: LegacyMap<ContractAddress, bool>,
```

```
/// The number of generations in the infinite game at the time of migration.

migration_generation_marker: felt252,
```

##### GoL2 Events: <a name="gol2-events"></a>

```
/// Indicates a new game was created.

GameCreated {
  #[key]
  user_id: ContractAddress,   // the user's address that created the game
  game_id: felt252,           // the id of the newly created game
  state: felt252,             // the genesis state of the game
}
```

```
GameEvolved {
  #[key]
  user_id: ContractAddress,   // the user's address that evolved the game #[key]
  game_id: felt252,           // the id of the evolved game
  generation: felt252,        // the new generation of the game
  state: felt252,             // the new state of the game
}
```

```

CellRevived {
  #[key]
  user_id: ContractAddress,   // the user's address that gave life to a cell
  generation: felt252,        // the generation of the game the user gave life to
  cell_index: usize,          // the index of the revived cell; in range: [0, 224]
  state: felt252,             // the new state of the game
}

```

</details>

#### GoL2 Interface: <a name="gol2-interface"></a>

<details>

View:

```
/// Get the game state at a given generation.

fn view_game(game_id: felt252, generation: felt252) -> felt252;
```

```
/// Get the current generation of a game.

fn get_current_generation(game_id: felt252) -> felt252;
```

```
/// Get if a user is a snapshotter.
/// @dev A snapshotter is a contract allowed to create snapshots of the infinite game.

fn is_snapshotter(user: ContractAddress) -> bool;
```

```
/// Get the snapshot of a generation in the infinite game.

fn view_snapshot(generation: felt252) -> GoL2::Snapshot;
```

> **_A snapshot is a capture of an evolution, if a cell is revived during a generation, this is not recorded in the snapshot, only its original state, creator & timestamp are._**

External (only-owner):

```
/// Migrate the contract from the old proxy implementation.
/// @dev Only callable once.

fn migrate(new_class_hash: ClassHash);
```

```
/// Upgrade the contract to the new implementation hash.
/// @dev Only callable by the contract owner.
/// @dev Calls the new implementation's initializer function.

fn upgrade(new_class_hash: ClassHash);
```

```
/// Set a user's snapshotter status.
/// @dev A snapshotter is a contract allowed to create snapshots for the infinite game.
/// @dev This allows pre-migration snapshots to be saved in the contract via 3rd party contracts.

fn set_snapshotter(user: ContractAddress, is_snapshotter: bool);
```

External (only-snapshotters):

```
/// Add a snapshot of a generation to the contract.
/// @dev Only callable by a snapshotter.
/// @dev Only callable for generations <= the migration_generation_marker
/// because post-migration snapshots are stored automatically.

fn add_snapshot(
generation: felt252,
user_id: ContractAddress,
game_state: felt252,
timestamp: u64
) -> bool;
```

External (public):

```
/// Create a new creator mode game.

fn create(game_state: felt252);
```

```
/// Evolve a game by 1 generation.
/// @dev Saves a snapshot of this generation if in infinite mode.

fn evolve(game_id: felt252);
```

```
/// Revive a cell in the infinite game.
/// @dev This function fails if the cell is already alive.

fn give_life_to_cell(cell_index: usize);
```

> **_The contract also implements [OpenZeppelin's](https://github.com/OpenZeppelin/cairo-contracts) ownable and erc20 components, gaining their storage vars, events, and functions._**

</details>

</details>

### GoL2NFT <a name="gol2nft"></a>

<details>

- [Overview](#gol2nft-overview)
- [Architecture](#gol2nft-architecture)
  - [Storage vars](#gol2nft-storage-vars)
- [Interface](#gol2nft-interface)
- [On-chain Metadata](#on-chain-metadata)

#### GoL2NFT Overview: <a name="gol2nft-overview"></a>

<details>

This is an ERC-721 contract for players to mint their snapshots.

</details>

#### GoL2NFT Architecture: <a name="gol2nft-architecture"></a>

<details>

##### GoL2NFT Storage vars: <a name="gol2-storage-vars"></a>

```
/// Total number of tokens minted.

total_supply: u256,
```

```
/// GoL2 game contract address.

gol2_addr: ContractAddress,
```

```
/// Mint price (wei).

mint_price: u256,
```

```
/// Mint token contract address.

mint_token_addr: ContractAddress,
```

```
/// Map of gamestates to the number of times it was minted.

game_state_copies: LegacyMap<felt252, felt252>,
```

```
/// Merkle root for whitelist mints.

merkle_root: felt252,
```

#### GoL2NFT Interface: <a name="gol2nft-interface"></a>

<details>

View:

```
/// Get the merkle root of the whitelist.

fn merkle_root() -> felt252;
```

```
/// Get the price to mint 1 token (in wei).

fn mint_price() -> u256;
```

```
/// Get the mint fee token address.

fn mint_token_address() -> ContractAddress;
```

External (only-owner):

```
/// Upgrade the contract to the new implementation hash.
/// @dev Only callable by the contract owner.
/// @dev Calls the new implementation's initializer function.

fn upgrade(new_class_hash: ClassHash)
```

```
/// Set a new merkle root for the whitelist.

fn set_merkle_root(new_root: felt252);
```

```
/// Set a new mint price (in wei).

fn set_mint_price(new_price: u256);
```

```
/// Set a new mint fee token address.

fn set_mint_token_address(new_addr: ContractAddress);
```

```
/// Withdraw ERC20 tokens from the contract.

fn withdraw(token_addr: ContractAddress, amount: u256, to: ContractAddress);
```

External (public):

```
/// Mint a token to the caller if they are the generation's owner.

fn mint(generation: felt252);
```

```
/// Mint a token to the caller if they have a vaild proof.
/// @dev Because snapshots are only stored in the GoL2 contract post
/// Cairo 1 migration, this function allows users to mint tokens for
/// generations that were evolved before the migration.
/// @dev If the caller's proof is valid, this contract writes the snapshot
/// to the GoL2 contract.

fn whitelist_mint(generation: felt252, state: felt252, timestamp: u64, proof: Array<felt252>);
```

> **_Whitelist details here (todo)._**

> **_The contract also implements [OpenZeppelin's](https://github.com/OpenZeppelin/cairo-contracts) ownable, erc721 and src5 components, gaining their storage vars, events, and functions._**

</details>

</details>

#### On-chain Metadata: <a name="#on-chain-metadata"></a>

<details>

This contract generates all token URI data on-chain [here](./tests/contracts/nft/uri/README.md).

To see an example, start by running this command to generate the JSON URI:

`npm run test_uri`.

> **_NOTE: This command runs `python3 ./tests/contracts/nft/uri/nft_uri_and_svg.py`. You may need to use a different python command other than `python3` to run the script depending on your machine._**

`Test passed!` means the test matches the expected output; to view it for yourself see below:

### Step 1:

Paste the URI into your browser to view the JSON data as marketplaces _**should**_; it will look like this:

`data:application/json,{"name":"GoL2%20%231","description"...,{"trait_type":"Generation","value":2}]}`.

_**This should be identical to this [sample json](./tests/contracts/nft/uri/example.json).**_

### Step 2:

To see the image, find the "image" field in this browser JSON and copy the data. Paste this text into the browser to see the image. It should look like this:

`data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org...width=%225%22/%3E%3C/g%3E%3C/svg%3E`.

> **_NOTE: This step is crucial because the special characters in the SVG URL are double encoded. When the JSON is resolved by the browser, the first layer of encoding is decoded. Pasting this resolved 'image' data into the browser then decodes the second set of special characters, ensuring the SVG renders correctly. The resulting SVG should match this [svg file](./tests/contracts/nft/uri/example.svg)._**

</details>

</details>

## Whitelist <a name="whitelist"></a>

<details>

Because pre-migration snapshots were not stored in the GoL2 contract, we need to use a Merkle Tree to verify a user owns the generation they are trying to mint. We also need to add these snapshot details to the GoL2 contract upon whitelist-minting.

**_[What is a Merkle Tree ?](https://decentralizedthoughts.github.io/2020-12-22-what-is-a-merkle-tree/)_**

The following steps are taken to implement this:

### On-chain:

<details>

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

> **Whitelist minting can be setup after deployment if need be. This is done by deploying the NFT contract with the constructor argument `_merkle_root` set to `0x0`. Then, the contract admin will call `set_merkle_root()` with the whitelist's root hash once finalized.**

> **If any off-chain issues are found in the whitelist, `set_merkle_root()` can be called again by the contract admin with a new root hash.**

</details>

### Off-chain:

<details>

The [whitelist directory](./whitelist/) contains helper functions to create the whitelist, root hash and proofs. When a user whitelist mints a token, they will need to pass their snapshot details and proof to the contract.

There can be either a service that holds the Merkle Tree and generates proofs upon client request (returning the snapshot details & proof), or all proofs & snapshot details can be generated & stored before hand and fetched by the client upon request.

> _**Note: The whitelist can be fully public, even using valid proofs, a malicious caller must match the user_id in the whitelist to produce the correct root hash on-chain.**_

#### Demo:

The finalized whitelist should match the format of this [example whitelist](./whitelist/fork_whitelist.json). Inside [this script](/whitelist/helpers.ts) are functions for generating the whitelist, root hash, and proofs. To demonstrate these helper functions using this example whitelist, start by making sure you have ts-node installed.

The following command should install it:

```
npm install -g ts-node typescript '@types/node'
```

Then, install the dependencies by running:

```
npm install
```

Finally run:

```
ts-node whitelist/helpers.ts
```

to see the demo output.

</details>

</details>

## Dev <a name="dev"></a>

<details>

To build, test & work on the contracts you will need:

- [scarb (>= 2.3.1)](https://book.cairo-lang.org/ch01-01-installation.html)
- [starknet-foundry (>= 0.12.0)](https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html)

Build the contracts by running:

```
scarb build
```

Test the contracts by running:

```
snforge test
```

</details>
