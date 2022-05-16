# Storage Account
This module will deploy a Storage Account with blob encryption at rest and delete retention policies. 

You can optionally configure file shares, storage queues, diagnostics and a resource lock.

## Usage

### Example 1 - Storage account with encryption enabled and a container
``` bicep
param deploymentName string = 'storage${utcNow()}'
param location string = resourceGroup().location

module storage './storage.bicep' = {
  name: deploymentName
  params: {
    storageAccountName: 'mystorageaccount'
    location: location    
    storageSku: 'Standard_LRS'
    storageKind: 'StorageV2'
    storageTier: 'Hot'
    deleteRetentionPolicy: 7
    containers: [
      {
        containerName: 'container1'
        publicAccess: 'None'
      }
    ]
  }
}
```

### Example 2 - Storage account without encryption enabled
``` bicep
param deploymentName string = 'storage${utcNow()}'
param location string = resourceGroup().location

module storage './storage.bicep' = {
  name: deploymentName
  params: {
    storageAccountName: 'mystorageaccount'
    location: location    
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
param location string = resourceGroup().location

module storage 'storage.bicep' = {
  name: deploymentName
  params: {
    storageAccountName: 'mystorageaccount'
    location: location
    storageSku: 'Standard_LRS'
    storageKind: 'StorageV2'
    storageTier: 'Hot'
    deleteRetentionPolicy: 7
    fileShares: [
      {
        fileShareName: 'share1'
        fileShareTier: 'Hot'
        fileShareProtocol: 'SMB'
        fileShareQuota: 5120
      }
    ]
    enableDiagnostics: true
    diagnosticLogAnalyticsWorkspaceId: '/subscriptions/200ef0b6-6c4f-4c21-a331-f8301096bac9/resourcegroups/dev-lab-rgp/providers/microsoft.operationalinsights/workspaces/dev-lab-law'
  }
}
```

### Example 4 - Storage account with storage queue
``` bicep
param deploymentName string = 'storage${utcNow()}'
param location string = resourceGroup().location

module storage 'storage.bicep' = {
  name: deploymentName
  params: {
    storageAccountName: 'mystorageaccount'
    location: location
    storageSku: 'Standard_LRS'
    storageKind: 'StorageV2'
    storageTier: 'Hot'
    deleteRetentionPolicy: 7
    queues: [
      {
        queueName: 'queue1'
      }
    ]
  }
}
```