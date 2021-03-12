pragma solidity ^0.7.0;

interface IBEP20 {
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.
 
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a pbepentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
 
    uint256 private _status;
 
    constructor() {
        _status = _NOT_ENTERED;
    }
 
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
 
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
 
        _;
 
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
 
contract Multisig is ReentrancyGuard {
    IBEP20 public tokenToTransfer;
    bool public canTransferToken;
    address public recipientForToken;
    uint256 public amountToTransferToken;
    
    bool public canTransferBNB;
    address payable public recipientForBNB;
    uint256 public amountToTransferForBNB;
    
    address payable public owner1;
    address payable public owner2 = 0xE298a311949745b7009174A9bD7c990ffE3Eea5E;
    
    constructor() {
        owner1 = msg.sender;
    }
    
    receive() payable external {
        
    }
    
    function initializeTransferToken(address _recipientForToken, IBEP20 _tokenToTransfer,uint256  _amountToTransferToken) external nonReentrant {
        require(msg.sender == owner2, "Only owner2 can initializeTransfer");
        recipientForToken = _recipientForToken;
        tokenToTransfer = _tokenToTransfer;
        amountToTransferToken = _amountToTransferToken;
        canTransferToken = true;
    }
    
    function transferToken(address _recipientForToken, IBEP20 _tokenToTransfer, uint256 _amountToTransferToken) external nonReentrant {
         require(msg.sender == owner1, "Only owner1 can transferToken");
         require(canTransferToken, "Trnsfer is not initialized");
         require(recipientForToken != address(0));
         require(tokenToTransfer != IBEP20(0));
         require(_recipientForToken == recipientForToken, "Recptient is not the same as the in the initialized recipient");
         require(_tokenToTransfer == tokenToTransfer, "tokenToTransfer is not the same as the in the initialized tokenToTransfer");
         require(_amountToTransferToken == amountToTransferToken, "amountToTransfer is not the same as the in the initialized amountToTransfer");
         canTransferToken = false;
         tokenToTransfer = IBEP20(0);
         amountToTransferToken = 0;
         recipientForToken = address(0);
         IBEP20(_tokenToTransfer).transfer(_recipientForToken, _amountToTransferToken);
    }
    
    
    function initializeTransferBNB(address payable _recipientForBNB, uint256  _amountToTransferBNB) external nonReentrant {
        require(msg.sender == owner2, "Only owner2 can initializeTransfer");
        recipientForBNB = _recipientForBNB;
        amountToTransferForBNB = _amountToTransferBNB;
        canTransferBNB = true;
    }
    
    function transferBNB(address payable _recipientForBNB,  uint256 _amountToTransferBNB) external nonReentrant {
         require(msg.sender == owner1, "Only owner1 can transferToken");
         require(canTransferBNB, "Trnsfer is not initialized");
         require(recipientForBNB != address(0));
         require(recipientForBNB == _recipientForBNB, "Recptient is not the same as the in the initialized recipient");
         require(amountToTransferForBNB == _amountToTransferBNB, "amountToTransfer is not the same as the in the initialized amountToTransfer");
         canTransferBNB = false;
         amountToTransferForBNB = 0;
         recipientForBNB = address(0);
         _recipientForBNB.transfer(_amountToTransferBNB);
    }
}