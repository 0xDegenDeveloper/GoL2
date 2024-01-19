import {
  createTree,
  getProofs,
  makeKeys,
  DataStructure,
  Snapshot,
} from "../helpers";
import * as fs from "fs";
import * as rawData from "../whitelist.json";
// import * as rawData from "../mock.json";

/// Load in whitelist.
const data: DataStructure = rawData;
console.log("data parsed!");

/// Script to generate proofs for generations [start, end] and write them to a file.
export const doScript = (start: number, end: number) => {
  const tree = createTree(data);
  console.log(`\nTree created!\n\nRoot hash:${tree.getHexRoot()}\n`);
  const generations = makeKeys(start, end);
  console.log("Generations gathered!\n");
  const proofs = getProofs(tree, generations, data);
  let output: any = {};

  proofs.map((proof, i) => {
    output[i + start] = proof;
  });

  const outputFile = `proofs/${start}_${end}.json`;

  fs.writeFileSync(outputFile, JSON.stringify(output, null, 2));

  console.log(`\n${outputFile} created!`);
};
