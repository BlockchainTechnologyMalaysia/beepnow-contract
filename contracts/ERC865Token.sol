pragma solidity ^0.4.23;

import './ERC865.sol';
import './openzeppelin-solidity-master/contracts/token/ERC20/StandardToken.sol';
import './openzeppelin-solidity-master/contracts/ownership/Ownable.sol';

/**
 * @title ERC865Token Token
 *
 * ERC865Token allows users paying transfers in tokens instead of gas
 * https://github.com/ethereum/EIPs/issues/865
 *
 */

contract ERC865Token is ERC865, StandardToken, Ownable {

    /* Nonces of transfers performed */
    mapping(bytes => bool) signatures;
    /* mapping of nonces of each user */
    mapping (address => uint256) nonces;

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);

    bytes4 internal constant transferSig = 0x48664c16;
    bytes4 internal constant approvalSig = 0xf7ac9c2e;
    bytes4 internal constant increaseApprovalSig = 0xa45f71ff;
    bytes4 internal constant decreaseApprovalSig = 0x59388d78;

    //return nonce using function
    function getNonce(address _owner) public view returns (uint256 nonce){
      return nonces[_owner];
    }


    /**
     * @notice Submit a presigned transfer
     * @param _signature bytes The signature, issued by the owner.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), transferSig, _to, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        require(_value.add(_fee) <= balances[from]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

    /**
     * @notice Submit a presigned approval
     * @param _signature bytes The signature, issued by the owner.
     * @param _spender address The address which will spend the funds.
     * @param _value uint256 The amount of tokens to allow.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), approvalSig, _spender, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        require(_value.add(_fee) <= balances[from]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        allowed[from][_spender] =_value;
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }

    /**
     * @notice Increase the amount of tokens that an owner allowed to a spender.
     * @param _signature bytes The signature, issued by the owner.
     * @param _spender address The address which will spend the funds.
     * @param _addedValue uint256 The amount of tokens to increase the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), increaseApprovalSig, _spender, _addedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        require(allowed[from][_spender].add(_addedValue).add(_fee) <= balances[from]);
        //require(_addedValue <= allowed[from][_spender]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        allowed[from][_spender] = allowed[from][_spender].add(_addedValue);
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, allowed[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

    /**
     * @notice Decrease the amount of tokens that an owner allowed to a spender.
     * @param _signature bytes The signature, issued by the owner
     * @param _spender address The address which will spend the funds.
     * @param _subtractedValue uint256 The amount of tokens to decrease the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), decreaseApprovalSig, _spender, _subtractedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        //require(_subtractedValue <= balances[from]);
        //require(_subtractedValue <= allowed[from][_spender]);
        //require(_subtractedValue <= allowed[from][_spender]);
        require(_fee <= balances[from]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        uint oldValue = allowed[from][_spender];
        if (_subtractedValue > oldValue) {
            allowed[from][_spender] = 0;
        } else {
            allowed[from][_spender] = oldValue.sub(_subtractedValue);
        }
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another
     * @param _signature bytes The signature, issued by the spender.
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
     * @param _nonce uint256 Presigned transaction number.
     */
    /*function transferFromPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(signatures[_signature] == false);
        signatures[_signature] = true;

        bytes32 hashedTx = transferFromPreSignedHashing(address(this), _from, _to, _value, _fee, _nonce);

        address spender = recover(hashedTx, _signature);
        require(spender != address(0));
        require(_value.add(_fee) <= balances[_from])​;

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][spender] = allowed[_from][spender].sub(_value);

        balances[spender] = balances[spender].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }*/

     /**
      * @notice Hash (keccak256) of the payload used by recoverPreSignedHash
      * @param _token address The address of the token
      * @param _spender address The address which will spend the funds.
      * @param _value uint256 The amount of tokens.
      * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
      * @param _nonce uint256 Presigned transaction number.
      */    
    function recoverPreSignedHash(
        address _token,
        bytes4 _functionSig,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
        )
      public pure returns (bytes32)
      {
        return keccak256(_token, _functionSig, _spender, _value, _fee, _nonce);
    }

    /**
     * @notice Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes sig) public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      //Check the signature length
      if (sig.length != 65) {
        return (address(0));
      }

      // Divide the signature in r, s and v variables
      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
      }

      // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
      if (v < 27) {
        v += 27;
      }

      // If the version is correct return the signer address
      if (v != 27 && v != 28) {
        return (address(0));
      } else {
        return ecrecover(hash, v, r, s);
      }
    }

}
