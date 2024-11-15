/**
 *Submitted for verification at Etherscan.io on 2019-10-22
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/CCP.sol

pragma solidity ^0.5.11;




contract CCP is Ownable {

   using SafeMath for uint256;

    /*** EVENTS ***/

    event Staking(address indexed borrower, address tokenAddress, uint256 stakingAmount);
    event RefundStakings(address indexed borrower, address tokenAddress, uint256 refundAmount);
    event NewCredit(address indexed borrower, uint256 creditID, uint creditAmount);
    event NewCreditRule(address indexed lender, uint256 creditRuleID);
    event Payment(address indexed borrower, uint256 creditID, uint256 paidAmount);
    event LogSlashing(address indexed borrower, address tokenAddress, uint256 slashingAmount);
    event MinStakingChanged(address tokenAddress, uint256 timestamp, uint256 stakingAmount);


    /*** DATA TYPES ***/
    struct CreditRule {
        address lenderAddress;
        uint256 startDate;
        uint256 endDate;
        uint256 validityPeriod;
        uint256 maxAmount;
        uint32 interestRate;
        uint32 lateRate;
        uint32 term;
        uint16 minAllowedScore;
    }

    struct Credit{
        address borrowerAddress;
        uint256 creditRuleID;
        uint256 timestamp;
        uint256 amount;
    }

    /*** STORAGE ***/

    /// @dev Addres of Colendi Controller Account
    address public creditController;

    /// @dev Minimum Staking amount allowed for borrowers
    mapping(address => uint256) public minStakings;

    /// @dev CreditRuleIDs to credit rules
    mapping(uint256 => CreditRule) public creditRules;

    /// @dev CreditIDs to credits
    mapping(uint256 => Credit) public credits;

    /// @dev Amount of stakes borrowers has locked to use CCP
    /// @dev TokenAddress -> BorrowerAddress -> StakingAmount
    mapping(address => mapping(address => uint256)) public borrowerStakes;

    /// @dev Amount of slashing and refunds
    /// @dev TokenAddress -> Amount
    mapping(address => uint256) public slashsAndRefunds;

    /*** MODIFIERS ***/
    modifier onlyCreditController(){
        require(msg.sender == creditController, "Only colendi can execute this transaction");
        _;
    }

    function stakeWithERC20(address borrower, address tokenAddress, uint amount) public {
        require(minStakings[tokenAddress] > 0, "Only eligible Erc20 token are allowed for staking");
        require(amount>0 && (amount >= minStakings[tokenAddress] || borrowerStakes[tokenAddress][borrower] > 0),
        "Requested amount is less than minimum");
        require(ERC20(tokenAddress).transferFrom(borrower,address(this), amount), "Not enough approved ERC20");
        borrowerStakes[tokenAddress][borrower] = borrowerStakes[tokenAddress][borrower].add(amount);
        emit Staking(borrower, tokenAddress, amount);
    }

    /// @dev address(0) is used to denote Ethereum
    function stakeWithETH(address borrower) public payable {
        require(minStakings[address(0)] > 0 && ( msg.value >= minStakings[address(0)] || borrowerStakes[address(0)][borrower] > 0),
        "Can not stake less than minimum amount");
        borrowerStakes[address(0)][borrower] = borrowerStakes[address(0)][borrower].add(msg.value);
        emit Staking(borrower, address(0), msg.value);
    }


    function refundStakings (address borrower, address tokenAddress, uint amount) external onlyCreditController {
        require(borrowerStakes[tokenAddress][borrower] >= amount, "Borrower does not have these amount of stakings");
        if(tokenAddress == address(0)) {
            address(uint160(borrower)).transfer(amount);
            borrowerStakes[tokenAddress][borrower] = borrowerStakes[tokenAddress][borrower].sub(amount);
        }
        else{
            require(ERC20(tokenAddress).transfer(borrower, amount), "Not enough approved ERC20");
            borrowerStakes[tokenAddress][borrower] = borrowerStakes[tokenAddress][borrower].sub(amount);
        }
        emit RefundStakings(borrower, tokenAddress, amount);
    }

    function createCredit( address _borrower, uint256 _amount, uint256 _creditID, uint256 _creditRuleID, uint256 _timestamp)
    external onlyCreditController {
        require(credits[_creditID].borrowerAddress == address(0), "The credit has already been issued");
        require(creditRules[_creditRuleID].lenderAddress != address(0), "There is no such credit rule defined");
        Credit memory credit = Credit(
            {borrowerAddress: _borrower,
            creditRuleID : _creditRuleID,
            timestamp : _timestamp,
            amount : _amount
            });
        credits[_creditID] = credit;
        emit NewCredit(_borrower, _creditID, _amount);
    }

    function createCreditRule(
        address _lender,
        uint256 _creditRuleID,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _validityPeriod,
        uint256 _maxAmount,
        uint32 _interestRate,
        uint32 _lateRate,
        uint32 _term,
        uint16 _minAllowedScore)
    external onlyCreditController  {
        CreditRule memory creditRule = CreditRule({
            lenderAddress: _lender,
            startDate: _startDate,
            endDate: _endDate,
            validityPeriod: _validityPeriod,
            maxAmount:_maxAmount,
            interestRate: _interestRate,
            lateRate: _lateRate,
            term: _term,
            minAllowedScore: _minAllowedScore
        });
        require(creditRules[_creditRuleID].lenderAddress == address(0), "The credit rule has already been issued");

        creditRules[_creditRuleID] = creditRule;
        emit NewCreditRule(_lender, _creditRuleID);
    }

    function payBack( address _borrower, uint256 _creditID) public payable {
        require(credits[_creditID].borrowerAddress == _borrower, "No matching credit with provided address");
        slashsAndRefunds[address(0)] = slashsAndRefunds[address(0)].add(msg.value);
        emit Payment(_borrower, _creditID, msg.value);
    }

    function setMinimumStaking(address tokenAddress, uint256 _minStaking) external onlyCreditController {
        minStakings[tokenAddress] = _minStaking;
        emit MinStakingChanged(tokenAddress, now,  _minStaking);
    }

    function slashBorrower(address borrower, address tokenAddress, uint256 amount) external onlyCreditController {
        slashsAndRefunds[tokenAddress] = slashsAndRefunds[tokenAddress].add(amount);
        borrowerStakes[tokenAddress][borrower] = borrowerStakes[tokenAddress][borrower].sub(amount);
        emit LogSlashing(borrower, tokenAddress, amount);
    }

    function transferTokenFunds(address tokenAddress) external onlyCreditController {
        require(ERC20(tokenAddress).transfer(msg.sender, slashsAndRefunds[tokenAddress]), "Failed ERC20 transfer");
        slashsAndRefunds[tokenAddress] = 0;
    }

    function transferETHFunds() external onlyCreditController {
        address(uint160(msg.sender)).transfer(slashsAndRefunds[address(0)]);
        slashsAndRefunds[address(0)] = 0;
    }

    function transferColendiController(address _colendiController) public onlyOwner{
        creditController = _colendiController;
    }

}