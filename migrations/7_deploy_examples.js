var Oracle = artifacts.require("./Oracle.sol");
var Client = artifacts.require("./Client.sol");
const ZapCoordinator = artifacts.require('./ZapCoordinator.sol');
var offChainOracleAddress = '0x6d0939163A0Ac18ACf54eC796A291c0915c0019A'; //Pokemon API Offchain Oracle
var offChainOracleEndpoint = '0x506f6b656d6f6e20415049000000000000000000000000000000000000000000'; //Pokemon API
const OracleEndpoint = "0x4f6e436861696e456e64706f696e744d6f696e00000000000000000000000000"; //OnChainEndpointMoin

module.exports = async function(deployer) {
    await deployer.deploy(Oracle, ZapCoordinator.address);
        await Oracle.deployed();
        await deployer.deploy(Client, ZapCoordinator.address, Oracle.address, OracleEndpoint);
};


