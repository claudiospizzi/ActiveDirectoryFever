
[CmdletBinding()]
param
(
    # The PowerShell module name, extracted from the path by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $ModuleName = ($PSScriptRoot | Split-Path | Split-Path -Leaf),

    # The build stating path for the PowerShell module, inside temp by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $ModulePath = (Join-Path -Path $env:TEMP -ChildPath 'WindowsPowerShell'),

    # The PowerShell module project root path, derived from the path by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $ProjectRoot = ($PSScriptRoot | Split-Path),

    # The PowerShell module version, excracted from the module manifest by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $ModuleVersion = ((Invoke-Expression -Command (Get-Content -Path "$ProjectRoot\$ModuleName\$ModuleName.psd1" -Raw)).ModuleVersion),

    # Option to enable the AppVeyor specific build tasks.
    [Parameter(Mandatory = $false)]
    [Switch]
    $AppVeyor,

    # The dynamically created AppVeyor build number.
    [Parameter(Mandatory = $false)]
    [System.String]
    $AppVeyorBuildNumber = $env:APPVEYOR_BUILD_NUMBER
)


## PREPARE

# Add the temporary module path to the current environment
if ($env:PSModulePath -notlike "*$ModulePath*")
{
    $env:PSModulePath += ';' + $ModulePath
}

# Cleanup the build environment from previous builds
if ((Test-Path -Path "$ModulePath\$ModuleName"))
{
    Remove-Item -Path "$ModulePath\$ModuleName" -Recurse -Force
}


## BUILD

Write-Verbose '** BUILD'

New-Item -Path "$ModulePath\$ModuleName" -ItemType Directory -Verbose:$VerbosePreference | Out-Null

Copy-Item -Path "$ProjectRoot\$ModuleName\$ModuleName.psd1" -Destination "$ModulePath\$ModuleName" -Verbose:$VerbosePreference
Copy-Item -Path "$ProjectRoot\$ModuleName\$ModuleName.psm1" -Destination "$ModulePath\$ModuleName" -Verbose:$VerbosePreference

Copy-Item -Path "$ProjectRoot\$ModuleName\en-US"     -Destination "$ModulePath\$ModuleName" -Recurse -Verbose:$VerbosePreference
Copy-Item -Path "$ProjectRoot\$ModuleName\Functions" -Destination "$ModulePath\$ModuleName" -Recurse -Verbose:$VerbosePreference
Copy-Item -Path "$ProjectRoot\$ModuleName\Helpers"   -Destination "$ModulePath\$ModuleName" -Recurse -Verbose:$VerbosePreference
Copy-Item -Path "$ProjectRoot\$ModuleName\Resources" -Destination "$ModulePath\$ModuleName" -Recurse -Verbose:$VerbosePreference


## BUILD (APPVEYOR)

if ($AppVeyor.IsPresent)
{
    Write-Verbose '** BUILD (APPVEYOR)'

    Compress-Archive -Path "$ModulePath\$ModuleName" -DestinationPath "$ModulePath\$ModuleName-$ModuleVersion.$AppVeyorBuildNumber.zip" -Force -Verbose:$VerbosePreference

    Push-AppveyorArtifact -Path "$ModulePath\$ModuleName-$ModuleVersion.$AppVeyorBuildNumber.zip" -DeploymentName 'Module' -Verbose:$VerbosePreference
}
