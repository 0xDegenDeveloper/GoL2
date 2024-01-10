# Game of Life

## Table of contents

- [Overview](#overview)

- [Contracts](#contracts)

  - [GoL2](#gol2)

  - [GoL2NFT](#gol2nft)

- [Dev](#dev)

<!-- 1. [Overview](#overview)
2. [Game modes](#game-modes)
3. [Interface](#interface)
4. [Architecture](#architecture)
   - [Variables, Events, Structs](#variables-events-structs)
     - [Constants](#constants)
     - [Events](#events)
     - [Storage variables](#storage-variables)
     - [Structs](#structs)
   - [Packing](#packing)
     - [Packing a game](#pack-a-game)
     - [Unpacking a game](#unpacking-a-game)
5. [Development](#development)
6. [Testing](#testing) -->

## Overview <a name="overview"></a>

An interactive implementation of Conway's Game of Life as a contract on Starknet, written in Cairo.

> **_Originally written in Cairo 0 and now migrated to Cairo 1; for more details about this migration see [here](./docs/MIGRATION.md#overview)_**.

## Contracts <a name="contracts"></a>

### GoL2 <a name="gol2"></a>

#### Overview

There are two game modes and both are defined in [this](./src/contracts/gol.cairo) contract:

##### Infinite:

- One never ending game allowing any player to evolve the game to its next state, by doing so the player is minted 1 credit token. These credit tokens can be used to revive a cell in this game, or create a new game.

- When a player evolves this game, a snapshot of this event is stored for the [GoL2NFT](#gol2nft) contract to use.

- All created games cost 10 credit tokens and are [creator](#creator) mode games.

##### Creator: <a name="creator"></a>

- To create a new game, a player specifies which cells are initially alive (this game_state is the game_id and must be unique). These creator mode games can be evolved by anyone (minting the player 1 credit token as well), but cannot have their cells revived like the infinite game.

- The purpose of this game mode is to allow players to explore different starting patterns in the the game. E.g., inventing a new starting position that last many generations before dying out or creating a unique pattern.

#### Constants <a name="constants"></a>

- Defined in [src/utils/constants.cairo](./src/utils/constants.cairo).

  - `INFINITE_GAME_GENESIS` - The genesis state for the infinite mode game (also used as the game_id for this game).
  - `DIM` - The game grid dimensions.
  - `CREATE_CREDIT_REQUIREMENT` - Credit tokens required to create a new creator mode game.
  - `GIVE_LIFE_CREDIT_REQUIREMENT` - Credit tokens required to give life to a cell in infinite mode.
  - `FIRST_ROW_INDEX` - Index of the first row of the game grid. Is 0 and should stay 0
    even if `DIM` changes.
  - `LAST_ROW_INDEX` - Index of the last row of the game grid; `DIM - 1`.
  - `LAST_ROW_CELL_INDEX` - Index of the first cell in the last row of the game grid. It should be `(DIM * DIM) - DIM`.
  - `FIRST_COL_INDEX` - Index of the first column of the game grid. Is 0 and should stay 0 even if `DIM` changes.
  - `LAST_COL_INDEX` - Index of the last column of the game grid; `DIM - 1`.
  - `LAST_COL_CELL_INDEX` - Index of the last cell in the last column of the game grid; `DIM - 1`.
  - `LOW_ARRAY_LEN` - Length of an array that represents the "low" value of the game board.
    - Max value is `128`, added to `HIGH_ARRAY_LEN` must be equal to `DIM**2`.
  - `HIGH_ARRAY_LEN` - Length of an array that represents the "high" value of the game board.
    - Max value is `97`, added to `LOW_ARRAY_LEN` has to be equal to `DIM**2`.
  - `BOARD_SQUARED` - The number of cells in the game board.

#### Structs <a name="structs"></a>

```
/// Used to store details about each evolution of the infinite game.

Snapshot {
  user_id: ContractAddress - Address of the player that evolved this generation.
  game_state: felt252 - State the game was evolved to.
  timestamp: u64 - Unix block timestamp when this snapshot was taken.
}
```

#### Storage Variables

```
1: stored_game: LegacyMap<(felt252, felt252), felt252>

2: current_generation: LegacyMap<felt252, felt252>,

3: is_migrated: bool,

4: snapshots: LegacyMap<felt252, Snapshot>,

5: is_snapshotter: LegacyMap<ContractAddress, bool>,
```

1. `stored_game` - Stores game information on chain.

   - params:

     - game_id: felt252 -> ID of the game
     - generation: felt252 -> Generation of the game

   - returns:

     - state: felt252 -> The state of the game_id at the given generation

2. `current_generation` - Stores the current generation for all games.

- params:

  - game_id: felt252 -> ID of the game

- returns:

  - game_generation: felt252 -> Current generation of the game

3. `is_migrated` - Stores if the contract has been migrated to Cairo 1 yet.

   - returns:

     - is_migrated: bool -> If the migration has happened

4. `snapshots` - Stores a record of generation evolutions (in infinite mode).

   - params:

     - generation: felt252 - The generation of the infinite game

   - returns:

     - snapshot: Snapshot - The Snapshot struct for the generation

5. `is_snapshotter` - Stores the snapshotter status for users.

   - params:

     - user_id: ContractAddress - The user/contract address

   - returns:

     - status: bool - The user's snapshotter status

       - Snapshotters are allowed to manually add snapshots to the contract. This allows the [GoL2NFT](./docs/NFT.md) contract to save pre-migration snapshots.

#### Interface

##### - View Functions:

`is_snapshotter(user: ContractAddress) -> bool`

- Return a user's snapshotter status.

  - Snapshotters can manually add pre-migration snapshots.
  - Allows the [GoL2NFT](#gol2nft) contract to manually add pre-migration snapshots during whitelist minting.

`view_game(game_id: felt252, generation: felt252) -> felt252`

- Return the game_state of a game at a generation.

`view_snapshot(generation) -> Snapshot`

- Return the snapshop of a generation.

> **_A snapshot is a capture of an evolution, if a cell is revived during a generation, this is not recorded in the snapshot, only its original state, creator & timestamp are, see [structs](#gol2nft)._**

`get_current_generation(game_id: felt252) -> felt252`

- Return the current generation of a game.

#### - External (Owner) Functions:

`initializer()`

- Empty function.

- Used for any future upgrades to the contract.

`upgrade(new_class_hash: ClassHash)`

- Upgrade the contract's implementation hash
  - Can only be called by the contract owner.

`migrate(new_class_hash: ClassHash)`

- Migrate the old proxy contract to a Cairo 1 upgradeable implementation.
  - For more details see [migration](./docs/MIGRATION.md).

#### - External (Public) Functions

`create(game_state: felt252)`

- Create a new creator mode game.

  - Costs the player 10 credit tokens.

`evolve(game_id: felt252)`

- Evolve a game by one generation.

  - Rewards the player 1 credit token.

`give_life_to_cell(cell_index: usize)`

- Give life to a cell at the cell_index in infinite mode.
  - Costs the player 1 credit token.

> **_The contract also implements [OpenZeppelin's](https://github.com/OpenZeppelin/cairo-contracts) ownable and erc20 components, gaining their view & external functions (`transfer_ownership(), total_supply(), etc.`)._**

#### Events <a name="events"></a>

- Emitted by the contract to be parsed by the indexer.

  - `GameCreated` - Indicates a new game was created.

    - values:
      - user_id: ContractAddress -> Address of the user who created the game
      - game_id: felt252 -> ID of the newly created game
      - state: felt252 -> Genesis state of the game

  - `GameEvolved` - Indicates a game was evolved.

    - values:
      - user_id: ContractAddress -> Address of a user that evolved the game
      - game_id: felt252 -> ID of the evolved game
      - generation: felt252 -> New generation of the game
      - state: felt252 -> New state of the game

  - `CellRevived` - Indicates a cell in infinite game was revived.

    - values:
      - user_id: ContractAddress -> ID of the user that gave life to cell
      - generation: felt252 -> Generation of the game user gave life to
      - cell_index: usize -> Index of the revived cell
      - state: felt252 -> New state of the game

## Dev <a name="dev"></a>

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
