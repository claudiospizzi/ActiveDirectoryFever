
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'Test-ADDomainControllerDiagnostic' {

    $Global:TestDataPath = "$ProjectRoot\Tests\TestData"

    Context 'Offline' {

        Mock Invoke-Command -ParameterFilter { $ComputerName -eq 'UNKNOWN' } -ModuleName 'ActiveDirectoryFever' {
            return (Start-Job -Name 'UNKNOWN' -ScriptBlock {
                throw (New-Object -TypeName 'System.Management.Automation.Remoting.PSRemotingTransportException' -ArgumentList 'Connecting to remote server unknown failed with the following error message : The WinRM client cannot process the request. If the authentication scheme is different from Kerberos, or if the client computer is not joined to a domain, then HTTPS transport must be used or the destination machine must be added to the TrustedHosts configuration setting. Use winrm.cmd to configure TrustedHosts. Note that computers in the TrustedHosts list might not be authenticated. You can get more information about that by running the following command: winrm help config. For more information, see the about_Remote_Troubleshooting Help topic.')
            })
        }

        It 'OfflineThrowException' {

            # Arrange
            $computerName = 'UNKNOWN'

            # Act
            { Test-ADDomainControllerDiagnostic -ComputerName $computerName -ErrorAction Stop } | Should Throw

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
