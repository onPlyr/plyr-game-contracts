// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract GameChip is OwnableUpgradeable, ERC20Upgradeable {
    string public gameId;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, string memory _gameId, string memory _name, string memory _symbol) public initializer {
        __Ownable_init(_owner);
        __ERC20_init(_name, _symbol);
        gameId = _gameId;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function gameTransfer(address _from, address _to, uint256 _amount) public onlyOwner {
        _transfer(_from, _to, _amount);
    }
}
