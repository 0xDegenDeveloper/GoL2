# GoL2 Cairo 0 -> Cairo 1 Migration

## Table of contents

1. [Overview](#overview)
2. [Casing Changes](#casing)
   - [Events](#events)
   - [Functions](#functions)
3. [Packing](#packing)
4. [Additional Functions](#added-functions)

## Overview <a name="overview"></a>

asdf

## Casing Changes <a name="casing"></a>

Back in the Cairo 0 days, there were conflicts with the casing for function and event names. Contracts implementing Ethereum standards (ERC-20, ERC-721, etc.) used the same casing for events and functions as they are in Ethereum (both use CamelCasing); all other Cairo functions/events were named using snake_casing.

Now in Cairo 1, the standard is to use snake_casing for all function names, and CamelCasing for all event names. The following changes were made to the contract:

### Events <a name="events"></a>

### Old

```
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

### New

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

**_The `#[key]` property is similar to Ethereum's `indexed` keyword making it easier to filter events more specifically by the member it is defined above. `ContractAddress` is a new Struct in Cairo 1 for contracts & user addresses, and `felt252` is the Cairo 1 way of saying `felt`._**

**_ERC-20 Events were already defined with CamelCasing, so there were no changes there._**

### Functions <a name="functions"></a>

### Old

**_This only effects the ERC-20 functions of the contract; other functions such as view_game() & give_life_to_cell() are already defined correctly._**

```
// Reads

totalSupply()

balanceOf(owner: felt)

// Writes

transferFrom(owner: felt, recipient: felt, amount: Uint256)

increaseAllowance(spender: felt, added_value: Uint256)

decreaseAllowance(spender: felt, subtracted_value: Uint256)
```

### New

```
// Reads

total_supply()

balance_of(owner: felt252)

// Writes

transfer_from(owner: felt252, recipient: felt252, amount: u256)

increase_allowance(spender: felt252, added_value: u256)

decrease_allowance(spender: felt252, subtracted_value: u256)
```

**_All other functions have similar changes to their parameter types, like: felts, uints, addresses, etc._**

### Packing <a name="packing"></a>

In Cairo 0 there was no looping or u256 primatives, and it was a much lower-level language in general. The upgraded contract takes advantage of these missing features, so now there is no more recursive functions and the game state can easily be converted from felt252 <-> u256 and back, making the packing/unpacking logic simpler.

4. [Additional Functions](#)

### Additional Functions <a name="added-functions"></a>

// todo:

Talk about the addition of the snapshot feature once requirements better defined/implemented
