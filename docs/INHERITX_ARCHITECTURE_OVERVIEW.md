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
- Claim code generation and validation
- Wallet inactivity monitoring
- Multi-asset support (STRK, USDT, USDC, NFT)

**Current Status**: ✅ Implemented with basic functionality
**Improvement Needed**: Enhanced beneficiary management, claim codes, events

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
3. Backend generates claim codes and stores in database (Off-Chain)
   ↓
4. Backend calls smart contract with validated data (Off-Chain → On-Chain)
   ↓
5. Smart contract creates plan and stores critical state (On-Chain)
   ↓
6. Indexer processes contract events and updates backend (On-Chain → Off-Chain)
   ↓
7. Backend stores plan details and sends email notifications (Off-Chain)
   ↓
8. Pinata stores encrypted beneficiary information (Off-Chain)
```

### Pattern 2: Inheritance Claim Process (Off-Chain → On-Chain → Off-Chain)
```
1. Beneficiary receives claim code via email (Off-Chain)
   ↓
2. Backend validates claim code against database (Off-Chain)
   ↓
3. Backend verifies KYC status and compliance (Off-Chain)
   ↓
4. Backend calls smart contract to execute claim (Off-Chain → On-Chain)
   ↓
5. Smart contract releases assets from escrow (On-Chain)
   ↓
6. Indexer monitors asset transfer completion (On-Chain → Off-Chain)
   ↓
7. Backend updates claim status and sends confirmation (Off-Chain)
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

## Security Architecture

### Data Protection
- **Encryption at Rest**: All sensitive data encrypted
- **Client-Side Encryption**: Zero-knowledge file storage
- **Access Control**: Role-based permissions
- **Audit Logging**: Complete activity tracking

### Blockchain Security
- **Smart Contract**: Formal verification recommended
- **Access Control**: Multi-signature support
- **Emergency Functions**: Pause and emergency withdrawal
- **Upgradeability**: Controlled upgrade process

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

### Throughput
- **Concurrent Users**: 10,000+
- **Plans per Second**: 100+
- **File Uploads**: 1000+ per hour
- **Email Notifications**: 10,000+ per hour

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
- [ ] Rust + Axum backend API development
- [ ] Basic Pinata integration
- [ ] Smart contract improvements
- [ ] Rust indexer development

### Phase 2 (Months 4-6)
- [ ] Advanced Pinata features
- [ ] Enhanced indexer functionality
- [ ] Frontend development
- [ ] Testing and security audit

### Phase 3 (Months 7-9)
- [ ] Production deployment
- [ ] Performance optimization
- [ ] User acceptance testing
- [ ] Launch preparation

### Phase 4 (Months 10-12)
- [ ] Production launch
- [ ] Monitoring and maintenance
- [ ] User feedback integration
- [ ] Feature enhancements

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