// scripts/deploy.js

const PROXY_ADMIN = '0x021922c7c661E6DffdB25550c6e4d0a7b6490CD7';
const PROXY_ADDRESS = '0x1c20E9ffD6Fac7a4842286683A8FfBE5B882990e';


async function main() {
  const [deployer] = await ethers.getSigners();

  const LogicContractName = 'GameRuleV1';

  const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin");
  const proxyAdmin = await ProxyAdmin.attach(PROXY_ADMIN);

  console.log("ProxyAdmin address:", proxyAdmin.target);

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy logic contract
  const Logic = await ethers.getContractFactory(LogicContractName);

  const logic = await Logic.deploy();
  await logic.waitForDeployment();

  console.log(LogicContractName, "deployed to:", logic.target);

  await proxyAdmin.upgradeAndCall(PROXY_ADDRESS, logic.target, '0x');

  console.log("Contract upgrade successfully!");
}

// 处理可能的错误
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
