import { config } from "dotenv";
import { createTree, getProofs, DataStructure } from "./helpers";
import { poseidonHashMany } from "@scure/starknet";
import { num } from "starknet";

const env: any = config().parsed;

/// Mock whitelist using your address for each of the pre-migration mock generations.
const mock_whitelist: DataStructure = {
  2: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x100030006e0000000000000000000000000000",
    timestamp: 2222,
  },
  3: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x18004a00740008000000000000000000000000",
    timestamp: 3333,
  },
  4: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x18004800760050000000000000000000000000",
    timestamp: 4444,
  },
  5: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x18004c004400d8000000000000000000000000",
    timestamp: 5555,
  },
  6: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x1c004c00c400d8000000000000000000000000",
    timestamp: 6666,
  },
  7: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x04001e004c008401d8000000000000000000000000",
    timestamp: 7777,
  },
  8: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x0c0012004200a40398010000000000000000000000",
    timestamp: 8888,
  },
  9: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x0c0038004601060258070000000000000000000000",
    timestamp: 9999,
  },
  10: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x14000c00870112069c070000000000000000000000",
    timestamp: 10000,
  },
  11: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x0e003f00d7011106dc0f1000000000000000000000",
    timestamp: 11111,
  },
  12: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x02000000008081000100fc0bb808000000000000000000",
    timestamp: 22222,
  },
  13: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x018039000206080e200000000000000000",
    timestamp: 33333,
  },
  14: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x098011812605080e001000000000000000",
    timestamp: 44444,
  },
  15: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x01c0388145058c12001800000000000000",
    timestamp: 55555,
  },
  16: {
    user_id: env.WALLET_ADDRESS,
    game_state: "0x4008c076c10d048c13001800000000000000",
    timestamp: 66666,
  },
};

async function main() {
  const nftAddress = process.argv[2];
  const tree = createTree(mock_whitelist);
  const proofs = getProofs(
    tree,
    [
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      "10",
      "11",
      "12",
      "13",
      "14",
      "15",
      "16",
    ],
    mock_whitelist
  );
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
