// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IRegister.sol";
import "./interfaces/IMirror.sol";
import "./Multicall.sol";
import "./interfaces/IGameChipFactory.sol";

contract Router is OwnableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable, Multicall {
    
    address public registerSC;
    address[] public gameRules;
    mapping(address => bool) public allowedGameRules;
    address public gameChipFactory;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event GameConfigured(address _game, bool _allowed);

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender) || msg.sender == owner(), "Router: caller is not the operator");
        _;
    }

    modifier onlyAllowGameRule() {
        require(allowedGameRules[msg.sender], "Router: game rule not allowed");
        _;
    }

    constructor() {}

    function initialize(address _owner, address _operator, address _registerSC) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _operator);
        registerSC = _registerSC;
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        __AccessControl_init();
    }

    function configGameRule(address _gameRule, bool _allowed) external onlyOwner {
        require(_gameRule != address(0), "Router: game rule is the zero address");
        require(!allowedGameRules[_gameRule], "Router: game rule is already configured");
        gameRules.push(_gameRule);
        allowedGameRules[_gameRule] = _allowed;
        emit GameConfigured(_gameRule, _allowed);
    }

    // Register Functions
    function createUser(address _primary, string calldata _username, uint64 _chainId) external onlyOperator {
        IRegister(registerSC).createUser(_primary, _username, _chainId);
    }

    function createUserWithMirror(address _primary, address _mirror, string calldata _username, uint64 _chainId) external onlyOperator {
        IRegister(registerSC).createUserWithMirror(_primary, _mirror, _username, _chainId);
    }

    function deleteUser(address _primary) external onlyOperator {
        IRegister(registerSC).deleteUser(_primary);
    }

    function computeMirrorAddress(address _primary) external view returns (address) {
        return IRegister(registerSC).computeMirrorAddress(_primary);
    }

    // Mirror Functions
    function mirrorNativeTransfer(address _from, address payable _to, uint256 _amount) external nonReentrant onlyAllowGameRule {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).nativeTransfer(_to, _amount);
    }

    function mirrorTokenTransfer(address _token, address _from, address _to, uint256 _amount) external nonReentrant onlyAllowGameRule {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).transfer(_token, _to, _amount);
    }

    function mirrorErc721TransferFrom(address _token, address _from, address _to, uint256 _tokenId, bytes calldata data) external nonReentrant onlyAllowGameRule {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).transferFrom(_token, _from, _to, _tokenId, data);
    }

    function mirrorErc1155TransferFrom(address _token, address _from, address _to, uint256 _tokenId, uint256 _amount, bytes calldata data) external nonReentrant onlyAllowGameRule {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).transferFrom(_token, _from, _to, _tokenId, _amount, data);
    }

    function mirrorApprove(address _token, address _from, address _spender, uint256 _amount) external nonReentrant onlyAllowGameRule {
        (address mirror,,) = IRegister(registerSC).getUserInfo(_from);
        IMirror(mirror).approve(_token, _spender, _amount);
    }

    // game chips functions
    function setGameChipFactory(address _gameChipFactory) external onlyOwner {
        gameChipFactory = _gameChipFactory;
    }

    function createGameChip(string memory _gameId, string memory _name, string memory _symbol) external onlyOperator {
        IGameChipFactory(gameChipFactory).createChip(_gameId, _name, _symbol);
    }

    function mintGameChips(address[] memory _chips, address[] memory _to, uint256[] memory _amounts) external onlyOperator {
        for (uint256 i = 0; i < _chips.length; i++) {
            IGameChipFactory(gameChipFactory).mint(_chips[i], _to[i], _amounts[i]);
        }
    }

    function burnGameChips(address[] memory _chips, address[] memory _from, uint256[] memory _amounts) external onlyOperator {
        for (uint256 i = 0; i < _chips.length; i++) {
            IGameChipFactory(gameChipFactory).burn(_chips[i], _from[i], _amounts[i]);
        }
    }

    function gameTransferGameChips(address[] memory _chips, address[] memory _from, address[] memory _to, uint256[] memory _amounts) external onlyOperator {
        for (uint256 i = 0; i < _chips.length; i++) {
            IGameChipFactory(gameChipFactory).gameTransfer(_chips[i], _from[i], _to[i], _amounts[i]);
        }
    }

    function chipInfo(address _chip) external view returns(address tokenAddress, string memory gameId, string memory name, string memory symbol, uint256 totalSupply, uint256 holderCount) {
        return IGameChipFactory(gameChipFactory).chipInfo(_chip);
    }
}
