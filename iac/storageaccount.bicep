@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the Storage account.')
param stgaccountname string

resource storgeaccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: stgaccountname
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
  }
}
