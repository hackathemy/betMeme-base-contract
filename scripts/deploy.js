// scripts/deploy.js
async function main() {
    const hre = require("hardhat");
    const [deployer] = await hre.ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await deployer.getBalance();
    console.log("Account balance:", balance.toString());

    const BetMeme = await hre.ethers.getContractFactory("BetMeme");
    const betMeme = await BetMeme.deploy();
    await betMeme.deployed();

    console.log("Contract deployed to address:", betMeme.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
