const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Router", function () {
  let router;
  let mockRegister;
  let mockMirror;
  let owner;
  let operator;
  let user1;
  let user2;

  beforeEach(async function () {
    [owner, operator, user1, user2] = await ethers.getSigners();

    // Deploy mock contracts
    const MockRegister = await ethers.getContractFactory("Register");
    mockRegister = await MockRegister.deploy();

    const MockMirror = await ethers.getContractFactory("Mirror");
    mockMirror = await MockMirror.deploy();

    // Deploy Router contract
    const Router = await ethers.getContractFactory("Router");
    router = await Router.deploy();
    await router.initialize(owner.address, operator.address, mockRegister.target);

    await mockRegister.initialize(owner.address, router.target);
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await router.owner()).to.equal(owner.address);
    });

    it("Should set the right operator", async function () {
      expect(await router.hasRole(await router.OPERATOR_ROLE(), operator.address)).to.be.true;
    });

    it("Should set the right register contract", async function () {
      expect(await router.registerSC()).to.equal(mockRegister.target);
    });
  });

  describe("Access Control", function () {
    it("Should allow owner to call onlyOwner functions", async function () {
      await expect(router.connect(owner).configGameRule(user1.address, true)).to.not.be.reverted;
    });

    it("Should not allow non-owner to call onlyOwner functions", async function () {
      await expect(router.connect(user1).configGameRule(user1.address, true)).to.be.reverted;
    });

    it("Should allow operator to call onlyOperator functions", async function () {
      await expect(router.connect(operator).createUser(user1.address, "user1", 1)).to.not.be.reverted;
    });

    it("Should not allow non-operator to call onlyOperator functions", async function () {
      await expect(router.connect(user1).createUser(user1.address, "user1", 1)).to.be.revertedWith("Router: caller is not the operator");
    });
  });

  describe("Game Rule Configuration", function () {
    it("Should allow owner to configure game rule", async function () {
      await expect(router.connect(owner).configGameRule(user1.address, true))
        .to.emit(router, "GameConfigured")
        .withArgs(user1.address, true);

      expect(await router.allowedGameRules(user1.address)).to.be.true;
    });

    it("Should not allow configuring zero address as game rule", async function () {
      await expect(router.connect(owner).configGameRule(ethers.ZeroAddress, true))
        .to.be.revertedWith("Router: game rule is the zero address");
    });

    it("Should not allow configuring already configured game rule", async function () {
      await router.connect(owner).configGameRule(user1.address, true);
      await expect(router.connect(owner).configGameRule(user1.address, false))
        .to.be.revertedWith("Router: game rule is already configured");
    });
  });

  describe("User Management", function () {
    it("Should create user", async function () {
      await expect(router.connect(operator).createUser(user1.address, "user1", 1)).to.not.be.reverted;
      await expect(router.connect(owner).createUser(user2.address, "user2", 1)).to.not.be.reverted;
    });

    it("Should create user with mirror", async function () {
      await expect(router.connect(operator).createUserWithMirror(user1.address, mockMirror.target, "user1", 1)).to.not.be.reverted;
    });

    it("Should delete user", async function () {
      await expect(router.connect(operator).deleteUser(user1.address)).to.not.be.reverted;
    });

    it("Should compute mirror address", async function () {
      const mirrorAddress = await router.computeMirrorAddress(user1.address);
      expect(mirrorAddress).to.be.properAddress;
    });
  });
});