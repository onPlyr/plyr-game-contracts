// scripts/deploy.js

const OWNER_ADDRESS = '0x800B3fc43E42255efc2B38279608b1a142372b0a';
const OPERATOR_ADDRESS = '0x61f295080526bD9967E0e3423d1fB7e149465973';

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  let register;
  let router;

  {
    const LogicContractName = 'Register';

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
    register = executor.target;
  
    console.log("Contract deployed successfully!");
  }

  {
    const LogicContractName = 'Router';

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
    router = executor.target;
  
    console.log("Contract deployed successfully!");
  }

  const Register = await ethers.getContractFactory('Register');
  const registerInstance = Register.attach(register);
  await registerInstance.initialize(OWNER_ADDRESS, router);

  console.log("Register initialized successfully!");

  const Router = await ethers.getContractFactory('Router');
  const routerInstance = Router.attach(router);
  await routerInstance.initialize(OWNER_ADDRESS, OPERATOR_ADDRESS, register);

  console.log("Router initialized successfully!");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
