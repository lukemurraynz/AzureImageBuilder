@description('The name of the Storage account.')
param stgaccountname string

// customizations.bicep
var customizations = [
  {
    type: 'PowerShell'
    name: 'Create Temp Directory on OS drive'
    runElevated: false
    runAsSystem: false
    inline: [
      'New-Item -ItemType Directory -Force -Path $env:SystemDrive\\temp'
    ]
  }

  {
    type: 'PowerShell'
    name: 'Set Timezone - New Zealand Standard Time'
    runElevated: true
    runAsSystem: true
    inline: [
      'Set-TimeZone -Id "New Zealand Standard Time"'
    ]
  }

  {
    type: 'WindowsUpdate'
    searchCriteria: 'IsInstalled=0'
    filters: [
      'exclude:$_.Title -like \'*Preview*\'' // Exclude preview updates
      'include:$true'
    ]
    updateLimit: 20
  }

  {
    //Restart after Windows updates have completed
    type: 'WindowsRestart'
    restartCheckCommand: 'write-host \'restarting post Windows Updates\''
    restartTimeout: '10m'
  }
  // Add more customizations here
    {
    type: 'PowerShell'
    name: 'Copy BGInfo from Storage account'
    runElevated: false
    runAsSystem: false
    inline: [
      'Start-BitsTransfer -Source https://${stgaccountname}.blob.core.windows.net/iac/bginfo/BGInfo.zip -Destination $env:SystemDrive\\temp -Asynchronous -Priority normal'
    ]
  }
]

output customizationsOutput array = customizations
