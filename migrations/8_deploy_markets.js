const MainMarket = artifacts.require('./MainMarket.sol');
const AuxiliaryMarket = artifacts.require('./AuxiliaryMarket.sol');
const ZapCoordinator = artifacts.require('./ZapCoordinator.sol');
const MainMarketToken = artifacts.require('./MainMarketToken.sol');
const AuxiliaryMarketToken = artifacts.require('./AuxiliaryMarketToken.sol');
const ZapToken = artifacts.require('./ZapToken.sol');

module.exports = async function(deployer) {
  const coordinator = await ZapCoordinator.deployed();
  const zapToken = await ZapToken.deployed();
  await deployer.deploy(MainMarketToken);
  await deployer.deploy(AuxiliaryMarketToken);
  const mmt = await MainMarketToken.deployed();
  const amt = await AuxiliaryMarketToken.deployed();
  await coordinator.addImmutableContract('MAINMARKET_TOKEN', mmt.address);
  await coordinator.addImmutableContract('AUXILIARYMARKET_TOKEN', amt.address);
  await deployer.deploy(AuxiliaryMarket, ZapCoordinator.address);
  await deployer.deploy(MainMarket, ZapCoordinator.address);
  const mm = await MainMarket.deployed();
  const am = await AuxiliaryMarket.deployed();
  await coordinator.addImmutableContract('MAINMARKET', mm.address);
  await coordinator.addImmutableContract('AUXMARKET', am.address);

  let zapInWei = await mm.zapInWei();
  let mmtDecimals = await mmt.decimals();

  //Mint initial 100 million MMT Tokens for Main Market to disperse to users who bond
  let mintAmount = 100000000;

  //turn to 18 decimal precision
  let mmtWei = web3.utils.toWei(mintAmount.toString(), 'ether');
  let amtWei = web3.utils.toWei(mintAmount.toString(), 'ether');
  //mmtWei is used for more precise transactions.
  await mmt.mint(mm.address, mmtWei);
  await amt.mint(am.address, amtWei);

  let allocate = 500;
  let allocateInWeiMMT = web3.utils.toWei(allocate.toString(), 'ether');
  let allocateInWeiAMT = web3.utils.toWei(allocate.toString(), 'ether');

  //Allocate 500 Zap to user for testing purposes locally
  await mm.allocateZap(allocateInWeiMMT);
  await am.allocateZap(allocateInWeiAMT);

  //100 zap
  let approved = 100;
  let approveWeiZap = web3.utils.toWei(approved.toString(), 'ether');

  //Approve MainMarket an allowance of 100 Zap to use on behalf of msg.sender(User)
  await zapToken.approve(mm.address, approveWeiZap);
  await zapToken.approve(am.address, approveWeiZap);
};
