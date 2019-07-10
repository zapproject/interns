const MainMarket = artifacts.require('./MainMarket.sol');
const AuxiliaryMarket = artifacts.require('./AuxiliaryMarket.sol');
const ZapCoordinator = artifacts.require('./ZapCoordinator.sol');
const MainMarketToken = artifacts.require('./MainMarketToken.sol');
const ZapToken = artifacts.require('./ZapToken.sol');

module.exports = async function(deployer) {
	const coordinator = await ZapCoordinator.deployed();
	const zapToken = await ZapToken.deployed();
	await deployer.deploy(MainMarketToken);
	const mmt = await MainMarketToken.deployed();
	await coordinator.addImmutableContract('MAINMARKET_TOKEN', mmt.address);
	await deployer.deploy(AuxiliaryMarket, ZapCoordinator.address);
	await deployer.deploy(MainMarket, ZapCoordinator.address);
	const aux = await AuxiliaryMarket.deployed();
	const mm = await MainMarket.deployed();
	await coordinator.addImmutableContract('MAINMARKET', mm.address);
	await coordinator.addImmutableContract('AUXMARKET', aux.address);

	//Mint initial 100 million MMT Tokens for Main Market to disperse to users who bond
  var mintAmount = 100000000;
  //turn to 18 decimal precision
  var mmtWei = web3.utils.toWei(mintAmount.toString(), 'ether');
  //mmtWei is used for more precise transactions.
	await mmt.mint(mm.address, mmtWei);

	var allocate = 500;
  var allocateInWeiMMT = web3.utils.toWei(allocate.toString(), 'ether');

	//Allocate 500 Zap to user for testing purposes locally
	await mm.allocateZap(allocateInWeiMMT);

  //100 zap
	var approved = 100;
  var approveWeiZap = web3.utils.toWei(approved.toString(), 'ether');

	//Approve MainMarket an allowance of 100 Zap to use on behalf of msg.sender(User)
	await zapToken.approve(mm.address, approveWeiZap);
};
