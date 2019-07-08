pragma solidity ^0.5.8;

import "../mainmarket/MainMarket.sol";
import "./AuxiliaryMarketInterface.sol";
import "./Helper.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../token/ZapToken.sol";
import "./AuxiliaryMarketTokenInterface.sol";

contract AuxiliaryMarket is Helper{
    using SafeMath for uint256;

    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    AuxiliaryMarketTokenInterface public auxiliaryMarketToken;

    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        address mainMarketAddr = coordinator.getContract("MAINMARKET");
        auxiliaryMarketToken = AuxiliaryMarketTokenInterface(coordinator.getContract("AUXILIARYMARKET_TOKEN"));
        zapToken = ZapToken(coordinator.getContract("ZAP_TOKEN"));
    }


    uint[] public assetPrices = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,
    10000, 11000, 12000, 13000, 14000, 15000, 16000];

    // Price of $0.01 USD
    uint zap = 28449300676025;

    function random() public returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, assetPrices)));
    }

    struct AuxMarketHolder{
        uint256 avgPrice;
        uint256 subTokensOwned;

    }

    //Mapping of holders
    mapping (address => AuxMarketHolder) holders;

    // Transfer zap from holder to market
    function buyAuxiliaryToken(uint256 _quantity) public payable {
        // //TODO: Exchange AuxMarketToken for Zap

        // get current price
        uint256 _currentAssetPrice = getCurrentPrice() * zap;
        uint256 _totalWei = _currentAssetPrice * _quantity;

        // check how much zap received // transfer from balalnce of(). use zap coordinator to get address of zap token contract
        require(getBalance(address(this)) * zap > _totalWei, "Not enough Zap in Wallet");
        // transfer equivalent amount in subtoken
        zapToken.transferFrom(msg.sender, address(this));
        // holder struct with price bought in and amount of subtokens
        uint256 avgPrice =
        (_totalWei + holders[msg.sender].avgPrice * holders[msg.sender].subTokensOwned).div(
            (_quantity + holders[msg.sender].subTokensOwned)
        );
        uint256 quantity = holders[msg.sender].subTokensOwned + _quantity;

        AuxMarketHolder memory holder = AuxMarketHolder(avgPrice, quantity);
        holders[msg.sender] = holder;

        // Map holder msg.sender to key: value being holder struct
    }

    function sellAuxiliaryToken(uint256 _quantity) public payable {
        // Sends Zap to Main Market when asset is sold at loss
        // function sendToMainMarket() private {}
        // Sends Zap to Main Market when asset is sold at gain
        // function getFromMainMarket() private {}
    }

    // Grabs current price of asset
    function getCurrentPrice() public returns (uint) {
        uint256 num = 16;
        return assetPrices[random() % num];
    }
    // Grabs User's current balance of SubTokens
    function getBalance(address _address) public view returns (uint256) {
        return zapToken.balanceOf(_address);
    }

    function allocateZap(uint256 amount) public {
        zapToken.allocate(address(this), amount);
    }

    function testZapBalance() public view returns (uint256) {
        return zapToken.balanceOf(address(this));
    }


    function test() public returns(uint256){
       return holders[msg.sender].avgPrice;
    }
}