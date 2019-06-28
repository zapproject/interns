pragma solidity ^0.5.8;

import "../platform/registry/RegistryInterface.sol";
import "../platform/registry/Registry.sol";
import "../platform/bondage/BondageInterface.sol";
import "../platform/bondage/Bondage.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
//import tokents
import "../token/ZapToken.sol";
import "./MainMarketToken.sol";


contract MainMarket {

    struct MainMarketHolder{
        uint256 tokensOwned;
        uint256 zapBalance;
    }

    RegistryInterface public registry;
    BondageInterface public bondage;
    ZapCoordinatorInterface public coordinator;
    ZapToken zapToken;
    MainMarketToken mainToken;

    bytes32 public endPoint = "Bond To Main Maket";
    int256[] curve1 = [1,1,1000];


    mapping (address => MainMarketHolder) holders;
    


    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        address bondageAddr = coordinator.getContract("BONDAGE");
        bondage = BondageInterface(bondageAddr);

        zapToken = ZapToken(coordinator.getContract("ZAP_TOKEN"));
        mainToken = MainMarketToken(coordinator.getContract("MAIN_MARKET_TOKEN"));

        address registryAddress = coordinator.getContract("REGISTRY");
        registry = RegistryInterface(registryAddress);

        // initialize in registry
        bytes32 title = "Main market";

        registry.initiateProvider(12345, title);
        registry.initiateProviderCurve(endPoint, curve1, address(0));


    }


    function depositZap (uint256 amount) public payable {
        uint256 zapBalance = zapToken.getBalance(msg.sender);

        //amount must be equal to balnce of zap deposited
        require (zapBalance >= amount, "not enough zap in account");

        holders[msg.sender].zapBalance = amount;

        zapToken.transfer(address(this), msg.sender, amount);
    }

     function getMMTBalance(address _owner) external returns(uint256) {
        return mainMarketToken.balanceOf(_owner);
    }

    //Disperse 5% fees to all
    function payFee() public payable {}

    // Exchange Zap for MainMarket Token
    function buyAndBond(uint256 amount) external payable{
        depositZap();
        uint zapSpent = bondage.delegateBond(msg.sender, address(this), endPoint, amount);
        MainToken.transfer(msg.sender, amount);
    }

    function sellAndUnbond(uint256 amount) public payable{
        uint netZap = bondage.unbound(msg.sender, address(this), endPoint, amount);
        zapToken.transfer(holders[address(this)],holders[msg.sender],netZap);
    }

    // Gets price of MainMarket Token in Zap
    function getZapPrice() public view {}


    // Withdraw
    function withdraw(address holder) external {
        //get 5%
        
    }

    // List all Auxiliary Markets
    function viewAuxiliaryMarkets() external view {}
    // checks if Auxiliary Market Exists
    function auxiliaryMarketExists() external view{}
    // Checks on a specific Auxiliary Market
    function getAuxiliaryMarket(address) external view{}

    // Destroys the contract when there is no more Zap
    function selfDestruct() private {}
}