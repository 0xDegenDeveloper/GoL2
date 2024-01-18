import {
  createTree,
  getProofs,
  makeKeys,
  DataStructure,
  Snapshot,
} from "../helpers";
import * as fs from "fs";
import * as rawData from "../whitelist-prod.json";
// import * as rawData from "../mock.json";
const data: DataStructure = rawData;
console.log("data parsed!");

export const doScript = (start: number, end: number) => {
  const tree = createTree(data);
  console.log("tree created!");
  const generations = makeKeys(start, end);
  console.log("generations gathered!");
  const proofs = getProofs(tree, generations, data);
  let output: any = {};

  proofs.map((proof, i) => {
    output[i + start] = proof;
  });

  const outputFile = `proofs/${start}_${end}.json`;

  fs.writeFileSync(outputFile, JSON.stringify(output, null, 2));

  console.log(`${outputFile} created!`);
};
