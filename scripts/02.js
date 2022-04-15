const hre = require("hardhat");

async function main() {

  const marketAddress = "0xa8552297BcC14F5253E5fCF7E841c39c7B137A5f";
  const Market721 = await hre.ethers.getContractFactory("Market721");
  const market721 = await Market721.attach(marketAddress);
  await market721.deployed(); 
  console.log("Market721 deployed to:", market721.address);   

  const minterAddress = "0xf23092F88425AC7a6c8B39bae755EbCFc22D548d";
  const MinterFactory721 = await hre.ethers.getContractFactory("MinterFactory721");
  const minterFactory721 = await MinterFactory721.attach(minterAddress);
  await minterFactory721.deployed(); 
  console.log("MinterFactory721 deployed to:", minterFactory721.address);   

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
