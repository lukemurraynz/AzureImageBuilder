param location string = resourceGroup().location

param azComputeGalleryName string = 'myGallery'

param azUserAssignedManagedIdentity string = 'useri'

var vmOfferDetails = {
  offer: 'WindowsServer'
  publisher: 'MicrosoftWindowsServer'
  sku: '2022-datacenter-azure-edition'
}

// main.bicep
module customizationsModule 'customizations.bicep' = {
  name: 'customizationsModule'
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

resource uamiassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'contributor')
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor

  }
  scope: resourceGroup()
 ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

}

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
    buildTimeoutInMinutes: 360
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: azImage.id
        runOutputName: 'myImageTemplateRunOutput'
    /*     replicationRegions: [
          'Australia East'

        ]
 */
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
      osDiskSizeGB: 128

    }
    optimize: {
      vmBoot: {
        state: 'Enabled'
      }
    }
  }
  dependsOn: [
    uami
  ]
}
