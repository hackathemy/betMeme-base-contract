const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Deploy WETH9
    const WETH9 = await ethers.getContractFactory("contracts/uniswap/v3-core/WETH9.sol:WETH9");
    const weth9 = await WETH9.deploy();
    await weth9.deployed();
    console.log("WETH9 deployed to:", weth9.address);

    // Deploy UniswapV3Factory
    const UniswapV3Factory = await ethers.getContractFactory("contracts/uniswap/v3-core/UniswapV3Factory.sol:UniswapV3Factory");
    const factory = await UniswapV3Factory.deploy();
    await factory.deployed();
    console.log("UniswapV3Factory deployed to:", factory.address);

    // Deploy SwapRouter
    const SwapRouter = await ethers.getContractFactory("contracts/uniswap/v3-periphery/SwapRouter.sol:SwapRouter");
    const swapRouter = await SwapRouter.deploy(factory.address, weth9.address);
    await swapRouter.deployed();
    console.log("SwapRouter deployed to:", swapRouter.address);

    // Save deployed addresses for later use
    console.log("Deployed addresses:");
    console.log("WETH9:", weth9.address);
    console.log("UniswapV3Factory:", factory.address);
    console.log("SwapRouter:", swapRouter.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
