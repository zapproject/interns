const AuxiliaryMarket = artifacts.require('AuxiliaryMarket.sol');
const ZapToken = artifacts.require('ZapToken.sol');

contract('Auxiliary Market', accounts => {
  // beforeEach(async () => {
  //   let zapToken = await ZapToken.deployed();
  //   let auxMarket = await AuxiliaryMarket.deployed();
  // });

  it('user should have 2000000 zap', async () => {
    let zapToken = await ZapToken.deployed();
    let auxMarket = await AuxiliaryMarket.deployed();

    let zapBalance = await zapToken.balanceOf.call(accounts[0]);
    //convert zapwei to zap
    zapBalance = web3.utils.fromWei(zapBalance.toString(), 'ether');
    assert.equal(
      zapBalance.toString(),
      2000000,
      'accont 0 should have 2000000 zap'
    );
  });

  it('Can buy Asset tokens', async () => {
    let zapToken = await ZapToken.deployed();
    let auxMarket = await AuxiliaryMarket.deployed();

    const originalZapBal = await zapToken.balanceOf.call(accounts[0]);
    console.log('originalZapBal: ', originalZapBal.toString());
    let auxWeiQuantity = 10;

    //in weiZap
    let assetPrice = await auxMarket.buy.call(auxWeiQuantity);
    await auxMarket.buy(auxWeiQuantity); //call fucntion without .call

    let auxWeiBalance = await auxMarket.getAMTBalance.call(accounts[0]);
    assert.equal(auxWeiBalance, auxWeiQuantity, 'should have 10 auxWei token');

    console.log(
      'total price in: ',
      assetPrice.toLocaleString('fullwide', { useGrouping: false })
    );

    let newZapBalance = await zapToken.balanceOf.call(accounts[0]);
    console.log('new zap bal: ', newZapBalance.toString());
    let expected = originalZapBal - assetPrice;
    //2000000 - assetPirice should be new zap balance;
    assert.equal(
      newZapBalance.toString(),
      expected,
      'should send the right amount of zap'
    );
  });
});
