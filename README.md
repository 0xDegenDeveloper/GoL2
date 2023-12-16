# Game of Life

## Table of contents

1. [Overview](#overview)
2. [Game modes](#game_modes)
   - [Infinite](#infinite)
   - [Creator](#creator)
3. [Interface](#interface)
4. [Architecture](#architecture)
   - [Variables, events, structs](#variables_and_events)
     - [Constant variables](#constants)
     - [Events](#events)
     - [Storage variables](#storage)
     - [Structs](#structs)
   - [Packing](#packing)
     - [Packing a game](#packing_game)
     - [Unpacking a game](#unpacking_game)
5. [Development](#development)
   - [Requirements](#requirements)

## Overview <a name="overview"></a>

An implementation of Conway's Game of Life as a contract on StarkNet, written
in Cairo, with an interactive element.

Players can alter the state of the game, affecting the future of the simulation.
People may create interesting states or coordinate with others to achieve some
outcome of interest.

This implementation is novel in that the game state is shared (agreed by all) and permissionless
(anyone may participate). The game rules are enforced by a validity proof, which means that
no one can evolve the game using different rules.

The main rules of the game are:

- The normal rules of Conways' Game of Life (3 to revive, 2 or 3 to stay alive).
- The boundaries wrap - a glider may travel infinitely within the confines of the grid.

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

## Game modes <a name="game_modes"></a>

There are two modes: Inifinite and Creator

### Infinite <a name="infinite"></a>

A single game with an ability for participants to evolve the game to its next state.
By doing so they also gain one credit token that can be used to either revive a chosen cell
or create a new creator game.

The game may flourish and produce a myriad of diverse game states, or it may fall to ruin and
become a barren wasteland. It will be up to the participants to decide if and when to use
their life-giving power.

The purpose of this game mode is to encourage collaboration.

### Creator <a name="creator"></a>

An open-ended collection of starting states that anyone can create. A player
can specify the alive/dead state for all the cells in the game they spawn. The
game can be evolved from that point, but individual cells cannot be altered.

Anyone can progress a game, and in return they get one credit token. Ten
credits can be used to create a new game. Each game has to be unique.

The purpose of this game is to allow players to explore interesting starting
patterns in the the game. E.g., inventing new starting positions that last
many generations before dying out or create a unique pattern.

## Interface <a name="interface"></a>

### External Functions:

1. Migrate - **_can only be called once, right after contract proxy deploy, by the contract owner/admin_**

It migrates the contract from Cairo 0 -> Cairo 1. See more details [here](./MIGRATION.md).

```
fn migrate (
  new_class_hash: ClassHash - Hash of new contract class implementation
)
```

2. Upgrade - **_can only be called by the contract owner/admin_**

Upgrades the contract.

```
fn upgrade (
  new_class_hash: ClassHash - Hash of new contract class implementation
)
```

3. Evolve

Evolves the game and rewards user with 1 credit token.

```
fn evolve (
  game_id: felt252 - Id of the game to evolve
)
```

4. Create - **_only creator mode_**

Creates a new game, reduces user credit balance by 10 credit tokens.

```
fn create (
  game_state: felt252 - Genesis state for a new game
)
```

5. Give life to cell - **_only infinite mode_**

Gives life to cell under chosen index, reduces user credit balance by 1 credit token.

```
fn give_life_to_cell (
  cell_index: usize - An index of the cell the user wants to revive (value between 0-224)
)
```

### View functions:

1. View game

Views the game board encoded as a single `felt252`.

```
fn view_game (
    game_id: felt252 - Id of the game to view
    generation: felt252 - Generation of the game to view
) -> game_state: felt252 - A felt containing an encoded game state for given game_id and generation
```

2. Get current generation

Gets the current generation of a given game.

```
fn get_current_generation (
    game_id: felt252 - Id of game to retrieve last generation
) -> generation: felt252 - Generation of the given game
```

3. Get snapshot details

Gets the snapshot of a specific generation in the infinite game. **_Note: A snapshot is a capture of an evolution, if a cell is revived for a generation, this is not recorded in the snapshot, only its original state/creator/timestamp._**

```
fn view_snapshot (
      generation: felt252 - The generation {}
) -> snapshot: Snapshot
```

**_A Snapshot is a new struct we have added, it is defined below._**

## Architecture <a name="architecture"></a>

Summary:

- Both game modes are defined in a single contract (`src/contracts/gol.cairo`)
- The game board is a square with side length `dim`, (`by default dim = 15`)
  containing `dim**2` cells
- Cells wrap around the edges
- Every cell state is being described as alive (1) or dead (0)
  - Each cell can be referenced by its index, starting from index 0
    (left-upper corner of the board) ending with index `dim**2-1`
    (by default 224) (right-lower corner of the board)
- Whole board can fit into one felt
  - Consult [Packing](#packing) for more
- Users can earn credit tokens by evolving games, and spend them by creating
  new games/reviving cells in infinite mode
- Genesis state of the game is its game_id
- No two games can have identical genesis states

### Variables, events, structs <a name="variables_and_events"></a>

#### Constant variables used in the contract (defined in `utils/constants.cairo`). <a name="constants"></a>

- `INFINITE_GAME_GENESIS` - The genesis state for the game in infinite mode;
  This state is also used as game_id for infinite game
- `DIM` - The game grid dimensions
- `CREATE_CREDIT_REQUIREMENT` - Credit token count required for new game creation in creator mode
- `GIVE_LIFE_CREDIT_REQUIREMENT` - Credit token count required for giving life in infinite mode
- `FIRST_ROW_INDEX` - Index of the first row of the game grid; Is 0 and should stay 0
  even when `DIM` change
- `LAST_ROW_INDEX` - Index of the last row of the game grid; `DIM - 1`
- `LAST_ROW_CELL_INDEX` - Index of the first cell in the last row of the game grid;
  Should be `DIM - DIM * DIM`
- `FIRST_COL_INDEX` - Index of the first column of the game grid;
  Is 0 and should stay 0 even when `DIM` change
- `LAST_COL_INDEX` - Index of the last column of the game grid; `DIM - 1`
- `LAST_COL_CELL_INDEX` - Index of the last cell of the last column of the game grid; `DIM - 1`
- `SHIFT` - Shift number used to pack game into one felt
- `LOW_ARRAY_LEN` - Length of an array that represents the "low" value of the game board;
  Max value is `128`, added to `HIGH_ARRAY_LEN` has to be equal to `DIM**2`
- `HIGH_ARRAY_LEN` - Length of an array that represents the "high" value of the game board;
  Max value is `128`, added to `LOW_ARRAY_LEN` has to be equal to `DIM**2`

#### Events that are emitted by the contract. These are later parsed by the [indexer](indexer/README.md). (defined in `utils/events.cairo`). <a name="events"></a>

- `GameCreated` - Indicates a new game was created

  - values:
    - user_id: ContractAddress -> Address of the user who created the game
    - game_id: felt252 -> ID of the newly created game
    - state: felt252 -> Genesis state of the game

- `GameEvolved` - Indicates a game was progressed

  - values:
    - user_id: ContractAddress -> Address of a user that evolved the game
    - game_id: felt252 -> ID of the evolved game
    - generation: felt252 -> New generation of the game
    - state: felt252 -> New state of the game

- `CellRevived` - Indicated a cell in infinite game was revived

  - values:
    - user_id: ContractAddress -> ID of the user that gave life to cell
    - generation: felt252 -> Generation of the game user gave life to
    - cell_index: usize -> Index of the revived cell
    - state: felt252 -> New state of the game

// todo: new snapshot ?

#### Storage variables used by the contract. (defined in `utils/state.cairo`). <a name="storage"></a>

- `stored_game` - Holds game information on chain

  - parameters:

    - game_id: felt252 -> ID of the game
    - generation: felt252 -> Generation of the game

  - values:
    - state: felt252 -> The state of the game_id at the given generation

- `current_generation` - Holds latest generation for game_ids

  - parameters:

    - game_id: felt252 -> ID of the game

  - values:

    - game_generation: felt252 -> Latest generation of the given game_id

- `is_migrated` - States if the contract has been upgraded to Cairo 1 yet

  - parameters:

    - none

  - values:

    - is_migrated: bool -> If the migration txn has occurred

- `snapshots` - Holds a record of generation Snapshots

  - parameters:

    - generation: felt252 - Generation of the infinite game to view a snapshot of

  - values:

    - snapshot: Snapshot - A snapshot object of the current generation

#### Structs <a name="structs"></a>

- Snapshot - Used to store details about each evolution in the infinite game

```
Snapshot {
  user_id: ContractAddress - Address of user to evolve this generation
  game_state: felt252 - State the game was evolved into
  timestamp: u64 - Unix block timestamp when this snapshot was taken
}
```

### Packing <a name="packing"></a>

#### Packing a game <a name="packing_game"></a>

To pack the game into one `felt252` we use the `src/utils/helpers.cairo::pack_game` function.

It takes an array of cells (representing binary), and verifies it has the proper length for a game.

#### Array:

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

#### Binary Representation:

`0b:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000001000000000001100111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

Next, the array is passed to the `srs/utils/helpers.cairo::pack_cells` function, where the binary representation is converted into its decimal representation.

This returns the value `39132555273291485155644251043342963441664`, which is our game board packed into a single `felt252`.

#### Unpacking a game <a name="unpacking_game"></a>

To unpack the game from a single `felt252` to an array of cell states, we use the `src/utils/helpers.cairo::unpack_game` function.

It takes the `felt252` packed game, converts it to its binary representation, then writes it into an array of cells.

## Development <a name="development"></a>

### Requirements <a name="requirements"></a>

- [scarb (>= 2.3.0)](https://book.cairo-lang.org/ch01-01-installation.html)
- [starknet-foundry (>= 0.12.0)](https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html)

To build the contracts run:

```
scarb build
```

For testing and see gas usage, see [here](./tests/).
