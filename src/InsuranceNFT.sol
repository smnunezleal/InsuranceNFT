// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ILendingProtocol {
    function getUserPosition(address user) external view returns (uint256 totalCollateral, uint256 totalDebt);
}

contract InsuranceNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
    IERC20 public usdc;
    ILendingProtocol public lendingProtocol;
    
    struct Policy {
        address policyHolder;
        uint256 amountInsured;
        string uri;
        bool isClaimable;
    }
    
    mapping(uint256 => Policy) public policies;
    address public oracle;
    address public governance;
    
    // Withdrawal pattern
    mapping(address => uint256) public pendingWithdrawals;
    
    // Timelock
    uint256 public constant TIMELOCK = 2 days;
    uint256 public timelockExpiry;
    address public newGovernance;
    
    constructor(address _usdc, address _oracle, address _lendingProtocol) ERC721("InsuranceNFT", "INFT") {
        usdc = IERC20(_usdc);
        oracle = _oracle;
        lendingProtocol = ILendingProtocol(_lendingProtocol);
        governance = msg.sender;
    }
    
    modifier onlyOracle() {
        require(msg.sender == oracle, "Not the oracle");
        _;
    }
    
    modifier onlyGovernance() {
        require(msg.sender == governance, "Not governance");
        _;
    }
    
    function purchaseInsurance(uint256 _amountInsured, string memory _uri) external nonReentrant {
        require(usdc.transferFrom(msg.sender, address(this), _amountInsured), "Payment failed");
        
        uint256 newPolicyId = totalSupply() + 1;
        _mint(msg.sender, newPolicyId);
        _setTokenURI(newPolicyId, _uri);
        
        policies[newPolicyId] = Policy(msg.sender, _amountInsured, _uri, false);
        emit PolicyPurchased(newPolicyId, msg.sender, _amountInsured);
    }
    
    function claimInsurance(uint256 _policyId) external nonReentrant {
        require(ownerOf(_policyId) == msg.sender, "Not policy owner");
        require(policies[_policyId].isClaimable, "Policy not claimable");
        
        // Using withdrawal pattern instead of direct transfer
        pendingWithdrawals[msg.sender] += policies[_policyId].amountInsured;
        
        _burn(_policyId);
        delete policies[_policyId];

        require(usdc.transfer(msg.sender, amountInsured), "Claim payment failed");
        emit PolicyClaimed(_policyId, msg.sender, amountInsured);
    }
    
    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds available");
        pendingWithdrawals[msg.sender] = 0;
        require(usdc.transfer(msg.sender, amount), "Withdrawal failed");
    }
    
    function updatePolicyClaimable(uint256 _policyId, bool _isClaimable) external onlyOracle {
        require(msg.sender == oracle, "Not the oracle");
        policies[_policyId].isClaimable = _isClaimable;
    }

    function updateOracle(address _newOracle) external onlyOwner {
        oracle = _newOracle;
    }
    
    function proposeNewGovernance(address _newGovernance) external onlyGovernance {
        newGovernance = _newGovernance;
        timelockExpiry = block.timestamp + TIMELOCK;
    }
    
    function confirmNewGovernance() external onlyGovernance {
        require(block.timestamp >= timelockExpiry, "Timelock not expired");
        governance = newGovernance;
    }
    
    function getUserPosition(address _user) external view returns (uint256 totalCollateral, uint256 totalDebt) {
        return lendingProtocol.getUserPosition(_user);
    }
}
