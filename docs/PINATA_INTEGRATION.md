# InheritX Pinata IPFS Integration Specification

## Overview
Pinata serves as the decentralized storage layer for InheritX, handling encrypted document storage, metadata management, and secure file sharing. This integration ensures that sensitive inheritance data remains private while being accessible to authorized parties.

## Core Use Cases

### 1. Encrypted Document Storage

#### KYC Documents
- **Document Types**: Identity documents, proof of address, financial statements
- **Encryption**: Client-side encryption before upload
- **Access Control**: Role-based permissions for document access
- **Retention Policy**: Automated cleanup based on compliance requirements

#### Inheritance Plan Details
- **Encrypted Data**: Beneficiary information, asset details, special instructions
- **Metadata**: Plan structure, timestamps, ownership information
- **Access Control**: Owner and guardian access only
- **Audit Trail**: Complete access history tracking

### 2. File Management System

#### Upload Process
```typescript
interface FileUpload {
  file: Buffer | File;
  metadata: {
    fileName: string;
    fileType: string;
    encryptionKey: string;
    owner: string;
    planId?: string;
    documentType: 'kyc' | 'inheritance' | 'other';
  };
  pinataOptions: {
    pinataMetadata: {
      name: string;
      keyvalues: Record<string, string>;
    };
    pinataOptions: {
      cidVersion: 0;
      wrapWithDirectory: false;
    };
  };
}
```

#### Storage Structure
```
/kyc-documents/
  /{user-id}/
    /identity/
    /address-proof/
    /financial/
    
/inheritance-plans/
  /{plan-id}/
    /encrypted-details/
    /beneficiary-info/
    /guardian-access/
    
/temp-uploads/
  /{session-id}/
    /pending-verification/
```

### 3. Encryption & Security

#### Client-Side Encryption
- **Algorithm**: AES-256-GCM for symmetric encryption
- **Key Generation**: Cryptographically secure random keys
- **Key Storage**: Encrypted keys stored in user's wallet
- **Zero-Knowledge**: Server never sees unencrypted content

#### Access Control
- **Role-Based Access**: Owner, beneficiary, guardian, admin
- **Time-Based Access**: Expiring access tokens
- **Audit Logging**: Complete access history
- **Revocation**: Immediate access removal capability

### 4. API Integration

#### Pinata API Endpoints
```typescript
// File Upload
POST /pinning/pinFileToIPFS
POST /pinning/pinJSONToIPFS

// File Management
GET /pinning/pinList
DELETE /pinning/unpin/{hash}

// Metadata
GET /pinning/pinList?metadata[name]={name}
GET /pinning/pinList?metadata[keyvalues]={key:value}
```

#### InheritX Integration Layer
```typescript
class PinataService {
  // Upload encrypted file
  async uploadEncryptedFile(file: Buffer, metadata: FileMetadata): Promise<IPFSResponse>
  
  // Retrieve file with access control
  async getFile(ipfsHash: string, accessToken: string): Promise<EncryptedFile>
  
  // Update file metadata
  async updateMetadata(ipfsHash: string, metadata: Partial<FileMetadata>): Promise<void>
  
  // Delete file and unpin
  async deleteFile(ipfsHash: string): Promise<void>
}
```

### 5. Metadata Management

#### File Metadata Schema
```json
{
  "name": "kyc_document_001",
  "description": "Identity verification document",
  "keyvalues": {
    "documentType": "kyc",
    "userId": "user_123",
    "planId": "plan_456",
    "encryptionKey": "encrypted_key_hash",
    "uploadDate": "2024-01-15T10:30:00Z",
    "expiryDate": "2025-01-15T10:30:00Z",
    "status": "pending_verification",
    "fileSize": "2048576",
    "mimeType": "application/pdf"
  }
}
```

#### Search & Retrieval
- **Tag-Based Search**: Find files by document type, user, or plan
- **Date Range Queries**: Filter by upload or expiry dates
- **Status Filtering**: Filter by verification or approval status
- **Full-Text Search**: Search within file names and descriptions

### 6. Data Lifecycle Management

#### Upload Workflow
1. **File Selection**: User selects file for upload
2. **Client Encryption**: File encrypted with AES-256-GCM
3. **Metadata Creation**: Generate comprehensive metadata
4. **IPFS Upload**: Upload to Pinata with metadata
5. **Database Update**: Store IPFS hash and metadata
6. **Access Control**: Set up role-based permissions
7. **Notification**: Alert relevant parties of new upload

#### Retrieval Workflow
1. **Access Verification**: Validate user permissions
2. **Metadata Retrieval**: Get file metadata from IPFS
3. **Access Token Generation**: Create temporary access token
4. **File Download**: Retrieve encrypted file from IPFS
5. **Decryption**: Client-side decryption with stored key
6. **Audit Logging**: Record access attempt and success

#### Cleanup Process
1. **Expiry Monitoring**: Track file expiration dates
2. **Access Review**: Verify current access permissions
3. **Unpinning**: Remove files from IPFS pinning
4. **Database Cleanup**: Remove expired file records
5. **Notification**: Alert users of file removal

### 7. Performance Optimization

#### Caching Strategy
- **Metadata Cache**: Redis-based metadata caching
- **Access Token Cache**: Temporary token storage
- **File Size Cache**: Pre-calculated file sizes
- **Permission Cache**: Role-based access caching

#### Batch Operations
- **Bulk Upload**: Multiple file uploads in single request
- **Batch Metadata**: Update multiple files simultaneously
- **Mass Unpinning**: Remove multiple expired files
- **Parallel Processing**: Concurrent file operations

### 8. Error Handling & Recovery

#### Upload Failures
- **Retry Logic**: Exponential backoff for failed uploads
- **Fallback Storage**: Temporary local storage during outages
- **Partial Upload Recovery**: Resume interrupted uploads
- **User Notification**: Clear error messages and recovery steps

#### Retrieval Failures
- **IPFS Fallback**: Multiple IPFS gateway support
- **Cached Retrieval**: Serve from local cache when possible
- **Graceful Degradation**: Provide metadata even if file unavailable
- **Recovery Procedures**: Automated file re-upload and pinning

### 9. Monitoring & Analytics

#### Performance Metrics
- **Upload Success Rate**: Percentage of successful uploads
- **Retrieval Latency**: Average file access time
- **Storage Utilization**: IPFS storage usage tracking
- **Error Rates**: Upload and retrieval failure rates

#### Usage Analytics
- **File Type Distribution**: Most common document types
- **Storage Growth**: Monthly storage increase trends
- **Access Patterns**: Peak usage times and patterns
- **User Behavior**: Upload and retrieval frequency

### 10. Compliance & Security

#### Data Privacy
- **GDPR Compliance**: Right to be forgotten implementation
- **Data Minimization**: Store only necessary information
- **Consent Management**: User consent tracking and management
- **Data Portability**: Export user data capability

#### Security Measures
- **Access Logging**: Complete audit trail of all access
- **Encryption at Rest**: All data encrypted before IPFS storage
- **Secure Key Management**: Hardware security module integration
- **Regular Security Audits**: Third-party security assessments

### 11. Integration with Smart Contract

#### On-Chain References
- **IPFS Hash Storage**: Store file hashes in smart contract
- **Metadata Verification**: Verify file authenticity on-chain
- **Access Control**: Smart contract-based permission management
- **Event Emission**: Contract events for file operations

#### Off-Chain Synchronization
- **Event Listening**: Monitor smart contract events
- **State Updates**: Keep IPFS metadata in sync with contract
- **Permission Updates**: Reflect contract permission changes
- **Cleanup Coordination**: Coordinate with contract state changes

### 12. Development & Testing

#### Local Development
- **IPFS Local Node**: Local development environment
- **Mock Pinata API**: Simulated API responses
- **Test Data**: Sample files and metadata
- **Integration Tests**: End-to-end workflow testing

#### Testing Strategy
- **Unit Tests**: Individual service testing
- **Integration Tests**: API endpoint testing
- **End-to-End Tests**: Complete workflow validation
- **Performance Tests**: Load and stress testing
- **Security Tests**: Penetration testing and vulnerability assessment

## Technical Implementation

### Required Dependencies
```json
{
  "dependencies": {
    "@pinata/sdk": "^2.1.0",
    "ipfs-http-client": "^60.0.0",
    "crypto-js": "^4.1.1",
    "multer": "^1.4.5-lts.1",
    "redis": "^4.6.0"
  }
}
```

### Environment Variables
```bash
PINATA_API_KEY=your_pinata_api_key
PINATA_SECRET_KEY=your_pinata_secret_key
PINATA_JWT_TOKEN=your_pinata_jwt_token
IPFS_GATEWAY_URL=https://gateway.pinata.cloud
REDIS_URL=redis://localhost:6379
ENCRYPTION_KEY=your_encryption_key
```

### Configuration Files
- **pinata.config.js**: Pinata API configuration
- **ipfs.config.js**: IPFS gateway configuration
- **encryption.config.js**: Encryption algorithm settings
- **storage.config.js**: Storage policy configuration 