// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IMirror {
    function nativeTransfer(address payable _to, uint256 _amount) external;
    function transfer(address _token, address _to, uint256 _amount) external;
    function transferFrom(address _token, address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function transferFrom(address _token, address _from, address _to, uint256 _tokenId, uint256 _amount, bytes calldata data) external;
    function approve(address _token, address _spender, uint256 _amount) external;
}