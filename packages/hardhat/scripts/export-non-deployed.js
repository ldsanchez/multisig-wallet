const fs = require("fs");
const chalk = require("chalk");

const contractsDir = "./hardhat/artifacts/contracts";
const destination =
  "./react-app/src/contracts/hardhat_non_deployed_contracts.json";

const exportContracts = (_contractNames, _destination) => {
  try {
    const dirPath = _destination.split("/").slice(0, -1).join("/");
    const destinationFile = _destination.split("/").slice(-1);

    const exported = {};
    _contractNames.forEach((contractName) => {
      const file = fs.readFileSync(
        `${contractsDir}/${contractName}.sol/${contractName}.json`
      );
      exported[contractName] = JSON.parse(file.toString()).abi;
    });

    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
    const filePath = `${dirPath}/${destinationFile}`;
    fs.writeFileSync(filePath, JSON.stringify(exported, null, 2), {
      flag: "w",
    });

    return true;
  } catch (e) {
    console.log(
      "Failed to export non-deployed contracts " +
        chalk.red(_contractNames) +
        "to frontend."
    );
    console.log(e);
    return false;
  }
};

function main() {
  // add any of your factory-created contracts here
  const contracts = ["MultisigWallet"];
  const success = exportContracts(contracts, destination);
  if (success) {
    console.log(
      `✅  Exported abi(s) for non-deployed contract(s) ${contracts} to the frontend.`
    );
  }
}
try {
  main();
  process.exit(0);
} catch (error) {
  console.error(error);
  process.exit(1);
}
