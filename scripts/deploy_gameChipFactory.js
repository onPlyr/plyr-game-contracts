// scripts/deploy.js

const OWNER_ADDRESS = '0xb0425C2D2C31A0cf492D92aFB64577671D50E3b5';
const ROUTER_ADDRESS = '0xaABae47f41fee8f877c7F2641A306A01F7d8A2FA';

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const LogicContractName = 'GameChipFactory';

  // Deploy logic contract
  const Logic = await ethers.getContractFactory(LogicContractName);

  const logic = await Logic.deploy();
  await logic.waitForDeployment();

  // Deploy proxy contract
  const Proxy = await ethers.getContractFactory("PlyrProxy");
  const proxy = await Proxy.deploy(
    logic.target,
    OWNER_ADDRESS,
    '0x'
  );
  await proxy.waitForDeployment();

  // Get proxyAdmin address from the deployment transaction
  const receipt = await proxy.deploymentTransaction().wait();
  const logs = receipt.logs;
  const proxyAdminLog = logs.find((log) => proxy.interface.parseLog(log)?.name === 'AdminChanged');
  const proxyAdminAddress = proxyAdminLog.args[1];
  console.log("ProxyAdmin address:", proxyAdminAddress);

  const GameChip = await ethers.getContractFactory('GameChip');
  const gameChip = await GameChip.deploy();
  await gameChip.waitForDeployment();

  console.log("GameChip address:", gameChip.target);

  const executor = Logic.attach(proxy.target);
  console.log(LogicContractName, "address:", executor.target);

  await executor.initialize(gameChip.target, OWNER_ADDRESS, ROUTER_ADDRESS);

  console.log("Contract deployed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
