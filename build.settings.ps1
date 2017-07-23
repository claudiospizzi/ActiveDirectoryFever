
Properties {

    $ModulePath  = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
    $ModuleNames = Get-ChildItem -Path $ModulePath | Select-Object -ExpandProperty 'BaseName' -First 1

    $SourceEnabled = $false
    $SourcePath    = ''
    $SourceNames   = ''

    $ReleasePath = Join-Path -Path $PSScriptRoot -ChildPath 'bin'

    $PesterPath = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $PesterFile = 'pester.xml'

    $ScriptAnalyzerPath  = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $ScriptAnalyzerFile  = 'scriptanalyzer.json'
    $ScriptAnalyzerRules = Get-ScriptAnalyzerRule

    $GalleryEnabled = $true
    $GalleryName    = 'PSGallery'
    $GallerySource  = 'https://www.powershellgallery.com/api/v2/'
    $GalleryPublish = 'https://www.powershellgallery.com/api/v2/package/'
    $GalleryKey     = ''

    $GitHubEnabled  = $true
    $GitHubRepoName = Split-Path -Path $PSScriptRoot -Leaf
    $GitHubKey      = ''
}
