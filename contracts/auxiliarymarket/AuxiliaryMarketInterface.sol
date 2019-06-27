pragma solidity ^0.5.8;

contract AuxiliaryMarketInterface{

    //Events
    event Transfer (address, address, uint256);

    //User Functions
    function getCurrentPrice() external returns(uint256);
    function getBalance(address) external view returns(uint256);
    function sellAsset(uint256) external returns(uint256);
    function buyAsset(uint256) external returns(uint256);

    //Auxiliary Market Functions
    function transferZap(address, address, uint256) external returns (bool);
    function transferSubToken(address, address, uint256) external returns (bool);

    //MainMakret Interaction Functions
    function sendToMainMarket(address, address, uint256) external returns (bool);
    function getFromMainMarket(address, address, uint256) external returns (bool);

}