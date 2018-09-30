
Properties {

    $ModuleNames    = 'ActiveDirectoryFever'

    $GalleryEnabled = $true
    $GalleryKey     = Use-VaultSecureString -TargetName 'PowerShell Gallery Key (claudiospizzi)'

    $GitHubEnabled  = $true
    $GitHubRepoName = 'claudiospizzi/ActiveDirectoryFever'
    $GitHubKey      = Use-VaultSecureString -TargetName 'GitHub Token (claudiospizzi)'
}
