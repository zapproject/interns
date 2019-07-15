pragma solidity ^0.5.8;

contract MainMarketInterface {
    function getEquityStake(address) public returns(uint256);
    function depositZap(uint256) public returns (bool);
    function bond(uint256) external returns(uint256);
    function allocateZap(uint256) public;
    function getZapBalance(address) public returns(uint256);
    function getMMTBalance(address) public returns(uint256);
    function withdraw(uint256, address) external returns(uint256);
}