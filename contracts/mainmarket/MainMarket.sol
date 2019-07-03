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
    }

    mapping (address => MainMarketHolder) holders;


    RegistryInterface public registry;
    BondageInterface public bondage;
    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    MainMarketTokenInterface public mainMarketToken;


    bytes32 public endPoint = "Bond To Main Market";
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
    function getHolder(address addr) public returns(MainMarketHolder memory) {
        MainMarketHolder storage holder = holders[msg.sender];
        if(!holder.initialized) {
            holder.initialized = true;
            holder.tokensOwned = 0;
            holder.zapBalance = 0;
        }
        return holder;
    }

    //Deposits Zap into Main Market Token Contract and approves Bondage an allowance of
    //zap amount to be used to bond
    function depositZap(uint256 amount) public hasZap(amount) hasApprovedZap(amount) returns (bool) {
        zapToken.transferFrom(msg.sender, address(this), amount);
        address bondageAddr = coordinator.getContract("BONDAGE");
        return zapToken.approve(bondageAddr, amount);
    }

    //Mint MMT to this contract before bonding so MainMarket is
    //able to transfer tokens to User
    function bond(uint256 dots) external {
        uint zapSpent = bondage.bond(address(this), endPoint, dots);
        address mainMarketTokenAddress = coordinator.getContract("MAINMARKET_TOKEN");
        mainMarketToken.transfer(msg.sender, dots);
    }

    //Sell Main Market token (param amount) in exchange for zap token
    function unbond(uint256 mmtAmount) public {
        mainMarketToken.transferFrom(msg.sender, address(this), mmtAmount);
        uint netZap = bondage.unbond(address(this), endPoint, mmtAmount);
        zapToken.transfer(msg.sender, netZap);
    }

    //For local testing purposes
    //Allocates Zap to user for use
    function allocateZap(uint256 amount) public {
        zapToken.allocate(msg.sender, amount);
    }

    //Get current Zap Balance of Owner
    function getZapBalance(address _owner) external returns(uint256) {
        return zapToken.balanceOf(_owner);
    }

    //Get current MMT Balance of Owner
    function getMMTBalance(address _owner) external returns(uint256) {
        return mainMarketToken.balanceOf(_owner);
    }

    //Once we get query functioning, this will get the Zap Price from OffChain Oracle
    function getZapPrice() public view {
    }

    //Withdraw Zap from gains/losses from Auxiliary Market and disperse 5% of
    //the fee based on the percentage of bonded stake on the Main Market
    function withdraw(address holder, uint256 amount) external returns(uint256) {
        uint256 fee = (amount.mul(5)).div(100);
        return fee;
    }
    // Destroys the contract when there is no more Zap
    function destroyMainMarket() private {}

    //Modifiers


    //Requires User to have enough Zap in their account
    modifier hasZap(uint256 amount) {
        uint256 zapBalance = zapToken.balanceOf(msg.sender);
        require (zapBalance >= amount, "Not enough Zap in account");
        _;
    }

    //Requires User to approve the Main Market Contract an allowance to spend on their behalf
    modifier hasApprovedZap(uint256 amount) {
        uint256 allowance = zapToken.allowance(msg.sender, address(this));
        require (allowance >= amount, "Not enough Zap allowance to be spent by MainMarket Contract");
        _;
    }

    modifier hasApprovedMMT(uint256 amount) {
        uint256 allowance = mainMarketToken.allowance(msg.sender, address(this));
        require (allowance >= amount, "Not enough MMT allowance to be spent by MainMarket Contract");
        _;
    }
}