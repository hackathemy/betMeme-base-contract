const { task } = require("hardhat/config");

// hardhat.config.js
task("createGame", "Creates a new game")
    .addParam("markedprice", "The marked price of the game") // changed to lowercase
    .addParam("duration", "The duration of the game in seconds")
    .addParam("minamount", "The minimum amount to bet") // changed to lowercase
    .addParam("tokenaddress", "The address of the token") // changed to lowercase
    .setAction(async ({ markedprice, duration, minamount, tokenaddress }, hre) => {
        console.log(markedprice, duration, minamount, tokenaddress)
        const [deployer] = await hre.ethers.getSigners();
        const BetMeme = await hre.ethers.getContractFactory("BetMeme");
        const betMeme = await BetMeme.deploy();
        await betMeme.deployed();
        await betMeme.createGame(markedprice, duration, minamount, tokenaddress);
    });

task("bet", "Places a bet on a game")
    .addParam("gameid", "The ID of the game") // changed to lowercase
    .addParam("betup", "Bet up or down (true/false)") // changed to lowercase
    .addParam("amount", "The amount to bet")
    .setAction(async ({ gameid, betup, amount }, hre) => {
        const [deployer] = await hre.ethers.getSigners();
        const BetMeme = await hre.ethers.getContractFactory("BetMeme");
        const betMeme = await BetMeme.deploy();
        await betMeme.deployed();
        await betMeme.bet(gameid, betup, amount);
    });

task("endGame", "Ends an existing game")
    .addParam("gameid", "The ID of the game") // changed to lowercase
    .addParam("lastprice", "The last price at the end of the game") // changed to lowercase
    .setAction(async ({ gameid, lastprice }, hre) => {
        const [deployer] = await hre.ethers.getSigners();
        const BetMeme = await hre.ethers.getContractFactory("BetMeme");
        const betMeme = await BetMeme.deploy();
        await betMeme.deployed();
        await betMeme.endGame(gameid, lastprice);
    });
module.exports = {};
