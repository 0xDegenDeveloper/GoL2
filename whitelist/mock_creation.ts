import { config } from "dotenv";
import { createTree, getProofs, DataStructure } from "./helpers";
import { poseidonHashMany } from "@scure/starknet";
import { num } from "starknet";

const env: any = config().parsed;

/// Mock whitelist using your address for each of the pre-migration mock generations.
const mock_whitelist: DataStructure = {
  2: {
    user_id: env.WALLET_ADDRESS,
    game_state: "356828257301254829749648773481885105184047104",
    timestamp: 2222,
  },
  3: {
    user_id: env.WALLET_ADDRESS,
    game_state: "535243066262194174258493647288748949532311552",
    timestamp: 3333,
  },
  4: {
    user_id: env.WALLET_ADDRESS,
    game_state: "535242385707850630526337402828901813818753024",
    timestamp: 4444,
  },
};

async function main() {
  const nftAddress = process.argv[2];
  const tree = createTree(mock_whitelist);
  const proofs = getProofs(tree, ["2", "3", "4"], mock_whitelist);
  const root_hash = tree.getHexRoot();

  console.log(
    `\nRoot hash: ${root_hash}\n\nProofs:\n${proofs
      .map((proof, i) => `\n${i + 2} -> [${proof.toString()}]\n`)
      .join(
        ""
      )}\n-Run: "npm run mint_helper ${nftAddress} ${root_hash}" to set the root hash and approve the GoL2NFT contract to spend your tokens.\n`
  );
}

main();
