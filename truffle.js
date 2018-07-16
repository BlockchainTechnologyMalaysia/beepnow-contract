module.exports = {
  networks: {
    development: {
      //deployment of the contract using from:accounts[0] & token approve and allowance using from:accounts[3], then change back the default account to from:accounts[0].
      from: "0x3f2c95fbd04bb158c9e4102394b0f2420bfcd219", // eth.accounts[0] - main node
      //from: "0x5b726c3970381f99a39c5124222840e0a792eb06", // eth.accounts[3] - main node
      host: "127.0.0.1", // main net primary node
      port: 6565, //main net node
      network_id: "*"
    }
  }
};
