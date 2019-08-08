pragma solidity ^0.5.8;

contract MainMarketInterface {
    function getEquityStake(address) public returns(uint256);
    function depositZap(uint256) public returns (bool);
    function bond(uint256) external returns(uint256);
    function allocateZap(uint256) public;
    function getZapBalance(address) public returns(uint256);
    function getDepositedZap() public returns(uint256);
    function getMMTBalance(address) public returns(uint256);
    function withdraw(uint256, address) external returns(uint256);
    function zapForDots(uint256 dots) public returns (uint256);
    function withdrawFunds(uint256 amount) public;
}