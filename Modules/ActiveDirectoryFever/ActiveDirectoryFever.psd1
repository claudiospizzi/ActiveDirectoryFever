@{
    RootModule         = 'ActiveDirectoryFever.psm1'
    ModuleVersion      = '1.0.0'
    GUID               = '73EA7A8D-F3F2-42D8-8173-BB7DCDC49FA2'
    Author             = 'Claudio Spizzi'
    Copyright          = 'Copyright (c) 2016 by Claudio Spizzi. Licensed under MIT license.'
    Description        = 'PowerShell Module with additional custom functions and cmdlets for Windows Active Directory.'
    PowerShellVersion  = '3.0'
    RequiredModules    = @(
        'ActiveDirectory'
    )
    ScriptsToProcess   = @()
    TypesToProcess     = @(
        'Resources\ActiveDirectoryFever.Types.ps1xml'
    )
    FormatsToProcess   = @(
        'Resources\ActiveDirectoryFever.Formats.ps1xml'
    )
    FunctionsToExport  = @(
        'Get-ADDirSyncChange'
        'Get-ADUsnNumberUpdate'
        'Test-ADDomainControllerDiagnostic'
        'Test-ADDomainControllerReplication'
    )
    CmdletsToExport    = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData        = @{
        PSData             = @{
            Tags               = @('PSModule', 'Active', 'Directory', 'AD', 'ADDS')
            LicenseUri         = 'https://raw.githubusercontent.com/claudiospizzi/ActiveDirectoryFever/master/LICENSE'
            ProjectUri         = 'https://github.com/claudiospizzi/ActiveDirectoryFever'
            ExternalModuleDependencies = @(
                'ActiveDirectory'
            )
        }
    }
}
