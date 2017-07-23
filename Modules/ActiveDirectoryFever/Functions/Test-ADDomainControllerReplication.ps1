<#
    .SYNOPSIS
    Replication test of Active Directory Domain Controllers by using the
    build-in and trusted "repadmin.exe" command line tool.

    .DESCRIPTION
    This function uses Windows PowerShell Remoting to connect to all specified
    Active Directory Domain Controllers. Inside the session, repadmin is
    executed with the /showrepl and /csv parameter. The result is then parsed
    into Windows PowerShell custom objects.

    .PARAMETER ComputerName
    The list of Domain Controllers to test. Aliases are defined to accept
    pipeline input from the result of the Active Directory built-in cmdlets.

    .PARAMETER Credential
    Optionally, provide credentials to create the PowerShell Remoting session.

    .INPUTS
    System.String. You can pipe an array of strings representing the computer names.

    .OUTPUTS
    ActiveDirectoryFever.ReplicationResult. A collection of result objects. One object per test.

    .EXAMPLE
    C:\> Test-ADDomainControllerReplication -ComputerName LON-DC1.contoso.com
    Run the replication test against one Domain Controller.

    .EXAMPLE
    C:\> Test-ADDomainControllerReplication -ComputerName LON-DC1.contoso.com -Credential (Get-Credential)
    Run the replication test against one Domain Controller by using custom credentials.

    .EXAMPLE
    C:\> Test-ADDomainControllerReplication -ComputerName LON-DC1, LON-DC2 | Where-Object { -not $_.Result }
    Run the replication test against two Domain Controllers and filter failed tests.

    .EXAMPLE
    C:\> Get-ADDomainController | Test-ADDomainControllerReplication
    Run the replication test on the current enumerated Domain Controller.

    .EXAMPLE
    C:\> Get-ADDomain -Identity "corp.contoso.com" | Test-ADDomainControllerReplication
    Run the replication test on all writable and read-only Domain Controllers in the "corp.contoso.com" domain.

    .EXAMPLE
    C:\> Get-ADForest -Identity "contoso.com" | Test-ADDomainControllerReplication
    Run the replication test on all Global Catalog Domain Controllers in the "contoso.com" forest.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/ActiveDirectoryFever
#>

function Test-ADDomainControllerReplication
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('HostName', 'DNSHostName', 'ReplicaDirectoryServers', 'GlobalCatalogs')]
        [String[]] $ComputerName,

        [Parameter(Mandatory=$false)]
        [PSCredential] $Credential = $null
    )

    begin
    {
        $Jobs = @()

        # Define the alternate credentials hash table
        $CredentialParameter = @{}
        if($Credential -ne $null) { $CredentialParameter['Credential'] = $Credential }
    }

    process
    {
        # For each provided computer name, use it as target to start the replsum
        # command inside a remoting session and as a job. This allows parallel
        # executing of all replsum commands.
        foreach ($ComputerNameTarget in $ComputerName)
        {
            Write-Verbose -Message "Start Job to execute 'repadmin.exe /showrepl /csv' on $ComputerNameTarget with PowerShell Remoting..."

            $Jobs += Invoke-Command -ComputerName $ComputerNameTarget -ScriptBlock { Write-Output (repadmin.exe /showrepl /csv) } @CredentialParameter -AsJob -JobName $ComputerNameTarget
        }
    }

    end
    {
        Write-Verbose -Message 'Wait for all Jobs to complete.'

        # Wait for all jobs to complete
        $Jobs = $Jobs | Wait-Job

        # Iterate all child jobs (one child job per domain controller)
        foreach ($Job in $Jobs)
        {
            try
            {
                if ($Job.State -eq 'Completed')
                {
                    # Fill name and domain with location
                    $Name   = $Job.Name.Split('.', 2)[0]
                    $Domain = try { $Job.Name.Split('.', 2)[1] } catch { '' }

                    # Receive result (and error, if occured)
                    $Result = $Job | Receive-Job -ErrorAction Stop

                    # Check if the result is empty
                    if ($Result -ne $null)
                    {
                        # Iterating all objects
                        foreach ($ChildResult in ($Result | ConvertFrom-Csv))
                        {
                            # Calculate last execution time
                            $LastTime = [DateTime]::MinValue
                            if (($ChildResult.'Last Failure Time' -ne '0') -and ($LastTime -lt ($LastFailureTime = [DateTime] $ChildResult.'Last Failure Time')))
                            {
                                $LastTime = $LastFailureTime
                            }
                            if (($ChildResult.'Last Success Time' -ne '0') -and ($LastTime -lt ($LastSuccessTime = [DateTime] $ChildResult.'Last Success Time')))
                            {
                                $LastTime = $LastSuccessTime
                            }

                            # Create a custom result object with custom type
                            $ReplicationResult = New-Object -TypeName PSObject -Property @{
                                Name           = $Name
                                Domain         = $Domain
                                NamingContext  = $ChildResult.'Naming Context'
                                SourceSite     = $ChildResult.'Source DSA Site'
                                SourceServer   = $ChildResult.'Source DSA'
                                TargetSite     = $ChildResult.'Destination DSA Site'
                                TargetServer   = $ChildResult.'Destination DSA'
                                ExecutionTime  = $LastTime
                                TransportType  = $ChildResult.'Transport Type'
                                FailureCount   = $ChildResult.'Number of Failures'
                                FailureStatus  = $ChildResult.'Last Failure Status'
                                Result         = $ChildResult.'Number of Failures' -eq '0'
                            }
                            $ReplicationResult.PSTypeNames.Insert(0, 'ActiveDirectoryFever.ReplicationResult')

                            Write-Output $ReplicationResult
                        }
                    }
                    else
                    {
                        Write-Warning "Replication test on $($Job.Location) does not return any data. This is expected, if the forest does only consist of one Domain Controller."
                    }
                }
                else
                {
                    $Job | Receive-Job -ErrorAction Stop | Out-Null
                }
            }
            catch
            {
                Write-Error -Message "Failed to execute diagnistic test.`r`n$_" -Exception $_.Exception -TargetObject $Job.Location
            }
        }

        # Cleanup jobs
        $Job | Remove-Job -ErrorAction SilentlyContinue
    }
}
