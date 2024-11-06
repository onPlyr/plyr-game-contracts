// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Multicall.sol";
import "./GameRoom.sol";

interface IRouter {
    function mirrorNativeTransfer(address _from, address payable _to, uint256 _amount) external;
    function mirrorTokenTransfer(address _token, address _from, address _to, uint256 _amount) external;
}

interface IRegister {
    function getENSAddress(string calldata _ensName) external view returns (address);
}

contract GameRuleV1 is OwnableUpgradeable, ReentrancyGuardUpgradeable, Multicall {
    using SafeERC20 for IERC20;

    address public router;
    address public registerSC;
    uint256 public platformFee;
    address public feeTo;

    mapping(address => bool) public operators;
    // gameId => createdRoomCount
    mapping(string => uint256) public gameRoomCount;
    // gameId => roomId => gameRoomAddress
    mapping(string => mapping(uint256 => address)) public gameRoomAddress;
    // gameRoomAddress => gameId 
    mapping(address => string) public roomOwner;

    event GameRoomCreated(string gameId, uint256 roomId, address roomAddress);

    modifier onlyOperator {
        require(operators[msg.sender] || msg.sender == owner(), "GameRuleV1: only operators");
        _;
    }

    constructor() {}

    function initialize(address _owner, address _router, address _feeTo, address _registerSC) public initializer {
        platformFee = 2; // 2%
        feeTo = _feeTo;
        router = _router;
        registerSC = _registerSC;
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
    }

    function create(string memory gameId, uint256 expiresIn) public onlyOperator {
        _create(gameId, expiresIn);
    }

    function _create(string memory gameId, uint256 expiresIn) internal returns (uint256 roomId) {
        uint256 roomCount = gameRoomCount[gameId];
        gameRoomCount[gameId] = roomCount + 1;
        roomId = roomCount + 1;
        address room = createGameRoom(gameId, roomId);
        GameRoom(payable(room)).initialize(gameId, roomId, expiresIn);
        gameRoomAddress[gameId][roomId] = room;
        roomOwner[room] = gameId;
    }

    function join(string memory gameId, uint256 roomId, string[] memory plyrIds) public onlyOperator {
        address room = gameRoomAddress[gameId][roomId];
        require(room != address(0), "GameRuleV1: room not found");
        GameRoom(payable(room)).join(plyrIds);
    }

    function isJoined(string memory gameId, uint256 roomId, string memory plyrId) public view returns (bool) {
        address room = gameRoomAddress[gameId][roomId];
        if (room == address(0)) {
            return false;
        }
        return GameRoom(payable(room)).isJoined(plyrId);
    }

    function leave(string memory gameId, uint256 roomId, string[] memory plyrIds) public onlyOperator {
        address room = gameRoomAddress[gameId][roomId];
        require(room != address(0), "GameRuleV1: room not found");
        GameRoom(payable(room)).leave(plyrIds);
    }

    function pay(string memory gameId, uint256 roomId, string memory plyrId, address token, uint256 amount) public onlyOperator {
        _pay(gameId, roomId, plyrId, token, amount);
    }

    function batchPay(string memory gameId, uint256 roomId, string[] memory plyrIds, address[] memory tokens, uint256[] memory amounts) public onlyOperator {
        for (uint256 i = 0; i < plyrIds.length; i++) {
            _pay(gameId, roomId, plyrIds[i], tokens[i], amounts[i]);
        }
    }

    function _pay(string memory gameId, uint256 roomId, string memory plyrId, address token, uint256 amount) internal {
        address room = gameRoomAddress[gameId][roomId];
        require(room != address(0), "GameRuleV1: room not found");
        require(GameRoom(payable(room)).isJoined(plyrId), "GameRuleV1: plyr not joined");
        GameRoom(payable(room)).registerToken(token);
        if (token == address(0)) {
            address primary = IRegister(registerSC).getENSAddress(plyrId);
            IRouter(router).mirrorNativeTransfer(primary, payable(room), amount);
        } else {
            address primary = IRegister(registerSC).getENSAddress(plyrId);
            IRouter(router).mirrorTokenTransfer(token, primary, room, amount);
        }
    }

    function earn(string memory gameId, uint256 roomId, string memory plyrId, address token, uint256 amount) public onlyOperator {
        _earn(gameId, roomId, plyrId, token, amount);
    }

    function batchEarn(string memory gameId, uint256 roomId, string[] memory plyrIds, address[] memory tokens, uint256[] memory amounts) public onlyOperator {
        for (uint256 i = 0; i < plyrIds.length; i++) {
            _earn(gameId, roomId, plyrIds[i], tokens[i], amounts[i]);
        }
    }

    function _earn(string memory gameId, uint256 roomId, string memory plyrId, address token, uint256 amount) internal {
        address room = gameRoomAddress[gameId][roomId];
        require(room != address(0), "GameRuleV1: room not found");
        require(GameRoom(payable(room)).isJoined(plyrId), "GameRuleV1: plyr not joined");
        GameRoom(payable(room)).registerToken(token);
        uint256 fee = amount * platformFee / 100;
        uint256 amountAfterFee = amount - fee;
        if (token == address(0)) {
            address mirror = IRegister(registerSC).getENSAddress(string.concat(plyrId, ".plyr"));
            GameRoom(payable(room)).nativeTransfer(payable(mirror), amountAfterFee);
            GameRoom(payable(room)).nativeTransfer(payable(feeTo), fee);
        } else {
            address mirror = IRegister(registerSC).getENSAddress(string.concat(plyrId, ".plyr"));
            GameRoom(payable(room)).transfer(token, mirror, amountAfterFee);
            GameRoom(payable(room)).transfer(token, feeTo, fee);
        }
    }

    function end(string memory gameId, uint256 roomId) public onlyOperator {
        address room = gameRoomAddress[gameId][roomId];
        require(room != address(0), "GameRuleV1: room not found");
        GameRoom(payable(room)).end();
    }

    function close(string memory gameId, uint256 roomId, address team) public onlyOperator {
        address room = gameRoomAddress[gameId][roomId];
        require(room != address(0), "GameRuleV1: room not found");
        GameRoom(payable(room)).close(team);
    }

    function createJoinPay(string memory gameId, uint256 expiresIn, string[] memory plyrIds, address[] memory tokens, uint256[] memory amounts) public onlyOperator {
        uint256 roomId = _create(gameId, expiresIn);
        address room = gameRoomAddress[gameId][roomId];
        GameRoom(payable(room)).join(plyrIds);
        for (uint256 i = 0; i < plyrIds.length; i++) {
            _pay(gameId, roomId, plyrIds[i], tokens[i], amounts[i]);
        }
    }

    function joinPay(string memory gameId, uint256 roomId, string[] memory plyrIds, address[] memory tokens, uint256[] memory amounts) public onlyOperator {
        address room = gameRoomAddress[gameId][roomId];
        require(room != address(0), "GameRuleV1: room not found");
        GameRoom(payable(room)).join(plyrIds);
        for (uint256 i = 0; i < plyrIds.length; i++) {
            _pay(gameId, roomId, plyrIds[i], tokens[i], amounts[i]);
        }
    }

    function earnLeaveEnd(string memory gameId, uint256 roomId, string[] memory plyrIds, address[] memory tokens, uint256[] memory amounts) public onlyOperator {
        for (uint256 i = 0; i < plyrIds.length; i++) {
            _earn(gameId, roomId, plyrIds[i], tokens[i], amounts[i]);
        }
        address room = gameRoomAddress[gameId][roomId];
        require(room != address(0), "GameRuleV1: room not found");
        GameRoom(payable(room)).leave(plyrIds);
        GameRoom(payable(room)).end();
    }

    function earnLeave(string memory gameId, uint256 roomId, string[] memory plyrIds, address[] memory tokens, uint256[] memory amounts) public onlyOperator {
        for (uint256 i = 0; i < plyrIds.length; i++) {
            _earn(gameId, roomId, plyrIds[i], tokens[i], amounts[i]);
        }
        address room = gameRoomAddress[gameId][roomId];
        require(room != address(0), "GameRuleV1: room not found");
        GameRoom(payable(room)).leave(plyrIds);
    }

    function configOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
    }

    function configPlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }

    function configFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function createGameRoom(string memory gameId, uint256 roomId) internal returns (address addr) {
        bytes32 salt = keccak256(abi.encode(gameId, roomId));
        bytes memory bytecode = type(GameRoom).creationCode;
        // Deploy the new contract
        addr = Create2.deploy(0, salt, bytecode);
        // Emit an event with deployment details
        emit GameRoomCreated(gameId, roomId, addr);
        // Return the address of the newly deployed contract
        return addr;
    }

    function computeRoomAddress(string memory gameId, uint256 roomId) public view returns (address) {
        // Generate a unique salt from the provided seed
        bytes32 salt = keccak256(abi.encode(gameId, roomId));
        bytes memory bytecode = type(GameRoom).creationCode;
        // Compute and return the address
        return Create2.computeAddress(salt, keccak256(bytecode));
    }
}
