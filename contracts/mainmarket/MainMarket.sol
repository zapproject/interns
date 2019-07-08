pragma solidity ^0.5.8;
//experimental allows returning structs in function
pragma experimental ABIEncoderV2;
import "../platform/registry/RegistryInterface.sol";
import "../platform/bondage/BondageInterface.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../token/ZapToken.sol";
import "./MainMarketTokenInterface.sol";

contract MainMarket {
    using SafeMath for uint256;


    struct MainMarketHolder{
        bool initialized;
        uint256 tokensOwned;
        uint256 zapBalance;
        uint256 dotsBonded;
    }

    mapping (address => MainMarketHolder) public holders;
    address[] public holderAddresses;
    uint256 public zapInWei = 28449300676025;


    RegistryInterface public registry;
    BondageInterface public bondage;
    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    MainMarketTokenInterface public mainMarketToken;


    bytes32 public endPoint = "Bond";
    int256[] curve1 = [1,1,1000];
    
    constructor(address _zapCoor) public {

        coordinator = ZapCoordinatorInterface(_zapCoor);

        address bondageAddress = coordinator.getContract("BONDAGE");
        address mainMarketTokenAddress = coordinator.getContract("MAINMARKET_TOKEN");
        address registryAddress = coordinator.getContract("REGISTRY");
        address zapTokenAddress = coordinator.getContract("ZAP_TOKEN");


        mainMarketToken = MainMarketTokenInterface(mainMarketTokenAddress);
        bondage = BondageInterface(bondageAddress);
        zapToken = ZapToken(zapTokenAddress);
        registry = RegistryInterface(registryAddress);


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
            holder.tokensOwned = 0;
            holder.zapBalance = 0;
            holder.dotsBonded = 0;
        }
        return holder;
    }

    //Calculates equity stake based on total Zap in Contract and
    //holders zap balance in Main Market Contract.
    //Decimal Precision may need to be increased in the future because
    //a holder's stake can be less than 1%, even .0003933% if enough
    //users are bonding to it
    function getEquityStake (address holder) public returns (uint256) {
        uint256 totalBonded = bondage.getDotsIssued(address(this), endPoint);
        uint256 holderTotal = mainMarketToken.balanceOf(holder);
        uint256 equityStake = holderTotal*100 / totalBonded;
        return equityStake;
    }
    

    //Deposits Zap into Main Market Token Contract and approves Bondage an allowance of
    //zap amount to be used to bond
    //For testing
    //100 zap == 2844930067602500 wei
    function depositZap(uint256 amount) public hasZap(amount) hasApprovedZap(amount) returns (bool) {
        zapToken.transferFrom(msg.sender, address(this), amount);
        MainMarketHolder storage holder = getHolder(msg.sender);
        holder.zapBalance = amount;
        address bondageAddr = coordinator.getContract("BONDAGE");
        return zapToken.approve(bondageAddr, amount);
    }

    //Mint MMT to this contract before bonding so MainMarket is
    //able to transfer tokens to User
    function bond(uint256 dots) external hasEnoughZapForDots(dots) returns(uint256) {
        MainMarketHolder storage holder = getHolder(msg.sender);
        //delegateBond bonds on behalf of msg.sender
        //but unbond doesn't. It assumes the contract is bonded
        //There is no delegateUnbond function
        uint zapSpent = bondage.bond(address(this), endPoint, dots);
        holder.zapBalance -= zapSpent;
        //Problem is we bond the contract to itself, but msg.sender(user) should
        //bond which is why getBoundDots will always return 0 for msg.sender(user)
        holder.dotsBonded = bondage.getBoundDots(msg.sender, address(this), endPoint);
        if(holder.dotsBonded > 0) holderAddresses.push(msg.sender);
        mainMarketToken.transfer(msg.sender, dots);
        return zapSpent;
    }

    //Exchange MMT token to unbond and collect zap from unbonded dots(i.e mmt tokens)
    function unbond(uint256 dots) external hasApprovedMMT(dots) {
        mainMarketToken.transferFrom(msg.sender, address(this), dots);
        uint netZap = bondage.unbond(address(this), endPoint, dots);
        zapToken.transfer(msg.sender, netZap);
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

    //Get current MMT Balance of Owner
    function getMMTBalance(address _owner) public returns(uint256) {
        return mainMarketToken.balanceOf(_owner);
    }

    //Once we get query functioning, this will get the Zap Price from OffChain Oracle
    function getZapPrice() public view {
    }

    //Withdraw Zap from gains/losses from Auxiliary Market and disperse 5% of
    //the fee based on the percentage of bonded stake on the Main Market
    function withdraw(uint256 amount) external returns(uint256) {
        uint256 fee = (amount.mul(5)).div(100);
        for (uint i = 0; i < holderAddresses.length; i++) {
            uint256 equity = getEquityStake(holderAddresses[i]);
            uint256 weiAmount = equity * fee / 100;
            zapToken.transferFrom(msg.sender, holderAddresses[i], weiAmount);
        }
        return fee;
    }


    //Destroys the contract when there is no more Zap
    //and distributes ratio
    function destroyMainMarket() private {}

    //Modifiers
    //Requires user to have enough zap to cover the cost of dots
    modifier hasEnoughZapForDots(uint256 dots) {
        uint256 zapBalance = zapToken.balanceOf(msg.sender);
        uint256 issued = getDotsIssued(address(this), endPoint);
        require(issued + numDots <= bondage.dotLimit(address(this), endPoint), "Error: Dot limit exceeded");
        uint256 numZapForDots = currentCost._costOfNDots(address(this), endPoint, issued + 1, numDots - 1);
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