require('babel-register');
require('babel-polyfill');

const HDWalletProvider = require('truffle-hdwallet-provider-privkey');
const HDWalletProviderMem = require('truffle-hdwallet-provider');

const mnemonic =
  'toward casual aware brand sea sport vital unknown escape elder soldier siren';

module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 9545,
      network_id: '*',
      // a lot of gas for testing
      gas: '200000000000000000000'
    },
    'ganache-cli': {
      host: 'localhost',
      port: 8545,
      network_id: '*',
      gas: '6721975',
      gasPrice: '10000000'
    },
    'ganache-gui': {
      host: 'localhost',
      port: 7545,
      network_id: '5777',
      gas: '6700000',
      gasPrice: '10000000'
    },
    docker: {
      host: 'bootstrap',
      port: 8545,
      network_id: '*',
      from: '0x010e49e47cbb34e67c072702ed6f4d8b273f751f' // must be first account in accounts[] array inside tests
    },
    'docker-local': {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
      from: '0x010e49e47cbb34e67c072702ed6f4d8b273f751f' // must be first account in accounts[] array inside tests
    },

    kovan: {
      provider: new HDWalletProviderMem(
        mnemonic,
        'wss://kovan.infura.io/ws/xeb916AFjrcttuQlezyq'
      ),
      gas: '6238278',
      gasPrice: '8000000000',
      network_id: '*'
    }
  }
};
