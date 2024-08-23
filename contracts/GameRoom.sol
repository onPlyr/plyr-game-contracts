// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GameRoom is Ownable {
    using SafeERC20 for IERC20;

    string public gameId;
    string public roomId;
    uint256 public deadline;
    bool public isEnded;

    address[] public tokens;

    mapping(string => bool) public joinedPlayers;
    mapping(address => bool) public tokenRegistered;

    event NativeTransfer(address to, uint256 amount);
    event Erc20Transfer(address to, uint256 amount);
    event PlayerJoined(string plyrId);
    event PlayerLeft(string plyrId);
    event TokenRegistered(address token);
    event GameEnded(string gameId, string roomId);
    event GameClosed(string gameId, string roomId, address team);

    constructor(string memory _gameId, string memory _roomId, uint256 _expiresIn) Ownable(msg.sender) {
        gameId = _gameId;
        roomId = _roomId;
        deadline = block.timestamp + _expiresIn;
    }

    receive() external payable {}

    function join(string[] memory plyrIds) external onlyOwner {
        for (uint256 i = 0; i < plyrIds.length; i++) {
            joinedPlayers[plyrIds[i]] = true;
            emit PlayerJoined(plyrIds[i]);
        }
    }

    function leave(string[] memory plyrIds) external onlyOwner {
        for (uint256 i = 0; i < plyrIds.length; i++) {
            joinedPlayers[plyrIds[i]] = false;
            emit PlayerLeft(plyrIds[i]);
        }
    }

    function isJoined(string memory plyrId) public view returns (bool) {
        return joinedPlayers[plyrId] || keccak256(abi.encodePacked(plyrId)) == keccak256(abi.encodePacked(gameId));
    }

    function registerToken(address _token) external onlyOwner {
        if (!tokenRegistered[_token]) {
            tokens.push(_token);
            tokenRegistered[_token] = true;
            emit TokenRegistered(_token);
        }
    }

    function end() external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(0)) {
                uint balance = IERC20(tokens[i]).balanceOf(address(this));
                require(balance == 0, "TokenBalanceNotZero");
            } else {
                uint balance = address(this).balance;
                require(balance == 0, "NativeCoinBalanceNotZero");
            }
        }
        isEnded = true;
        emit GameEnded(gameId, roomId);
    }

    function close(address _team) external onlyOwner {
        require(block.timestamp > deadline, "GameNotEnded");
        require(!isEnded, "GameAlreadyEnded");
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(0)) {
                if (IERC20(tokens[i]).balanceOf(address(this)) > 0) {
                    IERC20(tokens[i]).transfer(_team, IERC20(tokens[i]).balanceOf(address(this)));
                }
            } else {
                if (address(this).balance > 0) {
                    payable(_team).transfer(address(this).balance);
                }
            }
        }
        isEnded = true;
        emit GameClosed(gameId, roomId, _team);
    }
    
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function nativeTransfer(address payable _to, uint256 _amount) external onlyOwner {
        Address.sendValue(_to, _amount);
    }

    function transfer(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }
}