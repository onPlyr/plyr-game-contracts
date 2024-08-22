const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GameRoom", function () {
  let gameRoom;
  let owner;
  let user1;
  let user2;
  let erc20Token;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy GameRoom contract
    const GameRoom = await ethers.getContractFactory("GameRoom");
    gameRoom = await GameRoom.deploy("testGame");

    // Deploy a mock ERC20 token for testing
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    erc20Token = await MockERC20.deploy("TestToken", "TT");
  });

  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await gameRoom.owner()).to.equal(owner.address);
    });

    it("Should set the correct game ID", async function () {
      expect(await gameRoom.gameId()).to.equal("testGame");
    });
  });

  describe("Native token transfer", function () {
    it("Owner should be able to transfer native tokens", async function () {
      // Send 1 ETH to the GameRoom contract
      await owner.sendTransaction({ to: gameRoom.target, value: ethers.parseEther("1.0") });
      
      // Check initial balances
      const initialGameRoomBalance = await ethers.provider.getBalance(gameRoom.target);
      const initialUser1Balance = await ethers.provider.getBalance(user1.address);

      // Transfer 0.5 ETH from GameRoom to user1
      await expect(gameRoom.nativeTransfer(user1.address, ethers.parseEther("0.5")))
        .to.changeEtherBalances(
          [gameRoom, user1],
          [ethers.parseEther("-0.5"), ethers.parseEther("0.5")]
        );

      // Check final balances
      const finalGameRoomBalance = await ethers.provider.getBalance(gameRoom.target);
      const finalUser1Balance = await ethers.provider.getBalance(user1.address);

      expect(finalGameRoomBalance).to.equal(initialGameRoomBalance - ethers.parseEther("0.5"));
      expect(finalUser1Balance).to.equal(initialUser1Balance + ethers.parseEther("0.5"));
    });

    it("Non-owner should not be able to transfer native tokens", async function () {
      await expect(gameRoom.connect(user1).nativeTransfer(user2.address, 100))
        .to.be.revertedWithCustomError(gameRoom, "OwnableUnauthorizedAccount");
    });
  });

  describe("ERC20 token transfer", function () {
    beforeEach(async function () {
      // Transfer 1000 tokens to the GameRoom contract
      await erc20Token.transfer(gameRoom.target, 1000);
    });

    it("Owner should be able to transfer ERC20 tokens", async function () {
      // Check initial balances
      const initialGameRoomBalance = await erc20Token.balanceOf(gameRoom.target);
      const initialUser1Balance = await erc20Token.balanceOf(user1.address);

      // Transfer 500 tokens from GameRoom to user1
      await expect(gameRoom.transfer(erc20Token.target, user1.address, 500))
        .to.changeTokenBalances(erc20Token, [gameRoom, user1], [-500, 500]);

      // Check final balances
      const finalGameRoomBalance = await erc20Token.balanceOf(gameRoom.target);
      const finalUser1Balance = await erc20Token.balanceOf(user1.address);

      expect(finalGameRoomBalance).to.equal(initialGameRoomBalance - 500n);
      expect(finalUser1Balance).to.equal(initialUser1Balance + 500n);
    });

    it("Non-owner should not be able to transfer ERC20 tokens", async function () {
      await expect(gameRoom.connect(user1).transfer(erc20Token.target, user2.address, 100))
        .to.be.revertedWithCustomError(gameRoom, "OwnableUnauthorizedAccount");
    });
  });
});