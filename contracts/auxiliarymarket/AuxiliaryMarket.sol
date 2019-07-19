pragma solidity ^0.5.8;

import "../helpers/SafeMath.sol";
import "../mainmarket/MainMarket.sol";
import "./AuxiliaryMarketInterface.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../token/ZapToken.sol";
import "./AuxiliaryMarketTokenInterface.sol";

contract AuxiliaryMarket is AuxiliaryMarketInterface {
    using SafeMath for uint256;

    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    MainMarket public mainMarket;
    AuxiliaryMarketTokenInterface public auxiliaryMarketToken;
    MainMarket public mainMaket;
    // uint256 public auxTokenPrice; //in wei might not need

    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        address mainMarketAddr = coordinator.getContract("MAINMARKET");
        mainMarket = MainMarket(mainMarketAddr);
        auxiliaryMarketToken = AuxiliaryMarketTokenInterface(coordinator.getContract("AUXILIARYMARKET_TOKEN"));
        zapToken = ZapToken(coordinator.getContract("ZAP_TOKEN"));
    }

    //asset prices in wei
    uint[] public assetPrices = [3213875942658800128, 6427751885317600256, 9641627827976400896,
    12855503770635200512, 16069379713294000128, 19283255655952801792, 22497131598611599360,
    25711007541270401024, 28924883483929198592, 32138759426588000256, 35352635369246801920,
    38566511311905603584, 41780387254564397056, 44994263197223198720, 48208139139882000384,
    51422015082540802048];

    // Ethereum Wei in One Zap
    uint zapInWei = 28449300676025;
    // Precision of AuxMarketToken (18 Decimals)
    uint precision = 10 ** 18;
    // weiZap in One Zap
    uint weiZap = precision;
    // WeiZap in One Ethereum Wei
    uint weiInWeiZap = weiZap.div(zapInWei);

    function random() public returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, assetPrices)));
    }

    struct AuxMarketHolder{
        uint256 avgPrice;
        uint256 subTokensOwned;
    }

    //Mapping of holders
    mapping (address => AuxMarketHolder) holders;

      //@_quantity is auxwei
    // Transfer zap from holder to market

    function buy(uint256 _quantity) public returns(uint256){
        // get current price in wei
        uint256 totalWeiCost = 51422015082540802048/precision * _quantity; //Change to SafeMath

        //turn price from wei to weiZap
        uint256 totalWeiZap = totalWeiCost * weiInWeiZap;
        require(getBalance(msg.sender) > totalWeiZap, "Not enough Zap in Wallet");
        // send the _quantity of aux token to buyer
        auxiliaryMarketToken.transfer(msg.sender, _quantity);
        //get zap from buyer
        zapToken.transferFrom(msg.sender, address(this), totalWeiZap);
        address mainMarketAddr = coordinator.getContract("MAINMARKET");
        zapToken.transfer(mainMarketAddr, totalWeiZap);

        AuxMarketHolder memory holder = holders[msg.sender];
        uint256 newTotalTokens = holder.subTokensOwned.add(_quantity);
        // holder struct with price bought in and amount of subtokens
        uint256 avgPrice = (totalWeiCost + holder.avgPrice * holder.subTokensOwned).div(newTotalTokens);

        holder.avgPrice = avgPrice;
        holder.subTokensOwned = newTotalTokens;

        return totalWeiZap;
        // Map holder msg.sender to key: value being holder struct
    }

    function sell(uint256 _quantity) public hasApprovedAMT(_quantity) returns(uint256) {
        address mainMarketAddr = coordinator.getContract("MAINMARKET");
        require(_quantity < auxiliaryMarketToken.balanceOf(msg.sender), "You do not own enough AMT");

        uint256 totalWeiCost = 3213875942658800128/precision * _quantity; //Change to SafeMath
        uint256 totalWeiZap = totalWeiCost * weiInWeiZap; //Change to SafeMath

        require(getBalance(mainMarketAddr) > totalWeiZap, "Not enough Zap in Wallet");

        mainMarket.withdraw(totalWeiZap, msg.sender);

        auxiliaryMarketToken.transferFrom(msg.sender, address(this), _quantity);

        return totalWeiZap;
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
        zapToken.allocate(msg.sender, amount);
    }

    function getAMTBalance(address _owner) public view returns(uint256) {
        return auxiliaryMarketToken.balanceOf(_owner);
    }

    //Modifiers
    //Requires User to approve the Main Market Contract an allowance to spend amt on their behalf
    modifier hasApprovedAMT(uint256 amount) {
        uint256 allowance = auxiliaryMarketToken.allowance(msg.sender, address(this));
        require (allowance >= amount, "Not enough AMT allowance to be spent by Aux Contract");
        _;
    }
}
