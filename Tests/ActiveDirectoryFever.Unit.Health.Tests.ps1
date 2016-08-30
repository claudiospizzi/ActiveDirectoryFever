
$ModuleName  = ($PSScriptRoot | Split-Path | Split-Path -Leaf)
$ProjectRoot = ($PSScriptRoot | Split-Path)

Remove-Module -Name $ModuleName -Verbose:$false -ErrorAction SilentlyContinue -Force
Import-Module "$ProjectRoot\$ModuleName" -Verbose:$false -ErrorAction Stop -Force

Describe 'Test-ADDomainControllerDiagnostic' {

    $Global:TestDataPath = "$ProjectRoot\Tests\TestData"

    Context 'Offline' {

        Mock Invoke-Command -ParameterFilter { $ComputerName -eq 'UNKNOWN' } -ModuleName 'ActiveDirectoryFever' {
            return (Start-Job -Name 'UNKNOWN' -ScriptBlock {
                throw (New-Object -TypeName 'System.Management.Automation.Remoting.PSRemotingTransportException' -ArgumentList 'Connecting to remote server unknown failed with the following error message : The WinRM client cannot process the request. If the authentication scheme is different from Kerberos, or if the client computer is not joined to a domain, then HTTPS transport must be used or the destination machine must be added to the TrustedHosts configuration setting. Use winrm.cmd to configure TrustedHosts. Note that computers in the TrustedHosts list might not be authenticated. You can get more information about that by running the following command: winrm help config. For more information, see the about_Remote_Troubleshooting Help topic.')
            })
        }

        It 'OfflineThrowException' {

            # Act
            { $Result = Test-ADDomainControllerDiagnostic -ComputerName 'UNKNOWN' -ErrorAction Stop } | Should Throw

            # Assert
            Assert-MockCalled 'Invoke-Command' -ModuleName 'ActiveDirectoryFever' -Times 1 -Exactly
        }
    }

    Context 'Success' {

        Mock Invoke-Command -ParameterFilter { $ComputerName -eq 'DC11.adds.contoso.com' } -ModuleName 'ActiveDirectoryFever' {
            return (Start-Job -Name 'DC11.adds.contoso.com' -ArgumentList $Global:TestDataPath -ScriptBlock {
                Get-Content -Path "$args\DcDiag.DC11.Result.txt" -ReadCount 0 | Write-Output
            })
        }

        It 'SuccessParseResult' {

            # Arrange
            $ComputerName = 'DC11.adds.contoso.com'
            $ExpectedData = Import-Csv -Path "$Global:TestDataPath\DcDiag.DC11.Expected.csv"

            # Act
            $Result = Test-ADDomainControllerDiagnostic -ComputerName $ComputerName

            # Assert
            $Result.Count | Should Be 37
            for ($i = 0; $i -lt $Result.Count; $i++)
            {
                $Result[$i].Name   | Should Be $ExpectedData[$i].Name
                $Result[$i].Domain | Should Be $ExpectedData[$i].Domain
                $Result[$i].Target | Should Be $ExpectedData[$i].Target
                $Result[$i].Test   | Should Be $ExpectedData[$i].Test
                $Result[$i].Result | Should Be ($ExpectedData[$i].Result -eq 'true')
            }
            Assert-MockCalled 'Invoke-Command' -ModuleName 'ActiveDirectoryFever' -ParameterFilter { $ComputerName -eq 'DC11.adds.contoso.com' } -Times 1 -Exactly
        }
    }

    Context 'Failure' {

        Mock Invoke-Command -ParameterFilter { $ComputerName -eq 'DC21.adds.contoso.com' } -ModuleName 'ActiveDirectoryFever' {
            return (Start-Job -Name 'DC21.adds.contoso.com' -ArgumentList $Global:TestDataPath -ScriptBlock {
                Get-Content -Path "$args\DcDiag.DC21.Result.txt" -ReadCount 0 | Write-Output
            })
        }

        It 'FailureParseResult' {

            # Arrange
            $ComputerName = 'DC21.adds.contoso.com'
            $ExpectedData = Import-Csv -Path "$Global:TestDataPath\DcDiag.DC21.Expected.csv"

            # Act
            $Result = Test-ADDomainControllerDiagnostic -ComputerName $ComputerName

            # Assert
            $Result.Count | Should Be 37
            for ($i = 0; $i -lt $Result.Count; $i++)
            {
                $Result[$i].Name   | Should Be $ExpectedData[$i].Name
                $Result[$i].Domain | Should Be $ExpectedData[$i].Domain
                $Result[$i].Target | Should Be $ExpectedData[$i].Target
                $Result[$i].Test   | Should Be $ExpectedData[$i].Test
                $Result[$i].Result | Should Be ($ExpectedData[$i].Result -eq 'true')
            }
            Assert-MockCalled 'Invoke-Command' -ModuleName 'ActiveDirectoryFever' -ParameterFilter { $ComputerName -eq 'DC21.adds.contoso.com' } -Times 1 -Exactly
        }
    }
}

Describe 'Test-ADDomainControllerReplication' {

    Context 'Offline' {

        Mock Invoke-Command -ParameterFilter { $ComputerName -eq 'UNKNOWN' } -ModuleName 'ActiveDirectoryFever' {
            return (Start-Job -Name 'UNKNOWN' -ScriptBlock {
                throw (New-Object -TypeName 'System.Management.Automation.Remoting.PSRemotingTransportException' -ArgumentList 'Connecting to remote server unknown failed with the following error message : The WinRM client cannot process the request. If the authentication scheme is different from Kerberos, or if the client computer is not joined to a domain, then HTTPS transport must be used or the destination machine must be added to the TrustedHosts configuration setting. Use winrm.cmd to configure TrustedHosts. Note that computers in the TrustedHosts list might not be authenticated. You can get more information about that by running the following command: winrm help config. For more information, see the about_Remote_Troubleshooting Help topic.')
            })
        }

        It 'OfflineThrowException' {

            # Act
            { $Result = Test-ADDomainControllerReplication -ComputerName 'UNKNOWN' -ErrorAction Stop } | Should Throw

            # Assert
            Assert-MockCalled 'Invoke-Command' -ModuleName 'ActiveDirectoryFever' -Times 1 -Exactly
        }
    }

    Context 'Success' {

        Mock Invoke-Command -ParameterFilter { $ComputerName -eq 'DC11.adds.contoso.com' } -ModuleName 'ActiveDirectoryFever' {
            return (Start-Job -Name 'DC11.adds.contoso.com' -ArgumentList $Global:TestDataPath -ScriptBlock {
                Get-Content -Path "$args\RepAdmin.DC11.Result.txt" -ReadCount 0 | Write-Output
            })
        }

        It 'SuccessParseResult' {

            # Arrange
            $ComputerName = 'DC11.adds.contoso.com'
            $ExpectedData = Import-Csv -Path "$Global:TestDataPath\RepAdmin.DC11.Expected.csv"

            # Act
            $Result = Test-ADDomainControllerReplication -ComputerName $ComputerName

            # Assert
            $Result.Count | Should Be 10
            for ($i = 0; $i -lt $Result.Count; $i++)
            {
                $Result[$i].Name          | Should Be $ExpectedData[$i].Name
                $Result[$i].Domain        | Should Be $ExpectedData[$i].Domain
                $Result[$i].NamingContext | Should Be $ExpectedData[$i].NamingContext
                $Result[$i].SourceSite    | Should Be $ExpectedData[$i].SourceSite
                $Result[$i].SourceServer  | Should Be $ExpectedData[$i].SourceServer
                $Result[$i].TargetSite    | Should Be $ExpectedData[$i].TargetSite
                $Result[$i].TargetServer  | Should Be $ExpectedData[$i].TargetServer
                $Result[$i].ExecutionTime | Should Be ([DateTime] $ExpectedData[$i].ExecutionTime)
                $Result[$i].TransportType | Should Be $ExpectedData[$i].TransportType
                $Result[$i].FailureCount  | Should Be $ExpectedData[$i].FailureCount
                $Result[$i].FailureStatus | Should Be $ExpectedData[$i].FailureStatus
                $Result[$i].Result        | Should Be ($ExpectedData[$i].Result -eq 'true')
            }
            Assert-MockCalled 'Invoke-Command' -ModuleName 'ActiveDirectoryFever' -ParameterFilter { $ComputerName -eq 'DC11.adds.contoso.com' } -Times 1 -Exactly
        }
    }

    Context 'Failure' {

        Mock Invoke-Command -ParameterFilter { $ComputerName -eq 'DC21.adds.contoso.com' } -ModuleName 'ActiveDirectoryFever' {
            return (Start-Job -Name 'DC21.adds.contoso.com' -ArgumentList $Global:TestDataPath -ScriptBlock {
                Get-Content -Path "$args\RepAdmin.DC21.Result.txt" -ReadCount 0 | Write-Output
            })
        }

        It 'FailureParseResult' {

            # Arrange
            $ComputerName = 'DC21.adds.contoso.com'
            $ExpectedData = Import-Csv -Path "$Global:TestDataPath\RepAdmin.DC21.Expected.csv"

            # Act
            $Result = Test-ADDomainControllerReplication -ComputerName $ComputerName

            # Assert
            $Result.Count | Should Be 10
            for ($i = 0; $i -lt $Result.Count; $i++)
            {
                $Result[$i].Name          | Should Be $ExpectedData[$i].Name
                $Result[$i].Domain        | Should Be $ExpectedData[$i].Domain
                $Result[$i].NamingContext | Should Be $ExpectedData[$i].NamingContext
                $Result[$i].SourceSite    | Should Be $ExpectedData[$i].SourceSite
                $Result[$i].SourceServer  | Should Be $ExpectedData[$i].SourceServer
                $Result[$i].TargetSite    | Should Be $ExpectedData[$i].TargetSite
                $Result[$i].TargetServer  | Should Be $ExpectedData[$i].TargetServer
                $Result[$i].ExecutionTime | Should Be ([DateTime] $ExpectedData[$i].ExecutionTime)
                $Result[$i].TransportType | Should Be $ExpectedData[$i].TransportType
                $Result[$i].FailureCount  | Should Be $ExpectedData[$i].FailureCount
                $Result[$i].FailureStatus | Should Be $ExpectedData[$i].FailureStatus
                $Result[$i].Result        | Should Be ($ExpectedData[$i].Result -eq 'true')
            }
            Assert-MockCalled 'Invoke-Command' -ModuleName 'ActiveDirectoryFever' -ParameterFilter { $ComputerName -eq 'DC21.adds.contoso.com' } -Times 1 -Exactly
        }
    }
}
