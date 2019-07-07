const MainMarket  = artifacts.require('MainMarket.sol');
const ZapToken = artifacts.require('ZapToken.sol');

contract('Main Market', (accounts) => {
	it('can bond and unbond', async () => {
		let mm = await MainMarket.deployed();

		await mm.depositZap(1000, {from: accounts[0]});

		//account[0] bonds
		await mm.bond(20);
		await mm.bond(30);

		let marketTokensOwned = await mm.getMMTBalance.call(accounts[0]);
		assert.equal(marketTokensOwned.toString(), 50, "should have 50 main market tokens");
	});

	it('gets equity of holder', async () => {
		let mm = await MainMarket.deployed();
		let zapToken = await ZapToken.deployed();

		let zapInWei = await mm.zapInWei();

		//give 100 zap to account[1] for testing
		let allocateAmount = zapInWei.toString() + '00';
		await mm.allocateZap(allocateAmount, {from: accounts[1]});

		//approve and deposit zap to main market
		await zapToken.approve(mm.address, 500, {from: accounts[1]});
		await mm.depositZap(100, {from: accounts[1]});

		await mm.bond(50, {from: accounts[1]});

		let user0Equity = await mm.getEquityStake.call(accounts[0]);
		let user1Equity = await mm.getEquityStake.call(accounts[1]);

		//accoutn[0] should have the 50 tokens from previous test
		assert.equal(user0Equity.toString(),"50", "account 0 has 50% equity");
		assert.equal(user1Equity.toString(),"50", "account 1 has 50% equity");

		await mm.bond(20, {from: accounts[1]});
		
		//get updated equity
		user0Equity = await mm.getEquityStake.call(accounts[0]);
		user1Equity = await mm.getEquityStake.call(accounts[1]);

		assert.equal(user0Equity.toString(),"41", "account 0 has 41% equity");
		assert.equal(user1Equity.toString(),"58", "account 1 has 58% equity");
	});
});