pragma solidity ^0.5.8;

contract AuxiliaryMarketInterface{
    function buy(uint256) public returns(uint256);
    function sell(uint256) public returns(uint256);
    function getCurrentPrice() public returns(uint256);
    function getZapBalance(address) public view returns(uint256);
    function allocateZap(uint256) public;
    function getAMTBalance(address) public view returns(uint256);
    function pow(uint256 num, uint256 exp) public returns(uint256);
}