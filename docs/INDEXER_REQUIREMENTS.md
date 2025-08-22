# InheritX Indexer Requirements Specification

## Overview
The InheritX indexer serves as a critical bridge in the hybrid architecture, monitoring smart contract events, tracking wallet activity, and providing real-time data synchronization between on-chain and off-chain systems. Built in Rust for maximum performance and reliability, it handles both inheritance plan monitoring and wallet inactivity detection while maintaining data consistency across the entire platform.

## Core Responsibilities

### 1. Smart Contract Event Monitoring

#### Event Types to Monitor
```cairo
// Inheritance Plan Events
event InheritancePlanCreated {
    plan_id: u256,
    owner: ContractAddress,
    asset_type: AssetType,
    asset_amount: u256,
    timeframe: u64,
    created_at: u64
}

event InheritancePlanExecuted {
    plan_id: u256,
    executed_at: u64,
    executed_by: ContractAddress
}

event InheritanceClaimed {
    plan_id: u256,
    claimed_by: ContractAddress,
    claimed_at: u64,
    claim_code: ByteArray
}

event PlanOverridden {
    plan_id: u256,
    new_timeframe: u64,
    overridden_at: u64
}

// KYC Events
event KYCUploaded {
    user_address: ContractAddress,
    kyc_hash: ByteArray,
    user_type: UserType,
    uploaded_at: u64
}

event KYCApproved {
    user_address: ContractAddress,
    approved_by: ContractAddress,
    approved_at: u64
}

event KYCRejected {
    user_address: ContractAddress,
    rejected_by: ContractAddress,
    rejected_at: u64
}

// Swap Events
event SwapRequestCreated {
    swap_id: u256,
    plan_id: u256,
    from_token: ContractAddress,
    to_token: ContractAddress,
    amount: u256
}

event SwapExecuted {
    swap_id: u256,
    executed_at: u64,
    execution_price: u256
}
```

#### Event Processing Pipeline
1. **Event Detection**: Monitor blockchain for new events
2. **Event Parsing**: Extract relevant data from event logs
3. **Data Validation**: Verify event data integrity
4. **Database Update**: Store processed events in database
5. **Notification Trigger**: Alert backend of new events
6. **State Synchronization**: Update application state

### 2. Hybrid Data Synchronization

#### On-Chain to Off-Chain Sync
```typescript
interface DataSyncJob {
  id: string;
  syncType: 'event_processing' | 'state_sync' | 'cache_update';
  source: 'blockchain' | 'database' | 'external_api';
  target: 'database' | 'cache' | 'notification_service';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  priority: 'high' | 'medium' | 'low';
  createdAt: Date;
  processedAt?: Date;
}

interface SyncResult {
  jobId: string;
  recordsProcessed: number;
  recordsUpdated: number;
  errors: string[];
  executionTime: number;
  success: boolean;
}
```

#### Wallet Activity Monitoring
```typescript
interface WalletActivity {
  address: string;
  lastTransaction: string;
  lastActivity: Date;
  inactivityThreshold: number; // in seconds
  isInactive: boolean;
  beneficiaryEmail: string;
  notificationSent: boolean;
  onChainStatus: 'active' | 'inactive' | 'triggered';
  lastSyncTimestamp: Date;
}

interface InactivityTrigger {
  walletAddress: string;
  threshold: number; // 1 week, 1 month, 6 months
  email: string;
  createdAt: Date;
  isActive: boolean;
  lastChecked: Date;
  onChainEventId?: string;
}
```

#### Monitoring Strategies
- **Transaction Monitoring**: Track all incoming/outgoing transactions
- **Contract Interactions**: Monitor smart contract calls
- **Balance Changes**: Track token balance fluctuations
- **NFT Transfers**: Monitor NFT ownership changes
- **DeFi Activity**: Track lending, staking, and swapping

### 3. Hybrid Data Consistency Management

#### Data Consistency Patterns
```typescript
interface ConsistencyCheck {
  id: string;
  checkType: 'on_chain_off_chain' | 'cross_system' | 'temporal';
  sourceSystem: string;
  targetSystem: string;
  dataHash: string;
  expectedHash: string;
  actualHash: string;
  isConsistent: boolean;
  lastChecked: Date;
  resolutionStatus: 'pending' | 'resolved' | 'escalated';
}

interface ConsistencyRule {
  id: string;
  ruleType: 'hash_match' | 'timestamp_sync' | 'state_consistency';
  source: string;
  target: string;
  validationLogic: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  autoResolution: boolean;
}
```

#### Database Schema for Hybrid Architecture
```sql
-- Events table with hybrid tracking
CREATE TABLE blockchain_events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    block_number BIGINT NOT NULL,
    transaction_hash VARCHAR(66) NOT NULL,
    block_timestamp BIGINT NOT NULL,
    contract_address VARCHAR(42) NOT NULL,
    event_data JSONB NOT NULL,
    processed_at TIMESTAMP DEFAULT NOW(),
    off_chain_sync_status VARCHAR(20) DEFAULT 'pending',
    sync_attempts INTEGER DEFAULT 0,
    last_sync_attempt TIMESTAMP,
    INDEX idx_event_type (event_type),
    INDEX idx_block_number (block_number),
    INDEX idx_timestamp (block_timestamp),
    INDEX idx_sync_status (off_chain_sync_status)
);

-- Hybrid data consistency tracking
CREATE TABLE data_consistency_checks (
    id SERIAL PRIMARY KEY,
    check_type VARCHAR(50) NOT NULL,
    source_system VARCHAR(50) NOT NULL,
    target_system VARCHAR(50) NOT NULL,
    data_hash VARCHAR(255) NOT NULL,
    expected_hash VARCHAR(255) NOT NULL,
    actual_hash VARCHAR(255),
    is_consistent BOOLEAN DEFAULT FALSE,
    last_checked TIMESTAMP DEFAULT NOW(),
    resolution_status VARCHAR(20) DEFAULT 'pending',
    INDEX idx_check_type (check_type),
    INDEX idx_resolution_status (resolution_status)
);
```

-- Wallet activity table
CREATE TABLE wallet_activity (
    id SERIAL PRIMARY KEY,
    wallet_address VARCHAR(42) NOT NULL,
    last_transaction_hash VARCHAR(66),
    last_activity_timestamp BIGINT NOT NULL,
    inactivity_threshold BIGINT NOT NULL,
    beneficiary_email VARCHAR(255),
    is_inactive BOOLEAN DEFAULT FALSE,
    notification_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_wallet_address (wallet_address),
    INDEX idx_last_activity (last_activity_timestamp),
    INDEX idx_is_inactive (is_inactive)
);

-- Inheritance plans table
CREATE TABLE inheritance_plans (
    id SERIAL PRIMARY KEY,
    plan_id BIGINT NOT NULL,
    owner_address VARCHAR(42) NOT NULL,
    asset_type VARCHAR(20) NOT NULL,
    asset_amount NUMERIC(78,0) NOT NULL,
    timeframe BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at BIGINT NOT NULL,
    becomes_active_at BIGINT NOT NULL,
    is_claimed BOOLEAN DEFAULT FALSE,
    claimed_at BIGINT,
    claimed_by VARCHAR(42),
    ipfs_hash VARCHAR(255),
    INDEX idx_plan_id (plan_id),
    INDEX idx_owner (owner_address),
    INDEX idx_status (status),
    INDEX idx_becomes_active (becomes_active_at)
);

-- KYC data table
CREATE TABLE kyc_data (
    id SERIAL PRIMARY KEY,
    user_address VARCHAR(42) NOT NULL,
    kyc_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    uploaded_at BIGINT NOT NULL,
    approved_at BIGINT,
    approved_by VARCHAR(42),
    ipfs_hash VARCHAR(255),
    INDEX idx_user_address (user_address),
    INDEX idx_status (status),
    INDEX idx_uploaded_at (uploaded_at)
);
```

### 4. Real-Time Data Synchronization

#### WebSocket Integration
```typescript
interface WebSocketMessage {
  type: 'event' | 'wallet_activity' | 'plan_update' | 'kyc_update';
  data: any;
  timestamp: number;
  signature?: string;
}

class WebSocketService {
  // Broadcast new events to connected clients
  broadcastEvent(event: BlockchainEvent): void;
  
  // Send wallet inactivity alerts
  sendInactivityAlert(wallet: WalletActivity): void;
  
  // Update plan status in real-time
  updatePlanStatus(planId: string, status: string): void;
  
  // Notify KYC status changes
  notifyKYCUpdate(userAddress: string, status: string): void;
}
```

#### API Endpoints
```typescript
// Real-time data endpoints
GET /api/indexer/events/latest
GET /api/indexer/events/range?from={timestamp}&to={timestamp}
GET /api/indexer/wallet/{address}/activity
GET /api/indexer/plans/{planId}/status
GET /api/indexer/kyc/{userAddress}/status

// WebSocket endpoints
WS /api/indexer/ws/events
WS /api/indexer/ws/wallet-activity
WS /api/indexer/ws/plans
WS /api/indexer/ws/kyc
```

### 5. Inactivity Detection Algorithm

#### Detection Logic
```typescript
class InactivityDetector {
  // Check if wallet is inactive based on threshold
  isWalletInactive(wallet: WalletActivity): boolean {
    const now = Date.now();
    const timeSinceLastActivity = now - wallet.lastActivity;
    return timeSinceLastActivity >= wallet.inactivityThreshold;
  }
  
  // Process inactivity triggers
  async processInactivityTriggers(): Promise<void> {
    const triggers = await this.getActiveTriggers();
    
    for (const trigger of triggers) {
      const isInactive = await this.checkWalletInactivity(trigger.walletAddress);
      
      if (isInactive && !trigger.notificationSent) {
        await this.sendInactivityNotification(trigger);
        await this.markNotificationSent(trigger.id);
      }
    }
  }
  
  // Send email notification for inactivity
  async sendInactivityNotification(trigger: InactivityTrigger): Promise<void> {
    const emailData = {
      to: trigger.beneficiaryEmail,
      subject: 'Wallet Inactivity Alert - InheritX',
      template: 'inactivity-alert',
      data: {
        walletAddress: trigger.walletAddress,
        threshold: this.formatThreshold(trigger.threshold),
        platformUrl: process.env.PLATFORM_URL
      }
    };
    
    await this.emailService.sendEmail(emailData);
  }
}
```

### 6. Performance & Scalability

#### Indexing Performance
- **Block Processing**: Process 100+ blocks per second
- **Event Parsing**: Parse 1000+ events per second
- **Database Writes**: Handle 10,000+ writes per second
- **Real-Time Updates**: < 100ms latency for updates

#### Scalability Features
- **Horizontal Scaling**: Multiple indexer instances
- **Load Balancing**: Distribute blockchain queries
- **Database Sharding**: Partition data by time ranges
- **Caching Layer**: Redis-based event caching
- **Queue Processing**: Background job processing

#### Rust-Specific Performance Optimizations
```rust
// High-performance event processing with Rust
#[derive(Debug, Clone)]
pub struct EventProcessor {
    event_queue: Arc<Mutex<VecDeque<BlockchainEvent>>>,
    workers: Vec<JoinHandle<()>>,
    batch_size: usize,
}

impl EventProcessor {
    pub async fn process_events_batch(&self) -> Result<(), Box<dyn std::error::Error>> {
        let mut events = Vec::new();
        
        // Collect events in batches for efficiency
        {
            let mut queue = self.event_queue.lock().await;
            while events.len() < self.batch_size && !queue.is_empty() {
                if let Some(event) = queue.pop_front() {
                    events.push(event);
                }
            }
        }
        
        // Process events in parallel with Tokio
        let chunks: Vec<_> = events.chunks(self.batch_size / 4).collect();
        let handles: Vec<_> = chunks
            .into_iter()
            .map(|chunk| {
                let chunk = chunk.to_vec();
                tokio::spawn(async move {
                    Self::process_event_chunk(chunk).await
                })
            })
            .collect();
        
        // Wait for all chunks to complete
        for handle in handles {
            handle.await??;
        }
        
        Ok(())
    }
}

// Efficient database operations with Rust async
#[derive(Debug, Clone)]
pub struct DatabaseManager {
    pool: PgPool,
    redis_client: RedisClient,
    cache: Arc<Mutex<LruCache<String, Vec<u8>>>>,
}

impl DatabaseManager {
    pub async fn batch_insert_events(
        &self,
        events: Vec<BlockchainEvent>,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Use batch insert for efficiency
        let mut query_builder = QueryBuilder::new(
            "INSERT INTO blockchain_events (event_type, block_number, transaction_hash, event_data) "
        );
        
        query_builder.push_values(events.iter(), |mut b, event| {
            b.push_bind(&event.event_type)
                .push_bind(event.block_number)
                .push_bind(&event.transaction_hash)
                .push_bind(&event.event_data);
        });
        
        let query = query_builder.build();
        query.execute(&self.pool).await?;
        
        Ok(())
    }
}
```

### 7. Error Handling & Recovery

#### Failure Scenarios
- **Blockchain Node Failure**: Fallback to multiple RPC endpoints
- **Database Connection Loss**: Automatic reconnection with retry logic
- **Event Processing Errors**: Dead letter queue for failed events
- **Network Timeouts**: Exponential backoff for retries

#### Recovery Mechanisms
```typescript
class IndexerRecovery {
  // Recover from blockchain node failure
  async switchRpcEndpoint(): Promise<void> {
    const endpoints = this.getRpcEndpoints();
    for (const endpoint of endpoints) {
      if (await this.testEndpoint(endpoint)) {
        this.currentEndpoint = endpoint;
        break;
      }
    }
  }
  
  // Replay missed events
  async replayEvents(fromBlock: number, toBlock: number): Promise<void> {
    const events = await this.getEventsInRange(fromBlock, toBlock);
    for (const event of events) {
      await this.processEvent(event);
    }
  }
  
  // Verify data integrity
  async verifyDataIntegrity(): Promise<boolean> {
    const lastProcessedBlock = await this.getLastProcessedBlock();
    const blockchainBlock = await this.getLatestBlockNumber();
    
    return lastProcessedBlock >= blockchainBlock - 10; // Allow 10 block lag
  }
}
```

### 8. Hybrid System Monitoring & Alerting

#### Cross-System Health Checks
- **Block Processing Rate**: Monitor blocks processed per second
- **Event Processing Rate**: Track events processed per second
- **Off-Chain Sync Status**: Monitor data synchronization between systems
- **Data Consistency**: Track consistency between on-chain and off-chain data
- **Cross-System Latency**: Monitor response times between all components

#### Hybrid Health Metrics
```typescript
interface HybridHealthMetrics {
  blockchain: {
    blockProcessingRate: number;
    eventProcessingRate: number;
    rpcLatency: number;
    lastBlockProcessed: number;
  };
  backend: {
    apiResponseTime: number;
    databasePerformance: number;
    externalApiHealth: number;
    cacheHitRate: number;
  };
  synchronization: {
    onChainToOffChainSync: number;
    dataConsistencyScore: number;
    syncQueueLength: number;
    lastSyncTimestamp: Date;
  };
  overall: {
    systemHealth: 'healthy' | 'degraded' | 'critical';
    criticalIssues: string[];
    recommendations: string[];
  };
}
```

#### Hybrid Alerting System
```typescript
interface HybridAlert {
  id: string;
  alertType: 'consistency_breach' | 'sync_failure' | 'performance_degradation';
  severity: 'low' | 'medium' | 'high' | 'critical';
  sourceSystem: string;
  targetSystem: string;
  description: string;
  impact: string;
  recommendedAction: string;
  createdAt: Date;
  resolvedAt?: Date;
  resolutionNotes?: string;
}

class HybridAlertingService {
  // Monitor data consistency between systems
  async checkDataConsistency(): Promise<void> {
    const consistencyChecks = await this.performConsistencyChecks();
    
    for (const check of consistencyChecks) {
      if (!check.isConsistent) {
        await this.createAlert({
          alertType: 'consistency_breach',
          severity: 'high',
          sourceSystem: check.sourceSystem,
          targetSystem: check.targetSystem,
          description: `Data inconsistency detected between ${check.sourceSystem} and ${check.targetSystem}`,
          impact: 'Potential data loss or corruption',
          recommendedAction: 'Investigate and resolve data sync issues'
        });
      }
    }
  }
  
  // Monitor synchronization performance
  async checkSyncPerformance(): Promise<void> {
    const syncMetrics = await this.getSyncMetrics();
    
    if (syncMetrics.lag > 300) { // 5 minutes
      await this.createAlert({
        alertType: 'sync_failure',
        severity: 'medium',
        sourceSystem: 'blockchain',
        targetSystem: 'backend',
        description: 'Blockchain sync lag detected',
        impact: 'Delayed data updates',
        recommendedAction: 'Check indexer performance and blockchain connectivity'
      });
    }
  }
}
```

#### Alerting System
```typescript
interface Alert {
  type: 'error' | 'warning' | 'info';
  message: string;
  timestamp: Date;
  severity: 'low' | 'medium' | 'high' | 'critical';
  metadata: Record<string, any>;
}

class AlertingService {
  // Send critical alerts
  async sendCriticalAlert(alert: Alert): Promise<void> {
    await this.slackService.sendMessage(alert);
    await this.emailService.sendAlert(alert);
    await this.pagerDutyService.createIncident(alert);
  }
  
  // Monitor indexer health
  async checkIndexerHealth(): Promise<boolean> {
    const metrics = await this.getHealthMetrics();
    
    if (metrics.blockProcessingRate < 50) {
      await this.sendCriticalAlert({
        type: 'error',
        message: 'Block processing rate below threshold',
        timestamp: new Date(),
        severity: 'high',
        metadata: { currentRate: metrics.blockProcessingRate, threshold: 50 }
      });
      return false;
    }
    
    return true;
  }
}
```

### 9. Security & Privacy

#### Data Protection
- **Encryption**: Encrypt sensitive data at rest
- **Access Control**: Role-based access to indexer data
- **Audit Logging**: Log all data access and modifications
- **Data Retention**: Implement data retention policies

#### Blockchain Security
- **RPC Security**: Secure connections to blockchain nodes
- **Event Validation**: Verify event authenticity
- **Replay Protection**: Prevent duplicate event processing
- **Signature Verification**: Validate event signatures

### 10. Integration Points

#### Backend Integration
- **Event Notifications**: Real-time updates to backend services
- **Data Synchronization**: Keep backend database in sync
- **API Endpoints**: Provide indexed data to backend
- **WebSocket Connections**: Real-time data streaming

#### Frontend Integration
- **Real-Time Updates**: Live data updates in user interface
- **Search & Filtering**: Fast data queries for user searches
- **Dashboard Data**: Real-time dashboard updates
- **Notification System**: User alerts and updates

### 11. Development & Testing

#### Local Development
- **Local Blockchain**: Ganache or Hardhat for testing
- **Mock Events**: Simulated blockchain events
- **Test Database**: Local PostgreSQL instance
- **Development Tools**: Hot reloading and debugging

#### Testing Strategy
- **Unit Tests**: Individual component testing
- **Integration Tests**: End-to-end workflow testing
- **Performance Tests**: Load and stress testing
- **Security Tests**: Vulnerability assessment

### 12. Deployment & Operations

#### Rust Dependencies (Cargo.toml)
```toml
[dependencies]
# Async runtime
tokio = { version = "1.0", features = ["full"] }

# Database
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "postgres", "chrono"] }
redis = { version = "0.23", features = ["tokio-comp"] }

# HTTP client
reqwest = { version = "0.11", features = ["json"] }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Cryptography
sha2 = "0.10"
hex = "0.4"

# Logging
tracing = "0.1"
tracing-subscriber = "0.3"

# Error handling
anyhow = "1.0"
thiserror = "1.0"

# Time handling
chrono = { version = "0.4", features = ["serde"] }

# Caching
lru = "0.12"

# WebSocket
tokio-tungstenite = "0.20"
```

#### Infrastructure Requirements
- **High-Performance Servers**: CPU and memory optimized for Rust
- **Fast Storage**: SSD storage for database with async I/O
- **Network Bandwidth**: High-speed internet connection
- **Redundancy**: Multiple blockchain node connections

#### Deployment Options
- **Docker Containers**: Containerized deployment
- **Kubernetes**: Orchestrated container management
- **Cloud Deployment**: AWS, Azure, or Google Cloud
- **On-Premises**: Self-hosted infrastructure

#### Monitoring & Maintenance
- **Log Management**: Centralized log collection
- **Performance Monitoring**: Real-time performance tracking
- **Backup & Recovery**: Automated backup procedures
- **Update Management**: Seamless deployment updates 