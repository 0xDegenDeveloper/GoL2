const { Account, json, RpcProvider, Contract } = require("starknet");
const { config } = require("dotenv");
const process = require("process");
const { readFileSync } = require("fs");
const env = config().parsed;

const environment = env.ENVIRONMENT;
const nodeUrl =
  environment == "MAINNET"
    ? env.MAINNET_RPC_URL
    : environment == "GOERLI"
    ? env.GOERLI_RPC_URL
    : env.KATANA_RPC_URL;

const provider = new RpcProvider({ nodeUrl });
const account = new Account(provider, env.WALLET_ADDRESS, env.PRIVATE_KEY);

const ClassHashes = {
  /// For katana testing
  proxy: "0x04572af1cd59b8b91055ebb78df8f1d11c59f5270018b291366ba4585d4cdff0",
  oldGol: "0x043e0239c1a689a637f4fc2f0feb5f231542073e139844bf0b12ade15ca887e0",
  /// Class hash of new GoL2 contract
  newGol: "0x070620c557e6534b9acf57c7c6f4f9fac254c4d0b3fd448e3f151e510d0ba49b",
  /// Class hash of GoL2NFT contract
  nft: "0xc9fb934b3856fa4a9ac18495ea3c7652a64cf8287a219f96ff700a9c9dfb81",
};

const addresses = {
  /// Goerli proxy GoL2 address (manually deployed)
  goerliProxy:
    "0x07e34f4d645cf8b4d8d9bbe9539e94760b4e47193ef935774f8d54c7a4e2c89d",
  /// Mainnet GoL2 address
  mainnetProxy:
    "0x06a05844a03bb9e744479e3298f54705a35966ab04140d3d8dd797c1f6dc49d0",
};

const AbiPaths = {
  /// Old GoL2 contract ABI
  oldGol: json.parse(
    readFileSync("./migration/ABIs/OldGoL2.json").toString("ascii")
  ),
  /// New GoL2 compiled contract
  newGol: json.parse(
    readFileSync("./target/dev/gol2_GoL2.contract_class.json").toString("ascii")
  ),
  /// GoL2NFT compiled contract
  nft: json.parse(
    readFileSync("./target/dev/gol2_GoL2NFT.contract_class.json").toString(
      "ascii"
    )
  ),
};

/**
 * Deploy a mock proxy instance for testing.
 * @returns The address of the deployed mock proxy.
 */
const mockDeploy = async () => {
  console.log("\nDeploying mock proxy...\n");
  const deployResult = await account.deploy({
    classHash: ClassHashes.proxy,
    constructorCalldata: [ClassHashes.oldGol],
  });
  await provider.waitForTransaction(deployResult.transaction_hash);
  /**
   * @dev Initialize ERC20 meta, Proxy admin, and evolve the game 3 times to test state.
   */
  console.log(`Initializing mock proxy...\n`);
  const mockProxy = new Contract(
    AbiPaths.oldGol,
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
  console.log(`Mock proxy deployed!`);
  return deployResult.contract_address[0];
};

/**
 * Perform the 2-step migration process.
 * @dev Step 1 is upgrading the implementation hash of the proxy.
 * @dev Step 2 is migrating the proxy to no longer be a proxy.
 * @param {String} environment - The environment to run this migration in.
 * @note For KATANA | GOERLI, we need to pass a mock proxy instance. This
 * is because we cannot spoof the caller, requiring a fresh instance with
 * a new admin.
 * @note For MAINNET, we use the live contract instance.
 */
const migrate = async (environment = "KATANA", golInstanceAddress = null) => {
  /// Get GoL2 proxy address
  const golAddress =
    environment == "MAINNET" ? addresses["mainnetProxy"] : golInstanceAddress;

  if (golAddress == null) {
    throw new Error("No GoL2 address provided!");
  }

  /**
   * @dev GoL2 is already declared on Goerli and Katana, so we only need to
   * declare the new GoL2 on Mainnet.
   */
  if (environment == "MAINNET") {
    console.log("\nDeclaring new GoL2...\n");
    const response = await account.declare({
      contract: AbiPaths.newGol,
      classHash: ClassHashes.newGol,
      compiledClassHash: ClassHashes.newGol,
    });
    await provider.waitForTransaction(response.transaction_hash);
    console.log(`GoL2 declared!`);
  }

  console.log("\nPerforming migration...\n");
  const newGol = new Contract(AbiPaths.newGol.abi, golAddress, account);
  const multicall = [
    newGol.populate("upgrade", [ClassHashes.newGol]),
    newGol.populate("migrate", [ClassHashes.newGol]),
  ];
  const migrateResult = await account.execute(multicall);
  await provider.waitForTransaction(migrateResult.transaction_hash);
  return golAddress;
};

if (process.argv[2] == "MOCK") {
  mockDeploy()
    .then((address) => {
      console.log(
        `\nMock deployed at ${address}\n\nView proxy instance here: https://goerli.voyager.online/contract/${address}\n`
      );
      process.exit(0);
    })
    .catch((error) => {
      console.log(`\nFailed to deploy mock! Reason: ${error}\n`);
    });
}

if (process.argv[2] == "MIGRATE") {
  const golAddress = process.argv[3];
  migrate(environment, golAddress)
    .then((address) => {
      console.log(
        `Migrated successfully!\n\nView here: https://goerli.voyager.online/contract/${address}\n`
      );
      process.exit(0);
    })
    .catch((error) => {
      console.log(`Failed to migrate! Reason: ${error}\n`);
    });
}
