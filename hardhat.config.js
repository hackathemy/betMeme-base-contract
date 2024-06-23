require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require('dotenv').config();
require("./tasks/bet"); // 추가


// Replace with your actual network configuration
const ALCHEMY_PROJECT_ID = process.env.ALCHEMY_PROJECT_ID;
const PRIVATE_KEY  =process.env.PRIVATE_KEY;
//https://base-sepolia.g.alchemy.com/v2/MVuRquu4XE6nUM1OQLUSNhiGltrtBprf
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    base: {
      url: `https://base-sepolia.g.alchemy.com/v2/${ALCHEMY_PROJECT_ID}`,
      accounts: [`0x${PRIVATE_KEY}`]
    }
  }
};
