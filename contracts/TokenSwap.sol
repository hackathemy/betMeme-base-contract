/*
// contracts/TokenSwap.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is Ownable {
    IUniswapV2Router02 public uniswapRouter;
    IERC20 public token;
    address public WETH;

    constructor(address _token, address _router) Ownable(msg.sender) {
        token = IERC20(_token);
        uniswapRouter = IUniswapV2Router02(_router);
        WETH = _token;
    }

    function swapETHForTokens(uint256 tokenAmount) external payable {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(token);

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            tokenAmount,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount, uint256 ethAmount) external {
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Transfer failed");
        require(token.approve(address(uniswapRouter), tokenAmount), "Approve failed");

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = WETH;

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            ethAmount,
            path,
            msg.sender,
            block.timestamp
        );
    }

    receive() external payable {}
}
*/
