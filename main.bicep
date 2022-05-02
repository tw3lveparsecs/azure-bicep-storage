@description('Storage account name')
param storageAccountName string

@description('Storage account sku')
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

@description('Storage account kind')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param storageKind string

@description('Storage account access tier, Hot for frequently accessed data or Cool for infreqently accessed data')
@allowed([
  'Hot'
  'Cool'
])
param storageTier string

@description('Amount of days the soft deleted data is stored and available for recovery')
@minValue(1)
@maxValue(365)
param deleteRetentionPolicy int

@description('Enable blob encryption at rest')
param blobEncryptionEnabled bool = true

@description('Create storage account with a file share')
param enableFileShare bool = false

@description('File share name. Only required if enableFileShare is true')
param fileShareName string = ''

@allowed([
  'Hot'
  'Cool'
  'Premium'
  'TransactionOptimized'
])
@description('File share name. Only required if enableFileShare is true')
param fileShareTier string = 'Hot'

@allowed([
  'SMB'
  'NFS'
])
@description('The authentication protocol that is used for the file share. Only required if enableFileShare is true')
param fileShareProtocol string = 'SMB'

@minValue(1)
@maxValue(5120)
@description('The maximum size of the share, in gigabytes. Only required if enableFileShare is true')
param fileShareQuota int = 5120

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Specify the type of resource lock')
param resourcelock string = 'NotSpecified'

@description('Enable diagnostic logs')
param enableDiagnostics bool = false

@description('Storage account resource id. Only required if enableDiagnostics is set to true')
param diagnosticStorageAccountId string = ''

@description('Log analytics workspace resource id. Only required if enableDiagnostics is set to true')
param diagnosticLogAnalyticsWorkspaceId string = ''

@description('Event hub authorization rule for the Event Hubs namespace. Only required if enableDiagnostics is set to true')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Event hub name. Only required if enableDiagnostics is set to true')
param diagnosticEventHubName string = ''

var lockName = toLower('${storage.name}-${resourcelock}-lck')
var diagnosticsName = '${storage.name}-dgs'

resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: resourceGroup().location
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

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-08-01' = if (enableFileShare) {
  parent: storage
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      days: deleteRetentionPolicy
      enabled: enableFileShare ? true : null
    }
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = if (enableFileShare) {
  name: !empty(fileShareName) ? fileShareName : 'default'
  parent: fileServices
  properties: {
    accessTier: fileShareTier
    enabledProtocols: fileShareProtocol
    shareQuota: fileShareQuota
  }
}

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

resource diagnosticsFileServices 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && enableFileShare) {
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

output name string = storage.name
output id string = storage.id
