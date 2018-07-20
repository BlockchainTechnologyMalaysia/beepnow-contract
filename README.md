# Beepnow

Beepnow is a platform listing a wide variety of services from professionals like doctors, accountants, lawyers, to many other types of services like housekeeping, luggage re-delivery, tutoring, and many more.

With beepnow, you can easily request work and generate income!
There is no cash exchange either online or in-person and your safety is ensured.
Everything from request to settlement is done on your smartphone within our application using Beepnow tokens.

## Token Contract

Beepnow token smartcontract is created on ERC-20 based standard token.

Beepnow token transfers are backed with ERC-865 standard so it delegates the transafers of tokens through the application.


## Contract deployment instructions via truffle

Initially
---------
If you are using local geth accounts then Unlock Account before deployment
update your truffle to latest version and declare it globally - npm install -g truffle


Go to build folder
------------------
Check for 2_deploy_contracts.js file and setup the deployment order and check for the accounts to be set for admin roles.


Go to beepnow-contract folder
-----------------------------
truffle console
compile
migrate --reset
(You will receive the BeepToken contract address for further reference)

Note: delete the build contracts folder if you want to redeploy the contract.


set the variables in the truffle console so as to interact with the contracts
------------------------------------------------------------------------------
BeepToken.deployed().then(function(instance){token=instance}) - if you are declaring immediately when Beepoken contract is deployed. 

(or)

token = BeepToken.at ("tokenContractAddress") - To interact with the contract later on after deployment.
