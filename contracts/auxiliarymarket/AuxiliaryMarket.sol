pragma solidity ^0.5.8;

import "../mainmarket/MainMarket.sol";
import "./AuxiliaryMarketInterface.sol";
import "./Helper.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../platform/registry/RegistryInterface.sol";
import "../platform/registry/Registry.sol";
import "../platform/bondage/BondageInterface.sol";
import "../platform/bondage/Bondage.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";

contract AuxiliaryMarket is Helper{


    uint[] public assetPrices = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,
    10000, 11000, 12000, 13000, 14000, 15000, 16000];

    // Price of $0.01 USD
    uint zap = 28449300676025;

    function random() public returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, assetPrices)));
    }

    struct AuxMarketHolder{
        uint256 priceBoughtIn;
        uint256 subTokensOwned;
    }

    RegistryInterface public registry;
    BondageInterface public bondage;
    ZapCoordinatorInterface public coordinator;

    bytes32 public endPoint = "Bond to Auxiliary Market";
    int256[] curve = [1,1,1000];

    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        address bonadgeAddr = coordinator.getContract("BONDAGE");
        address mainMarketAddr = coordinator.getContract("MAINMARKET");

<<<<<<< HEAD
        address registryAddress = coordinator.getContract("REGISTRY");
        registry = RegistryInterface(registryAddress);

        // initialize in registry
        bytes32 title = "Auxiliary Market";

        registry.initiateProvider(12345, title);
        registry.initiateProviderCurve(endPoint, curve, address(0));
    }

=======
>>>>>>> 00c1898ec4f8860f56762f3e810c587c159c73da
    //Mapping of holders
    mapping (address => AuxMarketHolder) holders;

    // Transfer zap from holder to market
    function transferZap() private {}
    // Transfer SubToken to holder
    function transferSubToken() private {}

    // Sends Zap to Main Market when asset is sold at loss
    function sendToMainMarket() private {}
    // Sends Zap to Main Market when asset is sold at gain
    function getFromMainMarket() private {
        
    }

    // Grabs current price of asset
    function getCurrentPrice() public returns (uint) {
        uint256 num = 16;
        return assetPrices[random() % num];
    }
    // Grabs User's current balance of SubTokens
    function getBalance() public view returns (uint256) {
        return holders[msg.sender].subTokensOwned;
    }
    // User can sell Subtoken back to Aux Market for Zap
    function sellAsset() public {

    }

    // User can buy Subtoken from Aux Market for Zap
    function buyAsset(uint quantity) public payable {
        uint256 currentAssetPrice = getCurrentPrice();
        //TODO: Exchange AuxMarketToken for Zap
        AuxMarketHolder memory holder = AuxMarketHolder(currentAssetPrice, quantity);
        holders[msg.sender] = holder;
    }


    //Stretch

    // User can trade Subtoken to other users
    //function trade() public {}


}