const { merkle } = require("starknet");
const { pedersen } = require("@scure/starknet");
const whitelist = require("./sample.json");

/**
 * Creates a hashed leaf from the given data.
 * @param {*} generation The generation of the game.
 * @param {*} user_id The user that evolved to this generation.
 * @param {*} game_state The state of this generation (at the time of creation, ignoring cells brought to life).
 * @param {*} timestamp The timestamp when this generation was evolved.
 * @returns {string} The hashed leaf.
 */
const hashLeaf = (generation, user_id, game_state, timestamp) => {
  return pedersen(
    pedersen(pedersen(pedersen(0, generation), user_id), game_state),
    timestamp
  );
};

/**
 * Fetches the hashed leaf for a given generation.
 * @param {*} generation The generation to fetch the hashed leaf for.
 * @returns {string} The hashed leaf.
 */
const getHashedLeafFromGeneration = (generation) => {
  let snapshot = whitelist[generation];
  return hashLeaf(
    generation,
    snapshot.user_id,
    snapshot.game_state,
    snapshot.timestamp
  );
};

/**
 * Creates a Merkle tree from the whitelist data.
 * @returns {merkle.MerkleTree} The Merkle tree.
 */
const createTree = () => {
  /// Create array of leaves
  const leaves = Object.entries(whitelist).map(([key, value]) => {
    /// Get the hashed leaf for each generation in whitelist
    const leaf = getHashedLeafFromGeneration(key);
    return leaf;
  });
  /// Create Merkle tree from leaves
  return new merkle.MerkleTree(leaves);
};

const t = createTree();

const fetchProof = (generation) => {
  return t.getProof(getHashedLeafFromGeneration(generation));
};

let p1 = fetchProof(1).toString();
let p2 = fetchProof(2).toString();
let p3 = fetchProof(3).toString();
let p4 = fetchProof(4).toString();
let p5 = fetchProof(5).toString();

console.log(`
Root: ${t.root}

Proofs:

generation 1: <${p1}>

generation 2: <${p2}>

generation 3: <${p3}>

generation 4: <${p4}>

generation 5: <${p5}>
`);
