pragma solidity ^0.4.23;

import './ERC865Token.sol';
import './openzeppelin-solidity-master/contracts/ownership/rbac/RBAC.sol';

contract BeepToken is ERC865Token, RBAC{

    string public constant name = "Beepnow Token";
    string public constant symbol = "BPN";
    uint8 public constant decimals = 0;
    
    /* Mapping of whitelisted users */
    mapping (address => bool) transfersBlacklist;
    string constant ROLE_ADMIN = "admin";
    string constant ROLE_DELEGATE = "delegate";

    bytes4 internal constant transferSig = 0x48664c16;

    event UserInsertedInBlackList(address indexed user);
    event UserRemovedFromBlackList(address indexed user);
    event TransferWhitelistOnly(bool flag);
    event DelegatedEscrow(address indexed guest, address indexed beeper, uint256 total, uint256 nonce, bytes signature);
    event DelegatedRemittance(address indexed guest, address indexed beeper, uint256 value, uint256 _fee, uint256 nonce, bytes signature);

	modifier onlyAdmin() {
        require(hasRole(msg.sender, ROLE_ADMIN));
        _;
    }

    modifier onlyAdminOrDelegates() {
        require(hasRole(msg.sender, ROLE_ADMIN) || hasRole(msg.sender, ROLE_DELEGATE));
        _;
    }

    /*modifier onlyWhitelisted(bytes _signature, address _from, uint256 _value, uint256 _fee, uint256 _nonce) {
        bytes32 hashedTx = recoverPreSignedHash(address(this), transferSig, _from, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(!isUserInBlackList(from));
        _;
    }*/

    function onlyWhitelisted(bytes _signature, address _from, uint256 _value, uint256 _fee, uint256 _nonce) internal view returns(bool) {
        bytes32 hashedTx = recoverPreSignedHash(address(this), transferSig, _from, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(!isUserInBlackList(from));
        return true;
    }

    function addAdmin(address _addr) onlyOwner public {
        addRole(_addr, ROLE_ADMIN);
    }

    function removeAdmin(address _addr) onlyOwner public {
        removeRole(_addr, ROLE_ADMIN);
    }

    function addDelegate(address _addr) onlyAdmin public {
        addRole(_addr, ROLE_DELEGATE);
    }

    function removeDelegate(address _addr) onlyAdmin public {
        removeRole(_addr, ROLE_DELEGATE);
    }

    constructor(address _Admin, address reserve) public {
        require(_Admin != address(0));
        require(reserve != address(0));
        totalSupply_ = 17500000000;
		balances[reserve] = totalSupply_;
        emit Transfer(address(0), reserve, totalSupply_);
        addRole(_Admin, ROLE_ADMIN);
    }

    /**
     * Is the address allowed to transfer
     * @return true if the sender can transfer
     */
    function isUserInBlackList(address _user) public constant returns (bool) {
        require(_user != 0x0);
        return transfersBlacklist[_user];
    }


    /**
     *  User removed from Blacklist
     */
    function whitelistUserForTransfers(address _user) onlyAdmin public {
        require(isUserInBlackList(_user));
        transfersBlacklist[_user] = false;
        emit UserRemovedFromBlackList(_user);
    }

    /**
     *  User inserted into Blacklist
     */
    function blacklistUserForTransfers(address _user) onlyAdmin public {
        require(!isUserInBlackList(_user));
        transfersBlacklist[_user] = true;
        emit UserInsertedInBlackList(_user);
    }

    /**
    * @notice transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!isUserInBlackList(msg.sender));
        return super.transfer(_to, _value);
    }

    /**
     * @notice Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(!isUserInBlackList(_from));
        return super.transferFrom(_from, _to, _value);
    }

    function transferPreSigned(bytes _signature, address _to, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_to != address(0));
        onlyWhitelisted(_signature, _to, _value, _fee, _nonce);
        return super.transferPreSigned(_signature, _to, _value, _fee, _nonce);
    }

    function approvePreSigned(bytes _signature, address _spender, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_spender != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.approvePreSigned(_signature, _spender, _value, _fee, _nonce);
    }

    function increaseApprovalPreSigned(bytes _signature, address _spender, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_spender != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.increaseApprovalPreSigned(_signature, _spender, _value, _fee, _nonce);
    }

    function decreaseApprovalPreSigned(bytes _signature, address _spender, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_spender != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.decreaseApprovalPreSigned(_signature, _spender, _value, _fee, _nonce);
    }

    /*function transferFromPreSigned(bytes _signature, address _from, address _to, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_from != address(0));
        require(_to != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.transferPreSigned(_signature, _to, _value, _fee, _nonce);
    }*/

    /* Locking funds. User signs the offline transaction and the admin will execute this, through which the admin account the funds */
    function delegatedSignedEscrow(bytes _signature, address _from, address _to, address _admin, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdmin public returns (bool){
        require(_from != address(0));
        require(_to != address(0));
        require(_admin != address(0));
        onlyWhitelisted(_signature, _from, _value, _fee, _nonce); 
        require(hasRole(_admin, ROLE_ADMIN));
        require(_nonce == nonces[_from].add(1));
        require(signatures[_signature] == false);
        uint256 _total = _value.add(_fee);
        require(_total <= balances[_from]);

        nonces[_from] = _nonce;
        signatures[_signature] = true;
        balances[_from] = balances[_from].sub(_total);
        balances[_admin] = balances[_admin].add(_total);

        emit Transfer(_from, _admin, _total);
        emit DelegatedEscrow(_from, _to, _total, _nonce, _signature);
        return true;
    }

    /* Releasing funds.  User signs the offline transaction and the admin will execute this, in which other user receives the funds. */
    function delegatedSignedRemittance(bytes _signature, address _from, address _to, address _admin, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdmin public returns (bool){
        require(_from != address(0));
        require(_to != address(0));
        require(_admin != address(0));
        onlyWhitelisted(_signature, _from, _value, _fee, _nonce);
        require(hasRole(_admin, ROLE_ADMIN));
        require(_nonce == nonces[_from].add(1));
        require(signatures[_signature] == false);
        require(_value.add(_fee) <= balances[_from]);

        nonces[_from] = _nonce;
        signatures[_signature] = true;
        balances[_from] = balances[_from].sub(_value).sub(_fee);
        balances[_admin] = balances[_admin].add(_fee);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        emit Transfer(_from, _admin, _fee);
        emit DelegatedRemittance(_from, _to, _value, _fee, _nonce, _signature);
        return true;
    }
    
}
