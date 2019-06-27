pragma solidity ^0.5.8;

import "../platform/registry/RegistryInterface.sol";
import "../platform/registry/Registry.sol";
import "../platform/bondage/BondageInterface.sol";
import "../platform/bondage/Bondage.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";

contract MainMarket {

    struct MainMarketHolder{
        uint256 tokensOwned;
    }

    RegistryInterface public registry;
    BondageInterface public bondage;
    ZapCoordinatorInterface public coordinator;

    bytes32 public endPoint = "Bond To Main Maket";
    int256[] curve1 = [1,1,1000];


    mapping (address => MainMarketHolder) holders;



    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        address bondageAddr = coordinator.getContract("BONDAGE");
        bondage = BondageInterface(bondageAddr);

        address registryAddress = coordinator.getContract("REGISTRY");
        registry = RegistryInterface(registryAddress);

        // initialize in registry
        bytes32 title = "Main market";

        registry.initiateProvider(12345, title);
        registry.initiateProviderCurve(endPoint, curve1, address(0));

    }

    function bond (uint amount) external returns(uint256) {
        uint marketTokensGenerated = bondage.delegateBond(msg.sender, address(this), endPoint, amount);

        // return bondage.delegateBond(msg.sender, address(this), endPoint, amount);
    }
    


    //Disperse 5% fees to all
    function payFee() public payable {}
    // Exchange Zap for MainMarket Token
    function buyMMT() public {}
    // Gets price of MainMarket Token in Zap
    function getZapPrice() public view {}

    // User deposits Zap into Main Market
    function deposit() external payable {}
    // Withdraw
    function withdraw() external {}

    // List all Auxiliary Markets
    function viewAuxiliaryMarkets() external view {}
    // checks if Auxiliary Market Exists
    function auxiliaryMarketExists() external view{}
    // Checks on a specific Auxiliary Market
    function getAuxiliaryMarket(address) external view{}

    // Destroys the contract when there is no more Zap
    function selfDestruct() private {}
}