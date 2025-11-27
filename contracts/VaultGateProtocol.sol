// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VaultGate Protocol
 * @dev A secure vault management system with access control and time-locked withdrawals
 */
contract VaultGateProtocol {
    
    struct Vault {
        uint256 balance;
        uint256 lockTime;
        address owner;
        bool exists;
        uint256 createdAt;
    }
    
    mapping(address => Vault) public vaults;
    mapping(address => bool) public authorizedUsers;
    
    address public admin;
    uint256 public totalVaultsCreated;
    uint256 public totalValueLocked;
    uint256 public minimumLockPeriod;
    
    event VaultCreated(address indexed owner, uint256 amount, uint256 lockTime);
    event DepositMade(address indexed owner, uint256 amount);
    event WithdrawalMade(address indexed owner, uint256 amount);
    event LockTimeExtended(address indexed owner, uint256 newLockTime);
    event UserAuthorized(address indexed user);
    event UserRevoked(address indexed user);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    modifier onlyVaultOwner() {
        require(vaults[msg.sender].exists, "Vault does not exist");
        require(vaults[msg.sender].owner == msg.sender, "Not vault owner");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorizedUsers[msg.sender] || msg.sender == admin, "Not authorized");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        minimumLockPeriod = 1 days;
        authorizedUsers[admin] = true;
    }
    
    /**
     * @dev Function 1: Create a new vault with initial deposit
     * @param _lockTime Time in seconds to lock the vault
     */
    function createVault(uint256 _lockTime) external payable {
        require(msg.value > 0, "Must deposit some ETH");
        require(!vaults[msg.sender].exists, "Vault already exists");
        require(_lockTime >= minimumLockPeriod, "Lock time too short");
        
        vaults[msg.sender] = Vault({
            balance: msg.value,
            lockTime: block.timestamp + _lockTime,
            owner: msg.sender,
            exists: true,
            createdAt: block.timestamp
        });
        
        totalVaultsCreated++;
        totalValueLocked += msg.value;
        
        emit VaultCreated(msg.sender, msg.value, block.timestamp + _lockTime);
    }
    
    /**
     * @dev Function 2: Deposit additional funds to existing vault
     */
    function deposit() external payable onlyVaultOwner {
        require(msg.value > 0, "Must deposit some ETH");
        
        vaults[msg.sender].balance += msg.value;
        totalValueLocked += msg.value;
        
        emit DepositMade(msg.sender, msg.value);
    }
    
    /**
     * @dev Function 3: Withdraw funds after lock period expires
     * @param _amount Amount to withdraw
     */
    function withdraw(uint256 _amount) external onlyVaultOwner {
        Vault storage vault = vaults[msg.sender];
        require(block.timestamp >= vault.lockTime, "Vault is still locked");
        require(_amount <= vault.balance, "Insufficient balance");
        
        vault.balance -= _amount;
        totalValueLocked -= _amount;
        
        payable(msg.sender).transfer(_amount);
        
        emit WithdrawalMade(msg.sender, _amount);
    }
    
    /**
     * @dev Function 4: Extend lock time for additional security
     * @param _additionalTime Additional time in seconds
     */
    function extendLockTime(uint256 _additionalTime) external onlyVaultOwner {
        require(_additionalTime > 0, "Must extend by positive time");
        
        vaults[msg.sender].lockTime += _additionalTime;
        
        emit LockTimeExtended(msg.sender, vaults[msg.sender].lockTime);
    }
    
    /**
     * @dev Function 5: Get vault details
     * @param _owner Address of vault owner
     */
    function getVaultInfo(address _owner) external view returns (
        uint256 balance,
        uint256 lockTime,
        uint256 timeRemaining,
        uint256 createdAt
    ) {
        Vault memory vault = vaults[_owner];
        require(vault.exists, "Vault does not exist");
        
        uint256 remaining = 0;
        if (block.timestamp < vault.lockTime) {
            remaining = vault.lockTime - block.timestamp;
        }
        
        return (vault.balance, vault.lockTime, remaining, vault.createdAt);
    }
    
    /**
     * @dev Function 6: Authorize user for special privileges
     * @param _user Address to authorize
     */
    function authorizeUser(address _user) external onlyAdmin {
        require(_user != address(0), "Invalid address");
        require(!authorizedUsers[_user], "User already authorized");
        
        authorizedUsers[_user] = true;
        
        emit UserAuthorized(_user);
    }
    
    /**
     * @dev Function 7: Revoke user authorization
     * @param _user Address to revoke
     */
    function revokeUser(address _user) external onlyAdmin {
        require(_user != admin, "Cannot revoke admin");
        require(authorizedUsers[_user], "User not authorized");
        
        authorizedUsers[_user] = false;
        
        emit UserRevoked(_user);
    }
    
    /**
     * @dev Function 8: Check if vault is unlocked
     * @param _owner Address of vault owner
     */
    function isVaultUnlocked(address _owner) external view returns (bool) {
        require(vaults[_owner].exists, "Vault does not exist");
        return block.timestamp >= vaults[_owner].lockTime;
    }
    
    /**
     * @dev Function 9: Update minimum lock period
     * @param _newMinimum New minimum lock period in seconds
     */
    function updateMinimumLockPeriod(uint256 _newMinimum) external onlyAdmin {
        require(_newMinimum > 0, "Minimum must be positive");
        minimumLockPeriod = _newMinimum;
    }
    
    /**
     * @dev Function 10: Emergency withdrawal (only authorized users)
     * Allows withdrawal even during lock period in emergencies
     */
    function emergencyWithdraw() external onlyVaultOwner onlyAuthorized {
        Vault storage vault = vaults[msg.sender];
        uint256 amount = vault.balance;
        require(amount > 0, "No balance to withdraw");
        
        vault.balance = 0;
        totalValueLocked -= amount;
        
        payable(msg.sender).transfer(amount);
        
        emit EmergencyWithdrawal(msg.sender, amount);
    }
    
    /**
     * @dev Get total protocol statistics
     */
    function getProtocolStats() external view returns (
        uint256 vaultsCreated,
        uint256 valueLocked,
        uint256 minLockPeriod
    ) {
        return (totalVaultsCreated, totalValueLocked, minimumLockPeriod);
    }
}