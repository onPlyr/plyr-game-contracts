// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GameRoom is Ownable {
    using SafeERC20 for IERC20;

    string public gameId;

    event NativeTransfer(address to, uint256 amount);
    event Erc20Transfer(address to, uint256 amount);

    constructor(string memory _gameId) Ownable(msg.sender) {
        gameId = _gameId;
    }

    receive() external payable {}

    function nativeTransfer(address payable _to, uint256 _amount) external onlyOwner {
        Address.sendValue(_to, _amount);
    }

    function transfer(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }
}