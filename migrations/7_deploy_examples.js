var Oracle = artifacts.require("./Oracle.sol");
var Client = artifacts.require("./Client.sol");
const ZapCoordinator = artifacts.require('./ZapCoordinator.sol');
var offChainOracleAddress = '0x6cb027Db7C5aAd7c181092c80Bdb4a18043a2EBa'; //Pokemon API Offchain Oracle
var offChainOracleEndpoint = '0x506f6b656d6f6e20415049000000000000000000000000000000000000000000'; //Pokemon API
const OracleEndpoint = "0x4f6e436861696e456e64706f696e744d6f696e00000000000000000000000000"; //OnChainEndpointMoin

module.exports = async function(deployer) {
    await deployer.deploy(Oracle, ZapCoordinator.address);
        await Oracle.deployed();
        await deployer.deploy(Client, ZapCoordinator.address, offChainOracleAddress, offChainOracleEndpoint);
};


