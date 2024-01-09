const { merkle, num } = require("starknet");
const { MerkleTree } = require("merkletreejs");
const { poseidonHashMany } = require("@scure/starknet");
const {
  bytesToNumberBE,
  numberToBytesBE,
} = require("@noble/curves/abstract/utils");
const data = require("./fork_whitelist.json");

/**
 * Create a leaf's hash from the given data.
 * @param {*} generation The generation of the game.
 * @param {*} user_id The user that evolved this generation.
 * @param {*} game_state The state of this generation (at the time of creation, ignoring cells brought to life).
 * @param {*} timestamp The timestamp when this generation was evolved.
 * @returns {string} The hex-string ("0xabcd...") leaf hash.
 */
const createLeafHash = (generation, user_id, game_state, timestamp) => {
  return num.toHex(
    poseidonHashMany([
      num.toBigInt(generation),
      num.toBigInt(user_id),
      num.toBigInt(game_state),
      num.toBigInt(timestamp),
    ])
  );
};

/**
 * Gets the leaf hash for a given generation as a buffer.
 * @param {*} generation The generation to fetch the leaf hash for.
 * @returns {string} The hex string (0xabcd...) leaf hash.
 */
const getHashedLeaf = (generation) => {
  let snapshot = data[generation.toString()];
  return numberToBytesBE(
    num.toBigInt(
      createLeafHash(
        generation.toString(),
        snapshot.user_id,
        snapshot.game_state,
        snapshot.timestamp
      )
    ),
    32
  );
};

/**
 * Creates a Merkle tree from the whitelist data.
 * @returns {merkle.MerkleTree} The Merkle tree.
 */
const createTree = () => {
  let leaves = Object.entries(data).map(([key, value]) => getHashedLeaf(key));

  /**
   * Poseidon hash a pair of elements.
   * @param {*} input Byte buffer of both values to hash
   * @returns
   */
  const specialHash = (input) => {
    return numberToBytesBE(
      /// @dev Poseidon hashes a byte buffer.
      poseidonHashMany(
        /// @dev Convert the byte buffer to a big int.
        input.map((x) => bytesToNumberBE(x))
      ),
      32
    );
  };

  return new MerkleTree(leaves, specialHash, {
    concatenator: (buffers) => {
      return buffers;
    },
    fillDefaultHash: () => {
      return num.toBigInt(0x0);
    },
    sort: true,
  });
};

const getProof = (tree, generation) => {
  return tree
    .getHexProof(getHashedLeaf(generation, data))
    .map((p) => (p == "0x" ? "0x0" : p));
};

const getProofs = (tree, generations) => {
  return generations.map((generation) => {
    return getProof(tree, generation);
  });
};

/**
 * Run the sample whitelist script.
 */
const tree = createTree();
const proofs = getProofs(tree, [1, 2, 3, 4, 5]);

console.log(`\nRoot: ${tree.getHexRoot()}\n
Tree:\n${tree.toString("hex")}\n\n
Leaves:\n\n${tree.leaves
  .map((leaf) => `<${leaf.toString("hex")}>`)
  .join("\n")}\n
Proofs:\n\n${proofs
  .map((proof, i) => `generation ${i + 1}: <${proof}>`)
  .join("\n")}`);
