// scripts/deploy.js

const PROXY_ADMIN = '0x87bF47F780b78378DC986e2181a7A0553bdfBbaD';
const PROXY_ADDRESS = '0xB8Ba18c4D561fC187764c11d36ef9De09b86e5C6';


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
