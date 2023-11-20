// Define the parameter for the Storage account name
@description('The name of the Storage account.')
param stgaccountname string

// Get the environment-specific metadata
var environmentMetadata = environment()

// Define the customizations for the image
var customizations = [
  // Create a apps directory on the OS drive
  {
    type: 'PowerShell'
    name: 'Create Apps Directory on OS drive'
    runElevated: false
    runAsSystem: false
    inline: [
      // Use double backslashes to represent a single backslash in the file path
      'New-Item -ItemType Directory -Force -Path $env:SystemDrive\\apps\\'
    ]
  }

  // Set the timezone to New Zealand Standard Time
  {
    type: 'PowerShell'
    name: 'Set Timezone - New Zealand Standard Time'
    runElevated: true
    runAsSystem: true
    inline: [
      'Set-TimeZone -Id "New Zealand Standard Time"'
    ]
  }

  // Install Windows updates, excluding preview updates
  {
    type: 'WindowsUpdate'
    searchCriteria: 'IsInstalled=0'
    filters: [
      'exclude:$_.Title -like \'*Preview*\'' // Exclude preview updates
      'include:$true'
    ]
    updateLimit: 20
  }

  // Restart the system after Windows updates have completed
  {
    type: 'WindowsRestart'
    restartCheckCommand: 'write-host \'restarting post Windows Updates\''
    restartTimeout: '10m'
  }

  // Copy BGInfo from the Storage account to the temporary directory
  {
    type: 'File'
    name: 'Copy BGInfo from Storage account'
    sourceUri: 'https://${stgaccountname}.blob.${environmentMetadata.suffixes.storage}/iac/bginfo/BGInfo.zip'
    destination: '$env:SystemDrive\\apps\\BGInfo.zip'
  }

  // Copy Storage Explorer from the Storage account to the temporary directory
  {
    type: 'PowerShell'
    name: 'Copy Storage Explorer from Storage account'
    runElevated: true
    runAsSystem: true
    inline: [
      // Use double backslashes to represent a single backslash in the file path
      'Invoke-RestMethod  https://${stgaccountname}.blob.${environmentMetadata.suffixes.storage}/iac/storageexplorer/StorageExplorer-windows-x64.exe -OutFile  $env:SystemDrive\\apps\\StorageExplorer-windows-x64.exe'
    ]
  }

  // Extract BGInfo
  {
    type: 'PowerShell'
    name: 'Extract BGInfo'
    runElevated: true
    runAsSystem: true
    inline: [
      // Use double backslashes to represent a single backslash in the file path
      'Expand-Archive -LiteralPath $env:SystemDrive\\apps\\BGInfo.zip -DestinationPath $env:SystemDrive\\apps\\'
    ]
  }

  // Install Storage Explorer
  {
    type: 'PowerShell'
    name: 'Install Storage Explorer'
    runElevated: true
    runAsSystem: true
    inline: [
      // Use double backslashes to represent a single backslash in the file path
      // Check if the executable file exists
    '$exePath = "$env:SystemDrive\\apps\\StorageExplorer-windows-x64.exe"'
    'if (Test-Path $exePath) {'
    '  & $exePath /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /ALLUSERS'
    '} else {'
    '  Write-Output "The file $exePath does not exist."'
    '}'
    ]
  }

   // Install any Windows updates, that are left or needed after app installs
   {
    type: 'WindowsUpdate'
    searchCriteria: 'IsInstalled=0'
    filters: [
      'exclude:$_.Title -like \'*Preview*\'' // Exclude preview updates
      'include:$true'
    ]
    updateLimit: 20
  }

  // Restart the system after Windows updates have completed and fresh restart before sysprep.
  {
    type: 'WindowsRestart'
    restartCheckCommand: 'write-host \'restarting post image customisation\''
    restartTimeout: '10m'
  }

]

// Output the customizations array
output customizationsOutput array = customizations
