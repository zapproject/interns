pragma solidity ^0.5.8;

contract AuxiliaryMarketInterface{
    function buy(uint256) public;
    function sell(uint256) public;
    function getZapBalance(address) public view returns(uint256);
    function allocateZap(uint256) public;
    function getAMTBalance(address) public view returns(uint256);
    function callback(uint256 id, string calldata response1, string calldata response2, string calldata response3, string calldata response4) external;
}