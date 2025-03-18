// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GameChip.sol";

contract GameChipFactory is OwnableUpgradeable {
    address public chipImplementation;
    address public gameRouter;
    uint256 public totalChipCount;

    mapping(address => string) public chipGameId; // chipAddress => gameId
    mapping(uint256 => address) public chips; // chipId => chipAddress
    mapping(address => uint256) public chipHolderCount; // chipAddress => holderCount

    modifier onlyGameRouter() { 
        require(msg.sender == gameRouter, "GameChipFactory: caller is not the game router");
        _;
    }

    event ChipCreated(address indexed chip, string gameId, string name, string symbol);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address _implementation, address _owner, address _gameRouter) public initializer {
        __Ownable_init(_owner);
        chipImplementation = _implementation;
        gameRouter = _gameRouter;
    }

    function createChip(string memory _gameId, string memory _name, string memory _symbol) external onlyGameRouter {
        address chip = Clones.clone(chipImplementation);
        GameChip(chip).initialize(address(this), _gameId, _name, _symbol);
        chipGameId[chip] = _gameId;
        chips[totalChipCount] = chip;
        totalChipCount++;
        emit ChipCreated(chip, _gameId, _name, _symbol);
    }

    function mint(address _chip, address _to, uint256 _amount) external onlyGameRouter {
        if (_amount == 0) {
            return;
        }

        if (IERC20(_chip).balanceOf(_to) == 0) {
            chipHolderCount[_chip]++;
        }
        
        GameChip(_chip).mint(_to, _amount);
    }

    function burn(address _chip, address _from, uint256 _amount) external onlyGameRouter {
        GameChip(_chip).burn(_from, _amount);

        if (IERC20(_chip).balanceOf(_from) == 0) {
            chipHolderCount[_chip]--;
        }
    }

    function gameTransfer(address _chip, address _from, address _to, uint256 _amount) external onlyGameRouter {
        if (IERC20(_chip).balanceOf(_to) == 0) {
            chipHolderCount[_chip]++;
        }

        GameChip(_chip).gameTransfer(_from, _to, _amount);

        if (IERC20(_chip).balanceOf(_from) == 0) {
            chipHolderCount[_chip]--;
        }
    }

    function chipInfo(address _chip) external view returns(address tokenAddress, string memory gameId, string memory name, string memory symbol, uint256 totalSupply, uint256 holderCount) {
        return (address(_chip), chipGameId[_chip], GameChip(_chip).name(), GameChip(_chip).symbol(), GameChip(_chip).totalSupply(), chipHolderCount[_chip]);
    }

    function configGameRouter(address _gameRouter) external onlyOwner {
        gameRouter = _gameRouter;
    }

    function configChipImplementation(address _implementation) external onlyOwner {
        chipImplementation = _implementation;
    }
}

