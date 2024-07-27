// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IRegister.sol";
import "./interfaces/IMirror.sol";

contract Router is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public operator;
    address public registerSC;
    
    mapping(address => bool) public allowedGames;

    event GameConfigured(address _game, bool _allowed);

    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == owner(), "Router: caller is not the operator");
        _;
    }

    modifier onlyGame() {
        require(allowedGames[msg.sender], "Router: caller is not the game");
        _;
    }

    constructor() {}

    function initialize(address _owner, address _operator, address _registerSC) public initializer {
        operator = _operator;
        registerSC = _registerSC;
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
    }

    function configGame(address _game, bool _allowed) external onlyOwner {
        allowedGames[_game] = _allowed;
        emit GameConfigured(_game, _allowed);
    }

    // Register Functions
    function createUser(address _primary, string calldata _username, uint64 _chainId) external {
        IRegister(registerSC).createUser(_primary, _username, _chainId);
    }

    function createUserWithMirror(address _primary, address _mirror, string calldata _username, uint64 _chainId) external {
        IRegister(registerSC).createUserWithMirror(_primary, _mirror, _username, _chainId);
    }

    function deleteUser(address _primary) external {
        IRegister(registerSC).deleteUser(_primary);
    }

    function computeMirrorAddress(address _primary) external view returns (address) {
        return IRegister(registerSC).computeMirrorAddress(_primary);
    }

    // Mirror Functions
    function nativeTransfer(address _from, address payable _to, uint256 _amount) external nonReentrant onlyGame {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).nativeTransfer(_to, _amount);
    }

    function transfer(address _token, address _from, address _to, uint256 _amount) external nonReentrant onlyGame {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).transfer(_token, _to, _amount);
    }

    function transferFrom(address _token, address _from, address _to, uint256 _tokenId, bytes calldata data) external nonReentrant onlyGame {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).transferFrom(_token, _from, _to, _tokenId, data);
    }

    function transferFrom(address _token, address _from, address _to, uint256 _tokenId, uint256 _amount, bytes calldata data) external nonReentrant onlyGame {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).transferFrom(_token, _from, _to, _tokenId, _amount, data);
    }

    function approve(address _token, address _from, address _spender, uint256 _amount) external nonReentrant onlyGame {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).approve(_token, _spender, _amount);
    }
}
