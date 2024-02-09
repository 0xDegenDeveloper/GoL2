import * as fs from "fs";
import * as path from "path";

export type ProofList = {
  [generation: string]: string[];
};

// Dynamically import proofs
const proofRanges = [
  "2_25000",
  "25001_50000",
  "50001_75000",
  "75001_100000",
  "100001_125000",
  "125001_150000",
  "150001_175000",
  "175001_200000",
  "200001_225000",
  "225001_250000",
  "250001_275000",
  "275001_300000",
  "300001_325000",
  "325001_350000",
  "350001_375000",
  "375001_400000",
  "400001_425000",
  "425001_450000",
  "450001_475000",
  "475001_495621",
];
const parts: ProofList[] = proofRanges.map((range, index) => {
  const proof = require(`../proofs/${range}.json`);
  console.log(`${String.fromCharCode(97 + index)} parsed!`);
  return proof;
});

// Function to stream data to a file
function streamDataToFile(
  dataParts: ProofList[],
  outputFile: string,
  callback: () => void
) {
  const stream = fs.createWriteStream(outputFile, { flags: "w" });
  stream.write("{\n");

  let isFirstEntry = true;

  dataParts.forEach((part) => {
    Object.entries(part).forEach(([key, value]) => {
      if (!isFirstEntry) {
        stream.write(",\n");
      }
      isFirstEntry = false;
      stream.write(`  "${key}": ${JSON.stringify(value)}`);
    });
  });

  stream.write("\n}\n");
  stream.end();

  stream.on("finish", callback);
}

// Example usage
const outputFile = path.join(__dirname, "", "proofs.json");
streamDataToFile(parts, outputFile, () => {
  console.log(`${outputFile} has been created!`);
});
