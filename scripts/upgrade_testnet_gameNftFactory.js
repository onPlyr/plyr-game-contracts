// scripts/deploy.js

const PROXY_ADMIN = '0x15904bD6F0d4964fB9e0587F37AC438ABEDd2Aa7';
const PROXY_ADDRESS = '0xf7f560b82414ca10Fabb00A32BCc39A3Cad74Fc7';


async function main() {
  const [deployer] = await ethers.getSigners();

  const LogicContractName = 'GameNftFactory';

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
