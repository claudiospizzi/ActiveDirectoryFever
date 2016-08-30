
[CmdletBinding()]
param
(
    # The PowerShell module name, extracted from the path by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $ModuleName = ($PSScriptRoot | Split-Path | Split-Path -Leaf),

    # The PowerShell module project root path, derived from the path by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $ProjectRoot = ($PSScriptRoot | Split-Path),

    # Option to enable the AppVeyor specific build tasks.
    [Parameter(Mandatory = $false)]
    [Switch]
    $AppVeyor,

    # The dynamically created AppVeyor build job id.
    [Parameter(Mandatory = $false)]
    [System.String]
    $AppVeyorBuildJobId = $env:APPVEYOR_JOB_ID
)


## PREPARE

Import-Module Pester -Force


## TEST

Write-Verbose "** TEST"

$TestResults = Invoke-Pester -Path "$ProjectRoot\Tests" -OutputFormat NUnitXml -OutputFile "$env:TEMP\$ModuleName.NUnit.xml" -PassThru


## TEST (APPVEYOR)

if ($AppVeyor.IsPresent)
{
    Write-Verbose "** TEST (APPVEYOR)"

    $Source = "$env:TEMP\$ModuleName.NUnit.xml"
    $Target = "https://ci.appveyor.com/api/testresults/nunit/$AppVeyorBuildJobId"

    Write-Verbose "Upload $Source to $Target"

    $WebClient = New-Object -TypeName 'System.Net.WebClient'
    $WebClient.UploadFile($Target, $Source)

    # Finally, throw an exception if any test have failed
    if ($TestResults.FailedCount -gt 0)
    {
        throw "$($TestResults.FailedCount) test(s) failed!"
    }
}
