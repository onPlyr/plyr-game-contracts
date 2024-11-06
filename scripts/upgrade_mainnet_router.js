// scripts/deploy.js

const PROXY_ADMIN = '0x344494Be218d5DEE1e9764078a3abbA552fC0BCd';
const PROXY_ADDRESS = '0x0EF26D14851c84Dca15CB0265d9EA74f9cAEb828';


async function main() {
  const [deployer] = await ethers.getSigners();

  const LogicContractName = 'Router';

  // Deploy logic contract
  const Logic = await ethers.getContractFactory(LogicContractName);

  const logic = await Logic.deploy();
  await logic.waitForDeployment();

  console.log(LogicContractName, "deployed to:", logic.target);

  console.log("Manually upgrade the router contract on the mainnet!");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
