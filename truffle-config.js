var HDWalletProvider = require("truffle-hdwallet-provider");
const MNEMONIC = 'iron mother cage rubber acid ignore leaf trumpet feature seed quarter sausage'; // this shouldn't be here

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    solc: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    },
    ropsten: {
      provider: () => new HDWalletProvider(MNEMONIC, "https://ropsten.infura.io/v3/8953d9658726483d8fdef4edcdbb4542"),
      network_id: 3,
      gas: 4000000
    }
  }
};