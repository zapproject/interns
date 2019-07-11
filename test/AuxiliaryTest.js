const AuxiliaryMarket  = artifacts.require('AuxiliaryMarket.sol');
const ZapToken = artifacts.require('ZapToken.sol');

contract('Auxiliary Market', (accounts) => {
	it('user should have 2000000 zap', async () => {
		const zapToken = await ZapToken.deployed();
		const AuxMarket = await AuxiliaryMarket.deployed();

		var zapBalance = await zapToken.balanceOf.call(accounts[0]);
		//convert zapwei to zap
		zapBalance = web3.utils.fromWei(zapBalance.toString(), 'ether')
		assert.equal(zapBalance.toString(), 2000000, 'accont 0 should have 2000000 zap');
	});
	it('Can buy Asset tokens', async () => {
		const AuxMarket = await AuxiliaryMarket.deployed();
		const zapToken = await ZapToken.deployed();
		
		const originalZapBal = await zapToken.balanceOf.call(accounts[0]);
		console.log("originalZapBal: ", originalZapBal.toString());
		var auxWeiQuantity = 10;
		
		//in weiZap
		var assetPrice = await AuxMarket.buy.call(auxWeiQuantity);
						 await AuxMarket.buy(auxWeiQuantity); //call fucntion without .call

		var auxWeiBalance = await AuxMarket.getAMTBalance.call(accounts[0]);
		assert.equal(auxWeiBalance, auxWeiQuantity, "should have 10 auxWei token");
		
		console.log("total price in: ", assetPrice.toLocaleString('fullwide', {useGrouping:false}));

		var newZapBalance = await zapToken.balanceOf.call(accounts[0]);
		console.log("new zap bal: ", newZapBalance.toString());
		var expected = originalZapBal - assetPrice;
		//2000000 - assetPirice should be new zap balance;
		assert.equal(newZapBalance.toString(), expected, "should send the right amount of zap");
	});
});