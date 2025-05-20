// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

contract GameNft is OwnableUpgradeable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable {
    string public gameId;
    uint256 public holderCount;
    uint256 public mintCount;
    bool public isSoulBind;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, string memory _gameId, string memory _name, string memory _symbol, bool _isSoulBind) public initializer {
        __Ownable_init(_owner);
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        gameId = _gameId;
        isSoulBind = _isSoulBind;
    }

    function mint(address _to, string memory _tokenURI) public onlyOwner returns (uint256) {
        uint256 tokenId = mintCount + 1;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        mintCount += 1;
        return tokenId;
    }

    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }

    function gameTransfer(address _from, address _to, uint256 _tokenId) public onlyOwner {
        _safeTransfer(_from, _to, _tokenId, "");
    }

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (address) {
        // mint and transfer in
        if (to != address(0) && balanceOf(to) == 0) {
            holderCount += 1;
        }

        address previousOwner = super._update(to, tokenId, auth);

        require(!isSoulBind || previousOwner == address(0) || to == address(0), "GameNft: Soul bind nft not allowed to transfer");

        // transfer out or burn
        if (previousOwner != address(0) && balanceOf(previousOwner) == 0) {
            holderCount -= 1;
        }

        return previousOwner;
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(account, value);
    }
}
