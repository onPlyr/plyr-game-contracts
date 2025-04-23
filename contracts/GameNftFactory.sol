// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GameNft.sol";
import "./interfaces/ITeleporterReceiver.sol";
import "./interfaces/ITeleporterMessenger.sol";

contract GameNftFactory is OwnableUpgradeable {
    address public nftImplementation;
    address public operator;
    uint256 public totalNftCount;

    mapping(address => string) public nftGameId; // nftAddress => gameId
    mapping(uint256 => address) public nfts; // nftId => nftAddress
    ITeleporterMessenger public teleporterMessenger;
    address public relayer;
    address public remoteFactory;
    bytes32 public remoteBlockchainId;
    uint256 public remoteGasLimit;

    enum MessageType {
        CREATE_NFT,
        BATCH_MINT,
        BATCH_BURN,
        BATCH_GAME_TRANSFER
    }


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
        _createNft(_gameId, _name, _symbol);
    }

    function batchMint(address[] memory _nft, address[] memory _to, string[] memory _tokenURI) external onlyOperator {
        _batchMint(_nft, _to, _tokenURI);
    }

    function batchBurn(address[] memory _nft, uint256[] memory _tokenId) external onlyOperator {
        _batchBurn(_nft, _tokenId);
    }

    function batchGameTransfer(address[] memory _nft, address[] memory _from, address[] memory _to, uint256[] memory _tokenId) external onlyOperator {
        _batchGameTransfer(_nft, _from, _to, _tokenId);
    }

    function createNftRemote(string memory _gameId, string memory _name, string memory _symbol) external onlyOperator {
        bytes memory message = abi.encode(MessageType.CREATE_NFT, _gameId, _name, _symbol);
        address[] memory allowedRelayerAddresses = new address[](1);
        allowedRelayerAddresses[0] = relayer;
        TeleporterMessageInput memory input = TeleporterMessageInput({
            destinationBlockchainID: remoteBlockchainId,
            destinationAddress: remoteFactory,
            feeInfo: TeleporterFeeInfo({
                feeTokenAddress: address(0),
                amount: 0
            }),
            requiredGasLimit: remoteGasLimit,
            allowedRelayerAddresses: allowedRelayerAddresses,
            message: message
        });
        teleporterMessenger.sendCrossChainMessage(input);
    }

    function batchMintRemote(address[] memory _nft, address[] memory _to, string[] memory _tokenURI) external onlyOperator {
        bytes memory message = abi.encode(MessageType.BATCH_MINT, _nft, _to, _tokenURI);
        address[] memory allowedRelayerAddresses = new address[](1);
        allowedRelayerAddresses[0] = relayer;
        TeleporterMessageInput memory input = TeleporterMessageInput({
            destinationBlockchainID: remoteBlockchainId,
            destinationAddress: remoteFactory,
            feeInfo: TeleporterFeeInfo({
                feeTokenAddress: address(0),
                amount: 0
            }),
            requiredGasLimit: remoteGasLimit,
            allowedRelayerAddresses: allowedRelayerAddresses,
            message: message
        });
        teleporterMessenger.sendCrossChainMessage(input);
    }

    function batchBurnRemote(address[] memory _nft, uint256[] memory _tokenId) external onlyOperator {
        bytes memory message = abi.encode(MessageType.BATCH_BURN, _nft, _tokenId);
        address[] memory allowedRelayerAddresses = new address[](1);
        allowedRelayerAddresses[0] = relayer;
        TeleporterMessageInput memory input = TeleporterMessageInput({
            destinationBlockchainID: remoteBlockchainId,
            destinationAddress: remoteFactory,
            feeInfo: TeleporterFeeInfo({
                feeTokenAddress: address(0),
                amount: 0
            }),
            requiredGasLimit: remoteGasLimit,
            allowedRelayerAddresses: allowedRelayerAddresses,
            message: message
        });
        teleporterMessenger.sendCrossChainMessage(input);
    }

    function batchGameTransferRemote(address[] memory _nft, address[] memory _from, address[] memory _to, uint256[] memory _tokenId) external onlyOperator {
        bytes memory message = abi.encode(MessageType.BATCH_GAME_TRANSFER, _nft, _from, _to, _tokenId);
        address[] memory allowedRelayerAddresses = new address[](1);
        allowedRelayerAddresses[0] = relayer;
        TeleporterMessageInput memory input = TeleporterMessageInput({
            destinationBlockchainID: remoteBlockchainId,
            destinationAddress: remoteFactory,
            feeInfo: TeleporterFeeInfo({
                feeTokenAddress: address(0),
                amount: 0
            }),
            requiredGasLimit: remoteGasLimit,
            allowedRelayerAddresses: allowedRelayerAddresses,
            message: message
        });
        teleporterMessenger.sendCrossChainMessage(input);
    }

    function _createNft(string memory _gameId, string memory _name, string memory _symbol) internal {
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

    function _batchMint(address[] memory _nft, address[] memory _to, string[] memory _tokenURI) internal {
        for (uint256 i = 0; i < _to.length; i++) {
            mint(_nft[i], _to[i], _tokenURI[i]);
        }
    }

    function burn(address _nft, uint256 _tokenId) public onlyOperator {
        GameNft(_nft).burn(_tokenId);
    }

    function _batchBurn(address[] memory _nft, uint256[] memory _tokenId) internal {
        for (uint256 i = 0; i < _nft.length; i++) {
            burn(_nft[i], _tokenId[i]);
        }
    }

    function gameTransfer(address _nft, address _from, address _to, uint256 _tokenId) public onlyOperator {
        GameNft(_nft).gameTransfer(_from, _to, _tokenId);
    }

    function _batchGameTransfer(address[] memory _nft, address[] memory _from, address[] memory _to, uint256[] memory _tokenId) internal {
        for (uint256 i = 0; i < _from.length; i++) {
            gameTransfer(_nft[i], _from[i], _to[i], _tokenId[i]);
        }
    }

    function receiveTeleporterMessage(
        bytes32 sourceBlockchainID,
        address originSenderAddress,
        bytes calldata message
    ) external {
        require(msg.sender == address(teleporterMessenger), "GameNftFactory: caller is not the teleporter messenger");
        require(originSenderAddress == remoteFactory, "GameNftFactory: origin sender is not the remote factory");
        require(sourceBlockchainID == remoteBlockchainId, "GameNftFactory: source blockchain ID is not the remote blockchain ID");
        (MessageType messageType, bytes memory data) = abi.decode(message, (MessageType, bytes));
        
        if (messageType == MessageType.CREATE_NFT) {
            (string memory gameId, string memory name, string memory symbol) = abi.decode(data, (string, string, string));
            _createNft(gameId, name, symbol);
        } else if (messageType == MessageType.BATCH_MINT) {
            (address[] memory _nft, address[] memory _to, string[] memory _tokenURI) = abi.decode(data, (address[], address[], string[]));
            _batchMint(_nft, _to, _tokenURI);
        } else if (messageType == MessageType.BATCH_BURN) {
            (address[] memory _nft, uint256[] memory _tokenId) = abi.decode(data, (address[], uint256[]));
            _batchBurn(_nft, _tokenId);
        } else if (messageType == MessageType.BATCH_GAME_TRANSFER) {
            (address[] memory _nft, address[] memory _from, address[] memory _to, uint256[] memory _tokenId) = abi.decode(data, (address[], address[], address[], uint256[]));
            _batchGameTransfer(_nft, _from, _to, _tokenId);
        }
    }

    function nftInfo(address _nft) external view returns(address tokenAddress, string memory gameId, string memory name, string memory symbol, uint256 totalSupply, uint256 holderCount) {
        return (address(_nft), nftGameId[_nft], GameNft(_nft).name(), GameNft(_nft).symbol(), GameNft(_nft).totalSupply(), nftHolderCount(_nft));
    }

    function nftHolderCount(address _nft) public view returns(uint256) {
        return GameNft(_nft).holderCount();
    }

    function configTeleporterMessenger(address _teleporterMessenger) external onlyOwner {
        teleporterMessenger = ITeleporterMessenger(_teleporterMessenger);
    }

    function configRelayer(address _relayer) external onlyOwner {
        relayer = _relayer;
    }

    function configRemoteBlockchainId(bytes32 _remoteBlockchainId) external onlyOwner {
        remoteBlockchainId = _remoteBlockchainId;
    }

    function configRemoteGasLimit(uint256 _remoteGasLimit) external onlyOwner {
        remoteGasLimit = _remoteGasLimit;
    }

    function configRemoteFactory(address _remoteFactory) external onlyOwner {
        remoteFactory = _remoteFactory;
    }

    function configOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function configNftImplementation(address _implementation) external onlyOwner {
        nftImplementation = _implementation;
    }
}

