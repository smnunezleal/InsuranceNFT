pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {InsuranceNFT} from "../src/InsuranceNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InsuranceNFTTest is Test {
    InsuranceNFT public insuranceNFT;
    IERC20 public usdc;

    function setUp() public {
        // Assuming you have a deployed USDC contract or a mock one for testing
        address usdcAddress = address(0x...); // Replace with actual address
        usdc = IERC20(usdcAddress);

        // Deploy InsuranceNFT contract
        insuranceNFT = new InsuranceNFT(usdcAddress, address(this), address(0x...)); // Replace with actual lending protocol address
    }

    function test_PurchaseInsurance() public {
        uint256 initialBalance = 1000;
        uint256 insuranceCost = 100;

        // Mint some USDC for the InsuranceNFT contract
        // This might require a mock USDC contract that allows for minting
        usdc.mint(address(insuranceNFT), initialBalance);

        // Approve the InsuranceNFT contract to spend USDC
        usdc.approve(address(insuranceNFT), insuranceCost);

        // Purchase insurance
        insuranceNFT.purchaseInsurance(insuranceCost, "ipfs://metadata_uri");

        // Check USDC balance of InsuranceNFT contract
        assertEq(usdc.balanceOf(address(insuranceNFT)), initialBalance - insuranceCost);

        // Check NFT ownership
        assertEq(insuranceNFT.ownerOf(1), address(this));

        // Check policy data
        (address policyHolder, uint256 amountInsured, string memory uri, bool isClaimable) = insuranceNFT.policies(1);
        assertEq(policyHolder, address(this));
        assertEq(amountInsured, insuranceCost);
        assertEq(uri, "ipfs://metadata_uri");
        assertEq(isClaimable, false);
    }

    function test_PurchaseAndClaimInsurance() public {
        uint256 initialBalance = 1000;
        uint256 insuranceCost = 100;

        // Mint some USDC for the InsuranceNFT contract
        // This might require a mock USDC contract that allows for minting
        usdc.mint(address(insuranceNFT), initialBalance);

        // Approve the InsuranceNFT contract to spend USDC
        usdc.approve(address(insuranceNFT), insuranceCost);

        // Purchase insurance
        insuranceNFT.purchaseInsurance(insuranceCost, "ipfs://metadata_uri");

        // Check USDC balance of InsuranceNFT contract
        assertEq(usdc.balanceOf(address(insuranceNFT)), initialBalance - insuranceCost);

        // Check NFT ownership
        assertEq(insuranceNFT.ownerOf(1), address(this));

        // Check policy data
        (address policyHolder, uint256 amountInsured, string memory uri, bool isClaimable) = insuranceNFT.policies(1);
        assertEq(policyHolder, address(this));
        assertEq(amountInsured, insuranceCost);
        assertEq(uri, "ipfs://metadata_uri");
        assertEq(isClaimable, false);

        // Make the policy claimable
        insuranceNFT.updatePolicyClaimable(1, true);

        // Claim insurance
        insuranceNFT.claimInsurance(1);

        // Check that the policy is deleted
        (policyHolder, amountInsured, uri, isClaimable) = insuranceNFT.policies(1);
        assertEq(policyHolder, address(0));
        assertEq(amountInsured, 0);
        assertEq(uri, "");
        assertEq(isClaimable, false);

        // Check that the USDC balance of the InsuranceNFT contract is reduced
        assertEq(usdc.balanceOf(address(insuranceNFT)), initialBalance - 2 * insuranceCost);
    }

    function test_UpdatePolicyClaimable() public {
        uint256 initialBalance = 1000;
        uint256 insuranceCost = 100;

        // Mint some USDC for the InsuranceNFT contract
        // This might require a mock USDC contract that allows for minting
        usdc.mint(address(insuranceNFT), initialBalance);

        // Approve the InsuranceNFT contract to spend USDC
        usdc.approve(address(insuranceNFT), insuranceCost);

        // Purchase insurance
        insuranceNFT.purchaseInsurance(insuranceCost, "ipfs://metadata_uri");

        // Check policy data
        (address policyHolder, uint256 amountInsured, string memory uri, bool isClaimable) = insuranceNFT.policies(1);
        assertEq(policyHolder, address(this));
        assertEq(amountInsured, insuranceCost);
        assertEq(uri, "ipfs://metadata_uri");
        assertEq(isClaimable, false);

        // Update policy claimable status
        insuranceNFT.updatePolicyClaimable(1, true);

        // Check that the policy is now claimable
        (policyHolder, amountInsured, uri, isClaimable) = insuranceNFT.policies(1);
        assertEq(isClaimable, true);
    }

    function test_UnauthorizedUpdatePolicyClaimable() public {
        uint256 initialBalance = 1000;
        uint256 insuranceCost = 100;

        // Mint some USDC for the InsuranceNFT contract
        // This might require a mock USDC contract that allows for minting
        usdc.mint(address(insuranceNFT), initialBalance);

        // Approve the InsuranceNFT contract to spend USDC
        usdc.approve(address(insuranceNFT), insuranceCost);

        // Purchase insurance
        insuranceNFT.purchaseInsurance(insuranceCost, "ipfs://metadata_uri");

        // Try to update policy claimable status from unauthorized address and expect it to be reverted
        try insuranceNFT.connect(unauthorizedAddress).updatePolicyClaimable(1, true) {
            fail("Update policy claimable did not revert with unauthorized address");
        } catch Error(string memory reason) {
            assertEq(reason, "Not the oracle");
        }
    }

    function test_ConfirmNewGovernance() public {
        // Propose new governance
        address newGovernanceAddress = address(0xDEF...); // Replace with actual address
        insuranceNFT.proposeNewGovernance(newGovernanceAddress);
        
        // Fast forward time (if Forge supports it, otherwise, you may need to wait)
        // fastForwardTime(TIMELOCK + 1);
        
        // Confirm new governance
        insuranceNFT.confirmNewGovernance();
        
        // Check that the governance address is updated
        assertEq(insuranceNFT.governance(), newGovernanceAddress);
    }

    function test_WithdrawFunds() public {
        uint256 insuranceCost = 100;
        
        // Purchase insurance
        usdc.mint(address(insuranceNFT), insuranceCost);
        usdc.approve(address(insuranceNFT), insuranceCost);
        insuranceNFT.purchaseInsurance(insuranceCost, "ipfs://metadata_uri");
        
        // Make the policy claimable
        insuranceNFT.updatePolicyClaimable(1, true);
        
        // Claim insurance
        insuranceNFT.claimInsurance(1);
        
        // Check that the funds are available for withdrawal
        assertEq(insuranceNFT.pendingWithdrawals(address(this)), insuranceCost);
        
        // Withdraw funds
        insuranceNFT.withdraw();
        
        // Check that the funds have been withdrawn
        assertEq(insuranceNFT.pendingWithdrawals(address(this)), 0);
        assertEq(usdc.balanceOf(address(this)), insuranceCost);
    }

    function test_UpdateOracleAddress() public {
        // Update oracle address
        address newOracleAddress = address(0x123...); // Replace with actual address
        insuranceNFT.updateOracle(newOracleAddress);
        
        // Check that the oracle address is updated
        assertEq(insuranceNFT.oracle(), newOracleAddress);
    }

    function test_GetUserPosition() public {
        // Assuming the lending protocol contract is set up and has user positions
        
        // Get user position
        (uint256 totalCollateral, uint256 totalDebt) = insuranceNFT.getUserPosition(address(this));
        
        // Check that the user position is returned correctly
        // You may need to adjust the expected values based on the setup of your lending protocol contract
        assertEq(totalCollateral, /* expected collateral value */);
        assertEq(totalDebt, /* expected debt value */);
    }

    function test_GetUserPosition() public {
        // Assuming the lending protocol contract is set up and has user positions
        
        // Get user position
        (uint256 totalCollateral, uint256 totalDebt) = insuranceNFT.getUserPosition(address(this));
        
        // Check that the user position is returned correctly
        // You may need to adjust the expected values based on the setup of your lending protocol contract
        assertEq(totalCollateral, /* expected collateral value */);
        assertEq(totalDebt, /* expected debt value */);
    }

}
