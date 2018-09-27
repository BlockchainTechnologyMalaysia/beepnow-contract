pragma solidity ^0.4.23;

import './openzeppelin-solidity-master/contracts/math/SafeMath.sol';
import './openzeppelin-solidity-master/contracts/ownership/Ownable.sol';

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds destinated to a payee until they
 * withdraw them. The contract that uses the escrow as its payment method
 * should be its owner, and provide public methods redirecting to the escrow's
 * deposit and withdraw.
 */
contract BeepRefund is Ownable {
  using SafeMath for uint256;
  address public destinationWalletaddr;

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) public depositsOfRefund;

  constructor(address destinationWallet) public {
    require(destinationWallet != address(0));
    destinationWalletaddr = destinationWallet;
  }

  function getDepositsOf(address _payee) public view returns (uint256) {
    return depositsOfRefund[_payee];
  }

  /**
  * @dev Stores the sent amount as credit to be withdrawn.
  * @param _payee The destination address of the funds.
  */
  function deposit(address _payee) public onlyOwner payable {
    uint256 amount = msg.value;
    depositsOfRefund[_payee] = depositsOfRefund[_payee].add(amount);

    emit Deposited(_payee, amount);
  }

  /**
  * @dev Withdraw accumulated balance for a payee.
  * @param _payee The address whose funds will be withdrawn and transferred to.
  */
  function withdraw(address _payee) public onlyOwner {
    uint256 payment = depositsOfRefund[_payee];
    assert(address(this).balance >= payment);

    depositsOfRefund[_payee] = 0;

    _payee.transfer(payment);

    emit Withdrawn(_payee, payment);
  }

  function transferToWallet() public onlyOwner {
    destinationWalletaddr.transfer(address(this).balance);
  }

  function getDeposits(address _investor) public view returns(uint256) {
    return depositsOfRefund[_investor];
  }
}
