const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GameRuleV1", function () {
  let gameRuleV1;
  let owner;
  let operator;
  let user1;
  let user2;
  let router;
  let register;
  let mockERC20;

  beforeEach(async function () {
    [owner, operator, user1, user2] = await ethers.getSigners();

    // Deploy Register contract
    const Register = await ethers.getContractFactory("Register");
    register = await Register.deploy();

    // Deploy Router contract
    const Router = await ethers.getContractFactory("Router");
    router = await Router.deploy();
    await router.initialize(owner.address, operator.address, register.target);
    await register.initialize(owner.address, router.target);

    // Deploy GameRuleV1 contract
    const GameRuleV1 = await ethers.getContractFactory("GameRuleV1");
    gameRuleV1 = await GameRuleV1.deploy();
    await gameRuleV1.initialize(owner.address, router.target, user2.address, register.target);

    // Deploy MockERC20 for token tests
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockERC20 = await MockERC20.deploy("TestToken", "TT");

    // Set operator for GameRuleV1
    await gameRuleV1.configOperator(operator.address, true);

    // Configure GameRuleV1 in Router
    await router.connect(owner).configGameRule(gameRuleV1.target, true);

    // Set operator for Router
    // await router.connect(owner).configOperator(operator.address, true);
  });

  describe("Initialization", function () {
    it("Should set the correct owner", async function () {
      expect(await gameRuleV1.owner()).to.equal(owner.address);
    });

    it("Should set the correct router", async function () {
      expect(await gameRuleV1.router()).to.equal(router.target);
    });

    it("Should set the correct feeTo address", async function () {
      expect(await gameRuleV1.feeTo()).to.equal(user2.address);
    });

    it("Should set the correct register contract", async function () {
      expect(await gameRuleV1.registerSC()).to.equal(register.target);
    });

    it("Should set the default platform fee", async function () {
      expect(await gameRuleV1.platformFee()).to.equal(2);
    });
  });

  describe("Game Room Management", function () {
    it("Should create a game room", async function () {
      await expect(gameRuleV1.connect(operator).create("testGame", 3600))
        .to.emit(gameRuleV1, "GameRoomCreated")
        .withArgs("testGame", 1, await gameRuleV1.computeRoomAddress("testGame", 1));

      expect(await gameRuleV1.gameRoomCount("testGame")).to.equal(1);
    });

    it("Should join a game room", async function () {
      await gameRuleV1.connect(operator).create("testGame", 3600);
      await expect(gameRuleV1.connect(operator).join("testGame", 1, ["player1", "player2"]))
        .to.not.be.reverted;
    });

    it("Should leave a game room", async function () {
      await gameRuleV1.connect(operator).create("testGame", 3600);
      await gameRuleV1.connect(operator).join("testGame", 1, ["player1", "player2"]);
      await expect(gameRuleV1.connect(operator).leave("testGame", 1, ["player1"]))
        .to.not.be.reverted;
    });
  });

  describe("Payment and Earnings", function () {
    beforeEach(async function () {
      await gameRuleV1.connect(operator).create("testGame", 3600);
      await gameRuleV1.connect(operator).join("testGame", 1, ["player1"]);
      
      // Create a user in the Register contract
      await router.connect(operator).createUser(user1.address, "player1", 1);
    });

    it("Should process native token payment", async function () {
      const mirror = await register.getENSAddress("player1.plyr");
      await owner.sendTransaction({to: mirror, value: ethers.parseEther("1")});
      await gameRuleV1.connect(operator).join("testGame", 1, ["player1"]);
      await expect(gameRuleV1.connect(operator).pay("testGame", 1, "player1", ethers.ZeroAddress, 100))
        .to.not.be.reverted;
    });

    it("Should process ERC20 token payment", async function () {
      const mirror = await register.getENSAddress("player1.plyr");
      await mockERC20.transfer(mirror, 100);
      await expect(gameRuleV1.connect(operator).pay("testGame", 1, "player1", mockERC20.target, 100))
        .to.not.be.reverted;
    });

    it("Should process native token earnings", async function () {
      const mirror = await register.getENSAddress("player1.plyr");
      await owner.sendTransaction({to: mirror, value: ethers.parseEther("1")});
      await gameRuleV1.connect(operator).join("testGame", 1, ["player1"]);
      await gameRuleV1.connect(operator).pay("testGame", 1, "player1", ethers.ZeroAddress, 100);
      await expect(gameRuleV1.connect(operator).earn("testGame", 1, "player1", ethers.ZeroAddress, 100))
        .to.not.be.reverted;
    });

    it("Should process ERC20 token earnings", async function () {
      const mirror = await register.getENSAddress("player1.plyr");
      await mockERC20.transfer(mirror, 100);
      await gameRuleV1.connect(operator).pay("testGame", 1, "player1", mockERC20.target, 100);
      await expect(gameRuleV1.connect(operator).earn("testGame", 1, "player1", mockERC20.target, 100))
        .to.not.be.reverted;
    });
  });

  describe("Game Ending", function () {
    beforeEach(async function () {
      await gameRuleV1.connect(operator).create("testGame", 3600);
    });

    it("Should end a game", async function () {
      await expect(gameRuleV1.connect(operator).end("testGame", 1))
        .to.not.be.reverted;
    });

    it("Should close a game", async function () {
      // add time 3600 seconds
      await ethers.provider.send("evm_increaseTime", [3600*2]);
      await expect(gameRuleV1.connect(operator).close("testGame", 1, user1.address))
        .to.not.be.reverted;
    });
  });

  describe("Configuration", function () {
    it("Should configure an operator", async function () {
      await expect(gameRuleV1.connect(owner).configOperator(user1.address, true))
        .to.not.be.reverted;
      expect(await gameRuleV1.operators(user1.address)).to.be.true;
    });

    it("Should configure platform fee", async function () {
      await expect(gameRuleV1.connect(owner).configPlatformFee(3))
        .to.not.be.reverted;
      expect(await gameRuleV1.platformFee()).to.equal(3);
    });

    it("Should configure feeTo address", async function () {
      await expect(gameRuleV1.connect(owner).configFeeTo(user1.address))
        .to.not.be.reverted;
      expect(await gameRuleV1.feeTo()).to.equal(user1.address);
    });
  });

  describe("Access Control", function () {
    it("Should not allow non-operators to create a game room", async function () {
      await expect(gameRuleV1.connect(user1).create("testGame", 3600))
        .to.be.revertedWith("GameRuleV1: only operators");
    });

    it("Should not allow non-owners to configure operators", async function () {
      await expect(gameRuleV1.connect(user1).configOperator(user2.address, true))
        .to.be.revertedWithCustomError(gameRuleV1, "OwnableUnauthorizedAccount");
    });
  });

  describe("Utility Functions", function () {
    it("Should compute room address correctly", async function () {
      const computedAddress = await gameRuleV1.computeRoomAddress("testGame", 1);
      expect(computedAddress).to.be.properAddress;
    });
  });

  describe("Integration with Router", function () {
    it("Should allow GameRuleV1 to call Router functions", async function () {
      await router.connect(operator).createUser(user1.address, "player1", 1);
      const mirror = await register.getENSAddress("player1.plyr");
      await owner.sendTransaction({to: mirror, value: ethers.parseEther("1")});
      await gameRuleV1.connect(operator).create("testGame", 3600);
      await gameRuleV1.connect(operator).join("testGame", 1, ["player1"]);
      await gameRuleV1.connect(operator).pay("testGame", 1, "player1", ethers.ZeroAddress, 100);
      await expect(gameRuleV1.connect(operator).earn("testGame", 1, "player1", ethers.ZeroAddress, 100))
        .to.not.be.reverted;
    });

    it("Should not allow non-configured GameRuleV1 to call Router functions", async function () {
      const GameRuleV1 = await ethers.getContractFactory("GameRuleV1");
      const unauthorizedGameRule = await GameRuleV1.deploy();
      await unauthorizedGameRule.initialize(owner.address, router.target, user2.address, register.target);
      //config unauthorizedGameRule operator 
      await unauthorizedGameRule.configOperator(operator.address, true);
      await unauthorizedGameRule.connect(operator).create("testGame", 3600);
      await unauthorizedGameRule.connect(operator).join("testGame", 1, ["player1"]);

      await expect(unauthorizedGameRule.connect(operator).pay("testGame", 1, "player1", ethers.ZeroAddress, 100))
        .to.be.revertedWith("Router: game rule not allowed");
    });
  });
});