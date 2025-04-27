// scripts/deploy.js

async function main() {
  const [deployer] = await ethers.getSigners();


  const GameNft = await ethers.getContractFactory('GameNft');
  const gameNft = await GameNft.deploy();
  await gameNft.waitForDeployment();

  console.log("GameNft address:", gameNft.target);

  console.log("Contract deployed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
