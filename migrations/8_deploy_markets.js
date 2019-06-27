var MainMarket = artifacts.require("./MainMarket.sol");
var AuxiliaryMarket = artifacts.require("./AuxiliaryMarket.sol");

const MainMarketToken = artifacts.require("./MainMarketToken.sol");

module.exports = async function(deployer) {
     await deployer.deploy(MainMarketToken, "Market", "MMT");
     await deployer.deploy(AuxiliaryMarket);
     await deployer.deploy(MainMarket);
};


