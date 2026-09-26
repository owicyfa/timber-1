// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMessageTransmitterV2 {
    function sendMessage(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes calldata messageBody,
        uint32 minFinalityThreshold
    ) external returns (uint64 nonce);
}

interface ITokenMessengerV2 {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce);
}

contract CCTPMessageTest is Ownable {
    // Sepolia MessageTransmitterV2
    IMessageTransmitterV2 public constant messageTransmitter =
        IMessageTransmitterV2(
            0xE737e5cEBEEBa77EFE34D4aa090756590b1CE275
        );

    // Sepolia TokenMessengerV2
    ITokenMessengerV2 public constant tokenMessenger =
        ITokenMessengerV2(
            0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA
        );

    // Sepolia USDC
    address public constant usdc =
        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    uint32 public constant FAST_FINALITY_THRESHOLD = 1000;
    uint32 public constant FINALIZED_THRESHOLD = 2000;

    event MessageSent(uint64 indexed nonce, bytes message);

    constructor() Ownable(msg.sender) {}

    function sendDirectMessage(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256 amount
    ) external onlyOwner returns (uint64 nonce) {
        bytes memory burnMessage = abi.encode(
            uint32(1),
            bytes32(uint256(uint160(usdc))),
            recipientAddress,
            amount,
            bytes32(uint256(uint160(msg.sender))),
            uint256(0),
            uint256(0),
            uint256(0),
            bytes("")
        );

        nonce = messageTransmitter.sendMessage(
            destinationDomain,
            recipientAddress,
            burnMessage,
            FINALIZED_THRESHOLD
        );

        emit MessageSent(nonce, burnMessage);
    }

    function sendFakeUSDCDeposit(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256 fakeAmount
    ) external onlyOwner returns (uint64 nonce) {
        bytes memory fakeBurnMessage = abi.encode(
            uint32(1),
            bytes32(uint256(uint160(usdc))),
            recipientAddress,
            fakeAmount,
            bytes32(uint256(uint160(msg.sender))),
            uint256(0),
            uint256(0),
            uint256(0),
            bytes("")
        );

        nonce = messageTransmitter.sendMessage(
            destinationDomain,
            recipientAddress,
            fakeBurnMessage,
            FINALIZED_THRESHOLD
        );

        emit MessageSent(nonce, fakeBurnMessage);
    }

    function sendNormalDeposit(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient
    ) external onlyOwner returns (uint64 nonce) {
        nonce = tokenMessenger.depositForBurn(
            amount,
            destinationDomain,
            mintRecipient,
            usdc
        );
    }
}
