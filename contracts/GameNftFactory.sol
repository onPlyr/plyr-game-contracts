// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GameNft.sol";

contract GameNftFactory is OwnableUpgradeable {
    address public nftImplementation;
    address public operator;
    uint256 public totalNftCount;

    mapping(address => string) public nftGameId; // nftAddress => gameId
    mapping(uint256 => address) public nfts; // nftId => nftAddress

    modifier onlyOperator() { 
        require(msg.sender == operator, "GameNftFactory: caller is not the game router");
        _;
    }

    event NftCreated(address indexed nft, string gameId, string name, string symbol);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address _implementation, address _owner, address _operator) public initializer {
        __Ownable_init(_owner);
        nftImplementation = _implementation;
        operator = _operator;
    }

    function createNft(string memory _gameId, string memory _name, string memory _symbol) external onlyOperator {
        address nft = Clones.clone(nftImplementation);
        GameNft(nft).initialize(address(this), _gameId, _name, _symbol);
        nftGameId[nft] = _gameId;
        nfts[totalNftCount] = nft;
        totalNftCount++;
        emit NftCreated(nft, _gameId, _name, _symbol);
    }

    function mint(address _nft, address _to, string memory _tokenURI) public onlyOperator {
        GameNft(_nft).mint(_to, _tokenURI);
    }

    function batchMint(address[] memory _nft, address[] memory _to, string[] memory _tokenURI) external onlyOperator {
        for (uint256 i = 0; i < _to.length; i++) {
            mint(_nft[i], _to[i], _tokenURI[i]);
        }
    }

    function burn(address _nft, uint256 _tokenId) public onlyOperator {
        GameNft(_nft).burn(_tokenId);
    }

    function batchBurn(address[] memory _nft, uint256[] memory _tokenId) external onlyOperator {
        for (uint256 i = 0; i < _nft.length; i++) {
            burn(_nft[i], _tokenId[i]);
        }
    }

    function gameTransfer(address _nft, address _from, address _to, uint256 _tokenId) public onlyOperator {
        GameNft(_nft).gameTransfer(_from, _to, _tokenId);
    }

    function batchGameTransfer(address[] memory _nft, address[] memory _from, address[] memory _to, uint256[] memory _tokenId) external onlyOperator {
        for (uint256 i = 0; i < _from.length; i++) {
            gameTransfer(_nft[i], _from[i], _to[i], _tokenId[i]);
        }
    }

    function nftInfo(address _nft) external view returns(address tokenAddress, string memory gameId, string memory name, string memory symbol, uint256 totalSupply, uint256 holderCount) {
        return (address(_nft), nftGameId[_nft], GameNft(_nft).name(), GameNft(_nft).symbol(), GameNft(_nft).totalSupply(), nftHolderCount(_nft));
    }

    function nftHolderCount(address _nft) public view returns(uint256) {
        return GameNft(_nft).holderCount();
    }

    function configOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function configNftImplementation(address _implementation) external onlyOwner {
        nftImplementation = _implementation;
    }
}

