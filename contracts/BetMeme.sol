// contracts/BetMeme.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
contract BetMeme {

    struct Game {
        uint256 gameId;
        uint256 startTime;
        uint256 duration;
        uint256 markedPrice;
        uint256 lastPrice;
        uint256 minAmount;
        uint256 upAmount;
        uint256 downAmount;
        uint256 prizeAmount;
        bool isEnded;
        IERC20 token;
        address[] betUsers;
    }

    struct UserBet {
        uint256 gameId;
        bool betUp;
        uint256 amount;
        string status;
    }

    uint256 public gameCounter;
    address public burnAddress = address(0xdead);

    mapping(uint256 => Game) public games;
    mapping(address => mapping(uint256 => UserBet)) public userBets;

    address public constant WETH = 0x24fe7807089e321395172633aA9c4bBa4Ac4a357; // 하드코딩된 WETH 주소
    address public immutable factory = 0x3579357Ffc5B1b15778a004709Be5bb6B10B88b7;


    event GameCreated(uint256 gameId, address tokenAddress);
    event BetPlaced(address indexed user, uint256 gameId, bool betUp, uint256 amount);
    event GameEnded(uint256 gameId, uint256 lastPrice);
    event Claimed(address indexed user, uint256 gameId, uint256 reward);


    function createGame(
        uint256 duration,
        uint256 minAmount,
        address tokenAddress
    ) external {
        require(duration > 0, "Duration must be greater than 0");
        require(minAmount > 0, "Minimum bet amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        games[gameCounter] = Game({
            gameId: gameCounter,
            startTime: block.timestamp,
            duration: duration,
            markedPrice: getTokenPrice(tokenAddress),
            lastPrice: 0,
            minAmount: minAmount,
            upAmount: 0,
            downAmount: 0,
            prizeAmount: 0,
            isEnded: false,
            token: token,
            betUsers: new address[](0)
        });

        emit GameCreated(gameCounter, tokenAddress);
        gameCounter++;
    }

    function bet(uint256 gameId, bool betUp, uint256 amount) external {
        Game storage game = games[gameId];
        require(game.startTime != 0, "Game does not exist");
        //require(block.timestamp <= game.startTime + game.duration, "Betting period has ended");
        require(amount >= game.minAmount, "Bet amount too low");
        require(game.token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        require(game.isEnded == false, "Game already ended");
        UserBet storage userBet = userBets[msg.sender][gameId];
        require(userBets[msg.sender][gameId].amount == 0, "User already placed bet");


        userBet.gameId = gameId;
        userBet.betUp = betUp;
        userBet.amount += amount;
        userBet.status = "PENDING";

        if (betUp) {
            game.upAmount += amount;
        } else {
            game.downAmount += amount;
        }

        game.prizeAmount += amount;
        game.betUsers.push(msg.sender);

        emit BetPlaced(msg.sender, gameId, betUp, amount);
    }

    function endGame(uint256 gameId) external {
        Game storage game = games[gameId];
        //require(block.timestamp > game.startTime + game.duration + 60, "Game duration not yet completed");
        require(game.startTime != 0, "Game does not exist");
        //require(game.isEnded == false, "Game already ended");
        uint256 lastPrice = getTokenPrice(address(game.token));
        game.lastPrice = lastPrice;
        uint256 prizePool = game.prizeAmount;

        if (game.lastPrice >= game.markedPrice) {
            distributeRewards(gameId, game.upAmount, prizePool, true);
        } else {
            distributeRewards(gameId, game.downAmount, prizePool, false);
        }

        emit GameEnded(gameId, lastPrice);
        game.isEnded = true;
    }

    function distributeRewards(uint256 gameId, uint256 totalBet, uint256 prizePool, bool isBetUp) internal {

        Game storage game = games[gameId];

        for (uint256 i = 0; i < game.betUsers.length; i++) {
            address user = game.betUsers[i];
            UserBet storage userBet = userBets[user][gameId];
            uint256 reward = 0;
            if (userBet.betUp == isBetUp) {
                reward = (userBet.amount * prizePool) / totalBet;
                game.token.transfer(user, reward);
                userBet.status = "WON";
            } else {
                reward = (userBet.amount * prizePool) / totalBet;
                game.token.transfer(user, reward);
                userBet.status ="LOST";
            }
            emit Claimed(user, gameId, reward);

        }
    }

    function getGame(uint256 gameId) external view returns (Game memory) {
        return games[gameId];
    }

    function getUserBet(uint256 gameId) external view returns (UserBet memory) {
        return userBets[msg.sender][gameId];
    }

    function getGameList() external view returns (Game[] memory) {
        Game[] memory gameList = new Game[](gameCounter);
        for (uint256 i = 0; i < gameCounter; i++) {
            gameList[i] = games[i];
        }
        return gameList;
    }

    function getEndedGameList() external view returns (Game[] memory) {
        Game[] memory gameList = new Game[](gameCounter);
        uint256 endedGameCount = 0;
        for (uint256 i = 0; i < gameCounter; i++) {
            if (games[i].isEnded) {
                gameList[endedGameCount] = games[i];
                endedGameCount++;
            }
        }
        return gameList;
    }

    function getActiveGameList() external view returns (Game[] memory) {
        Game[] memory gameList = new Game[](gameCounter);
        uint256 activeGameCount = 0;
        for (uint256 i = 0; i < gameCounter; i++) {
            if (!games[i].isEnded) {
                gameList[activeGameCount] = games[i];
                activeGameCount++;
            }
        }
        return gameList;
    }

    function getUsersBetList() external view returns (UserBet[] memory) {
        UserBet[] memory userBetList = new UserBet[](gameCounter);
        for (uint256 i = 0; i < gameCounter; i++) {
            userBetList[i] = userBets[msg.sender][i];
        }
        return userBetList;
    }

    function getPair(address tokenA, address tokenB) internal view returns (address pair) {
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "Pair not found");
    }

    function getReserves(address pair) public view returns (uint112 reserve0, uint112 reserve1) {
        IUniswapV2Pair pairContract = IUniswapV2Pair(pair);
        (reserve0, reserve1, ) = pairContract.getReserves();
    }

    function getTokenPrice(address otherToken) public view returns (uint256 priceWETH) {
        address pairAddress = getPair(WETH, otherToken);
        (uint112 reserveWETH, uint112 reserveOtherToken) = getReserves(pairAddress);

        require(reserveWETH > 0 && reserveOtherToken > 0, "No liquidity in the pool");

        // Calculate price of WETH in terms of otherToken
        priceWETH = (uint256(reserveOtherToken) * 1e18) / uint256(reserveWETH);
    }

}