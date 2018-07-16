var BeepToken=artifacts.require("./BeepToken.sol");

module.exports = function(deployer,network,accounts) {
  const ReserveAccount=web3.eth.accounts[3];
  const BeepTokenAdmin=web3.eth.accounts[3];  
  deployer.deploy(BeepToken,BeepTokenAdmin,ReserveAccount);
};

