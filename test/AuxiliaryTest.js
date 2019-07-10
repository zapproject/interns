const AuxiliaryMarket  = artifacts.require('AuxiliaryMarket.sol');
const ZapToken = artifacts.require('ZapToken.sol');

contract('Auxiliary Market', (accounts) => {
	it('user should have 2000000 zap', async () => {
		const zapToken = await ZapToken.deployed();
		const AuxMarket = await AuxiliaryMarket.deployed();

		var zapBalance = await zapToken.balanceOf.call(accounts[0]);
		//convert zapwei to zap
		var auxWeiQuantity = web3.utils.fromWei(zapBalance.toString(), 'ether')
		assert.equal(auxWeiQuantity.toString(), 2000000, 'accont 0 should have 2000000 zap');
	});
	it('Can buy Asset tokens', async () => {
		const AuxMarket = await AuxiliaryMarket.deployed();
		const zapToken = await ZapToken.deployed();

		var auxWeiQuantity = 1;
		console.log("auxWei buying: ", auxWeiQuantity);
		await AuxMarket.buy(auxWeiQuantity);

		var auxWeiBalance = await AuxMarket.getAMTBalance.call(accounts[0]);
		console.log("aux balance: ", auxWeiBalance.toString());
		assert.equal(auxWeiBalance, 1, "should have 1 auxWei token");
	});
});