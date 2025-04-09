// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract GameNft is OwnableUpgradeable, ERC721URIStorageUpgradeable {
    string public gameId;
    uint256 public totalSupply;
    uint256 public holderCount;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, string memory _gameId, string memory _name, string memory _symbol) public initializer {
        __Ownable_init(_owner);
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        gameId = _gameId;
    }

    function mint(address _to, string memory _tokenURI) public onlyOwner returns (uint256) {
        uint256 tokenId = (totalSupply + 1);
        totalSupply = tokenId;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        return tokenId;
    }

    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
        totalSupply -= 1;
    }

    function gameTransfer(address _from, address _to, uint256 _tokenId) public onlyOwner {
        _safeTransfer(_from, _to, _tokenId, "");
    }

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721Upgradeable) returns (address) {
        // mint or transfer
        if (to != address(0) && balanceOf(to) == 0) {
            holderCount += 1;
        }

        address previousOwner = super._update(to, tokenId, auth);

        // burn
        if (to == address(0) && balanceOf(previousOwner) == 0) {
            holderCount -= 1;
        }
        return previousOwner;
    }
}
