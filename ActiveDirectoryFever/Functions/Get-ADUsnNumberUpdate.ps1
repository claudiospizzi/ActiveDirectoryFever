<#
    .SYNOPSIS
    Uses the USN propertiy of Active Directory to monitor the updates.

    .DESCRIPTION
    Uses the update sequence number (USN) propertiy of Active Directory to
    monitor the updates. Whenever an object is changed, its USN is incremented.
    Each domain controller maintains its own USN, they cannot be conpared
    between each other.

    .PARAMETER Partition
    Define the target partition to monitor the changes.

    .PARAMETER ComputerName
    Define the computer names for the Domain Controllers where the changes
    were monitored.

    .PARAMETER FilterRegex
    Filter the objects inside the partition based on the distinguished name
    with a regex filter. With the default filter value, all objects will be
    displayed.

    .PARAMETER FilterWildcard
    Filter the objects inside the partition based on the distinguished name
    with a wildcard filter. With the default filter value, all objects will
    be displayed.

    .PARAMETER CookieFile
    The path to the cookie file. If the cookie exist, the current USN number
    per domain controller will be loaded and the update scripts starts at
    this USN number. If no file exists, a new cookie file will be created.
    If no path will be specified, no cookie file will be used.

    .PARAMETER CookieReadOnly
    If this switch is specified, the cookie file will only be readed and not
    updated with the new USN numbers.

    .PARAMETER Once
    The script executs only one search loop.

    .EXAMPLE
    C:\> Get-ADUsnNumberUpdate
    Start change monitoring with default values.

    .EXAMPLE
    C:\> Get-ADUsnNumberUpdate -Partition 'DC=adds,DC=contoso,DC=com' -ComputerName 'DC21.adds.contoso.com'
    Endless change monitoring every second inside the given partition targeting the DC21 domain controller.

    .EXAMPLE
    C:\> Get-ADUsnNumberUpdate -Partition 'DC=adds,DC=contoso,DC=com' -ComputerName 'DC21.adds.contoso.com' -CookieFile 'cookie.xml' -Once
    Create a cookie file for the current state of the partition.

    .EXAMPLE
    C:\> Get-ADUsnNumberUpdate -Partition 'DC=adds,DC=contoso,DC=com' -ComputerName 'DC21.adds.contoso.com' -CookieFile 'cookie.xml' -CookieReadOnly -Once
    Get all changes inside the partition which has been performed since the cookie creation. Preserve the cookie value.

    .EXAMPLE
    C:\> Get-ADUsnNumberUpdate -Partition 'DC=adds,DC=contoso,DC=com' -FilterWildcard '*OU=Test,DC=adds,DC=contoso,DC=com'
    Endless change monitoring but only for the test OU. With this filter, deleting objects is not reported.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License
    Source     : Microsoft Exchange FAQ, Author: Frank Carius, Website: http://www.msxfaq.de

    This function is a complete rewrite of the original script 'Get-USNChanges'
    provided by Frank Carius. Credits for initial concept and idea goes to him.

    .LINK
    https://github.com/claudiospizzi/ActiveDirectoryFever

    .LINK
    http://www.msxfaq.de/tools/get-usnchanges.htm
#>
function Get-ADUsnNumberUpdate
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false)]
        [String] $Partition = ([ADSI] "LDAP://$env:USERDOMAIN/RootDSE").DefaultNamingContext,

        [Parameter(Mandatory=$false)]
        [String[]] $ComputerName = ([ADSI] "LDAP://$env:USERDOMAIN/RootDSE").DnsHostName,

        [Parameter(Mandatory=$false)]
        [String] $FilterRegex = ".*",

        [Parameter(Mandatory=$false)]
        [String] $FilterWildcard = "*",

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [String] $CookieFile = "",

        [Parameter(Mandatory=$false)]
        [Switch] $CookieReadOnly,

        [Parameter(Mandatory=$false)]
        [Switch] $Once
    )

    begin
    {
        # Counter variable to display the progress bar
        $Count = 0

        # Global hashtables to save the cookies and the serarcher objects per domain controller
        $Cookie = @{}
        $Searcher = @{}

        # The Active Directory properties to load
        $Properties = "DistinguishedName", "USNChanged", "USNCreated", "WhenChanged", "IsDeleted", "ObjectClass", "ObjectCategory", "ObjectGuid", "ObjectSID", "SamAccountName", "LastKnownParent", "msDS-LastKnownRDN"

        # Check the cookie file variable
        # - No path specified: Do not use a cookie file and do not store the USN numbers
        # - Path specified, file existing: Load the latest USN numbers from the cookie file
        # - Path specified, file not found: Create a new cookie file but start at the lastest USN number on the Domain Controller
        if ($CookieFile -ne "" -and (Test-Path -Path $CookieFile))
        {
            try
            {
                $Cookie = [Hashtable] (Import-Clixml -Path $CookieFile)
            }
            catch
            {
                Write-Error "Error while loading the cookie file: $_"
                return
            }
        }

        # Initialize the directory searcher object for each Domain Controller. Define the searcher to point
        # to the correct partition on the specified Domain Controllers and set the necessary properties.
        foreach ($Computer in $ComputerName)
        {
            # Load the USN number from the Domain controller, if the cookie file does not contain this USN number
            if (-not $Cookie.ContainsKey($Computer))
            {
                $RootDSE = [ADSI] "LDAP://${Computer}/RootDSE"
                $Cookie[$Computer] = [Int64] $RootDSE.HighestCommittedUSN[0]
            }

            # Initialize directory searcher
            $Searcher[$Computer] = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ArgumentList ([ADSI] "LDAP://${Computer}/${Partition}")
            $Searcher[$Computer].PropertiesToLoad.AddRange($Properties)
            $Searcher[$Computer].Sort.PropertyName = "USNChanged"
            $Searcher[$Computer].PageSize = 1000
            $Searcher[$Computer].Tombstone = $true
        }
    }

    process
    {
        do
        {
            foreach ($Computer in $ComputerName)
            {
                Write-Progress -Activity "Active Directory Update Searcher..." -Status "Search for USN updates in $Partition on $Computer" -PercentComplete (($Count++) % 100)

                # Define the directory searcher filter with a new highest usn
                $Searcher[$Computer].Filter = "(&(|(IsDeleted=*)(!IsDeleted=*))((!USNChanged<=$($Cookie[$Computer]))))"

                # Execute the search and filter all objects with no USN number
                $SearchResult = $Searcher[$Computer].FindAll() | Where-Object { $_.Properties["USNChanged"] -ne "" }

                # Filter search result with input filter (regex & wildcard)
                $SearchFilter = $SearchResult | Where-Object { $_.Properties["DistinguishedName"] -like $FilterWildcard -and $_.Properties["DistinguishedName"] -match $FilterRegex }

                # Iterating all result objects, parse the properties and return a object to the pipeline
                if ($SearchFilter.Count -gt 0)
                {
                    # Iterating all objects
                    foreach ($SearchObject in $SearchFilter)
                    {
                        # Create an output object
                        $Object = New-Object -TypeName PSObject -Property @{
                            Timestamp   = $SearchObject.Properties["WhenChanged"][0]
                            ObjectClass = $(try { $SearchObject.Properties["ObjectCategory"][0].Substring(3).Split(",")[0] } catch { "Unknown" })
                            ObjectGuid  = [String] [Guid] $SearchObject.Properties["ObjectGUID"][0]
                            ObjectSid   = [String] (New-Object -TypeName "System.Security.Principal.SecurityIdentifier" -ArgumentList ($SearchObject.Properties["ObjectSID"][0]) , 0)
                            Identity    = $SearchObject.Properties["DistinguishedName"][0]
                            Account     = $SearchObject.Properties["SamAccountName"][0]
                            Action      = ""
                            Field       = "USNChanged"
                            Value       = $SearchObject.Properties["USNChanged"][0]
                        }

                        # Update the action and identity (if necessary)
                        if ($SearchObject.Properties["USNChanged"][0] -eq $SearchObject.Properties["USNCreated"][0])
                        {
                            $Object.Action = "CREATE"
                        }
                        elseif ($SearchObject.Properties["IsDeleted"][0] -eq $null)
                        {
                            $Object.Action = "MODIFY"
                        }
                        else
                        {
                            $Object.Action = "DELETE"
                            $Object.Identity = "CN=" + $SearchObject.Properties["msDS-LastKnownRDN"] + "," + $SearchObject.Properties["LastKnownParent"]
                        }

                        $Object.PSTypeNames.Insert(0, "ActiveDirectoryFever.GetADUpdate.Result")

                        Write-Output $Object
                    }

                    # Update the cookie variable
                    $Cookie[$Computer] = $SearchResult[-1].Properties["USNChanged"]
                }

                # Update the cookie file if necessary
                if (($CookieFile -ne "") -and (-not $CookieReadOnly))
                {
                    $Cookie | Export-Clixml -Path $CookieFile -Encoding Unicode
                }
            }

            Start-Sleep -Seconds 1
        }
        until ($Once)
    }
}
