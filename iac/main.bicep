param location string = resourceGroup().location

param azComputeGalleryName string = 'myGallery'
param azImageDefinitionyName string = 'MyImage'

param azUserAssignedManagedIdentity string = 'useri'

var vmOfferDetails = {
  offer: 'WindowsServer'
  publisher: 'MicrosoftWindowsServer'
  sku: '2022-datacenter-azure-edition'
}


resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: azUserAssignedManagedIdentity
  location: location
}

resource azComputeGallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: azComputeGalleryName
  location: location
  properties: {
    description: 'mygallery'
  }
}

resource azImageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-07-01' = {
  name: 'myImageTemplate'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
    }

    properties: {
      distribute: [
        {
         type:  'SharedImage'
         galleryImageId: azComputeGallery.id
         runOutputName: 'myImageTemplateRunOutput'
        }
      ]
      source: {
        type: 'PlatformImage'
        platformImageSource: {
          publisher: vmOfferDetails.publisher
          offer: vmOfferDetails.offer
          sku: vmOfferDetails.sku
          version: 'latest'
        }
      }
  
    }
  }

