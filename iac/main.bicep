// Define parameters for the Bicep template
param location string = resourceGroup().location
param imagetemplatename string
param azComputeGalleryName string = 'myGallery'
@description('The name of the Storage account.')
param stgaccountname string
param azUserAssignedManagedIdentity string = 'useri'

// Define the details for the VM offer
var vmOfferDetails = {
  offer: 'WindowsServer'
  publisher: 'MicrosoftWindowsServer'
  sku: '2022-datacenter-azure-edition'
}

// Include the customizations module
module customizationsModule 'customizations.bicep' = {
  name: 'customizationsModule'
  params: {
    stgaccountname: stgaccountname
  }
}

// Create a user-assigned managed identity
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: azUserAssignedManagedIdentity
  location: location
}

// Create a Compute Gallery
resource azComputeGallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: azComputeGalleryName
  location: location
  properties: {
    description: 'mygallery'
  }
}

// Assign the Contributor role to the managed identity at the resource group scope
resource uamicontribassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'contributor')
  properties: {
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal' 
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
  }
  scope: resourceGroup()
}

// Assign the Storage Blob Data Reader role to the managed identity at the resource group scope
resource uamiblobassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'blobreader')
  properties: {
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal' 
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
  }
  scope: resourceGroup()
}

// Create an image in the Compute Gallery
resource azImage 'Microsoft.Compute/galleries/images@2022-03-03' = {
  name: '${azComputeGallery.name}/myImage'
  location: location
  properties: {
    description: 'myImage'
    osType: 'Windows'
    osState: 'Generalized'
    hyperVGeneration: 'V2'
    identifier: {
      publisher: vmOfferDetails.publisher
      offer: vmOfferDetails.offer
      sku: vmOfferDetails.sku
    }
  }
  dependsOn: [
    uami
  ]
}

// Create an image template
resource azImageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-07-01' = {
  name: imagetemplatename
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 360
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: azImage.id
        runOutputName: 'myImageTemplateRunOutput'
        replicationRegions: [
          'Australia East'
        ]
      }
    ]
    source: {
      type: 'PlatformImage'
      publisher: vmOfferDetails.publisher
      offer: vmOfferDetails.offer
      sku: vmOfferDetails.sku
      version: 'latest'
    }
    customize: customizationsModule.outputs.customizationsOutput
    vmProfile: {
      vmSize: 'Standard_D4ds_v5'
      osDiskSizeGB: 0 // Leave size as source image size.
    
    }
    
    optimize: {
      vmBoot: {
        state: 'Enabled'
      }
    }
  }
}
