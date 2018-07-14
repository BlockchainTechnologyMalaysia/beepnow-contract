var BeepToken=artifacts.require("./BeepToken.sol");

module.exports = function(deployer,network,accounts) {
  const ReserveAccount=web3.eth.accounts[3];
  const BeepTokenAdmin=web3.eth.accounts[3];
  //const DestinationWallet="0xCC0A7383ED9BC24D3b719bCE59A56e477DfEEA97"; //hardware wallet
  const DestinationWallet="0x9848132754209DecC58809B611910AcA9a7417a9"; //metamask wallet
  
  deployer.deploy(BeepToken,BeepTokenAdmin,ReserveAccount);
};




// With ICO contract deployment
/*
var BeepToken=artifacts.require("./BeepToken.sol");
var BeepTokenGeneration=artifacts.require("./BeepTokenGeneration.sol");

module.exports = function(deployer,network,accounts) {
  const ReserveAccount=web3.eth.accounts[3];
  const ICOAdmin=web3.eth.accounts[0];
  const BeepTokenAdmin=web3.eth.accounts[3];
  //const DestinationWallet="0xCC0A7383ED9BC24D3b719bCE59A56e477DfEEA97"; //hardware wallet
  const DestinationWallet="0x9848132754209DecC58809B611910AcA9a7417a9"; //metamask wallet
  
  deployer.deploy(BeepToken,BeepTokenAdmin,ReserveAccount).then(function(instance){
     tokenAddress=BeepToken.address;
     return deployer.deploy(BeepTokenGeneration,ICOAdmin,tokenAddress,DestinationWallet,ReserveAccount);
  });
};
*/