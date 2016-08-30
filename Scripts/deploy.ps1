
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

    # AppVeyor current build number.
    [Parameter(Mandatory = $false)]
    [System.String]
    $AppVeyorBuildNumber = $env:APPVEYOR_BUILD_NUMBER,

    # AppVeyor current branch name.
    [Parameter(Mandatory = $false)]
    [System.String]
    $AppVeyorBranch = $env:APPVEYOR_REPO_BRANCH,

    # AppVeyor option if the current build target is a tag.
    [Parameter(Mandatory = $false)]
    [System.String]
    $AppVeyorTag = $env:APPVEYOR_REPO_TAG,

    # AppVeyor repository tag if available.
    [Parameter(Mandatory = $false)]
    [System.String]
    $AppVeyorTagName = $env:APPVEYOR_REPO_TAG_NAME,

    # Option to enable the GitHub deployment.
    [Parameter(Mandatory = $false)]
    [Switch]
    $GitHub,

    # Access token for the GitHub repository to publish new releases.
    [Parameter(Mandatory = $false)]
    [System.String]
    $GitHubToken = $ENV:GitHubToken,

    # Option to enable the PowerShell Gallery deployment.
    [Parameter(Mandatory = $false)]
    [Switch]
    $PSGallery,

    # Security key to publish new versions to the PowerShell Gallery.
    [Parameter(Mandatory = $false)]
    [System.String]
    $PSGalleryKey = $ENV:PSGalleryKey
)


## PREPARE

# Add the temporary module path to the current environment
if ($env:PSModulePath -notlike "*$ModulePath*")
{
    $env:PSModulePath += ';' + $ModulePath
}

# Compose release information
$ReleaseVersion = $AppVeyorTagName
$ReleaseName    = "$ModuleName v$AppVeyorTagName"
$ReleaseNotes   = $ENV:APPVEYOR_REPO_COMMIT_MESSAGE + $ENV:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED + " "
$ReleaseAsset   = "$ModuleName-$ReleaseVersion.$AppVeyorBuildNumber.zip"


## DEPLOY

if ($AppVeyorTag -eq 'true' -and $AppVeyorBranch -eq 'master')
{
    Write-Verbose "** DEPLOY"


    if ($GitHub.IsPresent)
    {
        Write-Verbose "** DEPLOY (GITHUB)"

        # Create release inside GitHub
        $ReleaseHeaders = @{
            'Accept'        = 'application/vnd.github.v3+json'
            'Authorization' = "token $GitHubToken"
        }
        $ReleaseBody = @{
            tag_name         = $ReleaseVersion
            target_commitish = 'master'
            name             = $ReleaseName
            body             = $ReleaseNotes
            draft            = $false
            prerelease       = $false
        }
        $Release = Invoke-RestMethod -Method Post -Headers $ReleaseHeaders -Uri "https://api.github.com/repos/claudiospizzi/$ModuleName/releases" -Body ($ReleaseBody | ConvertTo-Json) -ErrorAction Stop

        # Upload artifact
        $AssetHeaders = @{
            'Accept'        = 'application/vnd.github.v3+json'
            'Authorization' = "token $GitHubToken"
            'Content-Type'  = 'application/zip'
        }
        $AssetInFile = "$ModulePath\$ModuleName-$ModuleVersion.$AppVeyorBuildNumber.zip"
        $Asset = Invoke-RestMethod -Method Post -Headers $AssetHeaders -Uri "https://uploads.github.com/repos/claudiospizzi/$ModuleName/releases/$($Release.id)/assets?name=$ModuleName-$ReleaseVersion.zip" -InFile $AssetInFile -ErrorAction Stop
    }


    if ($PSGallery.IsPresent)
    {
        Write-Verbose "** DEPLOY (PSGALLERY)"

        # Publish module into the PowerShell Gallery
        Publish-Module -Name $ModuleName -RequiredVersion $ReleaseVersion -NuGetApiKey $PSGalleryKey -ErrorAction Stop
    }
}
