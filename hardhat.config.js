require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      evmVersion: "london",
      optimizer: {
        enabled: false,
        runs: 200
      }
    }
  },
  networks: {
    polygonAmoy: {
      url: "https://polygon-amoy.blockpi.network/v1/rpc/public",
      accounts: [process.env.PK],
      gasPrice: 5e9,
    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.bnbchain.org:8545",
      accounts: [process.env.PK],
    },
    arbSepolia: {
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      accounts: [process.env.PK],
    },
    opSepolia: {
      url: "https://sepolia.optimism.io",
      accounts: [process.env.PK],
    },
    sepolia: {
      url: "https://rpc2.sepolia.org",
      accounts: [process.env.PK],
    },
    fuji: {
      url: 'https://avalanche-fuji-c-chain-rpc.publicnode.com',
      accounts: [process.env.PK],
    },
    plyrTestnet: {
      url: 'https://subnets.avax.network/plyr/testnet/rpc',
      accounts: [process.env.PK],
    },
    polygon: {
      url: 'https://137.rpc.thirdweb.com',
      accounts: [process.env.PK],
    },
    arbitrum: {
      url: 'https://42161.rpc.thirdweb.com',
      accounts: [process.env.PK],
    },
    optimism: {
      url: 'https://10.rpc.thirdweb.com',
      accounts: [process.env.PK],
    },
    bscMainnet: {
      url: 'https://bsc-rpc.publicnode.com',
      accounts: [process.env.PK],
    },
    avalanche: {
      url: 'https://avalanche.blockpi.network/v1/rpc/public',
      accounts: [process.env.PK],
    },
    plyrMainnet: {
      url: "https://subnets.avax.network/plyr/mainnet/rpc",
      accounts: [process.env.PK],
    },
    ethereum: {
      url: 'https://1.rpc.thirdweb.com',
      accounts: [process.env.PK],
    }
  },
  etherscan: {
    apiKey: ''
  }
};
