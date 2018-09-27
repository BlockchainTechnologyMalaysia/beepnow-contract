pragma solidity 0.4.23;


import './BeepToken.sol';
import './BeepRefund.sol';
import './openzeppelin-solidity-master/contracts/lifecycle/Pausable.sol';
import './openzeppelin-solidity-master/contracts/math/SafeMath.sol';

contract BeepTokenGeneration is Pausable {
    using SafeMath for uint256; //invoking safemath library
    BeepToken token;
    // refund escrow used to hold funds while crowdsale is running
    BeepRefund public escrow;

    uint256 public ethRaised;
    uint256 public contributors;
    uint256 public purchasedCoins;
    uint256 public startDate = 1537833600; //  Tuesday, September 25, 2018 12:00:00 AM
    uint256 public endDate = 1564531140; // Tuesday, July 30, 2019 11:59:00 PM
    //uint256 public price = 40000000000000; // checked against dollar price and updated
    //uint256 public coinsRemaining = 3000000000; // Converted to a method based on allowance
    address public Admin;
    address public multiSig;
    address public ACT_Reserve;
    address public ACT_Refund;

    event Purchase(address indexed buyer, uint256 value, uint256 tokens);
    event Finished(uint256 etherRaised, uint256 purchasedCoins);
    event WhitelistedAddressAdded(address indexed addr);
    event WhitelistedAddressRemoved(address indexed addr);
    event SetEtherPriceEtherCap(address indexed addr, uint256 etherCap, uint256 tokenPrice);
    event CoinExhaustedRefund(address indexed addr, uint256 tokensRefunded);
    event ExcessEtherInvested(address indexed addr, uint256 ethersToRefund);


    // Public method for deposits of an address
    mapping(address => uint256) public deposits;
    // Public method for tokens purchased by an address
    mapping(address => uint256) public tokensPurchased;
    //public method for whitelist
    mapping (address => bool) public permissions;
    //public method for maximum ether cap in wei
    mapping (address => uint256) public maxEtherCap;
    //public method for price per token in wei
    mapping (address => uint256) public pricePerToken;
    //public method for excess of ethers invested for users
    mapping (address => uint256) public excessEtherInvestedRefund;


    // Modifier to check KYC verification of an address
    modifier onlyWhitelist() {
        require(permissions[msg.sender]);
        _;
    }

    constructor(address _Admin, address _tokenAddress, address _DestinationWallet, address _ReserveAccount) public {
        require(_Admin != address(0));require(_tokenAddress != address(0));require(_DestinationWallet != address(0));require(_ReserveAccount != address(0));
        Admin = _Admin;
        token = BeepToken(_tokenAddress);
        multiSig = _DestinationWallet;
        ACT_Reserve = _ReserveAccount;
        escrow = new BeepRefund(_DestinationWallet);
    }

    modifier MustBeAdmin() {
        require(msg.sender == Admin);
        _;
    }

    function newAdmin(address _newAdmin) onlyOwner public{
        require(_newAdmin != address(0));
        Admin = _newAdmin;
    }

    function whitelistAddress(address user, uint256 _maxEtherCap, uint256 _pricePerToken) MustBeAdmin public returns(bool success) {
        require(user != address(0));
        if (!permissions[user]) {
            permissions[user] = true;
            maxEtherCap[user] = _maxEtherCap;
            pricePerToken[user] = _pricePerToken;
            emit WhitelistedAddressAdded(user);
            emit SetEtherPriceEtherCap(user, _maxEtherCap, _pricePerToken);
            success = true;
        } else {
            maxEtherCap[user] = _maxEtherCap;
            pricePerToken[user] = _pricePerToken;
            emit SetEtherPriceEtherCap(user, _maxEtherCap, _pricePerToken);
            success = true;
        }
    }

    /*function whitelistMultipleAddress(address[] users) MustBeAdmin public returns(bool success) {
        for (uint256 i = 0; i < users.length; i++) {
            if (whitelistAddress(users[i])) {
                success = true;
            }
        }
        }*/

        function disableWhitelistAddress(address user) MustBeAdmin public returns(bool success) {
            require(user != address(0));
            if (permissions[user]) {
                permissions[user] = false;
                emit WhitelistedAddressRemoved(user);
                success = true;
            }
        }

        function getDeposits(address addr) public view returns(uint256) {
            return deposits[addr];
        }

        function getTokensPurchased(address addr) public view returns(uint256) {
            return tokensPurchased[addr];
        }

        // Setting start date. Should only be used incase of exceptional circumstances
        function setStart(uint256 when_) onlyOwner public {
            startDate = when_;
        }

        function when() public view returns(uint256) {
            return now;
        }

        // Method to check funding status
        function funding() public view returns(bool) {
            if (paused) return false; //contract is paused
            if (now < startDate) return false; // too early
            if (now > endDate) return false; // past time
            return true;
        }

        function finished() public view returns(bool) {
            if (now > endDate) return true;
            return false;
        }

        function() public payable onlyWhitelist whenNotPaused {
            createTokens(msg.sender, msg.value);
        }

        function linkCoin(address coin) onlyOwner public {
            require(coin != address(0));
            token = BeepToken(coin);
        }

        function coinAddress() public view returns(address) {
            return address(token);
        }

        // Setting price of token in wei
    /*function setPrice(uint256 _price) onlyOwner public {
        price = _price;
        }*/

        function coinsRemaining() public view returns (uint256) {
            return token.allowance(ACT_Reserve, this);
        }

        function createTokens(address recipient, uint256 value) private {
           require(recipient != address(0));
           //  Check for active fund raiser
           require(funding());
           // Check for minimum values
           //require(value >= 1 finney);
           if(deposits[recipient] < maxEtherCap[recipient]) {
            uint tokens;
            uint256 actualTokens;
            uint256 excessEtherInvested;
            uint256 ethersAllowed;
            uint coinExhaustedRefund = 0;

            // Calculate number of tokens
            if(value.add(deposits[recipient]) <= maxEtherCap[recipient]) {
                tokens = value.div(pricePerToken[recipient]);
                actualTokens = tokens;
                } else {
                    ethersAllowed = maxEtherCap[recipient].sub(deposits[recipient]);
                    tokens = ethersAllowed.div(pricePerToken[recipient]);
                    actualTokens = tokens;
                    excessEtherInvested = value.sub(ethersAllowed);
                    value = value.sub(excessEtherInvested);
                }

                // Refund issued when there are more tokens that needs to be issued that what remains in the crowdsale
                // Value in ether of excess tokens are refunded to the sender

                if (tokens >= coinsRemaining()) {
                    actualTokens = coinsRemaining();
                    coinExhaustedRefund = tokens.sub(coinsRemaining()); // refund amount in tokens
                    coinExhaustedRefund = coinExhaustedRefund.mul(pricePerToken[recipient]); // refund amount in ETH
                    //coinsRemaining = 0;
                    value = value.sub(coinExhaustedRefund);
                    emit Finished(ethRaised, purchasedCoins);
                }

                ethRaised = ethRaised.add(value); //Kept for internal evaluation purpose

                if (deposits[recipient] == 0) contributors++;

                purchasedCoins = purchasedCoins.add(actualTokens);

                tokensPurchased[recipient] = tokensPurchased[recipient].add(actualTokens);

                require(token.transferFrom(ACT_Reserve, recipient, actualTokens));

                emit Purchase(recipient, value, actualTokens);

                deposits[recipient] = deposits[recipient].add(value);


                if (coinExhaustedRefund > 0) {
                    recipient.transfer(coinExhaustedRefund);
                    emit CoinExhaustedRefund(recipient, coinExhaustedRefund);
                }

                if (excessEtherInvested > 0) {
                    excessEtherInvestedRefund[recipient] = excessEtherInvested;
                    //ACT_Refund.transfer(excessEtherInvested);
                    _forwardFunds(excessEtherInvested);
                    emit ExcessEtherInvested(recipient, excessEtherInvested);
                }

                multiSig.transfer(value);
            }
            else {
                excessEtherInvestedRefund[recipient] = excessEtherInvestedRefund[recipient].add(value);
                //ACT_Refund.transfer(value);
                _forwardFunds(value);
                emit ExcessEtherInvested(recipient, value);
            }
        }

        //Note: To be deleted in future.
        // Setting End date. Should only be used incase of exceptional circumstances
        function setEnd(uint256 when_) onlyOwner public {
            endDate = when_;
        }

        //function to calim refund
        function claimRefund() public {
            escrow.withdraw(msg.sender);
        }

        /**
        * @dev Overrides Crowdsale fund forwarding, sending funds to escrow.
        */
        function _forwardFunds(uint256 _value) internal {
            escrow.deposit.value(_value)(msg.sender);
        }

        function _transferToWallet() public onlyOwner {
            escrow.transferToWallet();
        }

        function getRefundDeposits(address _investor) public view returns(uint256) {
          return escrow.getDeposits(_investor);
        }
    }
