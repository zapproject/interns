pragma solidity ^0.5.8;
import "../platform/registry/RegistryInterface.sol";
import "../platform/bondage/BondageInterface.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../token/ZapToken.sol";
import "../platform/bondage/currentCost/CurrentCostInterface.sol";
import "../lib/ownership/ZapCoordinator.sol";
import "../platform/registry/Registry.sol";
import "../platform/bondage/Bondage.sol";
import "./MainMarketToken.sol";
import "../platform/bondage/currentCost/CurrentCost.sol";
import "./MainMarketInterface.sol";

contract MainMarket is MainMarketInterface {
    using SafeMath for uint256;

    event Bonded(uint256 dots);
    event Unbonded(uint256 dots);


    //tokens represents dots bonded
    struct MainMarketHolder{
        bool initialized;
        uint256 tokens;
        uint256 zapBalance;
        bool bonded;
    }

    mapping (address => MainMarketHolder) holders;
    address[] public holderAddresses;
    uint public holderAddressesLength = 0;


    RegistryInterface public registry;
    BondageInterface public bondage;
    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    MainMarketTokenInterface public mainMarketToken;
    CurrentCostInterface public currentCost;


    bytes32 public endPoint = "Bond";
    int256[] public curve1 = [1,1,1000];
    
    constructor(address _zapCoor) public {

        coordinator = ZapCoordinatorInterface(_zapCoor);

        address bondageAddress = coordinator.getContract("BONDAGE");
        address mainMarketTokenAddress = coordinator.getContract("MAINMARKET_TOKEN");
        address registryAddress = coordinator.getContract("REGISTRY");
        address zapTokenAddress = coordinator.getContract("ZAP_TOKEN");
        address currentCostAddress = coordinator.getContract("CURRENT_COST");


        mainMarketToken = MainMarketTokenInterface(mainMarketTokenAddress);
        bondage = BondageInterface(bondageAddress);
        zapToken = ZapToken(zapTokenAddress);
        registry = RegistryInterface(registryAddress);
        currentCost = CurrentCostInterface(currentCostAddress);


        bytes32 title = "Main market";
        registry.initiateProvider(12345, title);
        registry.initiateProviderCurve(endPoint, curve1, address(0));
    }

    //Gets existing Holder
    //If one does not exists, creates one
    function getHolder(address addr) private returns(MainMarketHolder storage) {
        MainMarketHolder storage holder = holders[msg.sender];
        if(!holder.initialized) {
            holder.initialized = true;
            holder.tokens = 0;
            holder.zapBalance = 0;
            holder.bonded = false;
        }
        return holder;
    }

    //Calculates equity stake based on total Zap in Contract and
    //holders zap balance in Main Market Contract.
    //Decimal Precision may need to be increased in the future because
    //a holder's stake can be less than 1%, even .0003933% if enough
    //users are bonding to it
    function getEquityStake(address holder) public returns (uint256) {
        uint256 totalBonded = bondage.getDotsIssued(address(this), endPoint);
        uint256 holderTotal = mainMarketToken.balanceOf(holder);
        uint256 equityStake = holderTotal.mul(100).div(totalBonded);
        return equityStake;
    }

    //This works for any precision
    //Can be used in the future to increase equity precision
    function percent(uint numerator, uint denominator, uint precision) private returns(uint quotient) {
        // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    //Deposits Zap into Main Market Token Contract and approves Bondage an allowance of
    //zap amount to be used to bond
    function depositZap(uint256 amount) public hasZap(amount) hasApprovedZap(amount) returns (bool) {
        zapToken.transferFrom(msg.sender, address(this), amount);
        MainMarketHolder storage holder = getHolder(msg.sender);
        holder.zapBalance = holder.zapBalance.add(amount);
        address bondageAddr = coordinator.getContract("BONDAGE");
        return zapToken.approve(bondageAddr, amount);
    }

    //Mint MMT to this contract before bonding so MainMarket is
    //able to transfer tokens to User
    function bond(uint256 dots) external hasEnoughZapForDots(dots) returns(uint256) {
        MainMarketHolder storage holder = getHolder(msg.sender);
        uint zapSpent = bondage.bond(address(this), endPoint, dots);
        mainMarketToken.transfer(msg.sender, dots);
        holder.zapBalance = holder.zapBalance.sub(zapSpent);
        holder.tokens = holder.tokens.add(dots);
        if(!holder.bonded) {
            holderAddresses.push(msg.sender);
            holderAddressesLength++;
            holder.bonded = true;
        }

        emit Bonded(dots);
        return zapSpent;
    }

    function removeHolder(address addr) private returns(bool) {
        uint index;
        for (uint i = 0; i < holderAddressesLength; i++){
            if(holderAddresses[i] == addr) index = i;
        }

        if(index > holderAddressesLength) return false;

        for (uint i = index; i < holderAddressesLength-1; i++){
            holderAddresses[i] = holderAddresses[i+1];
        }
        holderAddresses.length--;
        holderAddressesLength--;
        return true;
    }

    //Exchange MMT token to unbond and collect zap from unbonded dots(i.e mmt tokens)
    function unbond(uint256 dots) external hasApprovedMMT(dots) {
        MainMarketHolder storage holder = getHolder(msg.sender);
        uint netZap = bondage.unbond(address(this), endPoint, dots);
        mainMarketToken.transferFrom(msg.sender, address(this), dots);
        holder.tokens = holder.tokens.sub(dots);
        zapToken.transfer(msg.sender, netZap);
        holder.zapBalance= holder.zapBalance.add(netZap);
        if(holder.tokens < 1) {
            removeHolder(msg.sender);
            holder.bonded = false;
        }
        emit Unbonded(dots);

    }

    //For local testing purposes
    //Allocates Zap to user for use
    function allocateZap(uint256 amount) public {
        zapToken.allocate(msg.sender, amount);
    }

    //Get current Zap Balance of Owner
    function getZapBalance(address _owner) public returns(uint256) {
        return zapToken.balanceOf(_owner);
    }

    //returns deposited zap amoun of msg.sender
    function getDepositedZap() public returns(uint256) {
        return holders[msg.sender].zapBalance;
    } 

    //Get current MMT Balance of Owner
    function getMMTBalance(address _owner) public returns(uint256) {
        return mainMarketToken.balanceOf(_owner);
    }

    //Once we get query functioning, this will get the Zap Price from OffChain Oracle
    // function getZapPrice() public view {
    // }

    function getCurve() public returns(int256[] memory) {
        return curve1;
    }

    //Withdraw Zap from gains/losses from Auxiliary Market and disperse 5% of
    //the fee based on the percentage of bonded stake on the Main Market
    function withdraw(uint256 amount, address addr) external returns(uint256) {
        address auxiliaryMarketAddress = coordinator.getContract("AUXMARKET");
        require(address(msg.sender)==address(auxiliaryMarketAddress),"Only Auxiliary Market can access this method");
        uint256 fee = (amount.mul(5)).div(100);
        for (uint i = 0; i < holderAddressesLength; i++) {
            MainMarketHolder storage holder = getHolder(holderAddresses[i]);
            uint256 equity = getEquityStake(holderAddresses[i]);
            uint256 equityAmount = equity.mul(fee).div(100);
            holder.zapBalance = holder.zapBalance.add(equityAmount);
        }
        uint256 netAmount = amount - fee;
        zapToken.transfer(addr, netAmount);
        return fee;
    }

    //user can withdraw their zap from main market
    function withdrawFunds(uint256 amount) public {
        MainMarketHolder storage holder = getHolder(msg.sender);
        //cant withdraw more than what was deposited
        require(holder.zapBalance > amount);
        zapToken.transfer(msg.sender, amount);
        holder.zapBalance = holder.zapBalance.sub(amount);

    }

    function zapForDots(uint256 dots) public returns (uint256) {
        MainMarketHolder storage holder = getHolder(msg.sender);
        uint256 issued = bondage.getDotsIssued(address(this), endPoint);
        require(issued + dots <= bondage.dotLimit(address(this), endPoint), "Error: Dot limit exceeded");
        uint256 numZapForDots = currentCost._costOfNDots(address(this), endPoint, issued + 1, dots - 1);
        return numZapForDots;
    }

    //Destroys the contract when there is no more Zap
    //and distributes ratio
    //function destroyMainMarket() private {}

    //Modifiers
    //Requires user to have enough zap in Main Market to cover the cost of dots
    modifier hasEnoughZapForDots(uint256 dots) {
        MainMarketHolder storage holder = getHolder(msg.sender);
        uint256 zapBalance = holder.zapBalance;
        uint256 numZapForDots = zapForDots(dots);
        require (zapBalance >= numZapForDots, "Not enough Zap to buy dots");
        _;
    }

    //Requires User to have enough Zap in their account
    modifier hasZap(uint256 amount) {
        uint256 zapBalance = zapToken.balanceOf(msg.sender);
        require (zapBalance >= amount, "Not enough Zap in account");
        _;
    }

    //Requires User to approve the Main Market Contract an allowance to spend zap on their behalf
    modifier hasApprovedZap(uint256 amount) {
        uint256 allowance = zapToken.allowance(msg.sender, address(this));
        require (allowance >= amount, "Not enough Zap allowance to be spent by MainMarket Contract");
        _;
    }

    //Requires User to approve the Main Market Contract an allowance to spend mmt on their behalf
    modifier hasApprovedMMT(uint256 amount) {
        uint256 allowance = mainMarketToken.allowance(msg.sender, address(this));
        require (allowance >= amount, "Not enough MMT allowance to be spent by MainMarket Contract");
        _;
    }
}