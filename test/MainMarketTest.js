const BigNumber =web3.utils.BN;

const expect = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .expect;

const ZapDB = artifacts.require("Database");
const ZapCoor = artifacts.require("ZapCoordinator");
const Bondage = artifacts.require("Bondage");
const Dispatch = artifacts.require("Dispatch");
const ZapToken = artifacts.require("ZapToken");
const Registry = artifacts.require("Registry");
const Cost = artifacts.require("CurrentCost");


const MainMarket  = artifacts.require('MainMarket.sol');
const MainMarketToken  = artifacts.require('MainMarketToken.sol');
const AuxiliaryMarket  = artifacts.require('AuxiliaryMarket.sol');
const AuxiliaryMarketToken  = artifacts.require('AuxiliaryMarketToken.sol');

contract('Main Market', (accounts) => {
	let mm, zapToken, auxmarket;

	const user1 = accounts[0];
	const user2 = accounts[1];
	const user3 = accounts[2];

	before(async () => {
		/***Deploy zap contrracts ***/
		zapdb = await ZapDB.new();
		zapcoor = await ZapCoor.new();
		await zapdb.transferOwnership(zapcoor.address);
		await zapcoor.addImmutableContract('DATABASE', zapdb.address);

		zapToken = await ZapToken.new();
		await zapcoor.addImmutableContract('ZAP_TOKEN', zapToken.address);

		registry = await Registry.new(zapcoor.address);
		await zapcoor.updateContract('REGISTRY', registry.address);

		cost = await Cost.new(zapcoor.address);
		await zapcoor.updateContract('CURRENT_COST', cost.address);

		bondage = await Bondage.new(zapcoor.address);
		await zapcoor.updateContract('BONDAGE', bondage.address);

		dispatch = await Dispatch.new(zapcoor.address);
		await zapcoor.updateContract('DISPATCH', dispatch.address);

		await zapcoor.updateAllDependencies();


		//deploy asset market contracts
		mmt = await MainMarketToken.new();
		await zapcoor.addImmutableContract('MAINMARKET_TOKEN', mmt.address);
		mm = await MainMarket.new(zapcoor.address);
		await zapcoor.addImmutableContract('MAINMARKET', mm.address);


		amt = await AuxiliaryMarketToken.new();
		await zapcoor.addImmutableContract('AUXILIARYMARKET_TOKEN', amt.address);
		am = await AuxiliaryMarket.new(zapcoor.address);
		await zapcoor.addImmutableContract('AUXMARKET', am.address);

	    // const zapWeiAmount = new BigNumber("2000000e18");
	    const zapWeiAmount = web3.utils.toWei('2000000', 'ether');

		//give zap to the three users
		// zapToken.allocate(user1, zapWeiAmount, {from: user1});
		await zapToken.allocate(user1, zapWeiAmount, {from: user1});
		await zapToken.allocate(user2, zapWeiAmount, {from: user2});
		await zapToken.allocate(user3, zapWeiAmount, {from: user3});

		//approve zap to the three users
		await zapToken.approve(mm.address,zapWeiAmount, {from: user1});
		await zapToken.approve(mm.address, zapWeiAmount, {from: user2});
		await zapToken.approve(am.address, zapWeiAmount, {from: user3});
		//user3 need to approve auxtoken to be able to sell it back to auxiliary contact


		await mm.depositZap(zapWeiAmount, {from: user1});
		await mm.depositZap(zapWeiAmount, {from: user2});

		let mintAmount = web3.utils.toWei('100000000', 'ether');
		//Mint initial 100 million MMT Tokens for Main Market to disperse to users who bond
		mmt.mint(mm.address, mintAmount);
		//Mint initial 100 million AMT Tokens for Main Market to disperse to users who that want to buy asset tokens
		amt.mint(am.address, mintAmount);
	});

	it('can bond', async function deployContract() {

		let user1Bal = await mm.getZapBalance.call(user1);

		let approveAmount = await zapToken.allowance(mm.address, bondage.address);

		await mm.bond(20, {from: user1});
		await mm.bond(30, {from: user1});

		let marketTokensOwned = await mm.getMMTBalance.call(user1);
		assert.equal(marketTokensOwned.toString(), 50, "should have 50 main market tokens");
	});

	it('gets equity of holder', async () => {
		await mm.bond(50, {from: user2});

		let user1Equity = await mm.getEquityStake.call(user1);
		let user2Equity = await mm.getEquityStake.call(user2);

		//accoutn[0] should have the 50 tokens from previous test
		assert.equal(user1Equity.toString(),"50", "account 0 has 50% equity");
		assert.equal(user2Equity.toString(),"50", "account 1 has 50% equity");

		await mm.bond(20, {from: user2});
		
		//get updated equity
		user1Equity = await mm.getEquityStake.call(user1);
		user2Equity = await mm.getEquityStake.call(user2);

		assert.equal(user1Equity.toString(),"41", "account 0 has 41% equity");
		assert.equal(user2Equity.toString(),"58", "account 1 has 58% equity");
	});

	it('can withdraw', async () => {
		let originalZapBal = await mm.getZapBalance.call(user1);

		// account 3 buys 10 auxwei tokens @ 51422015082540802048 wei
		let buyPrice = await am.buy.call(10, {from: user3});
		await am.buy(10, {from: user3});
		// need to approve aux market to spend aux token
		await amt.approve(am.address,10, {from: user3});
		//then sells it 10 @ 3213875942658800128
		let sellPrice = await am.sell.call(5, {from: user3});
		await am.sell(5, {from: user3});

		let fee = Math.floor(sellPrice.toNumber() * .05);
		let user1Equity = await mm.getEquityStake.call(user1);
			user1Equity = user1Equity.toNumber() / 100;

		let user1ExpectedZap = Math.floor(originalZapBal.toNumber() + (fee * user1Equity));
		let user1ActualZap = await mm.getZapBalance.call(user1);

		console.log("fee                 : ", fee);
		console.log("user1 equity        : ", user1Equity);
		console.log("user1 expected      : ", user1ExpectedZap);
		console.log("user1 actual        : ", user1ActualZap.toNumber());

		assert.equal(user1ActualZap.toNumber(), user1ExpectedZap, 'user1 did not receive correct amount of zap');
	});
});