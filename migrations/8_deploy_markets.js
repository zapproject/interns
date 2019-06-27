var MainMarket = artifacts.require('./MainMarket.sol');
var AuxiliaryMarket = artifacts.require('./AuxiliaryMarket.sol');
var ZapCoordinator = artifacts.require('./ZapCoordinator.sol');
const MainMarketToken = artifacts.require('./MainMarketToken.sol');

module.exports = async function(deployer) {
  const coordInstance = await ZapCoordinator.deployed();
  await deployer.deploy(MainMarketToken);
  await deployer.deploy(AuxiliaryMarket, ZapCoordinator.address);
  await deployer.deploy(MainMarket, ZapCoordinator.address);
  await coordInstance.addImmutableContract('MAINMARKET', MainMarket.address);
  await coordInstance.addImmutableContract(
    'AUXMARKET',
    AuxiliaryMarket.address
  );
};
