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

    event Results(uint256 response1, uint256 response2, string response3, string response4);

    struct AuxMarketHolder{
        uint256 avgPrice;
        uint256 tokens;
    }

    struct Order{
        address sender;
        uint256 _quantity;
        Action action;
    }

    enum Action { BUY, SELL }

    mapping (address => AuxMarketHolder) holders;
    mapping (uint256 => Order) queries;

    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    MainMarketInterface public mainMarket;
    AuxiliaryMarketTokenInterface public auxiliaryMarketToken;
    DispatchInterface public dispatch;
    BondageInterface public bondage;

    uint precision = 10 ** 18;
    uint weiZap = precision;
    bytes32 assetSymbol;
    string assetClass;


    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        dispatch = DispatchInterface(coordinator.getContract("DISPATCH"));
        mainMarket = MainMarketInterface(coordinator.getContract("MAINMARKET"));
        auxiliaryMarketToken = AuxiliaryMarketTokenInterface(coordinator.getContract("AUXILIARYMARKET_TOKEN"));
        zapToken = ZapToken(coordinator.getContract("ZAP_TOKEN"));
        bondage = BondageInterface(coordinator.getContract("BONDAGE"));
        assetSymbol = 0x4254430000000000000000000000000000000000000000000000000000000000; //BTC
        assetClass = "cryptocurrency";
    }

    function buy(uint256 _quantity) public{
        executeTransaction(_quantity, Action.BUY);
    }

    function sell(uint256 _quantity) public hasApprovedAMT(_quantity) hasEnoughAMT(_quantity) {
        executeTransaction(_quantity, Action.SELL);
    }

    function executeTransaction(uint256 _quantity, Action action) private returns (uint256) {
        address bondageAddress = coordinator.getContract("BONDAGE");
        uint256 auxiliaryContractZapBalance = zapToken.balanceOf(address(this));
        zapToken.approve(bondageAddress, auxiliaryContractZapBalance);
        bytes32[] memory bytes32Arr = new bytes32[](2);
        bytes32 zapSymbol = 0x5a41500000000000000000000000000000000000000000000000000000000000;
        bytes32Arr[0] = zapSymbol;
        bytes32Arr[1] = assetSymbol;
        address oracleAddress = 0xFE892f3a575d76601ddB4D0cDaaaEf087838aDbc;
        bytes32 assetMarketEndpoint = 0x4173736574204d61726b65740000000000000000000000000000000000000000;
        bondage.bond(oracleAddress, assetMarketEndpoint, 1);
        uint256 id = dispatch.query(oracleAddress, assetClass, assetMarketEndpoint, bytes32Arr);
        Order memory order = Order(msg.sender, _quantity, action);
        queries[id] = order;
        return id;
    }

    function callback(uint256 id, string calldata response1, string calldata response2) external {
        Order storage order = queries[id];
        address sender = order.sender;
        uint256 _quantity = order._quantity;
        Action action = order.action;
        uint256 zapInWei = stringToUint(response1);
        uint256 currentAssetPrice = stringToUint(response2);
        emit Results(zapInWei, currentAssetPrice, "NOTAVAILABLE", "NOTAVAILABLE");
        uint256 weiInWeiZap = weiZap.div(zapInWei);
        uint256 totalWeiZap = weiToWeiZap(currentAssetPrice, weiInWeiZap, _quantity);
        if(action == Action.BUY) {
            require(getZapBalance(sender) > totalWeiZap, "Not enough Zap in Wallet");
            exchange(sender, totalWeiZap, _quantity);
            calculateAveragePrice(currentAssetPrice, _quantity);
        }
        else if(action == Action.SELL) {
            require(getZapBalance(address(mainMarket)) > totalWeiZap, "Not enough Zap in MainMarket");
            mainMarket.withdraw(totalWeiZap, sender);
            auxiliaryMarketToken.transferFrom(sender, address(this), _quantity);
        }
        else {
            revert("Invalid Action");
        }
    }

    function stringToUint(string memory s) private returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            if (uint(uint8(b[i])) >= 48 && uint(uint8(b[i])) <= 57) {
                result = result * 10 + (uint(uint8(b[i])) - 48); // bytes and int are not compatible with the operator -.
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
