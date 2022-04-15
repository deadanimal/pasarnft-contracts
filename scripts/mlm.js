const hre = require("hardhat");

async function main() {

    const MLMRegistrar = await hre.ethers.getContractFactory("MLMRegistrar");
    const MLMRegistrarContract = await MLMRegistrar.deploy();
    await MLMRegistrarContract.deployed();
    // const MLMRegistrarContract = await MLMRegistrar.attach("0x4797f8053692128A9F6638a472fAB47b4775247e");
    console.log("MLMRegistrar deployed to:", MLMRegistrarContract.address);

    // let transactTx = await MLMRegistrarContract.register("0xF3F07bF98cd2D5B57ED39206F657E4eB1f477B45");
    // await transactTx.wait();   

    // let registered = await MLMRegistrarContract.registered("0xdb0E2ed28cd71b5620aa4ECCd3947B5E998D0313")
    // console.log("registered: ", registered)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
