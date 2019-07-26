pragma solidity ^0.5.8;

import "../helpers/SafeMath.sol";
import "../mainmarket/MainMarketInterface.sol";
import "./AuxiliaryMarketInterface.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../token/ZapToken.sol";
import "./AuxiliaryMarketTokenInterface.sol";

contract AuxiliaryMarket is AuxiliaryMarketInterface {
    using SafeMath for uint256;

    struct AuxMarketHolder{
        uint256 avgPrice;
        uint256 tokens;
    }

    //Mapping of holders
    mapping (address => AuxMarketHolder) holders;

    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    MainMarketInterface public mainMarket;
    AuxiliaryMarketTokenInterface public auxiliaryMarketToken;
    // uint256 public auxTokenPrice; //in wei might not need

    //Asset prices in wei
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


    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        mainMarket = MainMarketInterface(coordinator.getContract("MAINMARKET"));
        auxiliaryMarketToken = AuxiliaryMarketTokenInterface(coordinator.getContract("AUXILIARYMARKET_TOKEN"));
        zapToken = ZapToken(coordinator.getContract("ZAP_TOKEN"));
    }

    //@_quantity is auxwei
    // Transfer zap from holder to market
    function buy(uint256 _quantity) public returns(uint256){
        uint256 totalWeiZap = weiToWeiZap(51422015082540802048, _quantity);
        require(getZapBalance(msg.sender) > totalWeiZap, "Not enough Zap in Wallet");
        exchange(totalWeiZap, _quantity);
        calculateAveragePrice(51422015082540802048, _quantity);
        return totalWeiZap;
    }

    function sell(uint256 _quantity) public hasApprovedAMT(_quantity) hasEnoughAMT(_quantity) returns(uint256) {
        uint256 totalWeiZap = weiToWeiZap(3213875942658800128, _quantity);
        require(getZapBalance(address(mainMarket)) > totalWeiZap, "Not enough Zap in MainMarket");
        mainMarket.withdraw(totalWeiZap, msg.sender);
        auxiliaryMarketToken.transferFrom(msg.sender, address(this), _quantity);
        return totalWeiZap;
    }

    //Grabs current price of asset
    function getCurrentPrice() public returns (uint) {
        uint256 num = 16;
        return assetPrices[random() % num];
    }

    //Grabs User's current balance of Zap Balance
    function getZapBalance(address _address) public view returns (uint256) {
        return zapToken.balanceOf(_address);
    }

    function allocateZap(uint256 amount) public {
        zapToken.allocate(msg.sender, amount);
    }

    function getAMTBalance(address _owner) public view returns(uint256) {
        return auxiliaryMarketToken.balanceOf(_owner);
    }

    //Private
    function exchange(uint256 weiZapQuantity, uint256 auxWeiQuantity) private {
        auxiliaryMarketToken.transfer(msg.sender, auxWeiQuantity);
        zapToken.transferFrom(msg.sender, address(this), weiZapQuantity);
        zapToken.transfer(address(mainMarket), weiZapQuantity);
    }

    function weiToWeiZap(uint256 currentPriceinWei, uint256 _quantity) private returns(uint256) {
        return currentPriceinWei.div(precision).mul(_quantity).mul(weiInWeiZap);
    }

    function calculateAveragePrice(uint256 currentPriceinWei, uint256 _quantity) private {
        uint256 totalWeiCost = currentPriceinWei.div(precision).mul(_quantity); 
        AuxMarketHolder memory holder = holders[msg.sender];
        uint256 newTotalTokens = holder.tokens.add(_quantity);
        uint256 avgPrice = (totalWeiCost.add(holder.avgPrice).mul(holder.tokens)).div(newTotalTokens);
        holder.avgPrice = avgPrice;
        holder.tokens = newTotalTokens;
    }

    //Helpers 
    function random() public returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, assetPrices)));
    }

    function pow(uint256 num, uint256 exp) public returns(uint256) {
        uint256 product = 1;
        for (uint i = 0; i < exp; i++){
            product = product.mul(num);
        }
        return product;
    }

    //Modifiers
    //Requires User to approve the Auxiliary Market Contract an allowance to spend amt on their behalf
    modifier hasApprovedAMT(uint256 amount) {
        uint256 allowance = auxiliaryMarketToken.allowance(msg.sender, address(this));
        require (allowance >= amount, "Not enough AMT allowance to be spent by Auxiliary Market Contract");
        _;
    }

    //Requires User to have enough Zap in their account
    modifier hasEnoughZap(uint256 amount) {
        uint256 zapBalance = zapToken.balanceOf(msg.sender);
        require (zapBalance >= amount, "Not enough Zap in wallet");
        _;
    }

    modifier hasEnoughAMT(uint256 amount) {
        uint256 amtBalance = auxiliaryMarketToken.balanceOf(msg.sender);
        require (amtBalance >= amount, "Not enough AMT in wallet");
        _;
    }
}
