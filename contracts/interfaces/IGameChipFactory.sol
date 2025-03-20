// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IGameChipFactory {
    function createChip(string memory _gameId, string memory _name, string memory _symbol) external;
    function mint(address _chip, address _to, uint256 _amount) external;
    function burn(address _chip, address _from, uint256 _amount) external;
    function gameTransfer(address _chip, address _from, address _to, uint256 _amount) external;
    function chipInfo(address _chip) external view returns(address tokenAddress, string memory gameId, string memory name, string memory symbol, uint256 totalSupply, uint256 holderCount);
}
