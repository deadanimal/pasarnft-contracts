require("@nomiclabs/hardhat-waffle");
require('hardhat-abi-exporter');


const dotenv = require("dotenv")
dotenv.config()


task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});



const ACC_01_SECRET = process.env.ACC_01_SECRET;
const MLM_SECRET = process.env.MLM_SECRET;

module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  abiExporter: {
    path: './data/abi',
    runOnCompile: true,
    clear: true,
    flat: true,
    spacing: 2,
    pretty: true,
  },  
  networks: {    
    bifrost: {
      url: 'https://rpc.chainbifrost.com/',
      accounts: [`${ACC_01_SECRET}`]
    },   
    
    mlm: {
      url: 'https://rpc.chainbifrost.com/',
      accounts: [`${MLM_SECRET}`]
    },      
  },
};
