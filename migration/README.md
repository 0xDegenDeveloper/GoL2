# Migration

<details>

1. [Overview](#overview)
2. [Changes](#changes)

   - [Casing](#casing)
   - [Additional Functions and Storage Variables](#additional-functions-and-storage-variables)
   - [Packing Logic](#packing-logic)

3. [Gas Differences](#gas-differences)
4. [Migration Breakdown](#migration-breakdown)
5. [Doing the Migration](#doing-the-migration)

</details>

## Overview

This directory contains the script to migrate the GoL2 contract.

The purpose of this migration was to upgrade the current GoL2 contract form Cairo 0 to Cairo 1, and to add additional logic/storage vars for snapshot minting. More on the NFTs [here](../src/README.md#gol2nft).

In the pre-migrated contract, snapshot details (who/when) were not stored on-chain, they were fired through events, only the generation and game_state were stored. To overcome this, the new version of the contract now stores snapshot details in the contract during each infinite game evolution. A merkle tree was constructed using all pre-migration event data to verify pre-migration snapshot ownership.

When a user successfully whitelist mints a pre-migration generation, the snapshot details are then added to the GoL2 contract. Other changes from the migration are discussed below.

## Changes

### Casing

Back in the Cairo 0 days there were conflicts with the casing for function and event names. Contracts implementing Ethereum standards (ERC-20, ERC-721, etc.) used the same casing for naming events & functions as they are on Ethereum (both CamelCase); all other Cairo functions & events were named using snake_case.

Now in Cairo 1, the standard is to use snake_casing for all function names, and CamelCasing for all event names. The following changes were made to the contract:

#### Events

All of these previous GoL2 events:

```bash
game_created {
    user_id: felt,
    game_id : felt,
    state : felt
}

game_evolved {
    user_id : felt,
    game_id : felt,
    generation : felt,
    state : felt
}

cell_revived{
    user_id : felt,
    generation : felt,
    cell_index : felt,
    state : felt
}
```

had their names and members updated like so:

```bash
GameCreated {
    #[key]
    user_id: ContractAddress,
    game_id: felt252,
    state: felt252,
}

GameEvolved {
    #[key]
    user_id: ContractAddress,
    #[key]
    game_id: felt252,
    generation: felt252,
    state: felt252,
}

CellRevived {
    #[key]
    user_id: ContractAddress,
    generation: felt252,
    cell_index: usize,
    state: felt252,
}
```

**_The `#[key]` property is similar to Ethereum's `indexed` keyword making it easier to filter events more specifically by the member it is defined above (more [here](https://book.cairo-lang.org/ch99-01-03-03-contract-events.html)). `ContractAddress` is a new Struct in Cairo 1 for contracts & user addresses, `felt252` & `u256` are the Cairo 1 ways of saying `felt` & `Uint256`, and `usize` is another way of saying `u32`._**

**_ERC-20 Events were already defined with CamelCasing, so there were no changes there._**

#### Functions

All of these previous GoL2 functions:

```
* Reads

totalSupply() -> Uint256

balanceOf(owner: felt) -> Uint256


* Writes

transferFrom(owner: felt, recipient: felt, amount: Uint256)

increaseAllowance(spender: felt, added_value: Uint256)

decreaseAllowance(spender: felt, subtracted_value: Uint256)
```

had their names and parameters updated like so:

```
* Reads

total_supply() -> u256

balance_of(owner: felt252) -> u256


* Writes

transfer_from(owner: felt252, recipient: felt252, amount: u256)

increase_allowance(spender: felt252, added_value: u256)

decrease_allowance(spender: felt252, subtracted_value: u256)
```

**_This only effects the ERC-20 functions of the contract; other functions such as view_game() & give_life_to_cell() were already defined correctly._**

**_All other ERC20 functions have similar changes to their parameter types: felts, uints, addresses, etc._**

### Additional Functions and Storage Variables

The following elements were added to the new contract:

#### Storage vars

```
is_migrated: bool,

snapshots: LegacyMap<felt252, Snapshot>,

is_snapshotter: LegacyMap<ContractAddress, bool>,

migration_generation_marker: felt252,
```

#### Functions

```
/// Reads

fn is_snapshotter(user: ContractAddress) -> bool;

fn view_snapshot(generation: felt252) -> Snapshot

/// Writes

fn initializer();

fn migrate(new_class_hash: ClassHash);

fn set_snapshotter(user: ContractAddress, is_snapshotter: bool);

fn add_snapshot(
        generation: felt252, user_id: ContractAddress,
        game_state: felt252, timestamp: u64
    ) -> bool;
```

### Packing Logic

In Cairo 0 there was no looping or u256 primatives, and was a much lower-level language in general. The upgraded contract takes advantage of these lacking features; now there are no recursive functions and the game state can easily be converted from felt252 to u256 & back, making the packing/unpacking logic simpler.

## Gas Differences

View gas differences by running:

```
snforge test gas --ignored
```

Each output will be similar to:

```

[DEBUG] evolve          (raw: 0x65766f6c7665

[DEBUG] old             (raw: 0x6f6c64

[DEBUG]                 (raw: 0x1a734

[DEBUG] new             (raw: 0x6e6577

[DEBUG]                 (raw: 0x73a0

```

Where `0x1a734` is the Cairo 0 `evolve()` gas usage, and `0x73a0` is the Cairo 1 `evolve()` gas usage.

## Migration Breakdown

The previous GoL2 contract implemented [OpenZeppelin's proxy]() set up to allow for future contract upgrades. In the new Cairo, we can upgrade a contract's implementation hash directly with a syscall, omitting the need for a proxy setup. This makes migrating the previous contract a 2-step process:

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

This will call `replace_class_syscall(new_class_hash)`, finalizing the contract to its upgradeable, non-proxy, Cairo 1 implementation.

## Doing the Migration

First, build the contracts:

```
scarb build
```

(todo: add confirmation script to check class hashes match expected)

(todo: put finalzied class-hash here for docs)

(todo) env.example, setup npm script
