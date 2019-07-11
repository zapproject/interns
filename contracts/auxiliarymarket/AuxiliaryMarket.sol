pragma solidity ^0.5.8;

import "../mainmarket/MainMarket.sol";
import "./AuxiliaryMarketInterface.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../token/ZapToken.sol";
import "./AuxiliaryMarketTokenInterface.sol";

contract AuxiliaryMarket{
    using SafeMath for uint256;

    ZapCoordinatorInterface public coordinator;
    ZapToken public zapToken;
    AuxiliaryMarketTokenInterface public auxiliaryMarketToken;

    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        address mainMarketAddr = coordinator.getContract("MAINMARKET");
        auxiliaryMarketToken = AuxiliaryMarketTokenInterface(coordinator.getContract("AUXILIARYMARKET_TOKEN"));
        zapToken = ZapToken(coordinator.getContract("ZAP_TOKEN"));
    }

    uint[] public assetPrices = [3213875942658800128, 6427751885317600256, 9641627827976400896, 12855503770635200512, 16069379713294000128, 19283255655952801792, 22497131598611599360, 25711007541270401024, 28924883483929198592,
   32138759426588000256, 35352635369246801920, 38566511311905603584, 41780387254564397056, 44994263197223198720, 48208139139882000384, 51422015082540802048];

    // Price of $0.01 USD
    uint zapInWei = 28449300676025;
    uint weiInWeiZap = (10**18)/zapInWei;

    function random() public returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, assetPrices)));
    }

    struct AuxMarketHolder{
        uint256 avgPrice;
        uint256 subTokensOwned;
    }

    //Mapping of holders
    mapping (address => AuxMarketHolder) holders;

    // Transfer zap from holder to market
    function buy(uint256 _quantity) public payable {
        // //TODO: Exchange AuxMarketToken for Zap

        // get current price
        uint256 _currentAssetPrice = getCurrentPrice() * weiInWeiZap;
        uint256 _totalWeiZap = _currentAssetPrice * _quantity;

        // check how much zap received // transfer from balalnce of(). use zap coordinator to get address of zap token contract
        require(getBalance(msg.sender) * weiInWeiZap > _totalWeiZap, "Not enough Zap in Wallet");
        // transfer equivalent amount in subtoken
        // zapToken.transferFrom(msg.sender, address(this), _totalWei);
        // holder struct with price bought in and amount of subtokens
        uint256 avgPrice = (_totalWeiZap + holders[msg.sender].avgPrice * holders[msg.sender].subTokensOwned).div(
            (_quantity + holders[msg.sender].subTokensOwned));

        uint256 quantity = holders[msg.sender].subTokensOwned + _quantity;

        AuxMarketHolder memory holder = AuxMarketHolder(avgPrice, quantity);
        holders[msg.sender] = holder;

        // Map holder msg.sender to key: value being holder struct
    }

    function sell(uint256 _quantity) public payable {
        // Sends Zap to Main Market when asset is sold at loss
        // function sendToMainMarket() private {}
        // Sends Zap to Main Market when asset is sold at gain
        // function getFromMainMarket() private {}
    }

    // Grabs current price of asset
    function getCurrentPrice() public returns (uint) {
        uint256 num = 16;
        return assetPrices[random() % num];
    }

    // Grabs User's current balance of SubTokens
    function getBalance(address _address) public view returns (uint256) {
        return zapToken.balanceOf(_address);
    }

    function allocateZap(uint256 amount) public {
        zapToken.allocate(msg.sender, amount);
    }

    function getAMTBalance(address _owner) public returns(uint256) {
        return auxiliaryMarketToken.balanceOf(_owner);
    }

    function test() public returns(uint256){
       return holders[msg.sender].avgPrice;
    }


    /**
     * These functions are to be used on querying oracles
     */
    // https://ethereum.stackexchange.com/questions/884/how-to-convert-an-address-to-bytes-in-solidity
    function toBytes(address x) public pure returns (bytes b) {
        b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    }

    //https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    function bytes32ToString(bytes32 x) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        bytesString = abi.encodePacked(x);
        return string(bytesString);
    }

    //https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity
    function bytesToAddr (bytes b) public pure returns (address) {
        uint result = 0;
        for (uint i = b.length-1; i+1 > 0; i--) {
            uint c = uint(b[i]);
            uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
            result += to_inc;
        }
        return address(result);
    }
}