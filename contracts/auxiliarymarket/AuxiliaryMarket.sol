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
import "../token/ZapToken.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract AuxiliaryMarket is Helper{
    using SafeMath for uint256;

    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        address mainMarketAddr = coordinator.getContract("MAINMARKET");
        address zapTokenAddress = coordinator.getContract("ZAP_TOKEN");
        zapToken = ZapToken(zapTokenAddress);

    }


    uint[] public assetPrices = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,
    10000, 11000, 12000, 13000, 14000, 15000, 16000];

    // Price of $0.01 USD
    uint zap = 28449300676025;

    function random() public returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, assetPrices)));
    }

    struct AuxMarketHolder{
        uint256 avgPrice;
        uint256 subTokensOwned;
    }

    RegistryInterface public registry;
    BondageInterface public bondage;
    ZapCoordinatorInterface public coordinator;

    bytes32 public endPoint = "Bond to Auxiliary Market";
    int256[] curve = [1,1,1000];

    //Mapping of holders
    mapping (address => AuxMarketHolder) holders;

    // Transfer zap from holder to market
    function exchangeZapForSubtoken(uint256 _quantity) private {
        // get current price
        _currentAssetPrice = getCurrentPrice() * zap;
        unit256 _totalWei = _currentAssetPrice * _quantity
        // check how much zap received // transfer from balalnce of(). use zap coordinator to get address of zap token contract
        require(zapToken.balanceOf() * zap > _totalWei, "Not enough Zap in Wallet");
        // transfer equivalent amount in subtoken
        zapToken.transfer()
        // holder struct with price bought in and amount of subtokens
        holders[msg.sender].avgPrice = div((_totalWei + holders[msg.sender].avgPrice * holders[msg.sender].subTokensOwned),(_quantity + holders[msg.sender].subTokensOwned));
        holders[msg.sender].subTokensOwned = holders[msg.sender].subTokensOwned + _quantity;
        // Find average price
        // Map holder msg.sender to key: value being holder struct
    }

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