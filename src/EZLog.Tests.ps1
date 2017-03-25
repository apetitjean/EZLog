Import-Module -Force (Join-Path $PSScriptRoot EZLog.psd1)

InModuleScope "EZLog" {

    Describe "EZLog Module" {

        Context "WriteEZLog with ',' separator" {
            $logfile = Join-Path $TestDrive pester.log

            It "Creates a log file with a header in it." {
                Write-EZLog -Header -LogFile $logfile -Delimiter ','
                Test-Path $logfile | Should Be $true
            }

            It "Test if the header was written correctly" {
                $r = Select-String -Path $logfile -Pattern '^\+\-*\+$'
                $r.count | Should Be 2            
            }

            It "Test if there's a CR+LF at the end of the 1st header's line" {
               $bytefile = Get-Content -Path $logfile -Encoding Byte
               ($bytefile | ForEach-Object -Begin {$i=0} -Process {if ($_ -eq 10){$bytefile[$i-1]} ; $i++})[0] | Should Be 13
            }

            It "Writes an information into the log file." {
                Write-EZLog -Category INF -Message 'This is an info to be written in the log file'
                Get-Content $logfile | Select-String -Pattern 'INF,' -Quiet | Should Be $true
            }

            It "Writes a warning into the log file." {
                Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file'
                Get-Content $logfile | Select-String -Pattern 'WAR,' -Quiet | Should Be $true
            }
            
            It "Writes an error into the log file." {
                Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'
                Get-Content $logfile | Select-String -Pattern 'ERR,' -Quiet | Should Be $true
            }

            It "Writes the footer into the log file." {
                Write-EZLog -Footer
                Get-Content $logfile -Tail 1 | Should BeLike '+-*-+'
            }
        } # Context "Using separator ','"

        Context "WriteEZLog with ';' separator" {
            $logfile = Join-Path $TestDrive pester.log

            It "Creates a log file with a header in it." {
                Write-EZLog -Header -LogFile $logfile -Delimiter ';'
                Test-Path $logfile | Should Be $true
            }

            It "Test if the header was written correctly" {
                $r = Select-String -Path $logfile -Pattern '^\+\-*\+$'
                $r.count | Should Be 2            
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
                Get-Content $logfile -Tail 1 | Should BeLike '+-*-+'
            }
        } # Context "Using separator ';'"


        Context "Write-EZLog with 'TAB' separator" {
            $logfile = Join-Path $TestDrive pester.log

            It "Creates a log file with a header in it." {
                Write-EZLog -Header -LogFile $logfile -Delimiter "`t"
                Test-Path $logfile | Should Be $true
            }

            It "Test if the header was written correctly" {
                $r = Select-String -Path $logfile -Pattern '^\+\-*\+$'
                $r.count | Should Be 2            
            }

            It "Writes an information into the log file." {
                Write-EZLog -Category INF -Message 'This is an info to be written in the log file'
                Get-Content $logfile | Select-String -Pattern "INF`t" -Quiet | Should Be $true
            }

            It "Writes a warning into the log file." {
                Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file'
                Get-Content $logfile | Select-String -Pattern "WAR`t" -Quiet | Should Be $true
            }
            
            It "Writes an error into the log file." {
                Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'
                Get-Content $logfile | Select-String -Pattern "ERR`t" -Quiet | Should Be $true
            }

            It "Writes the footer into the log file." {
                Write-EZLog -Footer
                Get-Content $logfile -Tail 1 | Should BeLike '+-*-+'
            }

        } # Context "Using separator 'TAB'"

        Context "ConvertFrom-EZLog" {
            $logfile = Join-Path $TestDrive pester.log

            Write-EZLog -Header -LogFile $logfile -Delimiter ','
            Write-EZLog -Category INF -Message 'This is an info to be written in the log file'
            Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file'
            Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'
            Write-EZLog -Footer

            $objLog = ConvertFrom-EZlog -FilePath $logFile

            It "It converts the log to a Hashtable" {
                $objLog | Should BeOfType [System.Collections.Hashtable]
            }

            It "It exists 3 properties in the Hashtable" {
                $objLog.keys.count | Should Be 3
            }

            $objLog.Header.psbase.keys | foreach { 
                It "Header : property '$_' is not null " {
                    $objLog.Header.$_ | Should Not BeNullOrEmpty
                }
            }

            $objLog.Footer.psbase.keys | foreach { 
                It "Footer : property '$_' is not null " {
                    $objLog.Footer.$_ | Should Not BeNullOrEmpty
                }
            }
        } # Context ConvertFrom-EZLog
    } # Describe
}