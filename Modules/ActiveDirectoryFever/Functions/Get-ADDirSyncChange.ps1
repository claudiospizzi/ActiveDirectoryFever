<#
    .SYNOPSIS
    Use the DirSync function of Active Directory to monitor the changes.

    .DESCRIPTION
    Use the DirSync function of Active Directory to monitor the changes. To use
    this functionality, the user needs 'Domain Administrators' privileges or
    the 'Replication directory changes' is delegated to the user on the domain
    level.

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
    C:\> Get-ADDirSyncChange
    Start change monitoring with default values.

    .EXAMPLE
    C:\> Get-ADDirSyncChange -Partition 'DC=adds,DC=contoso,DC=com' -ComputerName 'DC21.adds.contoso.com'
    Endless change monitoring every second inside the given partition targeting the DC21 domain controller.

    .EXAMPLE
    C:\> Get-ADDirSyncChange -Partition 'DC=adds,DC=contoso,DC=com' -ComputerName 'DC21.adds.contoso.com' -CookieFile 'cookie.xml' -Once
    Create a cookie file for the current state of the partition.

    .EXAMPLE
    C:\> Get-ADDirSyncChange -Partition 'DC=adds,DC=contoso,DC=com' -ComputerName 'DC21.adds.contoso.com' -CookieFile 'cookie.xml' -CookieReadOnly -Once
    Get all changes inside the partition which has been performed since the cookie creation. Preserve the cookie value.

    .EXAMPLE
    C:\> Get-ADDirSyncChange -Partition 'DC=adds,DC=contoso,DC=com' -FilterWildcard '*OU=Test,DC=adds,DC=contoso,DC=com'
    Endless change monitoring but only for the test OU. With this filter, deleting objects is not reported.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License
    Source     : Microsoft Exchange FAQ, Author: Frank Carius, Website: http://www.msxfaq.de

    This function is a complete rewrite of the original script 'Get-ADChanges'
    provided by Frank Carius. Credits for initial concept and idea goes to him.

    .LINK
    https://github.com/claudiospizzi/ActiveDirectoryFever

    .LINK
    http://www.msxfaq.de/tools/exprivat/get-adchanges.htm
#>
function Get-ADDirSyncChange
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
        $Properties = "WhenChanged", "ObjectCategory", "ObjectSID"
        $CommonProperties = "", "ObjectGuid", "ParentGuid", "InstanceType", "DistinguishedName", "AdsPath", "Name", "IsDeleted", "LastKnownParent", "msds-LastKnownRDN"

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
            # If no DirSync cookie exists, create an empty array
            if (-not $Cookie.ContainsKey($Computer))
            {
                $Cookie[$Computer] = @()
            }

            # Initialize directory searcher
            $Searcher[$Computer] = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ArgumentList ([ADSI] "LDAP://${Computer}/${Partition}")
            $Searcher[$Computer].DirectorySynchronization = New-Object -TypeName System.DirectoryServices.DirectorySynchronization([System.DirectoryServices.DirectorySynchronizationOptions]::IncrementalValues, [System.Convert]::FromBase64String($Cookie[$Computer]))
            $Searcher[$Computer].Filter = "(objectClass=*)"

            # If the DirSync cookie is empty, initialize the DirSync cookie to the current value
            if ($Cookie[$Computer].Count -eq 0)
            {
                # Set the filter temporary to exclude all objects, load all objects (ignore the result) and reset the filter
                $Searcher[$Computer].Filter = "(objectClass=#)"
                $Searcher[$Computer].FindAll() | Out-Null
                $Searcher[$Computer].Filter = "(objectClass=*)"

                # Update the cookie
                $Cookie[$Computer] = [System.Convert]::ToBase64String($Searcher[$Computer].DirectorySynchronization.GetDirectorySynchronizationCookie())
            }
        }
    }

    process
    {
        do
        {
            # Iteratin Level 1: Computer
            foreach ($Computer in $ComputerName)
            {
                Write-Progress -Activity "Active Directory Update Searcher..." -Status "Search for DirSync changes in $Partition on $Computer" -PercentComplete (($Count++) % 100)

                # Execute the search for DirSync changes
                $SearchResult = $Searcher[$Computer].FindAll()

                # Filter search result with input filter (regex & wildcard)
                $SearchFilter = $SearchResult | Where-Object { $_.Properties["DistinguishedName"] -like $FilterWildcard -and $_.Properties["DistinguishedName"] -match $FilterRegex }

                # Iterating all result objects, parse the properties and return a object to the pipeline
                if ($SearchFilter.Count -gt 0)
                {
                    # Iteratin Level 2: Search result objects
                    foreach ($SearchObject in $SearchFilter)
                    {
                        # Verify if the object is deleted
                        if ($SearchObject.Path -like "*,CN=Deleted Objects,*")
                        {
                            # Search the deleted object
                            $DeletedSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ArgumentList ([ADSI] "LDAP://${Computer}/${Partition}")
                            $DeletedSearcher.Tombstone = $true
                            $DeletedSearcher.Filter = "(&(objectClass=*)(isDeleted=TRUE)(name=$($SearchObject.Properties['Name'][0])))"
                            $SearchObjectFull = $DeletedSearcher.FindOne()
                        }
                        else
                        {
                            # Search the full object
                            $SearchObjectFull = ([ADSI] "LDAP://$Computer/$($SearchObject.Properties["DistinguishedName"][0])")
                        }

                        # Define common properties for the change object
                        $CommonParameter = @{
                            Timestamp   = $SearchObjectFull.Properties["WhenChanged"][0]
                            ObjectClass = $SearchObjectFull.Properties["ObjectCategory"][0] + ""
                            ObjectGuid  = $SearchObject.Properties["ObjectGUID"][0]
                            ObjectSid   = (New-Object -TypeName "System.Security.Principal.SecurityIdentifier" -ArgumentList ($SearchObjectFull.Properties["ObjectSID"][0]) , 0)
                            Identity    = $SearchObject.Properties["DistinguishedName"][0]
                            Account     = $SearchObjectFull.Properties["SamAccountName"][0]
                        }

                        if ($SearchObject.Properties.Contains("IsDeleted") -and $SearchObject.Properties.Item("IsDeleted") -eq $true)
                        {
                            # Action: DELETE
                            New-ADChangeObject @CommonParameter -Action DELETE -Field "LastKnownDN" -Value "CN=$($SearchObject.Properties.Item('msds-LastKnownRDN')),$($SearchObject.Properties.Item('LastKnownParent'))"
                        }
                        elseif ($SearchObject.Properties.Contains("IsDeleted"))
                        {
                            # Action: RESTORE
                            New-ADChangeObject @CommonParameter -Action RESTORE -Field "ParentGuid" -Value ([String] [Guid] $SearchObject.Properties.Item("ParentGuid")[0])
                        }
                        elseif ($SearchObject.Properties.Contains("ParentGuid") -and $SearchObject.Properties.Contains("WhenCreated"))
                        {
                            # Action: CREATE
                            New-ADChangeObject @CommonParameter -Action CREATE -Field "ParentGuid" -Value ([String] [Guid] $SearchObject.Properties.Item("ParentGuid")[0])
                        }
                        elseif ($SearchObject.Properties.Contains("ParentGuid"))
                        {
                            # Action: MOVE
                            New-ADChangeObject @CommonParameter -Action MOVE -Field "ParentGuid" -Value ([String] [Guid] $SearchObject.Properties.Item("ParentGuid")[0])
                        }

                        # Iterating all modified properties without common properties
                        foreach ($Property in ($SearchObject.Properties.PropertyNames | Where-Object { $CommonProperties -notcontains $_ }))
                        {
                            switch -Wildcard ($Property)
                            {
                                "member;range=1-1"
                                {
                                    foreach ($Member in $SearchObject.Properties.Item("member;range=1-1"))
                                    {
                                        # Action: MEMBER ADD
                                        New-ADChangeObject @CommonParameter -Action MEMBER-ADD -Field "Member" -Value $Member

                                        # Action: MEMBEROF ADD
                                        # TODO
                                    }

                                    break
                                }

                                "member;range=0-0"
                                {
                                    foreach ($Member in $SearchObject.Properties.Item("member;range=0-0"))
                                    {
                                        # Action: MEMBER REMOVE
                                        New-ADChangeObject @CommonParameter -Action MEMBER-REMOVE -Field "Member" -Value $Member

                                        # Action: MEMBEROF REMOVE
                                        # TODO
                                    }

                                    break
                                }

                                "member;range=*"
                                {
                                    # Action: MEMBER ERROR
                                    New-ADChangeObject @CommonParameter -Action UNKNOWN -Field $Property -Value $SearchObject.Properties.Item($Property)

                                    break
                                }

                                "*;range=1-1"
                                {
                                    # Action: CUSTOM ADD
                                    New-ADChangeObject @CommonParameter -Action CUSTOM-ADD -Field $Property.Replace(';range=1-1', '') -Value $SearchObject.Properties.Item($Property)

                                    break
                                }

                                "*;range=0-0"
                                {
                                    # Action: CUSTOM REMOVE
                                    New-ADChangeObject @CommonParameter -Action CUSTOM-REMOVE -Field $Property.Replace(';range=1-1', '') -Value $SearchObject.Properties.Item($Property)

                                    break
                                }

                                default
                                {
                                    # Action: MODIFY
                                    New-ADChangeObject @CommonParameter -Action MODIFY -Field $Property -Value $SearchObject.Properties.Item($Property)
                                }
                            }
                        }
                    }

                    # Update cookie value
                    $Cookie[$Computer] = [System.Convert]::ToBase64String($Searcher[$Computer].DirectorySynchronization.GetDirectorySynchronizationCookie())
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

    end
    {
    }
}
