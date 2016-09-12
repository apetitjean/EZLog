Get-Module EZLog | Remove-Module

Import-Module EZLog

InModuleScope "EZLog" {

    Describe "Write-EZLog" {

        $logfile = "TestDrive:\pester.log"

        Context "Example 1" {

            It "Writes the header into the log file." {
                Write-EZLog -Header -LogFile $logfile
                Test-Path $logfile | Should Be $true
            }

            It "Writes an information into the log file." {
                Write-EZLog -Category INF -Message 'This is an info to be written in the log file'
                Get-Content $logfile | Select-String -Pattern 'INF;' -Quiet | Should Be $true
            }

            It "Writes a warning into the log file." {
                Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file'
                Get-Content $logfile | Select-String -Pattern 'WAR;' -Quiet | Should Be $true
            }

           
            It "Writes an error into the log file." {
                Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'
                Get-Content $logfile | Select-String -Pattern 'ERR;' -Quiet | Should Be $true
            }


            It "Writes the footer into the log file." {
                Write-EZLog -Footer
                Get-Content $logfile -Tail 1 | Should Be '+----------------------------------------------------------------------------------------+'
            }
        }
    
    }

}
