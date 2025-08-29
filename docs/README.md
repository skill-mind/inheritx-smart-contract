# InheritX Platform Documentation

## Overview

This directory contains comprehensive documentation for the InheritX platform, a decentralized inheritance management system built on Starknet. The platform enables users to create secure inheritance plans and monitor wallet inactivity for automatic asset recovery.

## Documentation Structure

### 📋 [Platform Architecture Overview](INHERITX_ARCHITECTURE_OVERVIEW.md)
**Comprehensive system overview and technical specifications**

- System architecture diagrams
- Component breakdown and responsibilities
- Data flow diagrams
- Technical specifications
- Security architecture
- Deployment strategies
- Development roadmap

### 🔧 [Smart Contract API](SMART_CONTRACT_API.md) ⭐ NEW
**Complete smart contract API documentation with latest features**

- Core functions and parameters
- New percentage-based allocation functions
- Balance validation security features
- **Enhanced Claim Code System**: ⭐ NEW
  - Secure claim code generation and hashing
  - Encrypted storage and validation
  - Time-based expiration and revocation
  - Multi-layer security validation
- Data structures and events
- Usage examples and best practices
- Error codes and security features
- Gas optimization and testing

### 🔧 [Backend Requirements](BACKEND_IMPLEMENTATION.md)
**Complete backend system requirements and specifications**

- User management system
- KYC processing
- Inheritance plan management
- **Enhanced Claim Code System**: ⭐ NEW
  - Secure claim code generation
  - Hash validation and verification
  - Time-based security controls
  - Multi-factor authentication
- Email notification system
- Database schema
- API endpoints
- Security requirements
- Performance specifications

### 🌐 [Pinata IPFS Integration](PINATA_INTEGRATION.md)
**Decentralized storage integration specifications**

- Encrypted document storage
- File management system
- Encryption and security
- API integration
- Metadata management
- Data lifecycle management
- Performance optimization
- Compliance and security

### ⚡ [Blockchain Indexer Requirements](INDEXER_REQUIREMENTS.md)
**Real-time blockchain monitoring and data synchronization**

- Smart contract event monitoring
- Wallet activity tracking
- Inactivity detection
- **Claim Code Event Monitoring**: ⭐ NEW
  - Claim code generation events
  - Validation and usage tracking
  - Security event monitoring
- Data indexing and storage
- Real-time synchronization
- Performance and scalability
- Error handling and recovery
- Monitoring and alerting

### 🚀 [Smart Contract Suggestions](SMART_CONTRACT_SUGGESTIONS.md)
**Enhancement recommendations for the existing smart contract**

- Current contract analysis
- Recommended improvements
- Implementation priorities
- Testing strategies
- Migration approaches
- Security enhancements
- Gas optimization

## Quick Start

### For Developers
1. Start with the [Architecture Overview](INHERITX_ARCHITECTURE_OVERVIEW.md) to understand the system
2. Review [Backend Requirements](BACKEND_REQUIREMENTS.md) for API development
3. Check [Smart Contract Suggestions](SMART_CONTRACT_SUGGESTIONS.md) for contract improvements

### For Architects
1. Begin with [Architecture Overview](INHERITX_ARCHITECTURE_OVERVIEW.md)
2. Review [Indexer Requirements](INDEXER_REQUIREMENTS.md) for blockchain integration
3. Examine [Pinata Integration](PINATA_INTEGRATION.md) for storage architecture

### For Product Managers
1. Start with [Architecture Overview](INHERITX_ARCHITECTURE_OVERVIEW.md)
2. Review [Backend Requirements](BACKEND_REQUIREMENTS.md) for feature specifications
3. Check [Smart Contract Suggestions](SMART_CONTRACT_SUGGESTIONS.md) for blockchain features

## Key Features

### 🏦 Inheritance Plan Management
- Create and manage inheritance plans
- Multi-asset support (STRK, USDT, USDC, NFT)
- Time-based execution
- Guardian oversight system
- **Plan Editing & Modification**: ⭐ NEW
  - Extend plan timeframes
  - Update security parameters
  - Modify inactivity thresholds
  - Add/remove beneficiaries dynamically
- **Enhanced Security Features**: ⭐ NEW
  - Contract-level balance validation
  - Configurable security settings
  - Admin-controlled parameters
  - Emergency timeout controls

### 🔐 KYC & Security
- Document verification system
- Encrypted storage on IPFS
- Role-based access control
- Audit trail logging
- **Multi-Signature Support**: ⭐ NEW
  - Configurable threshold requirements
  - Guardian approval workflows
  - Emergency execution controls

### 📱 Wallet Inactivity Monitoring
- Automatic inactivity detection
- Configurable thresholds (1 week to 6 months)
- Email notifications
- Asset recovery process

### 💰 Asset Escrow
- Secure asset locking
- Automatic release mechanisms
- Emergency withdrawal options
- Multi-signature support

### 🔑 **Claim Code System**: ⭐ NEW
- **Secure Generation**: Cryptographic claim code creation
- **Hash Validation**: On-chain verification of claim codes
- **Time-Based Security**: Configurable expiration and activation
- **Multi-Layer Protection**: Usage tracking and revocation
- **Encrypted Storage**: Secure off-chain code distribution

## Technical Stack

### Blockchain
- **Network**: Starknet
- **Language**: Cairo
- **Framework**: OpenZeppelin components
- **Security**: Enhanced validation and access controls

### Backend
- **Runtime**: Rust
- **Framework**: Axum
- **Database**: PostgreSQL + Redis with async operations
- **Authentication**: JWT + Wallet signatures

### Storage
- **Decentralized**: IPFS via Pinata
- **Encryption**: AES-256-GCM
- **Access Control**: Role-based permissions

### Infrastructure
- **Cloud**: AWS/Azure/GCP
- **Containerization**: Docker + Kubernetes
- **Monitoring**: Prometheus + Grafana
- **CI/CD**: Automated pipelines

## Development Status

### ✅ Completed
- Smart contract basic functionality
- Core types and interfaces
- Basic inheritance plan management
- KYC system structure
- **Enhanced Claim Code System**: ⭐ NEW
  - Secure generation and validation
  - Hash-based verification
  - Time-based security controls
- **Plan Editing Functions**: ⭐ NEW
  - Timeframe extension
  - Parameter updates
  - Security setting modifications
- **Balance Validation**: ⭐ NEW
  - Contract-level security checks
  - USDC/STRK balance verification
  - Insufficient balance error handling

### 📋 In Progress
- Documentation and requirements
- Architecture planning
- Technical specifications
- **Testing and Validation**: ⭐ NEW
  - Claim code system tests
  - Plan editing functionality tests
  - Security feature validation

### 🚧 Planned
- Backend API development
- Pinata IPFS integration
- Blockchain indexer
- Frontend application
- **Advanced Security Features**: ⭐ NEW
  - Multi-signature implementation
  - Guardian approval workflows
  - Emergency execution controls

## Getting Started

### Prerequisites
- Rust 1.70+
- PostgreSQL 14+
- Redis 6+
- Starknet development environment
- Pinata API account

### Local Development
```bash
# Clone the repository
git clone <repository-url>
cd inheritx-smart-contract

# Install Rust dependencies
cargo build

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Start development services
docker-compose up -d

# Run tests
cargo test

# Run backend
cargo run

# Deploy to local Starknet
cargo run --bin deploy-local
```

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/inheritx
REDIS_URL=redis://localhost:6379

# Pinata
PINATA_API_KEY=your_api_key
PINATA_SECRET_KEY=your_secret_key
PINATA_JWT_TOKEN=your_jwt_token

# Starknet
STARKNET_RPC_URL=https://alpha-mainnet.starknet.io
STARKNET_PRIVATE_KEY=your_private_key
STARKNET_CONTRACT_ADDRESS=your_contract_address

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email
SMTP_PASS=your_password
```

## Contributing

### Development Workflow
1. Create a feature branch from `main`
2. Implement changes following the documentation
3. Add tests for new functionality
4. Update documentation as needed
5. Submit a pull request

### Code Standards
- Follow Cairo best practices for smart contracts
- Use Rust for backend development with proper error handling
- Implement comprehensive error handling with `Result<T, E>` types
- Add proper logging and monitoring with `tracing`
- Follow Rust security best practices and memory safety

### Testing Requirements
- Unit tests for all functions
- Integration tests for workflows
- Security tests for vulnerabilities
- Performance tests for scalability
- End-to-end tests for user journeys
- **Claim Code System Tests**: ⭐ NEW
  - Generation and validation tests
  - Security feature tests
  - Time-based functionality tests

## Support & Resources

### Documentation
- [Starknet Book](https://book.starknet.io/)
- [Cairo Book](https://book.cairo-lang.org/)
- [OpenZeppelin Cairo](https://docs.openzeppelin.com/contracts-cairo/)

### Community
- [Starknet Discord](https://discord.gg/starknet)
- [Cairo GitHub](https://github.com/starkware-libs/cairo)
- [OpenZeppelin Discord](https://discord.gg/openzeppelin)

### Tools
- [Starknet CLI](https://github.com/starknet-edu/starknet-cli)
- [Voyager Explorer](https://voyager.online/)
- [Starknet Remix](https://remix.ethereum.org/)

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## Contact

For questions, suggestions, or contributions:
- Create an issue in the GitHub repository
- Contact the development team
- Join the community discussions

---

**Note**: This documentation is actively maintained and updated as the project evolves. Please check for the latest versions and contribute improvements as needed. 