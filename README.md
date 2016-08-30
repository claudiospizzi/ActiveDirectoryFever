[![AppVeyor - master](https://ci.appveyor.com/api/projects/status/518dlu3j7r78yejs/branch/master?svg=true)](https://ci.appveyor.com/project/claudiospizzi/ActiveDirectoryFever/branch/master)
[![AppVeyor - dev](https://ci.appveyor.com/api/projects/status/518dlu3j7r78yejs/branch/dev?svg=true)](https://ci.appveyor.com/project/claudiospizzi/ActiveDirectoryFever/branch/dev)
[![PowerShell Gallery - ActiveDirectoryFever](https://img.shields.io/badge/PowerShell%20Gallery-ActiveDirectoryFever-0072C6.svg)](https://www.powershellgallery.com/packages/ActiveDirectoryFever)


# ActiveDirectoryFever PowerShell Module

PowerShell Module with additional custom functions and cmdlets for Windows
Active Directory.


## Introduction

This is a personal PowerShell Module by Claudio Spizzi. I use it to manage
Windows Active Directory, e.g. testing the diagnostics (dcdiag) and replication
(replsum) health or monitor the Active Directory changes.


## Requirenments

The following minimum tested requirenments are necessary to use this module:

- Windows PowerShell 3.0
- Windows Server 2008 R2 / Windows 7
- ActiveDirectory PowerShell Module


## Installation

### PowerShell Gallery

Install this module automatically from the [PowerShell Gallery](https://www.powershellgallery.com/packages/ActiveDirectoryFever)
to your local system with PowerShell 5.0:

```powershell
Install-Module ActiveDirectoryFever
```

### GitHub Release

To install the module manually, perform the following steps:

1. Download the latest release from [GitHub](https://github.com/claudiospizzi/ActiveDirectoryFever/releases)
   as a ZIP file
2. Extract the downloaded module into one of your module paths ([TechNet: Installing Modules](https://technet.microsoft.com/en-us/library/dd878350))


## Cmdlets

The module contains the following cmdlets:

| Cmdlet                             | Description                                                                                                                 |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Get-ADDirSyncChange                | Use the DirSync function of Active Directory to monitor the changes.                                                        |
| Get-ADUsnNumberUpdate              | Uses the USN propertiy of Active Directory to monitor the updates.                                                          |
| Test-ADDomainControllerDiagnostic  | Health test of Active Directory Domain Controllers by using the built-in and trusted "dcdiag.exe" command line tool.        |
| Test-ADDomainControllerReplication | Replication test of Active Directory Domain Controllers by using the build-in and trusted "repadmin.exe" command line tool. |


## Versions

### tbd

- Initial public release
- Health and replication diagnostic test functions
- Change detection function based on USN and DirSync


## Examples

Use the following commands to test the health of the Domain Controllers and
their replication.

```powershell
# Test the Domain Controller health with dcdiag
Test-ADDomainControllerDiagnostic -ComputerName 'LON-DC1.contoso.com', 'LON-DC2.contoso.com'

# Test the Partition Replication health with repadmin
Test-ADDomainControllerReplication -ComputerName 'LON-DC1.contoso.com', 'LON-DC2.contoso.com'
```

With the following short script, the changes inside an Active Directory Domain
can be monitored with the update sequence number (USN).

```powershell
# Definition
$Partition = 'DC=adds,DC=contoso,DC=com'
$Server    = 'DC21.adds.contoso.com'
$Filter    = '*OU=Test,DC=adds,DC=contoso,DC=com'
$Cookie    = 'usnnumberupdate.xml'

# Create Cookie File
Get-ADUsnNumberUpdate -Partition $Partition -ComputerName $Server -FilterWildcard $Filter -CookieFile $Cookie -Once

# Get Difference Since Cookie File
Get-ADUsnNumberUpdate -Partition $Partition -ComputerName $Server -FilterWildcard $Filter -CookieFile $Cookie -CookieReadOnly -Once |
    Select-Object 'Timestamp', 'ObjectClass', 'ObjectGuid', 'ObjectSid', 'Identity', 'Account', 'Action', 'Field', 'Value' | Out-GridView
```

Finally, the DirSync API can be used to log detailed change information inside
an Active Directory Domain.

```powershell
# Definition
$Partition = 'DC=adds,DC=contoso,DC=com'
$Server    = 'DC21.adds.contoso.com'
$Filter    = '*OU=Test,DC=adds,DC=contoso,DC=com'
$Cookie    = 'dirsyncchange.xml'

# Create Cookie File
Get-ADDirSyncChange -Partition $Partition -ComputerName $Server -FilterWildcard $Filter -CookieFile $Cookie -Once

# Get Difference Since Cookie File
Get-ADDirSyncChange -Partition $Partition -ComputerName $Server -FilterWildcard $Filter -CookieFile $Cookie -CookieReadOnly -Once |
    Select-Object 'Timestamp', 'ObjectClass', 'ObjectGuid', 'ObjectSid', 'Identity', 'Account', 'Action', 'Field', 'Value' | Out-GridView
```


## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open the ActiveDirectoryFever solution with
Visual Studio 2015. The module can be tested with the 'Scripts\test.ps1' script.
