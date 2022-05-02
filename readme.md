# Storage Account
This module will deploy a Storage Account with blob encryption at rest and delete retention policies. 

## Usage

### Example 1 - Storage account with encryption enabled
``` bicep
param deploymentName string = 'storage${utcNow()}'

module storage './main.bicep' = {
  name: deploymentName
  params: {
    storageAccountName: 'mystorageaccount'
    storageSku: 'Standard_LRS'
    storageKind: 'StorageV2'
    storageTier: 'Hot'
    deleteRetentionPolicy: 7
  }
}
```

### Example 2 - Storage account without encryption enabled
``` bicep
param deploymentName string = 'storage${utcNow()}'

module storage './main.bicep' = {
  name: deploymentName
  params: {
    storageAccountName: 'mystorageaccount'
    storageSku: 'Standard_LRS'
    storageKind: 'StorageV2'
    storageTier: 'Hot'
    deleteRetentionPolicy: 7
    blobEncryptionEnabled: false
  }
}
```
### Example 3 - Storage account with file share and diagnostics
``` bicep
param deploymentName string = 'storage${utcNow()}'

module storage 'main.bicep' = {
  name: deploymentName
  params: {
    storageAccountName: 'mystorageaccount'
    storageSku: 'Standard_LRS'
    storageKind: 'StorageV2'
    storageTier: 'Hot'
    deleteRetentionPolicy: 7
    enableFileShare: true
    fileShareName: 'myshare'
    fileShareTier: 'Hot'
    enableDiagnostics: true
    diagnosticLogAnalyticsWorkspaceId: 'myLogAnalyticsWorkspaceResourceId'
  }
}
```