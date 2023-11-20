// Define the location parameter for all resources
@description('Location for all resources.')
param location string = resourceGroup().location

// Define the parameter for the Storage account name
@description('The name of the Storage account.')
param stgaccountname string

// Define the parameter for the public access setting of the Storage account
@description('Sets the public access of the storage account.')
param publicaccess bool

// Create a Storage account
resource storgeaccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower(stgaccountname) // Convert the Storage account name to lowercase
  location: location // Set the location of the Storage account
  kind: 'StorageV2' // Use the 'StorageV2' kind
  sku: {
    name: 'Standard_LRS' // Use the 'Standard_LRS' SKU
  }
  properties: {
    accessTier: 'Hot' // Set the access tier to 'Hot'
    allowBlobPublicAccess: publicaccess // Set the public access setting
  }
}

// Create a Blob service for the Storage account
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storgeaccount // Set the parent resource to the Storage account
  name: 'default' // Use the 'default' name
  properties: {
    isVersioningEnabled: true // Enable versioning
  
  }
}

// Create a container in the Blob service
resource appcontainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: 'iac' // Set the container name to 'iac'
  parent: blobService // Set the parent resource to the Blob service
  properties: {
    publicAccess: publicaccess ? 'Blob' : 'None' // Set the public access setting
  }
}

// Output the ID of the Storage account
output storgeaccountid string = storgeaccount.id

// Output the name of the Storage account
output storgeaccountname string = storgeaccount.name

// Output the name of the container
output containername string = appcontainer.name
