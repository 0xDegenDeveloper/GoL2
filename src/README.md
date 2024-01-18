# Contracts

## GoL2 <a name="gol2"></a>

<details>

- [Overview](#overview)
- [Interface](#interface)

</details>

### Overview:

This is an ERC-20 contract that also handles the logic and storage for both game modes:

- Infinite:

  - One never ending game allowing any player to evolve the game to its next state, by doing so the player is minted 1 (ERC-20) credit token. These credit tokens can be used to revive a cell in this game, or create a new game.

  - When a player evolves this game, a snapshot of this event is stored for the GoL2NFT contract to use.

  - All created games cost 10 credit tokens and are **_creator_** mode games.

- Creator:

  - To create a new game, a player specifies which cells are initially alive (this game_state is the game_id and must be unique). These creator mode games can be evolved by anyone (minting the player 1 credit token as well), but cannot have their cells revived like the infinite game can.

### Interface:

#### View:

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

#### External (only-owner):

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

#### External (only-snapshotters):

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

#### External (public):

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

## GoL2NFT

<details>

- [Overview](#overview-1)
- [Interface](#interface-1)
- [On-chain Metadata](#on-chain-token-uris)
- [Deployment](#deployment)

</details>

### Overview:

This is an ERC-721 contract for players to mint their snapshots in the infinite GoL2 game.

### Interface:

#### View:

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

#### External (only-owner):

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

#### External (public):

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

> **_Details about the whitelist are [here](../whitelist/README.md)._**

> **_The contract also implements [OpenZeppelin's](https://github.com/OpenZeppelin/cairo-contracts) ownable, erc721 and src5 components, gaining their storage vars, events, and functions._**

### On-chain Token URIs:

This contract generates all token URI data on-chain [here](../tests/contracts/nft/uri/README.md).

To see an example, start by running this command to generate the JSON URI:

`npm run test_uri`.

> **_NOTE: This command runs `python3 ./tests/contracts/nft/uri/nft_uri_and_svg.py` from the root directory. You may need to use a different python command to run the script depending on your machine._**

`Test passed!` means the test matches the expected output; to view it for yourself see below:

#### Step 1:

Paste the URI into your browser to view the JSON data as marketplaces _**should**_; it will look like this:

`data:application/json,{"name":"GoL2%20%231","description"...,{"trait_type":"Generation","value":2}]}`.

_**This should be identical to this [sample json](../tests/contracts/nft/uri/example.json).**_

#### Step 2:

To see the image, find the "image" field in this browser JSON and copy the data. Paste this text into the browser to see the image. It should look like this:

`data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org...width=%225%22/%3E%3C/g%3E%3C/svg%3E`.

> **_NOTE: This step is crucial because the special characters in the SVG URL are double encoded. When the JSON is resolved by the browser, the first layer of encoding is decoded. Pasting this resolved 'image' data into the browser then decodes the second set of special characters, ensuring the SVG renders correctly. The resulting SVG should match this [svg file](../tests/contracts/nft/uri/example.svg)._**

### Deployment

The GoL2 contract was already deployed ~2 years ago, so no (re-)deployment steps were necessary (see [migration](../migration/README.md)).

To deploy the GoL2NFT contract using `sncast` we first declare the class hash using:

```
sncast -p goerli declare --contract-name GoL2NFT
```

After this txn is confirmed, we can deploy an instance of the contract using:

```
sncast -p goerli deploy --class-hash <A> -c 0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973 0x47616D65206F66204C696665204E4654 0x476F4C324E4654 <B> <C> 1 0 <D>
```

Where -c denotes the constructor args:

- `0x03e61a95b01cb7d4b56f406ac2002fab15fb8b1f9b811cdb7ed58a08c7ae8973` - The contract admin.
- `0x47616D65206F66204C696665204E4654` - The collection name.
- `0x476F4C324E4654` - The collection symbol.
- `<B>` - The GoL2 contract address.
- `<C>` - The payment token's contract address.
- `1` - The mint fee (u256.low).
- `0` - The mint fee (u256.high).
- `<D>` - The whitelist root hash.

This deployment takes place during the migration multi-call [here](../migration/README.md).
