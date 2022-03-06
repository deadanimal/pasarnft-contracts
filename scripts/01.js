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
  const market721 = await Market721.deploy();
  await market721.deployed(); 
  console.log("Market721 deployed to:", market721.address);   

  const MinterFactory721 = await hre.ethers.getContractFactory("MinterFactory721");
  const minterFactory721 = await MinterFactory721.deploy();
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
