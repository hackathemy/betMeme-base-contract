// contracts/BetMeme.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BetMeme {
    struct Game {
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
    }

    struct UserBet {
        bool betUp;
        uint256 amount;
    }

    uint256 public gameCounter;
    address public burnAddress = address(0xdead);

    mapping(uint256 => Game) public games;
    mapping(address => mapping(uint256 => UserBet)) public userBets;

    event GameCreated(uint256 gameId, address tokenAddress);
    event BetPlaced(address indexed user, uint256 gameId, bool betUp, uint256 amount);
    event GameEnded(uint256 gameId, uint256 lastPrice);
    event Claimed(address indexed user, uint256 gameId, uint256 reward);

    function createGame(
        uint256 markedPrice,
        uint256 duration,
        uint256 minAmount,
        address tokenAddress
    ) external {
        require(duration > 0, "Duration must be greater than 0");
        require(minAmount > 0, "Minimum bet amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        games[gameCounter] = Game({
            startTime: block.timestamp,
            duration: duration,
            markedPrice: markedPrice,
            lastPrice: 0,
            minAmount: minAmount,
            upAmount: 0,
            downAmount: 0,
            prizeAmount: 0,
            isEnded: false,
            token: token
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

        UserBet storage userBet = userBets[msg.sender][gameId];
        userBet.betUp = betUp;
        userBet.amount += amount;

        if (betUp) {
            game.upAmount += amount;
        } else {
            game.downAmount += amount;
        }

        game.prizeAmount += amount;

        emit BetPlaced(msg.sender, gameId, betUp, amount);
    }

    function endGame(uint256 gameId, uint256 lastPrice) external {
        Game storage game = games[gameId];
        //require(block.timestamp > game.startTime + game.duration + 60, "Game duration not yet completed");
        require(game.startTime != 0, "Game does not exist");
        require(game.isEnded == false, "Game already ended");
        require(lastPrice > 0, "Invalid last price");

        game.lastPrice = lastPrice;
        uint256 prizePool = game.prizeAmount;

        if (game.lastPrice > game.markedPrice) {
            distributeRewards(gameId, game.downAmount, prizePool, false);
        } else {
            distributeRewards(gameId, game.upAmount, prizePool, true);
        }

        emit GameEnded(gameId, lastPrice);
        game.isEnded = true;
    }

    function distributeRewards(uint256 gameId, uint256 totalBet, uint256 prizePool, bool isBetUp) internal {
        if (totalBet == 0) return;  // if no bets, exit early

        Game storage game = games[gameId];

        for (uint256 i = 0; i < gameCounter; i++) {
            UserBet storage userBet = userBets[msg.sender][i];
            if (userBet.betUp == isBetUp && userBet.amount > 0) {
                uint256 userReward = (userBet.amount * prizePool) / totalBet;
                game.token.transfer(msg.sender, userReward);
                emit Claimed(msg.sender, gameId, userReward);
            }
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

}