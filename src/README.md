# Contracts

- [GoL2](#gol2)
- [GoL2NFT](#gol2nft)
- [Deployment](#deployment)

# GoL2

<details>

- [Overview](#overview)
- [Interface](#interface)

</details>

## Overview:

An ERC-20 contract that handles the logic and storage for both game modes:

- Infinite:

  - One never ending game allowing any player to evolve the game to its next state, by doing so the player is minted 1 (ERC-20) credit token. These credit tokens can be used to revive a cell in this game, or create a new game.

  - When a player evolves this game, a snapshot of this event is stored for the GoL2NFT contract to use.

  - All created games cost 10 credit tokens and are **_creator_** mode games.

- Creator:

  - To create a new game, a player specifies which cells are initially alive (this game_state is the game_id and must be unique). These creator mode games can be evolved by anyone (minting the player 1 credit token as well), but cannot have their cells revived like the infinite game can.

## Interface:

- View:

```
/// Get the game state at a given generation.

fn view_game(game_id: felt252, generation: felt252) -> felt252;
```

```
/// Get the current generation of a game.

fn get_current_generation(game_id: felt252) -> felt252;
```

```
/// Get the snapshotter
/// @dev The snapshotter is the contract allowed to create snapshots of the infinite game.
/// @dev Allows the GoL2NFT contract to store pre-migration snapshots.

fn snapshotter() -> ContractAddress;
```

```
/// Get the snapshot of a generation in the infinite game.

fn view_snapshot(generation: felt252) -> GoL2::Snapshot;
```

> A snapshot is a capture of an evolution, if a cell is revived during a generation, this is not recorded in the snapshot, only its original state, creator & timestamp are.

- External (only-owner):

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
/// Set the snapshotter
/// @dev The snapshotter is allowed to create snapshots for the infinite game.
/// @dev This allows pre-migration snapshots to be saved in the contract by
/// the GoL2NFT contract.

fn set_snapshotter(user: ContractAddress);
```

- External (only-snapshotter):

```
/// Add a snapshot of a generation to the contract.
/// @dev Only callable by the snapshotter.
/// @dev Only callable for generations <= the migration_generation_marker
/// because post-migration snapshots are stored automatically.

fn add_snapshot(
    generation: felt252,
    user_id: ContractAddress,
    game_state: felt252,
    timestamp: u64
  ) -> bool;
```

- External (public):

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

> The contract also implements _[OpenZeppelin's](https://github.com/OpenZeppelin/cairo-contracts)_ ownable and erc20 components, gaining their storage vars, events, and functions.

# GoL2NFT

<details>

- [Overview](#overview-1)
- [Interface](#interface-1)
- [On-chain Metadata](#on-chain-token-uris)
- [Whitelist](#whitelist)

</details>

## Overview:

An ERC-721 contract for players to mint their snapshots in the infinite game.

## Interface:

- View:

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

- External (only-owner):

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

- External (public):

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

> Details about the whitelist are _[here](../whitelist/README.md)_.

> The contract also implements _[OpenZeppelin's](https://github.com/OpenZeppelin/cairo-contracts)_ ownable, erc721 and src5 components, gaining their storage vars, events, and functions.

## On-chain Token URIs:

This contract generates all token URI data on-chain.

To see an example, start by running this command to generate the JSON URI:

`npm run uri`.

> **_NOTE:_** This command runs `python3 ./tests/contracts/nft/uri/nft_uri_and_svg.py` from the root directory. You may need to use a different python command to run the script depending on your machine.

`Test passed!` means the test matches the expected output; to view it for yourself:

### Step 1:

Paste the URI into your browser to view the JSON data as marketplaces _**should**_; it will look like this:

`data:application/json,{"name":"GoL2%20%231","description"...,{"trait_type":"Generation","value":2}]}`.

_**This should be identical to this [sample json](../tests/contracts/nft/uri/example.json).**_

### Step 2:

To see the image, find the "image" field in the browser JSON object and copy the data. Paste this text into another tab to see the image. It should look like this:

`data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org...width=%225%22/%3E%3C/g%3E%3C/svg%3E`.

> **_NOTE:_** This step is crucial because the special characters in the SVG URL are double encoded. When the JSON is resolved by the browser, the first layer of encoding is decoded. Pasting this resolved "image" data into the browser then decodes the second set of special characters, ensuring the SVG renders correctly. The resulting SVG should match this _[svg file](../tests/contracts/nft/uri/example.svg)_.

We use [these scripts](../tests/contracts/nft/uri/README.md) to parse the cairo output.

## Whitelist

Details about the whitelist are _[here](../whitelist/README.md)_.

# Deployment

For migration & deployment instructions, see _[here](../migration/README.md)_.
