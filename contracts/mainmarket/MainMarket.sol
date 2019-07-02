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
    //tokensOwner for quantity of tokens
    struct MainMarketHolder{
        bool initialized;
        uint256 tokensOwned;
        uint256 zapBalance;
    }
    RegistryInterface public registry;
    BondageInterface public bondage;
    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    MainMarketTokenInterface public mainMarketToken;
    bytes32 public endPoint = "Bond To Main Market";
    int256[] curve1 = [1,1,1000];
    mapping (address => MainMarketHolder) holders;
    
    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        address bondageAddr = coordinator.getContract("BONDAGE");
        address mainMarketTokenAddress = coordinator.getContract("MAINMARKET_TOKEN");
        mainMarketToken = MainMarketTokenInterface(mainMarketTokenAddress);
        bondage = BondageInterface(bondageAddr);
        zapToken = ZapToken(coordinator.getContract("ZAP_TOKEN"));
        address registryAddress = coordinator.getContract("REGISTRY");
        registry = RegistryInterface(registryAddress);
        // initialize in registry
        bytes32 title = "Main market";
        registry.initiateProvider(12345, title);
        registry.initiateProviderCurve(endPoint, curve1, address(0));
    }
    function getHolder(address addr) public returns(MainMarketHolder memory) {
        MainMarketHolder storage holder = holders[msg.sender];
        if(!holder.initialized) {
            holder.initialized = true;
            holder.tokensOwned = 0;
            holder.zapBalance = 0;
        }
        return holder;
    }
//    function depositZap(uint256 amount) external payable {
//        uint256 zapBalance = zapToken.balanceOf(msg.sender);
//
//        //amount must be equal to balance of zap deposited
//        require (zapBalance >= amount, "Not enough Zap in account");
//        MainMarketHolder memory holder = getHolder(msg.sender);
//        holder.zapBalance = amount;
//
//        zapToken.transferFrom(msg.sender, address(this), amount);
//    }
    function approve(uint256 amount) public hasZap(amount) hasApprovedZap(amount) returns (bool) {
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
    function sellAndUnbond(uint256 amount) public payable{
        mainMarketToken.transferFrom(msg.sender, address(this), amount);
        uint netZap = bondage.unbond(msg.sender, endPoint, amount);
        //Unbonding Zap from this contract so now tranfer it to the msg.sender
        zapToken.transferFrom(address(this), msg.sender, netZap);
    }
    function getZapBalance(address _owner) external returns(uint256) {
        return zapToken.balanceOf(_owner);
    }
    //For Testing purposes
    function allocateZap(uint256 amount) public {
        zapToken.allocate(msg.sender, amount);
    }
     function getMMTBalance(address _owner) external returns(uint256) {
        return mainMarketToken.balanceOf(_owner);
    }
    function getZapPrice() public view {
    }
    //Withdraw 5% from
    function withdraw(address holder, uint256 amount) external returns(uint256) {
        uint256 fee = (amount.mul(5)).div(100);
        return fee;
    }
    // Destroys the contract when there is no more Zap
    function destroyMainMarket() private {}
    //Modifiers
    modifier hasZap(uint256 amount) {
        uint256 zapBalance = zapToken.balanceOf(msg.sender);
        require (zapBalance >= amount, "Not enough Zap in account");
        _;
    }
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