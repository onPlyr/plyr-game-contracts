// scripts/deploy.js

const PROXY_ADMIN = '0x03B586981c1dBb719235D57051e9Dd44c71bd1b6';
const PROXY_ADDRESS = '0xaABae47f41fee8f877c7F2641A306A01F7d8A2FA';


async function main() {
  const [deployer] = await ethers.getSigners();

  const LogicContractName = 'Router';

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
