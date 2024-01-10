import { num } from "starknet";
import { MerkleTree } from "merkletreejs";
import { poseidonHashMany } from "@scure/starknet";
import { bytesToNumberBE, numberToBytesBE } from "@noble/curves/abstract/utils";
import * as rawData from "./fork_whitelist.json";

type Snapshot = {
  user_id: string;
  game_state: string;
  timestamp: number;
};

type DataStructure = {
  [generation: string]: Snapshot;
};

/**
 * Create a leaf's hash from the given data.
 * @param generation The generation of the game.
 * @param snapshot The snapshot of the game.
 * @returns The hex-string ("0xabcd...") leaf hash.
 */
const createLeafHash = (generation: string, snapshot: Snapshot): string => {
  return num.toHex(
    poseidonHashMany([
      num.toBigInt(generation),
      num.toBigInt(snapshot.user_id),
      num.toBigInt(snapshot.game_state),
      num.toBigInt(snapshot.timestamp),
    ])
  );
};

/**
 * Gets the leaf hash for a given generation as a buffer.
 * @param generation The generation to fetch the leaf hash for.
 * @returns The hex string (0xabcd...) leaf hash.
 */
const getHashedLeaf = (generation: string): Buffer => {
  return Buffer.from(
    numberToBytesBE(
      num.toBigInt(createLeafHash(generation, data[generation])),
      32
    )
  );
};

/**
 * Creates a Merkle tree from the whitelist data.
 * @returns The Merkle tree.
 */
const createTree = (data: DataStructure): MerkleTree => {
  /// Create the leaf hashes for each generation in the data.
  const leaves: Buffer[] = Object.keys(data).map((generation) =>
    getHashedLeaf(generation)
  );
  /**
   * Re-defined Poseidon hash function.
   * @dev The bytesToNumberBE and back ensures correct padding when the Merkle Tree
   * is created. Without the correct padding, leaves with a non-full byte
   * are dropped (odd hex-lengths lose their last nible).
   */
  const specialHash = (input: Buffer[]): Buffer =>
    Buffer.from(
      numberToBytesBE(
        poseidonHashMany(input.map((x) => bytesToNumberBE(x))),
        32
      )
    );

  return new MerkleTree(leaves, specialHash, {
    /// @dev Allows us to break apart the pre-buffered value into its components.
    concatenator: (buffers: Buffer[]): Buffer[] => {
      return buffers;
    },
    /// @dev Fills the extra leaves with 0x0 to complete the Tree.
    fillDefaultHash: (): Buffer => {
      return Buffer.from([0x0]); // todo check if need to go back to num.toBigInt(0x0)
    },
    /// @dev Sorts the leaves to ensure the logic matches Alexandria's implementation.
    /// @dev Located here: https://github.com/keep-starknet-strange/alexandria/blob/main/src/merkle_tree/README.md
    sort: true,
  });
};

/**
 * Get a generation's proof.
 * @param tree The Merkle tree.
 * @param generation The generation to get the proof for.
 * @returns The proof as an array of strings representing felt252s.
 */
const getProof = (tree: MerkleTree, generation: string): string[] =>
  tree.getHexProof(getHashedLeaf(generation));

/**
 * Get proofs for a list of generations.
 * @param tree The Merkle tree.
 * @param generations The generations to get the proofs for.
 * @returns A list of proofs, each proof is an array of strings representing felt252s.
 */
const getProofs = (tree: MerkleTree, generations: string[]): string[][] =>
  generations.map((generation) => getProof(tree, generation));

/**
 * Demonstrate helper functions using mock whitelist data.
 */
const data: DataStructure = rawData;
const tree = createTree(data);
const generations = Object.keys(data);
const proofs = getProofs(tree, generations);

const output: string = `
--- Root: ${tree.getHexRoot()}\n
--- Tree:\n\n${tree.toString()}\n
--- Leaves:\n\n${tree
  .getHexLeaves()
  .map((leaf) => `< ${leaf} >`)
  .join("\n")}\n
--- Proofs for generations:\n\n${proofs
  .map((proof, i) => `<${i + 1}>\n\n[${proof.join(", ")}]\n`)
  .join("\n")}
  `;

console.log(output);