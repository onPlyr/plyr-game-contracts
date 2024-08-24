const { expect } = require("chai");
const { ZeroAddress } = require("ethers");
const { ethers } = require("hardhat");

describe("GameRoom", function () {
  let gameRoom;
  let owner;
  let user1;
  let user2;
  let erc20Token;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    const GameRoom = await ethers.getContractFactory("GameRoom");
    gameRoom = await GameRoom.deploy("testGame", "testRoom", 3600);

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    erc20Token = await MockERC20.deploy("TestToken", "TT");
  });

  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await gameRoom.owner()).to.equal(owner.address);
    });

    it("Should set the correct game ID and room ID", async function () {
      expect(await gameRoom.gameId()).to.equal("testGame");
      expect(await gameRoom.roomId()).to.equal("testRoom");
    });

    it("Should set the correct deadline with ±5 seconds tolerance", async function () {
      const deploymentTime = await ethers.provider.getBlock("latest").then(block => block.timestamp);
      const deadline = await gameRoom.deadline();
      const expectedDeadline = deploymentTime + 3600;
      expect(deadline).to.be.closeTo(expectedDeadline, 5);
    });
  });

  describe("Player management", function () {
    it("Owner should be able to add players", async function () {
      await expect(gameRoom.join(["player1", "player2"]))
        .to.emit(gameRoom, "PlayerJoined").withArgs("player1")
        .to.emit(gameRoom, "PlayerJoined").withArgs("player2");

      expect(await gameRoom.isJoined("player1")).to.be.true;
      expect(await gameRoom.isJoined("player2")).to.be.true;
    });

    it("Owner should be able to remove players", async function () {
      await gameRoom.join(["player1", "player2"]);
      await expect(gameRoom.leave(["player1"]))
        .to.emit(gameRoom, "PlayerLeft").withArgs("player1");

      expect(await gameRoom.isJoined("player1")).to.be.false;
      expect(await gameRoom.isJoined("player2")).to.be.true;
    });

    it("Non-owner should not be able to add or remove players", async function () {
      await expect(gameRoom.connect(user1).join(["player1"]))
        .to.be.revertedWithCustomError(gameRoom, "OwnableUnauthorizedAccount");
      await expect(gameRoom.connect(user1).leave(["player1"]))
        .to.be.revertedWithCustomError(gameRoom, "OwnableUnauthorizedAccount");
    });
  });

  describe("Token management", function () {
    it("Owner should be able to register tokens", async function () {
      await expect(gameRoom.registerToken(erc20Token.target))
        .to.emit(gameRoom, "TokenRegistered").withArgs(erc20Token.target);

      const registeredTokens = await gameRoom.getTokens();
      expect(registeredTokens).to.include(erc20Token.target);
    });

    it("Non-owner should not be able to register tokens", async function () {
      await expect(gameRoom.connect(user1).registerToken(erc20Token.target))
        .to.be.revertedWithCustomError(gameRoom, "OwnableUnauthorizedAccount");
    });
  });

  describe("Game ending", function () {
    it("Owner should be able to end the game when balances are zero", async function () {
      await expect(gameRoom.end()).to.emit(gameRoom, "GameEnded").withArgs("testGame", "testRoom");
      expect(await gameRoom.isEnded()).to.be.true;
    });

    it("Owner should not be able to end the game when balances are not zero", async function () {
      await owner.sendTransaction({ to: gameRoom.target, value: ethers.parseEther("1.0") });
      await gameRoom.registerToken(ZeroAddress);
      await expect(gameRoom.end()).to.be.revertedWith("NativeCoinBalanceNotZero");
    });

    it("Owner should be able to close the game after deadline", async function () {
      await owner.sendTransaction({ to: gameRoom.target, value: ethers.parseEther("1.0") });
      await gameRoom.registerToken(ZeroAddress);
      
      await ethers.provider.send("evm_increaseTime", [3601]);
      await ethers.provider.send("evm_mine");

      await expect(gameRoom.close(user1.address))
        .to.emit(gameRoom, "GameClosed").withArgs("testGame", "testRoom", user1.address);
      expect(await gameRoom.isEnded()).to.be.true;
    });

    it("Owner should not be able to close the game before deadline", async function () {
      await expect(gameRoom.close(user1.address)).to.be.revertedWith("GameNotEnded");
    });
  });

  describe("Native token transfer", function () {
    it("Owner should be able to transfer native tokens", async function () {
      await owner.sendTransaction({ to: gameRoom.target, value: ethers.parseEther("1.0") });
      
      await expect(gameRoom.nativeTransfer(user1.address, ethers.parseEther("0.5")))
        .to.changeEtherBalances(
          [gameRoom, user1],
          [ethers.parseEther("-0.5"), ethers.parseEther("0.5")]
        );
    });

    it("Non-owner should not be able to transfer native tokens", async function () {
      await expect(gameRoom.connect(user1).nativeTransfer(user2.address, 100))
        .to.be.revertedWithCustomError(gameRoom, "OwnableUnauthorizedAccount");
    });
  });

  describe("ERC20 token transfer", function () {
    beforeEach(async function () {
      await gameRoom.registerToken(erc20Token.target);
      await erc20Token.transfer(gameRoom.target, 1000);
    });

    it("Owner should be able to transfer ERC20 tokens", async function () {
      await expect(gameRoom.transfer(erc20Token.target, user1.address, 500))
        .to.changeTokenBalances(erc20Token, [gameRoom, user1], [-500, 500]);
    });

    it("Non-owner should not be able to transfer ERC20 tokens", async function () {
      await expect(gameRoom.connect(user1).transfer(erc20Token.target, user2.address, 100))
        .to.be.revertedWithCustomError(gameRoom, "OwnableUnauthorizedAccount");
    });
  });
});