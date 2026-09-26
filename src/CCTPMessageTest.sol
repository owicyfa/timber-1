// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenMessengerV2 {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce);
}

contract CCTPMessageTest is Ownable {
    // Sepolia TokenMessengerV2
    ITokenMessengerV2 public constant tokenMessenger =
        ITokenMessengerV2(0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA);

    // Sepolia USDC
    IERC20 public constant usdc =
        IERC20(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);

    event BurnInitiated(
        uint64 indexed nonce,
        uint256 burnAmount,
        uint32 destinationDomain,
        bytes32 recipient
    );

    event TestResult(
        string testName,
        uint256 requestedAmount,
        uint256 actualBurnAmount,
        bool attestationExpected
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Test 1: Legitimate USDC burn through proper CCTP flow
     * Amount matches what's reported to TokenMessenger
     */
    function testLegitimateUSDCBurn(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256 burnAmount
    ) external onlyOwner returns (uint64 nonce) {
        require(burnAmount > 0, "Burn amount must be > 0");
        require(
            usdc.balanceOf(address(this)) >= burnAmount,
            "Insufficient USDC balance"
        );

        // Approve TokenMessenger to burn
        usdc.approve(address(tokenMessenger), burnAmount);

        // Execute legitimate burn through official CCTP flow
        nonce = tokenMessenger.depositForBurn(
            burnAmount,
            destinationDomain,
            recipientAddress,
            address(usdc)
        );

        emit BurnInitiated(nonce, burnAmount, destinationDomain, recipientAddress);
        emit TestResult(
            "LegitimateUSDCBurn",
            burnAmount,
            burnAmount,
            true
        );

        return nonce;
    }

    /**
     * @notice Test 2: Small test burn (minimal USDC)
     * Validates that Iris attests even for small amounts
     */
    function testSmallBurn(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256 smallAmount
    ) external onlyOwner returns (uint64 nonce) {
        require(smallAmount > 0, "Amount must be > 0");
        require(
            usdc.balanceOf(address(this)) >= smallAmount,
            "Insufficient USDC balance"
        );

        usdc.approve(address(tokenMessenger), smallAmount);

        nonce = tokenMessenger.depositForBurn(
            smallAmount,
            destinationDomain,
            recipientAddress,
            address(usdc)
        );

        emit BurnInitiated(nonce, smallAmount, destinationDomain, recipientAddress);
        emit TestResult(
            "SmallBurn",
            smallAmount,
            smallAmount,
            true
        );

        return nonce;
    }

    /**
     * @notice Test 3: Multiple burns to understand Iris attestation batching
     * Tests if Iris handles sequential burns correctly
     */
    function testMultipleBurns(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(amounts.length > 0, "Must provide at least one amount");

        uint256 totalRequired = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalRequired += amounts[i];
        }
        require(
            usdc.balanceOf(address(this)) >= totalRequired,
            "Insufficient total USDC balance"
        );

        usdc.approve(address(tokenMessenger), totalRequired);

        for (uint256 i = 0; i < amounts.length; i++) {
            uint64 nonce = tokenMessenger.depositForBurn(
                amounts[i],
                destinationDomain,
                recipientAddress,
                address(usdc)
            );

            emit BurnInitiated(
                nonce,
                amounts[i],
                destinationDomain,
                recipientAddress
            );
            emit TestResult(
                "MultipleBurns",
                amounts[i],
                amounts[i],
                true
            );
        }
    }

    /**
     * @notice View function to check contract's USDC balance
     */
    function getUSDCBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /**
     * @notice Emergency withdraw USDC (for cleanup after testing)
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        usdc.transfer(msg.sender, amount);
    }

    /**
     * @notice Receive function to accept native ETH
     */
    receive() external payable {}
}
