[![PowerShell Gallery - ActiveDirectoryFever](https://img.shields.io/badge/PowerShell_Gallery-ActiveDirectoryFever-0072C6.svg)](https://www.powershellgallery.com/packages/ActiveDirectoryFever)
[![GitHub - Release](https://img.shields.io/github/release/claudiospizzi/ActiveDirectoryFever.svg)](https://github.com/claudiospizzi/ActiveDirectoryFever/releases)
[![AppVeyor - master](https://img.shields.io/appveyor/ci/claudiospizzi/ActiveDirectoryFever/master.svg)](https://ci.appveyor.com/project/claudiospizzi/ActiveDirectoryFever/branch/master)
[![AppVeyor - dev](https://img.shields.io/appveyor/ci/claudiospizzi/ActiveDirectoryFever/master.svg)](https://ci.appveyor.com/project/claudiospizzi/ActiveDirectoryFever/branch/dev)


# ActiveDirectoryFever PowerShell Module

PowerShell Module with custom functions and cmdlets for Windows Active
Directory.


## Introduction

This is a personal PowerShell Module by Claudio Spizzi.It is used to manage
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
* ActiveDirectory PowerShell Module


## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code] with the [PowerShell Extension]
* [Pester], [PSScriptAnalyzer] and [psake] PowerShell Modules

To release a new version in the PowerShell Gallery and the GitHub Releases
section by using the release pipeline on AppVeyor, use the following procedure:

1. Commit all changes in the dev branch
2. Push the commits to GitHub
3. Merge all commits to the master branch
4. Update the version number and release notes in the module manifest and CHANGELOG.md
5. Commit all changes in the master branch (comment: Version x.y.z)
6. Push the commits to GitHub
7. Tag the last commit with the version number
8. Push the tag to GitHub



[PowerShell Gallery]: https://www.powershellgallery.com/packages/OperationsManagerFever
[GitHub Releases]: https://github.com/claudiospizzi/OperationsManagerFever/releases
[Installing a PowerShell Module]: https://msdn.microsoft.com/en-us/library/dd878350

[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell
[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[psake]: https://www.powershellgallery.com/packages/psake
