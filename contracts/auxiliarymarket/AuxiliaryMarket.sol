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

    event Results(uint256 zapInWei, uint256 assetInWei, string zapInUsd, string assetInUsd);
    event Bought(address sender, uint256 totalWeiZap, uint256 amt);
    event Sold(address sender, uint256 totalWeiZap, uint256 amt);

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
    uint256 totalWeiZap;

    address public oracleAddress;
    bytes32 assetMarketEndpoint;
    bytes32 zapSymbol = 0x5a41500000000000000000000000000000000000000000000000000000000000;


    constructor(address _zapCoor, address _oracleAddress, bytes32 _endpoint, bytes32 _assetSymbol, string memory _assetClass) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        dispatch = DispatchInterface(coordinator.getContract("DISPATCH"));
        mainMarket = MainMarketInterface(coordinator.getContract("MAINMARKET"));
        auxiliaryMarketToken = AuxiliaryMarketTokenInterface(coordinator.getContract("AUXILIARYMARKET_TOKEN"));
        zapToken = ZapToken(coordinator.getContract("ZAP_TOKEN"));
        bondage = BondageInterface(coordinator.getContract("BONDAGE"));
        assetSymbol = _assetSymbol;
        assetClass = _assetClass;
        oracleAddress = _oracleAddress;
        assetMarketEndpoint = _endpoint;
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
        bytes32Arr[0] = zapSymbol;
        bytes32Arr[1] = assetSymbol;
        bondage.bond(oracleAddress, assetMarketEndpoint, 1);
        uint256 id = dispatch.query(oracleAddress, assetClass, assetMarketEndpoint, bytes32Arr);
        Order memory order = Order(msg.sender, _quantity, action);
        queries[id] = order;
        return id;
    }

    function callback(
        uint256 id, 
        string calldata response1, 
        string calldata response2, 
        string calldata response3, 
        string calldata response4
    ) 
    external onlyDispatch 
    {
        Order storage order = queries[id];
        address sender = order.sender;
        uint256 _quantity = order._quantity;
        Action action = order.action;
        uint256 zapInWei = stringToUint(response1);
        uint256 currentAssetPrice = stringToUint(response2);
        emit Results(zapInWei, currentAssetPrice, response3, response4);
        uint256 weiInWeiZap = weiZap.div(zapInWei);
        totalWeiZap = weiToWeiZap(currentAssetPrice, weiInWeiZap, _quantity);
        exchange(totalWeiZap, _quantity, sender, action);
    }

    function exchange(uint256 weiZap, uint256 weiAux, address sender, Action action) private {
        if(action == Action.BUY) {
            _buy(totalWeiZap, weiAux, sender);
        }
        else if(action == Action.SELL) {
            _sell(totalWeiZap, weiAux, sender);
        }
        else {
            revert("Invalid Action");
        }
    }

    function _sell(uint256 weiZap, uint256 weiAux, address sender) private {
        mainMarket.withdraw(weiZap, sender);
        auxiliaryMarketToken.transferFrom(sender, address(this), weiAux);
        uint256 amt = getAMTBalance(sender);
        emit Sold(sender, weiZap, amt);
    }

    function _buy(uint256 weiZap, uint256 weiAux, address sender) private {
        require(getZapBalance(address(mainMarket)) > totalWeiZap, "Not enough Zap in MainMarket");
        auxiliaryMarketToken.transfer(sender, weiAux);
        zapToken.transferFrom(sender, address(this), weiZap);
        zapToken.transfer(address(mainMarket), weiZap);
        uint256 amt = getAMTBalance(sender);
        emit Bought(sender, weiZap, amt);
    }

    function stringToUint(string memory s) private pure returns (uint) {
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

    function weiToWeiZap(uint256 currentPriceinWei, uint256 weiInWeiZap, uint256 _quantity) private view returns(uint256) {
        return currentPriceinWei.div(precision).mul(_quantity).mul(weiInWeiZap);
    }

    function calculateAveragePrice(uint256 currentPriceinWei, uint256 _quantity) private view {
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

    modifier onlyDispatch() {
        address dispatchAddress = coordinator.getContract("DISPATCH");
        require(address(msg.sender)==address(dispatchAddress),"Only accept response from dispatch");
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
