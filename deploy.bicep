param deploymentName string = 'storage${utcNow()}'
param location string = resourceGroup().location

module storage './storage.bicep' = {
  name: deploymentName
  params: {
    storageAccountName: 'devajlabstorage02'
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
