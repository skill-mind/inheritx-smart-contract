

# Contributing to InheritX Smart Contract

Thank you for your interest in contributing to InheritX! **InheritX** is a revolutionary blockchain-powered digital asset inheritance platform that empowers users to securely manage, transfer, and optimize their digital assets—including cryptocurrencies and NFTs—using a decentralized exchange (DEX) swap feature. Built on StarkNet, InheritX ensures transparency, security, and automation in digital estate planning.

## Project Overview

**InheritX** combines:
- **Digital Asset Inheritance:** Secure, automated transfer of digital assets to designated beneficiaries.
- **Enhanced Claim Code System:** Zero-knowledge encrypted claim codes with contract-generated randomness for maximum security.
- **DEX Swap Integration**: Pre- and post-inheritance asset swaps for optimal portfolio management.
- **Blockchain Technology:** Leveraging **StarkNet** to guarantee a decentralized, trustless, and secure environment.
- **User-Centric Design:** Intuitive dashboards and robust identity verification for asset owners and beneficiaries.

## Enhanced Claim Code System

InheritX implements the most secure claim code generation system in the blockchain space:

### 🔐 **Zero-Knowledge Security**
- **Contract-Generated Randomness**: Smart contract generates 32-byte cryptographically secure random codes
- **Asset Owner Privacy**: Asset owners never see plain text claim codes, only encrypted versions
- **Beneficiary-Only Access**: Only intended beneficiaries can decrypt and access actual codes

### 🚀 **Advanced Features**
- **Public Key Encryption**: Codes encrypted with beneficiary's public key for secure delivery
- **Automatic Expiration**: Time-based code expiration with configurable durations
- **Comprehensive Auditing**: Complete audit trail for all claim code operations
- **Delivery Tracking**: Real-time monitoring of code delivery and usage patterns

### 🏗️ **Architecture**
- **Smart Contract**: Core logic for code generation, encryption, and validation
- **Indexer**: Real-time event monitoring and off-chain synchronization
- **Backend**: Secure delivery orchestration and beneficiary management
- **Frontend**: User-friendly interface for code generation and management

### 📊 **Performance & Security**
- **Code Generation**: < 5 seconds for secure random code generation
- **Encryption**: < 2 seconds for public key encryption
- **Delivery**: < 60 seconds for email, < 10 seconds for SMS
- **Scalability**: Support for 1000+ concurrent code generations
- **Audit Trail**: Complete lifecycle tracking from generation to usage

# How to Apply 
1. Star the project
2. Drop your TG handle
3. Join the group `https://t.me/+xN161b3GkwNiYTZk`


## How to Contribute

We welcome contributions in various forms, including bug fixes, feature implementations, and documentation improvements.

### 1. Fork the Repository
1. Navigate to the 
(https://github.com/skill-mind/InheritX-smart_contract.git).
2. Click the **Fork** button to create your copy of the repository.

### 2. Clone the Repository
- Clone your forked repository to your local machine:
```bash
git clone https://github.com/<your-username>/InheritX-smart_contract.git
cd InheritX-smart_contract
```


### 3. Create a New Branch

**Create a branch for your feature or bug fix:**
```bash
  git checkout -b feature/<Issue title>
```

### 5. Make Changes and Commit

- Implement your changes.
- Test your changes thoroughly.
- Commit your work with a descriptive message:

```bash
   git add .
   git commit -m "Issue Title"
```

### 6. Push Changes
 - Push your branch to your forked repository:

```bash
   git push origin <Issue Title>
```

### 7. Create a Pull Request (PR)

- Click on Pull Requests and select New Pull Request.
- Provide a clear and concise title and description for your PR.
- Link any relevant issues.

**Code of Conduct**

- Please adhere to our Code of Conduct to maintain a respectful and inclusive community.

### Contribution Guidelines
- Write clean and modular code following the repository's coding standards.
- Ensure all changes are tested before submission.
- Document new features and updates thoroughly.

# Upgradeable Contract System Deployment Guide

This document provides instructions for deploying and upgrading the counter contract system using Starknet.

## Prerequisites

- Starknet CLI installed
- Cairo compiler installed
- Account configured with Starknet

## Deployment Steps

### 1. Compile the Contracts

First, compile all the contracts:

```bash
scarb build
```

### 2. Declare Logic Contract (V1)

```bash
starknet declare --contract target/release/CounterLogic.json
```

Make note of the returned class hash: `0x<LOGIC_CLASS_HASH>`

### 3. Deploy Logic Contract (V1)

```bash
starknet deploy --class_hash 0x<LOGIC_CLASS_HASH> --inputs <OWNER_ADDRESS>
```

### 4. Declare Proxy Contract

```bash
starknet declare --contract target/release/CounterProxy.json
```

Make note of the returned class hash: `0x<PROXY_CLASS_HASH>`

### 5. Deploy Proxy Contract

```bash
starknet deploy --class_hash 0x<PROXY_CLASS_HASH> --inputs <OWNER_ADDRESS> <LOGIC_CLASS_HASH>
```

Your proxy contract is now deployed with the class hash of the logic contract. The proxy contract will be the one users interact with.

## Upgrading the Contract

When you want to upgrade to a new version of the logic contract, follow these steps:

### 1. Declare New Logic Contract (V2)

```bash
starknet declare --contract target/release/CounterLogicV2.json
```

Make note of the returned class hash: `0x<LOGIC_V2_CLASS_HASH>`

### 2. Call the Upgrade Function on Proxy

```bash
starknet invoke \
  --address <PROXY_CONTRACT_ADDRESS> \
  --function upgrade \
  --inputs <LOGIC_V2_CLASS_HASH> \
  --account <YOUR_ACCOUNT>
```

### 3. Verify the Upgrade

You can verify that the logic contract has been upgraded by calling the `get_version` function:

```bash
starknet call \
  --address <PROXY_CONTRACT_ADDRESS> \
  --function get_version
```

The response should be "v2.0", confirming that the upgrade was successful.

## State Persistence

The beauty of this upgrade pattern is that all state is stored in the proxy contract. When you upgrade the logic contract, the state remains intact in the proxy contract's storage. This means:

1. Counter values will persist after an upgrade
2. Ownership will remain the same
3. Any other state variables will be preserved

## Security Considerations

1. Only the contract owner can perform an upgrade
2. The proxy pattern ensures that state is preserved during upgrades
3. New implementations can add functionality but shouldn't change the storage layout

## Community Engagement

Join our Telegram group to discuss this project and share your feedback:
[TG Group Link] (replace with your actual TG group link)

When you join, please drop your TG handle so we can welcome you properly!

## Troubleshooting

If you encounter any issues during deployment or upgrade, please:

1. Verify that you're using the correct class hashes
2. Make sure you're calling functions with the correct account (owner)
3. Check transaction receipts for detailed error messages

Thank you for contributing to InheritX and helping us build a secure, innovative platform for digital asset inheritance!