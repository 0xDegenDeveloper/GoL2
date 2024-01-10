# Game of Life

## Table of contents

1. [Overview](#overview)
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
6. [Testing](#testing)

## Overview <a name="overview"></a>

An implementation of Conway's Game of Life as a contract on Starknet, written in Cairo, with an interactive element.

> **_Originally written in Cairo 0 and now migrated to Cairo 1; for more details about this migration see [here](./docs/MIGRATION.md#overview)_**.

Players can alter the state of the game, affecting the future of the simulation.
They may also create interesting states or coordinate with others to achieve an
outcome of interest.

This implementation is novel in that the game state is shared (agreed by all) and permissionless (anyone may participate). The game rules are enforced by a validity proof, meaning no one can evolve the game using different rules.

The main rules of the game are:

- The normal rules of Conways' Game of Life (3 to revive, 2 or 3 to stay alive).
- The boundaries wrap - a glider may travel infinitely within the confines of the grid.

### Example evolution:

<table>
<tr><th> Acorn Generation 1 </th><th> Acorn Generation 2 </th></tr>
<tr><td>

|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
| :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  ■  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  ■  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  ■  |  ■  |  •  |  •  |  ■  |  ■  |  ■  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |

</td><td>

|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
| :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  ■  |  ■  |  ■  |  •  |  ■  |  ■  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  ■  |  ■  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  ■  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |
|  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |  •  |

</td></tr>
</table>

## Game modes <a name="game-modes"></a>

The two modes are: Inifinite and Creator

### Infinite

A single game with an ability for participants to evolve the game to its next state. By doing so they also gain one credit token that can be used to either revive a chosen cell or create a new (creator mode) game. When a player evolves this game, a snapshot of this event is saved for the [GoL2NFT contract](./docs/NFT.md) to use.

The game may flourish and produce a myriad of diverse game states, or it may fall to ruin and become a barren wasteland. It is up to the players to decide if and when to use their life-giving power.

The purpose of this game mode is to encourage collaboration.

### Creator

Creator mode games are an open-ended collection of games with varying initial states. When a player creates one of these games, they specify which cells are alive at spawn. These games can be evolved, but individual cells cannot be altered (revived via credit token).

Anyone can evolve one of these games, and in return will gain a credit token, just like infinite mode. Ten credits can be used to create a new creator mode game, and each game has to be unique.

The purpose of this game is to allow players to explore interesting starting patterns in the the game. E.g., inventing new starting positions that last many generations before dying out or create a unique pattern.

## Interface <a name="interface"></a>

### View functions:

- `is_snapshotter(user: ContractAddress) -> bool`

  - Return a user's snapshotter status.
    - Snapshotters can manually add pre-migration snapshots.
    - Allows the GoL2NFT contract to manually add pre-migration snapshots during whitelist minting.

- `view_game(game_id: felt252, generation: felt252) -> felt252`

  - Return the game_state of a game at a generation.

- `view_snapshot(generation) -> Snapshot`

  - Return the snapshop of a generation.
    - **_A snapshot is a capture of an evolution, if a cell is revived during a generation, this is not recorded in the snapshot, only its original state, creator & timestamp are, see [structs](#structs)._**

- `get_current_generation(game_id: felt252) -> felt252`

  - Return the current generation of a game.

### External Functions (Only Owner):

- `initializer()`

  - Empty function.
    - Used for any future upgrades to the contract.

- `upgrade(new_class_hash: ClassHash)`

  - Upgrade the contract's implementation hash
    - Can only be called by the contract owner.

- `migrate(new_class_hash: ClassHash)`

  - Migrate the old proxy contract to a Cairo 1 upgradeable implementation.
    - Can only be called once by the contract owner, right after contract proxy implementation hash is upgraded.
      - For more details see [migration](./docs/MIGRATION.md).

### External Functions (Public)

- `create(game_state: felt252)`

  - Create a new creator mode game.
    - Costs the player 10 credit tokens.

- `evolve(game_id: felt252)`

  - Evolve a game by one generation.
    - Rewards the player 1 credit token.

- `give_life_to_cell(cell_index: usize)`

  - Give life to a cell at the cell_index in infinite mode.
    - Costs the player 1 credit token.

**_The contract also implements [OpenZeppelin's](https://github.com/OpenZeppelin/cairo-contracts) ownable and erc20 components, gaining their view & external functions (`transfer_ownership(), total_supply(), etc.`)._**

## Architecture <a name="architecture"></a>

Summary:

- Both game modes are defined in a single contract (`src/contracts/gol.cairo`).
- The game board is a square with side length `dim`, (`by default dim = 15`) containing `dim**2` cells.
- Cells wrap around the edges.
- Every cell state is described as alive (1) or dead (0).
  - Each cell can be referenced by its index, starting from index 0 (upper-left corner of the board), and ending with index `dim**2-1` (by default 224, lower-right corner of the board).
- The whole board can fit into a single `felt252`
  - See [Packing](#packing) for details.
- Users earn credit tokens by evolving games, and spend them by creating
  new creator mode games or reviving cells in infinite mode.
- The genesis state of a game is its game_id.
- No two games can have the same genesis states.

### Variables, Events, Structs <a name="variables_events_structs"></a>

#### Constants <a name="constants"></a>

Defined in [src/utils/constants.cairo](./src/utils/constants.cairo).

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

#### Events <a name="events"></a>

Emitted by the contract to be parsed by the indexer.

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

- `CellRevived` - Indicated a cell in infinite game was revived.

  - values:
    - user_id: ContractAddress -> ID of the user that gave life to cell
    - generation: felt252 -> Generation of the game user gave life to
    - cell_index: usize -> Index of the revived cell
    - state: felt252 -> New state of the game

#### Storage variables <a name="storage-variables"></a>

```
stored_game: LegacyMap<(felt252, felt252), felt252>

current_generation: LegacyMap<felt252, felt252>,

is_migrated: bool,

snapshots: LegacyMap<felt252, Snapshot>,

is_snapshotter: LegacyMap<ContractAddress, bool>,

migration_generation_marker: felt252,
```

- `stored_game` - Stores game information on chain.

  - params:

    - game_id: felt252 -> ID of the game
    - generation: felt252 -> Generation of the game

  - returns:

    - state: felt252 -> The state of the game_id at the given generation

- `current_generation` - Stores the current generation for all games.

  - params:

    - game_id: felt252 -> ID of the game

  - returns:

    - game_generation: felt252 -> Current generation of the game

- `is_migrated` - Stores if the contract has been migrated to Cairo 1 yet.

  - returns:

    - is_migrated: bool -> If the migration has happened

- `snapshots` - Stores a record of generation evolutions (in infinite mode).

  - params:

    - generation: felt252 - The generation of the infinite game

  - returns:

    - snapshot: Snapshot - The Snapshot struct for the generation

- `is_snapshotter` - Stores the snapshotter status for users.

  - params:

    - user_id: ContractAddress - The user/contract address

  - returns:

    - status: bool - The user's snapshotter status

      - Snapshotters are allowed to manually add snapshots to the contract. This allows the [GoL2NFT](./docs/NFT.md) contract to save pre-migration snapshots.

#### Structs <a name="structs"></a>

```
/// Used to store details about each evolution of the infinite game.

Snapshot {
  user_id: ContractAddress - Address of the player that evolved this generation.
  game_state: felt252 - State the game was evolved to.
  timestamp: u64 - Unix block timestamp when this snapshot was taken.
}
```

### Packing <a name="packing"></a>

#### Pack a game <a name="packing-a-game"></a>

To pack a game into one `felt252` we use the `src/utils/helpers.cairo::pack_game` function.

It takes an array of cells (representing binary), and verifies it has the proper length for a game.

#### Acorn Generation Example:

#### As array:

```
000000000000000
000000000000000
000000000000000
000000000000000
000000000000000
000000000000000
000000000100000
000000000001000
000000001100111
000000000000000
000000000000000
000000000000000
000000000000000
000000000000000
000000000000000
```

#### As binary:

`0b:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111001100000000000100000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

The array is passed to the `srs/utils/helpers.cairo::pack_cells` function, where the binary representation is converted into its decimal representation.

This returns the value `39132555273291485155644251043342963441664`, which is our game board packed into a single `felt252`.

#### Unpacking a game <a name="unpacking-a-game"></a>

To unpack a game from a single `felt252` to an array of cell states, we use the `src/utils/helpers.cairo::unpack_game` function.

It takes the `felt252` packed game, converts it to its binary representation, then writes it into an array of cells.

## Development <a name="development"></a>

### Requirements

- [scarb (>= 2.3.1)](https://book.cairo-lang.org/ch01-01-installation.html)
- [starknet-foundry (>= 0.12.0)](https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html)

To build the contracts run:

```
scarb build
```

## Testing <a name="testing"></a>

### Run basic tests:

`snforge test`

## View Gas Differences:

`snforge test gas --ignored`

The output will be similar to:

```
[DEBUG] evolve                          (raw: 0x65766f6c7665

[DEBUG] old                             (raw: 0x6f6c64

[DEBUG]                                 (raw: 0x1a734

[DEBUG] new                             (raw: 0x6e6577

[DEBUG]                                 (raw: 0x73a0
```

where `0x1a734` is the Cairo 0 `evolve` function's gas usage, and `0x73a0` is the Cairo 1 `evolve` function's gas usage.
