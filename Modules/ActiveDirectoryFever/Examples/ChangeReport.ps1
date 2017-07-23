
# With the following short script, the changes inside an Active Directory Domain
# can be monitored with the update sequence number (USN).

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


# The DirSync API can be used to log detailed change information inside an
# Active Directory Domain.

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
