var MainMarket = artifacts.require('./MainMarket.sol');
var AuxiliaryMarket = artifacts.require('./AuxiliaryMarket.sol');
var ZapCoordinator = artifacts.require('./ZapCoordinator.sol');
const MainMarketToken = artifacts.require('./MainMarketToken.sol');
var coordInstance;
var mmtInstance;
var aux;
var mm;

module.exports = async function(deployer) {
	coordInstance = await ZapCoordinator.deployed();
	await deployer.deploy(MainMarketToken);
	mmtInstance = await MainMarketToken.deployed();
	await coordInstance.addImmutableContract('MAINMARKET_TOKEN', mmtInstance.address);
	await deployer.deploy(AuxiliaryMarket, ZapCoordinator.address);
	await deployer.deploy(MainMarket, ZapCoordinator.address);
	aux = await AuxiliaryMarket.deployed();
	mm = await MainMarket.deployed();
	await coordInstance.addImmutableContract('MAINMARKET', mm.address);
	await coordInstance.addImmutableContract('AUXMARKET', aux.address);
};
