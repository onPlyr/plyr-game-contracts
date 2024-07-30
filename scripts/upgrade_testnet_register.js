// scripts/deploy.js

const PROXY_ADMIN = '0x3Ec45b6315B95ca0AC56c94d43fAf84B4b484761';
const PROXY_ADDRESS = '0xC650e83b1cC9A1438fe2b1E9b4556B6fAa6B6Fb4';


async function main() {
  const [deployer] = await ethers.getSigners();

  const LogicContractName = 'Register';

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
