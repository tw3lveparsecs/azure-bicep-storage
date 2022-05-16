@description('Storage account name.')
param storageAccountName string

@description('Storage account location.')
param location string

@description('Storage account sku.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageSku string

@description('Storage account kind.')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param storageKind string

@description('Storage account access tier, Hot for frequently accessed data or Cool for infreqently accessed data.')
@allowed([
  'Hot'
  'Cool'
])
param storageTier string

@description('Allow or disallow public network access to Storage Account.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Amount of days the soft deleted data is stored and available for recovery.')
@minValue(1)
@maxValue(365)
param deleteRetentionPolicy int

@description('Enable blob encryption at rest.')
param blobEncryptionEnabled bool = true

@description('Containers to create in the storage account.')
@metadata({
  containerName: 'Container name.'
  publicAccess: 'Specifies whether data in the container may be accessed publicly and the level of access. Accepted values: None, Blob, Container.'
})
param containers array = []

@description('Files shares to create in the storage account.')
@metadata({
  fileShareName: 'File share name.'
  fileShareTier: 'File share tier. Accepted values are Hot, Cool, TransactionOptimized or Premium.'
  fileShareProtocol: 'The authentication protocol that is used for the file share. Accepted values are SMB and NFS.'
  fileShareQuota: 'The maximum size of the share, in gigabytes.'
})
param fileShares array = []

@description('Queue to create in the storage account.')
@metadata({
  queueName: 'Queue name.'
})
param queues array = []

@description('Rule definitions governing the Storage network access.')
@metadata({
  bypass: 'Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Possible values are any combination of Logging, Metrics, AzureServices.'
  defaultAction: 'Specifies the default action of allow or deny when no other rules match. Accepted values: "Allow" or "Deny".'
  ipRules: [
    {
      action: 'Allow'
      value: 'IPv4 address or CIDR range'
    }
  ]
  virtualNetworkRules: [
    {
      action: 'The action of virtual network rule.'
      id: 'Full resource id of a vnet subnet.'
    }
  ]
  resourceAccessRules: [
    {
      resourceId: '	Resource Id.'
      tenantId: 'Tenant Id.'
    }
  ]
})
param networkRuleSet object = {}

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Specify the type of resource lock.')
param resourcelock string = 'NotSpecified'

@description('Enable diagnostic logs.')
param enableDiagnostics bool = false

@description('Storage account resource id. Only required if enableDiagnostics is set to true.')
param diagnosticStorageAccountId string = ''

@description('Log analytics workspace resource id. Only required if enableDiagnostics is set to true.')
param diagnosticLogAnalyticsWorkspaceId string = ''

@description('Event hub authorization rule for the Event Hubs namespace. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Event hub name. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubName string = ''

var lockName = toLower('${storage.name}-${resourcelock}-lck')
var diagnosticsName = '${storage.name}-dgs'

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSku
  }
  kind: storageKind
  properties: {
    accessTier: storageTier
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: blobEncryptionEnabled
        }
      }
    }
    networkAcls: networkRuleSet
    publicNetworkAccess: publicNetworkAccess
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: deleteRetentionPolicy
    }
  }
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = [for container in containers: {
  name: container.containerName
  parent: blobServices
  properties: {
    publicAccess: container.publicAccess
  }
}]

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-08-01' = if (!empty(fileShares)) {
  parent: storage
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      days: deleteRetentionPolicy
      enabled: true
    }
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = [for fileShare in fileShares: {
  name: fileShare.fileShareName
  parent: fileServices
  properties: {
    accessTier: fileShare.fileShareTier
    enabledProtocols: fileShare.fileShareProtocol
    shareQuota: fileShare.fileShareQuota
  }
}]

resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2021-09-01' = if (!empty(queues)) {
  parent: storage
  name: 'default'
  properties: {}
}

resource storageQueues 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-09-01' = [for queue in queues: {
  parent: queueServices
  name: queue.queueName
  properties: {}
}]

resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (resourcelock != 'NotSpecified') {
  name: lockName
  properties: {
    level: resourcelock
    notes: (resourcelock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: storage
}

resource diagnosticsStorage 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: storage
  name: diagnosticsName
  properties: {
    workspaceId: empty(diagnosticLogAnalyticsWorkspaceId) ? null : diagnosticLogAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    eventHubAuthorizationRuleId: empty(diagnosticEventHubAuthorizationRuleId) ? null : diagnosticEventHubAuthorizationRuleId
    eventHubName: empty(diagnosticEventHubName) ? null : diagnosticEventHubName
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

resource diagnosticsBlobServices 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: blobServices
  name: diagnosticsName
  properties: {
    workspaceId: empty(diagnosticLogAnalyticsWorkspaceId) ? null : diagnosticLogAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    eventHubAuthorizationRuleId: empty(diagnosticEventHubAuthorizationRuleId) ? null : diagnosticEventHubAuthorizationRuleId
    eventHubName: empty(diagnosticEventHubName) ? null : diagnosticEventHubName
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

resource diagnosticsFileServices 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(fileShares)) {
  scope: fileServices
  name: diagnosticsName
  properties: {
    workspaceId: empty(diagnosticLogAnalyticsWorkspaceId) ? null : diagnosticLogAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    eventHubAuthorizationRuleId: empty(diagnosticEventHubAuthorizationRuleId) ? null : diagnosticEventHubAuthorizationRuleId
    eventHubName: empty(diagnosticEventHubName) ? null : diagnosticEventHubName
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

resource diagnosticsQueueServices 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(queues)) {
  scope: queueServices
  name: diagnosticsName
  properties: {
    workspaceId: empty(diagnosticLogAnalyticsWorkspaceId) ? null : diagnosticLogAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    eventHubAuthorizationRuleId: empty(diagnosticEventHubAuthorizationRuleId) ? null : diagnosticEventHubAuthorizationRuleId
    eventHubName: empty(diagnosticEventHubName) ? null : diagnosticEventHubName
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

output name string = storage.name
output id string = storage.id
