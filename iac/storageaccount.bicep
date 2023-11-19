
@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the Storage account.')
param stgaccountname string

@description('Sets the public access of the storage account.')
param publicaccess bool

resource storgeaccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower(stgaccountname)
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: publicaccess
  }
  
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storgeaccount
  name: 'default'
  
 properties: {
  
  isVersioningEnabled: true


}

}

resource appcontainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
 name: 'iac'
  parent: blobService
  }


output storgeaccountid string = storgeaccount.id
output storgeaccountname string = storgeaccount.name
output containername string = appcontainer.name

