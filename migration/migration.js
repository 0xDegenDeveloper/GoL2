const { Account, json, RpcProvider, Contract } = require("starknet");
const { config } = require("dotenv");
const { readFileSync } = require("fs");
const env = config().parsed;

const environment = env.ENVIRONMENT;
const nodeUrl =
  environment == "KATANA"
    ? env.KATANA_RPC_URL
    : environment == "GOERLI"
    ? env.GOERLI_RPC_URL
    : env.MAINNET_RPC_URL;

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
    // readFileSync("./migration/ABIs/NewGoL2.json").toString("ascii")
  ),
  /// GoL2NFT compiled contract
  nft: json.parse(
    readFileSync("./target/dev/gol2_GoL2NFT.contract_class.json").toString(
      "ascii"
    )
  ),
};

/**
 * Deploy a mock proxy instance for testing with Katana.
 * @returns The address of the deployed mock proxy.
 */
const mockDeploy = async () => {
  /// Deploy the mock proxy
  console.log("\nDeploying mock proxy...\n");
  const deployResult = await account.deploy({
    classHash: ClassHashes.proxy,
    constructorCalldata: [ClassHashes.oldGol],
  });
  await provider.waitForTransaction(deployResult.transaction_hash);

  /// Initialize (ERC20/Admin) the mock proxy
  console.log(`Initializing mock proxy...\n`);
  const initResult = await new Contract(
    AbiPaths.oldGol,
    deployResult.contract_address[0],
    account
  ).invoke("initializer", [
    account.address,
    "0x47616d65206f66204c69666520546f6b656e",
    "0x474f4c",
    "0x0",
  ]);
  await provider.waitForTransaction(initResult.transaction_hash);

  console.log(`Mock proxy deployed!`);
  return deployResult.contract_address[0];
};

/**
 * Perform the 2-step migration process.
 * @dev Step 1 is upgrading the implementation hash of the proxy.
 * @dev Step 2 is migrating the proxy to no longer be a proxy.
 * @param {string} environment The environment to run this migration in.
 * @note For KATANA, we deploy a mock proxy instance because we cannot
 * cheat the caller, requiring a new instance with a new proxy admin.
 * @note For GOERLI, we manually deploy a proxy instance because the live
 * goerli instance is not a proxy.
 * @note For MAINNET, we use the live contract instance.
 */
const migrate = async (environment = "KATANA") => {
  /// Get GoL2 proxy address
  const golAddress =
    environment == "KATANA"
      ? await mockDeploy()
      : environment == "GOERLI"
      ? addresses["goerliProxy"]
      : addresses["mainnetProxy"];

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

  /**
   * @dev Step 1: Upgrade the proxy implementation hash.
   */
  const newGol = new Contract(AbiPaths.newGol.abi, golAddress, account);
  console.log("\nUpgrading proxy implementation hash...\n");
  const upgradeResult = await newGol.invoke("upgrade", [ClassHashes.newGol]);
  await provider.waitForTransaction(upgradeResult.transaction_hash);
  console.log(`Proxy implementation hash upgraded!\n`);

  /**
   * @dev Step 2: Migrate from proxy implementation.
   */
  console.log("Migrating from proxy implementation...\n");
  const migrateResult = await newGol.invoke("migrate", [ClassHashes.newGol]);
  await provider.waitForTransaction(migrateResult.transaction_hash);
};

migrate("KATANA")
  .then(() => {
    console.log("Migrated successfully!\n");
    process.exit(0);
  })
  .catch((error) => {
    console.log(`Failed to migrate ! reason: ${error}\n`);
  });
