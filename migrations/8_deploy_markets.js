<<<<<<< HEAD
var MainMarket = artifacts.require('./MainMarket.sol');
var AuxiliaryMarket = artifacts.require('./AuxiliaryMarket.sol');
var ZapCoordinator = artifacts.require('./ZapCoordinator.sol');
const MainMarketToken = artifacts.require('./MainMarketToken.sol');
var coordInstance;

module.exports = async function(deployer) {
	coordInstance = await ZapCoordinator.deployed();
	await deployer.deploy(MainMarketToken);
	await deployer.deploy(AuxiliaryMarket);
	await deployer.deploy(MainMarket, ZapCoordinator.address);
	await coordInstance.addImmutableContract('MAINMARKET', MainMarket.address);
	await coordInstance.addImmutableContract('AUXMARKET', AuxiliaryMarket.address);
=======
var MainMarket = artifacts.require("./MainMarket.sol");
var AuxiliaryMarket = artifacts.require("./AuxiliaryMarket.sol");
var ZapCoordinator = artifacts.require("./ZapCoordinator.sol");
const MainMarketToken = artifacts.require("./MainMarketToken.sol");
var coordInstance;

module.exports = async function(deployer) {
     coordInstance = await ZapCoordinator.deployed();
     await deployer.deploy(MainMarketToken);
     await deployer.deploy(AuxiliaryMarket);
     await deployer.deploy(MainMarket, ZapCoordinator.address);
     await coordInstance.addImmutableContract('MAINMARKET', MainMarket.address);
     await coordInstance.addImmutableContract('AUXMARKET', AuxiliaryMarket.address);
>>>>>>> 9c38a1c9e3193439115643600fa6d84b5190d2b6
};
