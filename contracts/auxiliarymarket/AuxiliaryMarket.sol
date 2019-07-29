pragma solidity ^0.5.8;

import "../helpers/SafeMath.sol";
import "../mainmarket/MainMarketInterface.sol";
import "../platform/dispatch/Dispatch.sol";
import "./AuxiliaryMarketInterface.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../token/ZapToken.sol";
import "./AuxiliaryMarketTokenInterface.sol";

contract AuxiliaryMarket is AuxiliaryMarketInterface {
    using SafeMath for uint256;

    event Results(string response1, string response2, string response3, string response4);

    struct AuxMarketHolder{
        uint256 avgPrice;
        uint256 tokens;
        Order order;
    }

    struct Order{
        uint256 _quantity;
        Action action;
    }

    enum Action { BUY, SELL }

    mapping (address => AuxMarketHolder) holders;
    mapping (uint256 => address) queries;

    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    MainMarketInterface public mainMarket;
    AuxiliaryMarketTokenInterface public auxiliaryMarketToken;
    DispatchInterface public dispatch;


    uint precision = 10 ** 18;
    uint weiZap = precision;
    bytes32 symbol;
    string assetClass;


    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        dispatch = DispatchInterface(coordinator.getContract("DISPATCH"));
        mainMarket = MainMarketInterface(coordinator.getContract("MAINMARKET"));
        auxiliaryMarketToken = AuxiliaryMarketTokenInterface(coordinator.getContract("AUXILIARYMARKET_TOKEN"));
        zapToken = ZapToken(coordinator.getContract("ZAP_TOKEN"));
        //Assign the Symbol and AssetClass 
        symbol = 0x4254430000000000000000000000000000000000000000000000000000000000;
        assetClass = "cryptocurrency";
    }

    function buy(uint256 _quantity) public{
        uint256 id = executeTransaction(_quantity, "BUY");
        queries[id] = msg.sender;
    }

    function sell(uint256 _quantity) public hasApprovedAMT(_quantity) hasEnoughAMT(_quantity) {
        uint256 id = executeTransaction(_quantity, "SELL");
        queries[id] = msg.sender;
    }

    function executeTransaction(uint256 _quantity, string memory action) private returns (uint256) {
        bytes32 bytes32Quantity = bytes32(_quantity);
        //bytes32 zapSymbol = bytes32("ZAP");
        //bytes32 bytes32Action = bytes32(action);
        //bytes32[] memory params = new bytes32[](3);
        //params = [bytes32Quantity, symbol];
        address oracleAddress = 0x6cb027Db7C5aAd7c181092c80Bdb4a18043a2EBa;
        uint256 id = dispatch.query(oracleAddress, assetClass, 0x4173736574204d61726b65740000000000000000000000000000000000000000, [symbol]);
        return id;
    }

    function callback(uint256 id, string calldata response1, string calldata response2, string calldata response3, string calldata response4) external {
        emit Results(response1, response2, response3, response4);
        address userAddress = queries[id];
        uint256 zapInWei = stringToUint(response1);
        uint256 currentAssetPrice = stringToUint(response2);
        uint256 weiInWeiZap = weiZap.div(zapInWei);
        uint256 _quantity = stringToUint(response3);
        uint256 totalWeiZap = weiToWeiZap(currentAssetPrice, weiInWeiZap, _quantity);
        if(keccak256(bytes(response4)) == keccak256(bytes("BUY"))) {
            require(getZapBalance(userAddress) > totalWeiZap, "Not enough Zap in Wallet");
            exchange(userAddress, totalWeiZap, _quantity);
            calculateAveragePrice(currentAssetPrice, _quantity);
        } 
        else if(keccak256(bytes(response4)) == keccak256(bytes("SELL"))) {
            require(getZapBalance(address(mainMarket)) > totalWeiZap, "Not enough Zap in MainMarket");
            mainMarket.withdraw(totalWeiZap, userAddress);
            auxiliaryMarketToken.transferFrom(userAddress, address(this), _quantity);
        } 
        else {
            revert("Invalid Action");
        }
    }

    function stringToUint(string memory s) public returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            if (b[i] >= 48 && b[i] <= 57) {
                result = result * 10 + (uint(b[i]) - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return result; 
    }

    
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
    function exchange(address addr, uint256 weiZapQuantity, uint256 auxWeiQuantity) private {
        auxiliaryMarketToken.transfer(addr, auxWeiQuantity);
        zapToken.transferFrom(addr, address(this), weiZapQuantity);
        zapToken.transfer(address(mainMarket), weiZapQuantity);
    }

    function weiToWeiZap(uint256 currentPriceinWei, uint256 weiInWeiZap, uint256 _quantity) private returns(uint256) {
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

    //Requires User to have enough AMT in their account to sell
    modifier hasEnoughAMT(uint256 amount) {
        uint256 amtBalance = auxiliaryMarketToken.balanceOf(msg.sender);
        require (amtBalance >= amount, "Not enough AMT in wallet");
        _;
    }
}
