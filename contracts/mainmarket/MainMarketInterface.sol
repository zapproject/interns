pragma solidity ^0.5.8;

contract MainMarketInterface {

//User Functions
    function buyMMT(address, uint256) external payable returns (uint256);
    function deposit(address, uint256) external payable returns (uint256);
    function withdraw(address, uint256) external returns (uint256);

//Main Market Functions
    function payFee(address, uint256) external payable returns (uint256);
    function getZapPrice() external view returns (uint256);
    function auxiliaryMarketExists(address) external view returns (bool);

}
