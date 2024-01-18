# Game of Life

An interactive implementation of Conway's Game of Life as a contract on Starknet, written in Cairo.

<details>

- [Contracts](#contracts)

- [Migration/Deployment](#migrationdeployment)

- [Whitelist](#whitelist)

- [Testing](#testing)

</details>

## Contracts

Documentation for the contracts can be found [here](./src/README.md).

## Migration/Deployment

The old GoL2 contract & documentation can be found [here](https://github.com/yuki-wtf/GoL2-Contract). This new repo is for the GoL2 migration to Cairo 1, and the NFT deployment. Read more about this migration [here](./migration/README.md).

## Whitelist

Documentation for the whitelist can be found [here](./whitelist/README.md).

## Testing

To test the contracts you will need:

- [scarb (>= 2.3.1)](https://book.cairo-lang.org/ch01-01-installation.html)
- [starknet-foundry (>= 0.12.0)](https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html)

Run the test suite via:

```
snforge test
```
