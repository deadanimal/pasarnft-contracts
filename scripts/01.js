const hre = require("hardhat");

async function main() {

  const PasarToken = await hre.ethers.getContractFactory("PasarToken");
  const pasarToken = await PasarToken.deploy();
  await pasarToken.deployed();
  console.log("PasarToken deployed to:", pasarToken.address);

  const PasarGovernor = await hre.ethers.getContractFactory("PasarGovernor");
  const pasarGovernor = await PasarGovernor.deploy(pasarToken.address);
  await pasarGovernor.deployed(); 
  console.log("PasarGovernor deployed to:", pasarGovernor.address); 

  const Market721 = await hre.ethers.getContractFactory("Market721");
  const market721 = await Market721.deploy(pasarGovernor.address);
  await market721.deployed(); 
  console.log("Market721 deployed to:", market721.address);   

  const Minter721 = await hre.ethers.getContractFactory("Minter721");
  const minter721 = await Minter721.deploy(pasarGovernor.address);
  await minter721.deployed(); 
  console.log("Minter721 deployed to:", minter721.address);   

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
