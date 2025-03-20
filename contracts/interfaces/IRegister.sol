// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IRegister {
    function createUser(address _primary, string calldata _username, uint64 _chainId) external;
    function createUserWithMirror(address _primary, address _mirror, string calldata _username, uint64 _chainId) external;
    function deleteUser(address _primary) external;
    function computeMirrorAddress(address _primary) external view returns (address);
    function getUserInfo(address _primary) external view returns (address mirror, string memory username, uint64 chainId);
    function getENSAddress(string calldata _ensName) external view returns (address);
}