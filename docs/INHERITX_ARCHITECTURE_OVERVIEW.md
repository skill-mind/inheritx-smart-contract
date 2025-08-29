# InheritX Platform Architecture Overview

## Executive Summary

InheritX is a comprehensive inheritance management platform built on Starknet that enables users to create secure inheritance plans and monitor wallet inactivity for automatic asset recovery. The platform consists of four main components: Smart Contract, Backend, Pinata IPFS Integration, and Blockchain Indexer.

## Hybrid System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend UI   │    │   Mobile App    │    │   Admin Panel   │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │        Backend API        │
                    │   (Off-Chain Computation) │
                    │      (Rust + Axum)        │
                    └─────────────┬─────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
┌─────────┴─────────┐    ┌────────┴────────┐    ┌────────┴────────┐
│   Pinata IPFS     │    │   Database      │    │   Email Service │
│   (Encrypted      │    │  (Hybrid Data)  │    │   (SMTP/        │
│    Storage)       │    │  (PostgreSQL)   │    │    Nodemailer)  │
└───────────────────┘    └─────────────────┘    └─────────────────┘
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │      Blockchain Indexer   │
                    │   (Hybrid Sync Engine)    │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │    InheritX Smart Contract │
                    │      (On-Chain Security)   │
                    │      (Starknet)           │
                    └───────────────────────────┘
```

### Hybrid Architecture Layers

#### **Off-Chain Layer (Backend)**
- **Computation Engine**: Complex calculations, business logic
- **External Integration**: APIs, email services, market data
- **User Experience**: Search, filtering, notifications
- **Data Processing**: KYC verification, fraud detection

#### **On-Chain Layer (Smart Contract)**
- **Critical State**: Asset ownership, plan status, permissions
- **Verification Data**: Hash references, signatures, timestamps
- **Business Rules**: Access control, state transitions
- **Event Logging**: Immutable audit trail

#### **Synchronization Layer (Indexer)**
- **Real-Time Sync**: On-chain to off-chain data flow
- **Consistency Monitoring**: Data integrity across systems
- **Event Processing**: Blockchain event interpretation
- **Performance Optimization**: Caching and load balancing

## Component Breakdown

### 1. Smart Contract (Starknet)
**Location**: `src/inheritx.cairo`

**Purpose**: Core business logic and asset management on-chain

**Key Features**:
- Inheritance plan creation and management
- Asset escrow and release mechanisms
- KYC verification system
- **Enhanced Claim Code System**: Zero-knowledge encrypted claim codes with contract-generated randomness
- Wallet inactivity monitoring
- Multi-asset support (STRK, USDT, USDC, NFT)
- **Percentage-Based Beneficiary Allocation**: Support for multiple beneficiaries with different percentage shares (0-100%)
- **Balance Validation**: On-chain validation of user token balances before plan creation
- **Enhanced Beneficiary Management**: Structured beneficiary data with percentages, ages, relationships, and email hashes
- **Plan Editing & Modification**: Extend timeframes, update parameters, modify inactivity thresholds, and add/remove beneficiaries

**Enhanced Claim Code System**:
- **Hash-Based Validation**: Secure cryptographic verification of claim codes using on-chain hashing
- **Time-Based Security**: Configurable expiration and activation controls with contract-level validation
- **Usage Tracking**: Prevents duplicate usage and tracks claim history with comprehensive state management
- **Revocation Support**: Admin-controlled claim code invalidation for security management
- **Multi-Layer Protection**: Multiple validation layers including hash matching, expiration checks, and usage status
- **Off-Chain Generation**: Secure off-chain claim code creation with on-chain hash validation
- **Event Logging**: Comprehensive audit trail for all claim code operations including storage, usage, expiration, and revocation
- **Security Controls**: Contract-level security settings for minimum timeframes and access controls

**Current Status**: ✅ Implemented with enhanced claim code system, percentage-based allocation, balance validation, and enhanced beneficiary management
**Improvement Needed**: Production hardening of cryptographic functions

### 2. Backend API
**Technology**: Rust + Axum

**Purpose**: High-performance orchestration layer for off-chain computation, external integrations, and user experience features

**Key Responsibilities**:
- **Off-Chain Computation**: Complex calculations, business logic, asset valuations
- **External Integration**: KYC verification, market data, email services
- **User Experience**: Search, filtering, notifications, session management
- **Data Validation**: Input validation, business rule enforcement
- **Smart Contract Coordination**: Prepare and validate data for on-chain operations
- **Hybrid Data Management**: Maintain consistency between off-chain and on-chain systems

**Status**: 📋 Requirements defined, needs implementation

### 3. Pinata IPFS Integration
**Technology**: IPFS + Pinata SDK

**Purpose**: Decentralized storage for encrypted documents and metadata

**Key Features**:
- Encrypted KYC document storage
- Inheritance plan details storage
- Client-side encryption (AES-256-GCM)
- Role-based access control
- Automated cleanup and retention policies

**Status**: 📋 Requirements defined, needs implementation

### 4. Blockchain Indexer
**Technology**: Node.js + WebSocket + PostgreSQL

**Purpose**: Hybrid synchronization engine that bridges on-chain and off-chain systems

**Key Responsibilities**:
- **Smart Contract Event Monitoring**: Process blockchain events in real-time
- **Hybrid Data Synchronization**: Maintain consistency between on-chain and off-chain data
- **Wallet Activity Tracking**: Monitor wallet activity for inactivity detection
- **Cross-System Consistency**: Ensure data integrity across all platform components
- **Performance Optimization**: Caching, load balancing, and performance monitoring
- **Real-Time Updates**: WebSocket-based live data streaming to frontend

**Status**: 📋 Requirements defined, needs implementation

## Hybrid Data Flow Patterns

### Pattern 1: Inheritance Plan Creation (Off-Chain → On-Chain → Off-Chain)
```
1. User creates plan (Frontend)
   ↓
2. Backend validates input and calculates beneficiary shares (Off-Chain)
   ↓
3. Backend calls smart contract with beneficiary public keys (Off-Chain → On-Chain)
   ↓
4. Smart contract generates encrypted claim codes and stores hashes (On-Chain)
   ↓
5. Smart contract returns encrypted codes to asset owner (On-Chain → Off-Chain)
   ↓
6. Indexer processes contract events and updates backend (On-Chain → Off-Chain)
   ↓
7. Backend initiates secure code delivery to beneficiaries (Off-Chain)
   ↓
8. Pinata stores encrypted beneficiary information (Off-Chain)
```

### Pattern 2: Enhanced Claim Code Generation & Delivery (Off-Chain → On-Chain → Beneficiary)
```
1. Asset owner generates claim code off-chain (Off-Chain)
   ↓
2. Asset owner calls store_claim_code_hash() with code hash (Off-Chain → On-Chain)
   ↓
3. Smart contract stores hash and validates input (On-Chain)
   ↓
4. Smart contract emits ClaimCodeStored event (On-Chain)
   ↓
5. Indexer monitors ClaimCodeStored event (On-Chain → Off-Chain)
   ↓
6. Backend receives hash confirmation and initiates delivery (Off-Chain)
   ↓
7. Backend sends plain claim code to beneficiary via secure channel (Off-Chain)
   ↓
8. Beneficiary receives plain code and stores securely (Beneficiary)
   ↓
9. Beneficiary uses plain code to claim inheritance (Beneficiary → On-Chain)
   ↓
10. Smart contract validates code hash and releases assets (On-Chain)
```

### Pattern 3: Inheritance Claim Process (Off-Chain → On-Chain → Off-Chain)
```
1. Beneficiary receives encrypted claim code via secure delivery (Off-Chain)
   ↓
2. Beneficiary decrypts code using private key (Beneficiary)
   ↓
3. Beneficiary calls claim_inheritance() with plain code (Off-Chain → On-Chain)
   ↓
4. Smart contract validates code hash and releases assets (On-Chain)
   ↓
5. Indexer monitors ClaimCodeUsed event and updates backend (On-Chain → Off-Chain)
   ↓
6. Backend updates claim status and sends confirmation (Off-Chain)
```

### Pattern 3: Wallet Inactivity Monitoring (Hybrid Continuous)
```
1. Backend sets up inactivity monitor with threshold (Off-Chain)
   ↓
2. Indexer continuously monitors wallet activity (Hybrid)
   ↓
3. Indexer detects inactivity and triggers alert (Hybrid)
   ↓
4. Backend sends email notification to beneficiary (Off-Chain)
   ↓
5. Backend updates monitoring status in database (Off-Chain)
   ↓
6. Smart contract logs inactivity trigger event (Off-Chain → On-Chain)
   ↓
7. Backend initiates inheritance process if needed (Off-Chain)
```

### Inheritance Claim Flow
```
1. Beneficiary receives claim code (email)
   ↓
2. Beneficiary completes KYC verification
   ↓
3. Backend validates KYC and claim code
   ↓
4. Smart contract executes inheritance transfer
   ↓
5. Indexer monitors transfer completion
   ↓
6. Backend updates plan status
   ↓
7. Assets released from escrow
```

### Wallet Inactivity Monitoring Flow
```
1. User sets up inactivity monitor (Backend)
   ↓
2. Indexer continuously monitors wallet activity
   ↓
3. Inactivity threshold reached
   ↓
4. Indexer triggers inactivity alert
   ↓
5. Backend sends email notification
   ↓
6. Beneficiary completes KYC
   ↓
7. Inheritance process initiated
```

## Technical Specifications

### Backend Requirements
- **Framework**: Rust + Axum
- **Database**: PostgreSQL + Redis with async operations
- **Authentication**: JWT + Wallet signatures
- **API**: RESTful + WebSocket
- **Performance**: < 50ms response time (Rust performance)
- **Scalability**: 100,000+ concurrent users (Rust efficiency)
- **Memory Safety**: Zero runtime errors, compile-time guarantees

### Pinata Integration
- **Encryption**: AES-256-GCM (client-side)
- **Storage**: IPFS via Pinata
- **Access Control**: Role-based permissions
- **Metadata**: JSON-based organization
- **Retention**: Automated cleanup policies

### Indexer Requirements
- **Performance**: 100+ blocks/second processing
- **Real-time**: < 100ms update latency
- **Scalability**: Horizontal scaling support
- **Reliability**: 99.9% uptime target
- **Monitoring**: Comprehensive health checks

### Smart Contract
- **Language**: Cairo (Starknet)
- **Upgradeability**: Yes (OpenZeppelin pattern)
- **Security**: Pausable + Access control
- **Gas Optimization**: Efficient storage patterns
- **Events**: Comprehensive event emission
- **Enhanced Claim Code System**: 
  - Contract-generated 32-byte random codes
  - Public key encryption for secure delivery
  - Automatic expiration management
  - Comprehensive audit trail

### Enhanced Claim Code System Requirements
- **Code Generation**: 32-byte cryptographically secure random codes
- **Encryption**: Public key-based encryption (currently XOR, production: RSA/ECC)
- **Delivery Methods**: Email, SMS, secure portal, API integration
- **Security Features**: Zero-knowledge approach, automatic expiration, audit logging
- **Performance**: < 5 second code generation, < 2 second encryption
- **Scalability**: Support for 1000+ concurrent code generations
- **Audit Trail**: Complete lifecycle tracking from generation to usage

## Security Architecture

### Data Protection
- **Encryption at Rest**: All sensitive data encrypted
- **Client-Side Encryption**: Zero-knowledge file storage
- **Access Control**: Role-based permissions
- **Audit Logging**: Complete activity tracking
- **Enhanced Claim Code Security**: 
  - Zero-knowledge code generation (asset owners never see plain codes)
  - Public key encryption for secure delivery
  - On-chain hash validation for code verification
  - Automatic expiration and revocation mechanisms

### Blockchain Security
- **Smart Contract**: Formal verification recommended
- **Access Control**: Multi-signature support
- **Emergency Functions**: Pause and emergency withdrawal
- **Upgradeability**: Controlled upgrade process
- **Claim Code Security**: 
  - Contract-generated randomness (not human-generated)
  - Cryptographic hashing for code validation
  - Immutable audit trail through blockchain events
  - Access control for code generation and management

### API Security
- **Rate Limiting**: API abuse prevention
- **Input Validation**: Comprehensive data validation
- **CORS**: Cross-origin resource sharing
- **HTTPS**: TLS encryption for all communications

## Deployment Architecture

### Development Environment
- **Local Development**: Docker containers
- **Testing**: Local blockchain + test database
- **CI/CD**: Automated testing pipeline

### Staging Environment
- **Infrastructure**: Cloud-based staging
- **Database**: Staging database instance
- **Blockchain**: Testnet deployment

### Production Environment
- **Infrastructure**: Cloud provider (AWS/Azure/GCP)
- **Load Balancing**: Multiple backend instances
- **Database**: High-availability PostgreSQL
- **Blockchain**: Mainnet deployment
- **Monitoring**: Comprehensive observability

## Integration Points

### External Services
- **Email Service**: SMTP provider (SendGrid, AWS SES)
- **SMS Service**: Twilio or similar (optional)
- **KYC Provider**: Third-party verification service
- **Analytics**: Google Analytics, Mixpanel

### Blockchain Networks
- **Primary**: Starknet Mainnet
- **Testnet**: Starknet Testnet
- **RPC Providers**: Multiple endpoint support
- **Block Explorers**: Voyager integration

## Performance Requirements

### Response Times
- **API Endpoints**: < 200ms average
- **File Uploads**: < 5 seconds (10MB)
- **Email Delivery**: < 30 seconds
- **Blockchain Transactions**: < 10 seconds
- **Claim Code Generation**: < 5 seconds
- **Claim Code Encryption**: < 2 seconds
- **Code Delivery**: < 60 seconds (email), < 10 seconds (SMS)

### Throughput
- **Concurrent Users**: 10,000+
- **Plans per Second**: 100+
- **File Uploads**: 1000+ per hour
- **Email Notifications**: 10,000+ per hour
- **Claim Code Generation**: 1000+ per hour
- **Code Delivery**: 5000+ per hour
- **Code Decryption**: 2000+ per hour

### Scalability
- **Horizontal Scaling**: Auto-scaling support
- **Database**: Read replicas + sharding
- **Caching**: Multi-layer caching strategy
- **CDN**: Global content delivery

## Monitoring & Observability

### Health Checks
- **Backend Services**: API endpoint health
- **Database**: Connection and query performance
- **Blockchain**: RPC endpoint availability
- **External Services**: Third-party service status

### Metrics Collection
- **Application Metrics**: Response times, error rates
- **Infrastructure Metrics**: CPU, memory, storage
- **Business Metrics**: Plan creation, claim rates
- **Security Metrics**: Failed login attempts, suspicious activity
- **Enhanced Claim Code Metrics**: 
  - Code generation success rates and performance
  - Delivery success rates by method (email, SMS, portal)
  - Decryption success rates and failure patterns
  - Code expiration and revocation statistics
  - Security audit scores and recommendations
  - Delivery retry patterns and failure analysis

### Alerting System
- **Critical Alerts**: Service downtime, security breaches
- **Performance Alerts**: Response time degradation
- **Business Alerts**: Unusual activity patterns
- **Escalation**: Automated escalation procedures

## Compliance & Legal

### Data Privacy
- **GDPR Compliance**: European data protection
- **Data Retention**: Automated cleanup policies
- **User Rights**: Data access and deletion
- **Consent Management**: Explicit user consent

### Financial Regulations
- **KYC/AML**: Anti-money laundering compliance
- **Audit Trails**: Complete transaction history
- **Reporting**: Regulatory reporting capabilities
- **Tax Compliance**: Tax reporting support

## Development Roadmap

### Phase 1 (Months 1-3)
- [x] Enhanced claim code system smart contract implementation
- [x] Zero-knowledge encrypted code generation
- [x] Public key encryption and delivery workflow
- [ ] Rust + Axum backend API development
- [ ] Basic Pinata integration
- [ ] Smart contract improvements
- [ ] Rust indexer development

### Phase 2 (Months 4-6)
- [ ] Advanced Pinata features
- [ ] Enhanced indexer functionality with claim code monitoring
- [ ] Frontend development with claim code management
- [ ] Testing and security audit of claim code system
- [ ] Production hardening of cryptographic functions

### Phase 3 (Months 7-9)
- [ ] Production deployment
- [ ] Performance optimization of claim code system
- [ ] User acceptance testing
- [ ] Launch preparation
- [ ] Advanced delivery methods (SMS, secure portal)

### Phase 4 (Months 10-12)
- [ ] Production launch
- [ ] Monitoring and maintenance
- [ ] User feedback integration
- [ ] Feature enhancements
- [ ] Advanced security features (multi-sig, VRF)

## Risk Assessment

### Technical Risks
- **Smart Contract Vulnerabilities**: Mitigation through formal verification
- **Scalability Issues**: Mitigation through horizontal scaling
- **Performance Degradation**: Mitigation through monitoring and optimization

### Business Risks
- **Regulatory Changes**: Mitigation through compliance monitoring
- **Market Competition**: Mitigation through unique features
- **User Adoption**: Mitigation through user experience optimization

### Operational Risks
- **Service Outages**: Mitigation through redundancy and monitoring
- **Data Loss**: Mitigation through backup and recovery procedures
- **Security Breaches**: Mitigation through security best practices

## Conclusion

The InheritX platform represents a comprehensive solution for digital inheritance management, combining the security of blockchain technology with the flexibility of modern web applications. The modular architecture ensures scalability, maintainability, and security while providing a seamless user experience.

The phased development approach allows for iterative improvement and risk mitigation, ensuring that critical functionality is delivered first while maintaining system stability and security. 