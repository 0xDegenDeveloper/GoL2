import { num } from "starknet";
import { MerkleTree } from "merkletreejs";
import { poseidonHashMany } from "@scure/starknet";
import { bytesToNumberBE, numberToBytesBE } from "@noble/curves/abstract/utils";

export type Snapshot = {
  user_id: string;
  game_state: string;
  timestamp: number;
};

export type DataStructure = {
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
const getHashedLeaf = (generation: string, data: DataStructure): Buffer => {
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
export const createTree = (data: DataStructure): MerkleTree => {
  const leaves: Buffer[] = Object.keys(data).map((generation) =>
    getHashedLeaf(generation, data)
  );

  const specialHash = (input: Buffer[]): Buffer =>
    Buffer.from(
      numberToBytesBE(
        poseidonHashMany(input.map((x) => bytesToNumberBE(x))),
        32
      )
    );

  return new MerkleTree(leaves, specialHash, {
    concatenator: (buffers: Buffer[]): Buffer[] => buffers,
    fillDefaultHash: (): Buffer => Buffer.from([0x0]),
    sort: true,
  });
};

/**
 * Get a generation's proof.
 * @param tree The Merkle tree.
 * @param generation The generation to get the proof for.
 * @returns The proof as an array of strings representing felt252s.
 */
const getProof = (
  tree: MerkleTree,
  generation: string,
  data: DataStructure
): string[] => {
  const proof = tree.getHexProof(getHashedLeaf(generation, data));
  console.log("proof", generation, "fetched");
  return proof;
};

/**
 * Get proofs for a list of generations.
 * @param tree The Merkle tree.
 * @param generations The generations to get the proofs for.
 * @returns A list of proofs, each proof is an array of strings representing felt252s.
 */
export const getProofs = (
  tree: MerkleTree,
  generations: string[],
  data: DataStructure
): string[][] =>
  generations.map((generation) => getProof(tree, generation, data));

export const makeKeys = (start: number, end: number): string[] => {
  return Array.from({ length: end - start + 1 }, (_, index) =>
    (start + index).toString()
  );
};
