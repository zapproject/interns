pragma solidity ^0.5.8;

contract Helper{

    uint[] public assetPrices = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,
    10000, 11000, 12000, 13000, 14000, 15000, 16000];

    // Picks Random Price for asset in asset list
    function random() external returns (uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now , assetPrices)));
    }

    // Converts amount to wei to help with non-float numbers
    function toWei(uint amount) external returns (uint256) {
        return amount * 1000000000000000000;
    }

    // Converts amount to cents. i.e. 1 penny = 100
    function toUSD(uint amount) external returns (uint256) {
        return amount * 100;
    }
}