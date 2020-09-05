[![PowerShell Gallery - ActiveDirectoryFever](https://img.shields.io/badge/PowerShell_Gallery-ActiveDirectoryFever-0072C6.svg)](https://www.powershellgallery.com/packages/ActiveDirectoryFever)
[![GitHub - Release](https://img.shields.io/github/release/claudiospizzi/ActiveDirectoryFever.svg)](https://github.com/claudiospizzi/ActiveDirectoryFever/releases)
[![AppVeyor - master](https://img.shields.io/appveyor/ci/claudiospizzi/ActiveDirectoryFever/master.svg)](https://ci.appveyor.com/project/claudiospizzi/ActiveDirectoryFever/branch/master)

# ActiveDirectoryFever PowerShell Module

PowerShell Module with custom functions and cmdlets for Windows Active
Directory.

## Introduction

This is a personal PowerShell Module by Claudio Spizzi. It is used to manage
Windows Active Directory, e.g. testing the diagnostics (dcdiag) and replication
(replsum) health or monitor the Active Directory changes.

## Features

### Health Test

* **Test-ADDomainControllerDiagnostic**  
  Health test of Active Directory Domain Controllers by using the built-in and
  trusted "dcdiag.exe" command line tool.

* **Test-ADDomainControllerReplication**  
  Replication test of Active Directory Domain Controllers by using the build-in and trusted "repadmin.exe" command line tool.

### Change Report

* **Get-ADDirSyncChange**  
  Use the DirSync function of Active Directory to monitor the changes.

* **Get-ADUsnNumberUpdate**  
  Uses the USN property of Active Directory to monitor the updates.

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

The DirSync API can be used to log detailed change information inside an Active
Directory Domain.

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




## Versions

Please find all versions in the [GitHub Releases] section and the release notes
in the [CHANGELOG.md] file.

## Installation

Use the following command to install the module from the [PowerShell Gallery],
if the PackageManagement and PowerShellGet modules are available:

```powershell
# Download and install the module
Install-Module -Name 'ActiveDirectoryFever'
```

Alternatively, download the latest release from GitHub and install the module
manually on your local system:

1. Download the latest release from GitHub as a ZIP file: [GitHub Releases]
2. Extract the module and install it: [Installing a PowerShell Module]

## Requirements

The following minimum requirements are necessary to use this module, or in other
words are used to test this module:

* Windows PowerShell 3.0
* Windows Server 2008 R2 / Windows 7

## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code] with the [PowerShell Extension]
* [Pester], [PSScriptAnalyzer] and [psake] PowerShell Modules

[PowerShell Gallery]: https://www.powershellgallery.com/packages/ActiveDirectoryFever
[GitHub Releases]: https://github.com/claudiospizzi/ActiveDirectoryFever/releases
[Installing a PowerShell Module]: https://msdn.microsoft.com/en-us/library/dd878350

[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell
[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[psake]: https://www.powershellgallery.com/packages/psake
