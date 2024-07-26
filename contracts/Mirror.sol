// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Mirror is Initializable, AccessControl, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;

    address public primary;

    bool public paused;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public constant VERSION = 1;

    event MirrorTransferERC20(address _token, address _to, uint256 _amount);
    event MirrorTransferERC721(address _token, address _from, address _to, uint256 _tokenId);
    event MirrorTransferERC1155(address _token, address _from, address _to, uint256 _tokenId, uint256 _amount);
    event MirrorNativeTransfer(address _to, uint256 _amount);
    event MirrorApprove(address _token, address _spender, uint256 _amount);

    modifier notPaused() {
        require(!paused, "Mirror: paused");
        _;
    }

    function initialize(address _admin, address _operator, address _primary) initializer external {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _operator);
        primary = _primary;
    }

    receive() external payable {}

    function nativeTransfer(address payable _to, uint256 _amount) external notPaused onlyRole(OPERATOR_ROLE) {
        Address.sendValue(_to, _amount);
        emit MirrorNativeTransfer(_to, _amount);
    }

    function transfer(address _token, address _to, uint256 _amount) external notPaused onlyRole(OPERATOR_ROLE) {
        IERC20(_token).safeTransfer(_to, _amount);
        emit MirrorTransferERC20(_token, _to, _amount);
    }

    function transferFrom(address _token, address _from, address _to, uint256 _tokenId) external notPaused onlyRole(OPERATOR_ROLE) {
        IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
        emit MirrorTransferERC721(_token, _from, _to, _tokenId);
    }

    function transferFrom(address _token, address _from, address _to, uint256 _tokenId, uint256 _amount) external notPaused onlyRole(OPERATOR_ROLE) {
        IERC1155(_token).safeTransferFrom(_from, _to, _tokenId, _amount, "");
        emit MirrorTransferERC1155(_token, _from, _to, _tokenId, _amount);
    }

    function approve(address _token, address _spender, uint256 _amount) external notPaused onlyRole(OPERATOR_ROLE) {
        IERC20(_token).safeIncreaseAllowance(_spender, _amount);
        emit MirrorApprove(_token, _spender, _amount);
    }

    function pause(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = _paused;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Holder, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
