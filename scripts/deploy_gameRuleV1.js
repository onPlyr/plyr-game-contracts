// scripts/deploy.js

const OWNER_ADDRESS = '0xb0425C2D2C31A0cf492D92aFB64577671D50E3b5';
const OPERATOR_ADDRESS = '0x61f295080526bD9967E0e3423d1fB7e149465973';

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const LogicContractName = 'GameRuleV1';

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

  const executor = Logic.attach(proxy.target);
  console.log(LogicContractName, "address:", executor.target);

  console.log("Contract deployed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
