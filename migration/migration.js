const { Account, json, RpcProvider, Contract } = require("starknet");
const { config } = require("dotenv");
const { readFileSync } = require("fs");
const process = require("process");

/// Constants
const ADDRESSES = {
  gol: "0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0", // mainnet (live)
  eth: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7", // goerli and mainnet
  usdc: "0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8", // mainnet
};

const ABIs = {
  /// Cairo 0 GoL2
  oldGol: json.parse(
    readFileSync("./migration/ABIs/OldGoL2.json").toString("ascii")
  ),
  /// Cairo 1 GoL2
  newGol: json.parse(
    readFileSync("./target/dev/gol2_GoL2.contract_class.json").toString("ascii")
  ),
  /// GoL2NFT
  nft: json.parse(
    readFileSync("./target/dev/gol2_GoL2NFT.contract_class.json").toString(
      "ascii"
    )
  ),
};

const CASM = {
  /// Cairo0 GoL2
  newGol: json.parse(
    readFileSync(
      "./target/dev/gol2_GoL2.compiled_contract_class.json"
    ).toString("ascii")
  ),
  /// GoL2NFT
  nft: json.parse(
    readFileSync(
      "./target/dev/gol2_GoL2NFT.compiled_contract_class.json"
    ).toString("ascii")
  ),
};

/// Environment setup
const env = config().parsed;

const ENVIRONMENT = env.ENVIRONMENT;

const NODE_URL =
  ENVIRONMENT == "MAINNET"
    ? env.MAINNET_RPC_URL
    : ENVIRONMENT == "GOERLI"
    ? env.GOERLI_RPC_URL
    : env.KATANA_RPC_URL;

/// Wallet setup
const WALLET_ADDRESS =
  ENVIRONMENT == "KATANA" ? env.KATANA_WALLET_ADDRESS : env.WALLET_ADDRESS;
const PRIVATE_KEY =
  ENVIRONMENT == "KATANA" ? env.KATANA_PRIVATE_KEY : env.PRIVATE_KEY;

/// @dev Initialize account and provider
const provider = new RpcProvider({ nodeUrl: NODE_URL });
const account = new Account(provider, WALLET_ADDRESS, PRIVATE_KEY);

/**
 * Deploy a mock proxy instance for testing.
 * @dev This is only used for Katana or Goerli.
 * @dev For ENVIRONMENT: KATANA | GOERLI, we need to use a mock proxy instance
 * because we cannot spoof the caller, requiring a fresh instance with a custom admin.
 * @dev If Katana, make sure to be using a goerli fork because the
 * proxy/old gol class_hashes are not declared on an empty Katana.
 * @returns The address of the deployed mock proxy.
 */
const mockDeploy = async () => {
  /// Value from mainnet gol instance here pre-migration:
  /// https://voyager.online/contract/0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0
  const cario0ProxyHash =
    "0x04572af1cd59b8b91055ebb78df8f1d11c59f5270018b291366ba4585d4cdff0";
  /// Value from test gol instance here:
  /// https://goerli.voyager.online/contract/0x06dc4bd1212e67fd05b456a34b24a060c45aad08ab95843c42af31f86c7bd093
  const cairo0GoL2Hash =
    "0x043e0239c1a689a637f4fc2f0feb5f231542073e139844bf0b12ade15ca887e0";

  /// @dev Deploy mock proxy with old GoL2 implementation
  console.log("Deploying mock proxy...\n");
  const deployResult = await account.deploy({
    classHash: cario0ProxyHash,
    constructorCalldata: [cairo0GoL2Hash],
  });
  await provider.waitForTransaction(deployResult.transaction_hash);
  console.log(`Mock deployed to: ${deployResult.contract_address[0]}\n`);

  /// @dev Initialize ERC20 meta, Proxy admin, and evolve the game 3 times
  /// using a multicall (for testing)
  console.log(`Initializing mock proxy...\n`);
  const mockProxy = new Contract(
    ABIs.oldGol,
    deployResult.contract_address[0], // address just deployed
    account
  );

  const multicall = [
    mockProxy.populate("initializer", [
      account.address, /// set account as admin
      "0x47616d65206f66204c69666520546f6b656e", // "Game of Life Token"
      "0x474f4c", // "GOL"
      "0x0", // decimals
    ]),
    mockProxy.populate("evolve", ["0x7300100008000000000000000000000000"]),
    mockProxy.populate("evolve", ["0x7300100008000000000000000000000000"]),
    mockProxy.populate("evolve", ["0x7300100008000000000000000000000000"]),
  ];
  const simulateResult = await account.execute(multicall);
  await provider.waitForTransaction(simulateResult.transaction_hash);
  console.log(`Mock proxy initialized!`);

  return deployResult.contract_address[0];
};

/**
 * Perform the 2-step migration process.
 * @dev Step 1 is upgrading the implementation hash of the proxy.
 * @dev Step 2 is migrating the proxy to no longer be a proxy.
 * @param {String} golInstanceAddress - The address of the Cairo 0 GoL2 proxy instance to migrate.
 * @note For ENVIRONMENT: KATANA | GOERLI, we need to use a mock proxy instance
 * because we cannot spoof the caller, requiring a fresh instance with a custom admin.
 * @note For MAINNET, we use the live contract instance.
 * @returns The address of the GoL2 contract.
 */
const migrate = async (golInstanceAddress = null) => {
  /// Gol address to migrate
  const golAddress =
    ENVIRONMENT == "MAINNET" ? ADDRESSES.gol : golInstanceAddress;
  if (golAddress == null) throw new Error("No GoL2 address provided!");

  /// Declare new GoL2 contract class
  console.log("Declaring new GoL2...\n");
  const response = await account.declareIfNot({
    contract: ABIs.newGol,
    casm: CASM.newGol,
  });
  if (response.transaction_hash)
    await provider.waitForTransaction(response.transaction_hash);
  console.log(`GoL2 declared!`);

  /// Do the 2-step migration
  console.log("\nPerforming migration...");
  const newGol = new Contract(ABIs.newGol.abi, golAddress, account);
  const multicall = [
    newGol.populate("upgrade", [response.class_hash]),
    newGol.populate("migrate", [response.class_hash]),
  ];
  const migrateResult = await account.execute(multicall);
  await provider.waitForTransaction(migrateResult.transaction_hash);
  console.log(`\nMigration complete!`);

  return golAddress;
};

/**
 * Deploy the GoL2NFT contract.
 * @param {String} golAddress - The address of the GoL2 contract to link to.
 * @returns The address of the GoL2NFT contract.
 */
const deployNft = async (golAddress = null) => {
  if (golAddress == null) {
    throw new Error("No GoL2 address provided!");
  }

  /// Declare and deploy GoL2NFT
  console.log("Deploying new GoL2NFT...\n");
  const deployResponse = await account.declareAndDeploy({
    contract: ABIs.nft,
    casm: CASM.nft,
    constructorCalldata: [
      account.address,
      "0x47616D65206F66204C696665204E4654", // "Game of Life NFT"
      "0x476F4C324E4654", // "GoL2NFT"
      golAddress,
      ENVIRONMENT == "MAINNET" ? ADDRESSES.usdc : ADDRESSES.eth, // cost is 1 USDC on mainnet, 0.000000001 ETH on goerli
      ENVIRONMENT == "MAINNET" ? 1 : 1000000000, // 1 USDC on mainnet, 1 gwei (10^-9 ether) on goerli
      0,
      "0x0595d834a768d680188fce9858f850eeaf8926f86b54238e30fecc53f6317962", // root hash, todo: update when wl complete
    ],
  });
  await provider.waitForTransaction(deployResponse.deploy.transaction_hash);
  console.log(
    `GoL2NFT deployed to: ${deployResponse.deploy.contract_address}\n`
  );

  /// Set GoL2NFT as the snapshotter in GoL2
  console.log("Setting snapshotter...\n");
  const invoke = await new Contract(
    ABIs.newGol.abi,
    golAddress,
    account
  ).invoke("set_snapshotter", [deployResponse.deploy.contract_address]);
  await provider.waitForTransaction(invoke.transaction_hash);
  console.log(`Snapshotter set!`);

  return deployResponse.deploy.contract_address;
};

async function main() {
  try {
    const command = process.argv[2];
    switch (command) {
      case "MOCK":
        console.log(createOutputString(await mockDeploy(), "migrate"));
        break;
      case "MIGRATE":
        console.log(createOutputString(await migrate(process.argv[3]), "nft"));
        break;
      case "NFT":
        console.log(createOutputString(await deployNft(process.argv[3]), null));
        break;
      default:
        console.log("Invalid command. Use MOCK, MIGRATE, or NFT.");
    }
  } catch (error) {
    console.error(`Operation failed! Reason: ${error.message}`);
  } finally {
    process.exit(0);
  }
}

/**
 * Create output string to guide user through the migration process.
 * @param {String} address - The address to provide a blockscanner link to.
 * @note There is no blockscanner link when using Katana. Can just view in shell.
 * @param {String} nextCommand - The next command to run.
 * @note If nextCommand is null, then we are done.
 * @note If nextCommand not, then we need to instruct the
 * user to run the next command.
 * @returns The output string.
 */
function createOutputString(address, nextCommand) {
  const baseUrl = ENVIRONMENT === "MAINNET" ? "" : "goerli.";
  const url =
    ENVIRONMENT === "KATANA"
      ? ""
      : `\nView here: https://${baseUrl}voyager.online/contract/${address}\n`;
  const nextStep = nextCommand
    ? `\n- Run: "npm run ${nextCommand} ${address}" to ${
        nextCommand === `migrate`
          ? `migrate the gol contract`
          : `deploy the nft contract`
      }.\n`
    : "\nYay done!\n";

  return `${url}${nextStep}`;
}

main();
