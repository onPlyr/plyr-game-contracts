// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./Mirror.sol";

contract Register is OwnableUpgradeable, ReentrancyGuardUpgradeable {

    struct UserInfo {
        address mirror;
        string username;
        uint64 chainId;
    }

    address public router;

    mapping(address => UserInfo) public userInfo;
    mapping(string => address) public ensRecords;
    mapping(address => string) public ensNames;


    event MirrorDeployed(address indexed primary, address indexed mirror);
    event CreateUser(address _primary, string _username, address _mirror, uint64 chainId);
    event DeleteUser(address _primary);

    modifier onlyRouter() {
        require(msg.sender == router, "PlyrCluster: caller is not the operator");
        _;
    }

    constructor() {}

    function initialize(address _owner, address _router) public initializer {
        router = _router;
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
    }

    function getUserInfo(address _primary) external view returns (address mirror, string memory username, uint64 chainId) {
        return (userInfo[_primary].mirror, userInfo[_primary].username, userInfo[_primary].chainId);
    }

    function createUser(address _primary, string calldata _username, uint64 _chainId) external onlyRouter {
        require(userInfo[_primary].mirror == address(0), "UserExisted");
        require(bytes(_username).length > 0, "UserNameEmpty");
        
        userInfo[_primary].mirror = createMirror(_primary);
        userInfo[_primary].username = _username;
        userInfo[_primary].chainId = _chainId;

        registerENS(_username, _primary, userInfo[_primary].mirror);

        emit CreateUser(_primary, _username, userInfo[_primary].mirror, _chainId);
    }

    function createUserWithMirror(address _primary, address _mirror, string calldata _username, uint64 _chainId) external onlyRouter {
        require(userInfo[_primary].mirror == address(0), "UserExisted");
        require(bytes(_username).length == 0, "UserNameEmpty");

        userInfo[_primary].mirror = _mirror;
        userInfo[_primary].username = _username;
        userInfo[_primary].chainId = _chainId;

        registerENS(_username, _primary, userInfo[_primary].mirror);

        emit CreateUser(_primary, _username, userInfo[_primary].mirror, _chainId);
    }

    function registerENS(string calldata _username, address _primary, address _mirror) internal {
        ensRecords[_username] = _primary;
        ensRecords[string.concat(_username, ".plyr")] = _mirror;
        ensNames[_primary] = _username;
        ensNames[_mirror] = string.concat(_username, ".plyr");
    }

    function getENSAddress(string calldata _ensName) external view returns (address) {
        return ensRecords[_ensName];
    }

    function getENSName(address _primary) external view returns (string memory) {
        return ensNames[_primary];
    }

    function deleteUser(address _primary) external onlyRouter {
        userInfo[_primary].mirror = address(0);
        userInfo[_primary].username = "";
        userInfo[_primary].chainId = 0;
        emit DeleteUser(_primary);
    }

    function createMirror(address _primary) internal returns (address) {
        address mirror = deployMirror(_primary);
        Mirror(payable(mirror)).initialize(owner(), router, _primary);
        return mirror;
    }

    function deployMirror(address _primary) internal returns (address addr) {
        bytes32 salt = keccak256(abi.encodePacked(_primary));
        bytes memory bytecode = type(Mirror).creationCode;
        // Deploy the new contract
        addr = Create2.deploy(0, salt, bytecode);
        // Emit an event with deployment details
        emit MirrorDeployed(_primary, addr);
        // Return the address of the newly deployed contract
        return addr;
    }

    function computeMirrorAddress(address _primary) public view returns (address) {
        // Generate a unique salt from the provided seed
        bytes32 salt = keccak256(abi.encodePacked(_primary));
        bytes memory bytecode = type(Mirror).creationCode;
        // Compute and return the address
        return Create2.computeAddress(salt, keccak256(bytecode));
    }
}