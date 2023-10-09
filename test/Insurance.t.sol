// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {InsuranceNFT} from "../src/InsuranceNFT.sol";

contract CounterTest is Test {
    const {expect} = require("chai");

    describe("InsuranceNFT", function() {
        let insuranceNFT, usdc, owner, user;

        beforeEach(async () => {
            [owner, user] = await ethers.getSigners();

            // Deploy a mock USDC contract
            const ERC20 = await ethers.getContractFactory("ERC20");
            usdc = await ERC20.deploy("USDC", "USDC");
            await usdc.deployed();

            // Deploy the InsuranceNFT contract
            const InsuranceNFT = await ethers.getContractFactory("InsuranceNFT");
            insuranceNFT = await InsuranceNFT.deploy(usdc.address, owner.address, /* lendingProtocol address */);
            await insuranceNFT.deployed();

            // Mint some USDC for the user
            await usdc.mint(user.address, ethers.utils.parseEther("1000"));
        });

        it("Should allow purchasing of insurance", async function() {
            // Approve the InsuranceNFT contract to spend user's USDC
            await usdc.connect(user).approve(insuranceNFT.address, ethers.utils.parseEther("100"));

            // User purchases insurance
            await insuranceNFT.connect(user).purchaseInsurance(ethers.utils.parseEther("100"), "ipfs://metadata_uri");

            // Check that the user's USDC balance decreased
            expect(await usdc.balanceOf(user.address)).to.equal(ethers.utils.parseEther("900"));

            // Check that the InsuranceNFT contract's USDC balance increased
            expect(await usdc.balanceOf(insuranceNFT.address)).to.equal(ethers.utils.parseEther("100"));

            // Check that the NFT was minted to the user
            expect(await insuranceNFT.ownerOf(1)).to.equal(user.address);

            // Check that the policy data is correct
            const policy = await insuranceNFT.policies(1);
            expect(policy.policyHolder).to.equal(user.address);
            expect(policy.amountInsured).to.equal(ethers.utils.parseEther("100"));
            expect(policy.uri).to.equal("ipfs://metadata_uri");
            expect(policy.isClaimable).to.equal(false);
        });
    });

}
