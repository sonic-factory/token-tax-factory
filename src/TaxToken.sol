// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title TaxToken contract
 * @notice This contract implements an ERC20 token with a transfer tax mechanism.
 * @dev The tax is applied on transfers and the tax amount is burned by default.
 */
contract TaxToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {

    /// @notice Thrown when the tax rate exceeds the maximum tax rate
    error TaxRateExceedsMax();
    /// @notice Thrown when the address set is zero
    error ZeroAddress();
    /// @notice Thrown when the amount is zero
    error ZeroAmount();

    /// @notice Scaling factor for decimal precision.
    uint256 public constant SCALING_FACTOR = 10_000; 
    /// @notice Transfer tax rate in basis points. (default = 5%)
    uint256 public transferTaxRate;
    /// @notice Maximum tax rate in basis points. (default = 20%)
    uint256 public maxTaxRate;

    /// @notice Recipient addresses that are to be excluded from tax.
    mapping(address => bool) public noTaxRecipient;
    /// @notice Sender addresses that are to be excluded from tax.
    mapping(address => bool) public noTaxSender;

    /// @notice Token mint counter
    uint256 public totalMinted = 0;
    /// @notice Token burn counter
    uint256 public totalBurned = 0;

    /// @notice Event emitted when the transfer tax rate is updated.
    event TransferTaxRateUpdated(address indexed owner, uint256 newRate);
    /// @notice Event emitted when a no tax sender address is set.
    event SetNoTaxSenderAddr(address indexed owner, address indexed noTaxSenderAddr, bool _value);
    /// @notice Event emitted when a no tax recipient address is set.
    event SetNoTaxRecipientAddr(address indexed owner, address indexed noTaxRecipientAddr, bool _value);

    /// @notice Constructor arguments for the TaxToken contract.
    /// @param _name Full name of the token.
    /// @param _symbol Short name of the token.
    /// @param _initialSupply Number of tokens to be minted. Expressed in wei.
    /// @param _transferTaxRate Transfer tax rate to be imposed. Expressed in basis points (ex. 1_000 = 10%).
    /// @param _maxTaxRate Maximum tax rate. Once set, CANNOT be modified again.
    /// @dev The constructor sets the initial values for the token and mints the initial supply to the owner.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint256 _transferTaxRate,
        uint256 _maxTaxRate

       ) ERC20(_name, _symbol) Ownable(msg.sender) {

        transferTaxRate = _transferTaxRate;
        maxTaxRate = _maxTaxRate;

        noTaxRecipient[msg.sender] = true;
        noTaxSender[msg.sender] = true;

        totalMinted = totalMinted + _initialSupply;
        _mint(msg.sender, _initialSupply);

        emit TransferTaxRateUpdated(msg.sender, transferTaxRate);
        emit SetNoTaxSenderAddr(msg.sender, msg.sender, true);
        emit SetNoTaxRecipientAddr(msg.sender, msg.sender, true);
    }

    /// @notice External privileged function to create or mint an X amount of tokens to a specified address.
    function mint(address _to, uint256 _amount) external onlyOwner {
        if (_to == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroAmount();

        totalMinted = totalMinted + _amount;   
        _mint(_to, _amount);
    }

    /// @notice External function to burn or destroy an X amount of tokens.
    function burn(uint256 _amount) external {
        if (_amount == 0) revert ZeroAmount();

        totalBurned = totalBurned + _amount;
        _burn(msg.sender, _amount);
    }

    /// @notice Overrides transfer function to meet tokenomics of tax token
    function _update(address from, address to, uint256 value) internal virtual override {
        
        // This computation results to a rounded up tax amount that can handle small amounts. Rounds up to minimum of 1 wei.
        uint256 taxAmount = value * transferTaxRate / SCALING_FACTOR;
        uint256 sendAmount = value - taxAmount;

        if (taxAmount == 0 || noTaxRecipient[to] == true || noTaxSender[from] == true || from == address(0) || to == address(0)) {

            // Transfer with no Tax
            super._update(from, to, value);  
            
        } else {

            totalBurned = totalBurned + taxAmount;

            //Transfer with tax, burns the tax amount and transfers the net amount.
            _burn(from, taxAmount);
            super._update(from, to, sendAmount);
        }
    }

    /// @notice External privileged function to update the transfer tax rate up to the maximum tax rate set.
    function updateTransferTaxRate(uint256 _transferTaxRate) external onlyOwner {
        if (_transferTaxRate > maxTaxRate) revert TaxRateExceedsMax();

        transferTaxRate = _transferTaxRate;

        emit TransferTaxRateUpdated(msg.sender, _transferTaxRate);
    }

    /// @notice External privileged function to update the no tax mapping for senders.
    function setNoTaxSenderAddr(address _noTaxSenderAddr, bool _value) external onlyOwner {
        noTaxSender[_noTaxSenderAddr] = _value;

        emit SetNoTaxSenderAddr(msg.sender, _noTaxSenderAddr, _value);
    }

    /// @notice External privileged function to update the no tax mapping for recipients.
    function setNoTaxRecipientAddr(address _noTaxRecipientAddr, bool _value) external onlyOwner {
        noTaxRecipient[_noTaxRecipientAddr] = _value;

        emit SetNoTaxRecipientAddr(msg.sender, _noTaxRecipientAddr, _value);
    }
}