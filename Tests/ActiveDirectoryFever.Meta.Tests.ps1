
$ModuleName  = ($PSScriptRoot | Split-Path | Split-Path -Leaf)
$ProjectRoot = ($PSScriptRoot | Split-Path)

Describe 'Meta' {

    $TextFiles = Get-ChildItem -Path "$PSScriptRoot\.." -File -Recurse |
                     Where-Object { '.gitignore', '.gitattributes', '.ps1', '.psm1', '.psd1', '.ps1xml', '.txt', '.xml', '.cmd', '.json', '.md' -contains $_.Extension } |
                         ForEach-Object { $_.FullName }

    Context 'Project Structure' {

        $Files = '\LICENSE',
                 '\README.md',
                 '\appveyor.yml',
                 '\Scripts\build.ps1',
                 '\Scripts\test.ps1',
                 '\Scripts\deploy.ps1',
                 "\$ModuleName.sln",
                 "\$ModuleName\$ModuleName.pssproj",
                 "\$ModuleName\$ModuleName.psd1",
                 "\$ModuleName\$ModuleName.psm1",
                 "\$ModuleName\en-US\about_$ModuleName.help.txt",
                 "\$ModuleName\Resources\$ModuleName.Formats.ps1xml",
                 "\$ModuleName\Resources\$ModuleName.Types.ps1xml"

        foreach ($File in $Files)
        {
            It "should contain the file $File" {

                Test-Path -Path "$ProjectRoot$File" | Should Be $true
            }
        }
    }

    Context 'File Encoding' {

        It 'should not use Unicode encoding' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                if (@([System.IO.File]::ReadAllBytes($TextFile) -eq 0).Length -gt 0)
                {
                    Write-Warning "File $TextFile contains 0x00 bytes. It's probably uses Unicode and need to be converted to UTF-8."

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }

        It 'should not use BOM for UTF-8' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                $Bytes = [System.IO.File]::ReadAllBytes($TextFile)

                if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191)
                {
                    Write-Warning "File $TextFile starts with 0xEF 0xBB 0xBF. It's probably uses UTF-8 with BOM encoding. Remove the BOM encoding."

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }
    }

    Context 'Indentations' {

        It 'should use spaces for indentation, not tabs' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                $ErrorLines = @()

                $Content = Get-Content -Path $TextFile

                for ($Line = 0; $Line -lt $Content.Length; $Line++)
                {
                    if(($Content[$Line] | Select-String "`t" | Measure-Object).Count -ne 0)
                    {
                        $ErrorLines += $Line + 1
                    }
                }

                if ($ErrorLines -gt 0)
                {
                    Write-Warning "There are tab in $TextFile. Remove tabs or replace with spaces. Lines: $($ErrorLines -join ', ')"

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }

        It 'should use no trailing spaces for lines' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                $ErrorLines = @()

                $Content = Get-Content -Path $TextFile

                for ($Line = 0; $Line -lt $Content.Length; $Line++)
                {
                    if($Content[$Line].TrimEnd() -ne $Content[$Line])
                    {
                        $ErrorLines += $Line + 1
                    }
                }

                if ($ErrorLines -gt 0)
                {
                    Write-Warning "There are trailing white spaces in $TextFile. Remove white space. Lines: $($ErrorLines -join ', ')"

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }
    }

    Context 'New Lines' {

        It 'should end with a new line' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                $TextFileContent = Get-Content -Path $TextFile -Raw

                if ($TextFileContent.Length -ne 0 -and $TextFileContent[-1] -ne "`n")
                {
                    Write-Warning "$TextFile does not end with a new line."

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }
    }

    Context 'Module Import' {

        It 'should import without any errors' {

            { Import-Module "$ProjectRoot\$ModuleName" -Verbose:$false -ErrorAction Stop } | Should Not Throw

            Remove-Module -Name $ModuleName -Verbose:$false -ErrorAction SilentlyContinue -Force
        }
    }
}
