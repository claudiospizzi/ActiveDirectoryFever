<#
    .SYNOPSIS
    Health test of Active Directory Domain Controllers by using the built-in
    and trusted "dcdiag.exe" command line tool.

    .DESCRIPTION
    This function uses Windows PowerShell Remoting to connect to all specified
    Active Directory Domain Controllers. Inside the session, dcdiag is executed
    with best practice parameter values. The result is then parsed into
    Windows PowerShell custom objects.

    .PARAMETER ComputerName
    The list of Domain Controllers to test. Aliases are defined to accept
    pipeline input from the result of the Active Directory built-in cmdlets.

    .PARAMETER Credential
    Optionally, provide credentials to create the PowerShell Remoting session.

    .INPUTS
    System.String. You can pipe an array of strings representing the computer names.

    .OUTPUTS
    ActiveDirectoryFever.DiagnosticResult. A collection of result objects. One object per test.

    .EXAMPLE
    C:\> Test-ADDomainControllerDiagnostic -ComputerName LON-DC1.contoso.com
    Run the diagnostic test against one Domain Controller.

    .EXAMPLE
    C:\> Test-ADDomainControllerDiagnostic -ComputerName LON-DC1.contoso.com -Credential (Get-Credential)
    Run the diagnostic test against one Domain Controller by using custom credentials.

    .EXAMPLE
    C:\> Test-ADDomainControllerDiagnostic -ComputerName LON-DC1, LON-DC2 | Where-Object { -not $_.Result }
    Run the diagnostic test against two Domain Controllers and filter failed tests.

    .EXAMPLE
    C:\> Get-ADDomainController | Test-ADDomainControllerDiagnostic
    Run the diagnostic test on the current enumerated Domain Controller.

    .EXAMPLE
    C:\> Get-ADDomain -Identity "corp.contoso.com" | Test-ADDomainControllerDiagnostic
    Run the diagnostic test on all writable and read-only Domain Controllers in the "corp.contoso.com" domain.

    .EXAMPLE
    C:\> Get-ADForest -Identity "contoso.com" | Test-ADDomainControllerDiagnostic
    Run the diagnostic test on all Global Catalog Domain Controllers in the "contoso.com" forest.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/ActiveDirectoryFever
#>

function Test-ADDomainControllerDiagnostic
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
        # For each provided computer name, use it as target to start the dcdiag
        # command inside a remoting session and as a job. This allows parallel
        # executing of all dcdiag commands.
        foreach ($ComputerNameTarget in $ComputerName)
        {
            Write-Verbose -Message "Start Job to execute 'dcdiag.exe /v /c /Skip:OutboundSecureChannels' on $ComputerNameTarget with PowerShell Remoting..."

            $Jobs += Invoke-Command -ComputerName $ComputerNameTarget -ScriptBlock { Write-Output (dcdiag.exe /v /c /Skip:OutboundSecureChannels) } @CredentialParameter -AsJob -JobName $ComputerNameTarget
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
                    $Domain = $(try { $Job.Name.Split('.', 2)[1] } catch { '' })

                    # Receive result (and error, if occured)
                    $Result = $Job | Receive-Job -ErrorAction Stop

                    # Iterating all lines
                    for ($Line = 0; $Line -lt $Result.length; $Line++)
                    {
                        # Correct wrong line breaks
                        if ($Result[$Line] -match '^\s{9}.{25} (\S+) (\S+) test$')
                        {
                            $Result[$Line] = $Result[$Line] + ' ' + $Result[$Line + 2].Trim()
                        }

                        # Verify test start line
                        if ($Result[$Line] -match '^\s{6}Starting test: \S+$')
                        {
                            $LineStart = $Line
                        }

                        # Verify test end line
                        if ($Result[$Line] -match '^\s{9}.{25} (\S+) (\S+) test (\S+)$')
                        {
                            # Create a custom result object with custom type
                            $DiagnosticResult = New-Object -TypeName PSObject -Property @{
                                Name    = $Name
                                Domain  = $Domain
                                Target  = $Matches[1]
                                Test    = $Matches[3]
                                Result  = $Matches[2] -eq 'passed'
                                Data    = $Result[$LineStart..$Line] -join [System.Environment]::NewLine
                            }
                            $DiagnosticResult.PSTypeNames.Insert(0, 'ActiveDirectoryFever.DiagnosticResult')

                            Write-Output $DiagnosticResult
                        }
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
