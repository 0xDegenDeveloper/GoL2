const { merkle, num } = require("starknet");
const { MerkleTree } = require("merkletreejs");
const {
  poseidonHashMany,
  poseidonHashFunc,
  poseidonHash,
  poseidonHashSingle,
  poseidonBasic,
  poseidonCreate,
  poseidonSmall,
  Poseidon,
  _poseidonMDS,
  // buildPoseidon,
} = require("@scure/starknet");
const whitelist = require("./sample.json");
const { buildPoseidon, buildPoseidonOpt } = require("circomlibjs");

/// still a work in progress

/**
 * Creates a hashed leaf from the given data.
 * @param {*} generation The generation of the game.
 * @param {*} user_id The user that evolved to this generation.
 * @param {*} game_state The state of this generation (at the time of creation, ignoring cells brought to life).
 * @param {*} timestamp The timestamp when this generation was evolved.
 * @returns {string} The hashed leaf.
 */
const createLeafHash = (generation, user_id, game_state, timestamp) => {
  return poseidonHashMany([
    num.toBigInt(generation),
    num.toBigInt(user_id),
    num.toBigInt(game_state),
    num.toBigInt(timestamp),
  ]);
};

/**
 * Fetches the hashed leaf for a given generation.
 * @param {*} generation The generation to fetch the hashed leaf for.
 * @returns {string} The hashed leaf.
 */
const getHashedLeaf = (generation) => {
  let snapshot = whitelist[generation];
  return createLeafHash(
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
const createTree = async () => {
  const leaves = Object.entries(whitelist).map(([key, value]) => {
    let hashed_leaf = getHashedLeaf(key);

    // return num.toBigInt(hashed_leaf);
    return hashed_leaf;
  });
  const poseidon = await buildPoseidon();
  const poseidonHash = (inputs) => {
    const hash = poseidon(inputs.map(MerkleTree.bigNumberify));
    const bn = MerkleTree.bigNumberify(poseidon.F.toString(hash));
    return MerkleTree.bufferify(bn);
  };

  console.log("leaves", leaves);

  console.log("p hash of [1,2,3]:", poseidonHash([1, 2, 3, 4]).toString("hex"));
  /// bug is here:
  return new MerkleTree(leaves, poseidonHashMany);
};

const t = createTree();

const fetchProof = (generation) => {
  return t.getProof(getHashedLeaf(generation));
};

// let p1 = fetchProof(1).toString();
// let p2 = fetchProof(2).toString();
// let p3 = fetchProof(3).toString();
// let p4 = fetchProof(4).toString();
// let p5 = fetchProof(5).toString();

// console.log(`
// Root: ${t.root}

// Leaves:

// ${t.leaves.join("\n")}

// Proofs:

// generation 1: <${p1}>

// generation 2: <${p2}>

// generation 3: <${p3}>

// generation 4: <${p4}>

// generation 5: <${p5}>
// `);
