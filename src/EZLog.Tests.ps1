Import-Module -Force (Join-Path $PSScriptRoot EZLog.psd1)

InModuleScope "EZLog" {

    Describe "WriteEZLog function" {
        
        Function Test-EZLogDelimiter {
            Param ($delimiter)

            $logfile   = Join-Path $TestDrive pester.log
            $PSDefaultParameterValues.Clear()
            $PSDefaultParameterValues.Add('Write-EZLog:LogFile',   $logfile)
            $PSDefaultParameterValues.Add('Write-EZLog:Delimiter', $delimiter)

            Context "Separator '$delimiter'" {
 
                It "Creates a log file with a header in it." {
                    Write-EZLog -Header  
                    Test-Path $logfile | Should Be $true
                }

                It "Test if the header was written correctly" {
                    $r = Select-String -Path $logfile -Pattern '^\+\-*\+$'
                    $r.count | Should Be 2            
                }

                It "Writes an information into the log file." {
                    Write-EZLog -Category INF -Message 'This is an info to be written in the log file'  
                    Get-Content $logfile | Select-String -Pattern ('INF' + $delimiter) -Quiet | Should Be $true
                }

                It "Writes a warning into the log file." {
                    Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file' 
                    Get-Content $logfile | Select-String -Pattern ('WAR' + $delimiter) -Quiet | Should Be $true
                }
            
                It "Writes an error into the log file." {
                    Write-EZLog -Category ERR -Message 'This is an error to be written in the log file' 
                    Get-Content $logfile | Select-String -Pattern ('ERR' + $delimiter) -Quiet | Should Be $true
                }

                It "Writes the footer into the log file." {
                    Write-EZLog -Footer
                    Get-Content $logfile -Tail 1 | Should BeLike '+-*-+'
                }
             
            } # Context "separator validation"
        }

        Test-EZLogDelimiter -delimiter ','
        Test-EZLogDelimiter -delimiter ';'
        Test-EZLogDelimiter -delimiter "`t"
        Test-EZLogDelimiter -delimiter "#"
     } # Write-EZLog Describe block

     Describe 'ConvertFromEZLog function' {

         Function Test-ConvertFromEZLog {
            Param ($delimiter)

            Context "Separator '$delimiter'" {
                
                $logfile = Join-Path $TestDrive pester.log
                $PSDefaultParameterValues.Clear()
                $PSDefaultParameterValues.Add('Write-EZLog:LogFile',   $logfile)
                $PSDefaultParameterValues.Add('Write-EZLog:Delimiter', $delimiter)
                
                Write-EZLog -Header
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
        }

        Test-ConvertFromEZLog -delimiter ','
        Test-ConvertFromEZLog -delimiter ';'
        Test-ConvertFromEZLog -delimiter "`t"
        Test-ConvertFromEZLog -delimiter "#"

    } # Describe block

    Describe 'Invoke-EZLogRotation' -Tag Rotate {

        Context 'Newest parameter' {

            BeforeEach {
                1..50 | ForEach-Object { New-Item -Path "$TestDrive\file_$_.test" -ItemType file
                                         Start-Sleep -Milliseconds 25 }
            }
            AfterEach {
                Get-ChildItem -Path $TestDrive -Filter *.test | Remove-Item
            }

            It 'should only keep 20 files' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Newest 20
                (Get-ChildItem -Path $TestDrive -Filter *.test).count | Should BeExactly 20
            }

            It 'should only keep the newest files' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Newest 20
                # Check if the remaining files are the ones that should really be
                $arr1 = 31..50 | ForEach-Object {"file_$_.test"}
                $arr2 = Get-ChildItem -Path $TestDrive -Filter file_*.test | Sort-Object -Property LastWriteTime | Select-Object -ExpandProperty Name
                (Compare-Object -ReferenceObject $arr1 -DifferenceObject $arr2) | Should Be $Null
            }
        } # context
        
        Context 'Newest parameter combined with ArchiveTo parameter (no existing archive file)' {

            BeforeEach {
                1..50 | Foreach { New-Item -Path "$TestDrive\file_$_.test" -ItemType file
                                  Start-Sleep -Milliseconds 25 }
            }
            AfterEach {
                Get-ChildItem -Path $TestDrive -Filter *.test | Remove-Item
            }

            $archivePath = "$TestDrive\Archive.zip"
            It 'Should create an archive' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Newest 20 -ArchiveTo $archivePath
                Test-Path -Path $archivePath | Should Be $True
            }

            It 'The archive should be valid and should contain files' {
                Expand-Archive -Path $archivePath -DestinationPath $TestDrive\temp
                (Get-ChildItem -Path $TestDrive\temp).count | Should BeExactly 30
            }
        } # context


        Context 'Newest parameter combined with ArchiveTo parameter (archive file already exists)' {

            BeforeEach {
                # Archive creation. The goal is to check that the files are appended to it.
                101..150 | Foreach { New-Item -Path "$TestDrive\file_$_.test" -ItemType file
                                  Start-Sleep -Milliseconds 25 }
                $archivePath = "$TestDrive\Archive.zip"
                # 1st log rotation. We just keep the 15 newest files. 35 files should be archived.
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Newest 15 -ArchiveTo $archivePath
                
                # Adding 50 more files
                1..50 | Foreach { New-Item -Path "$TestDrive\file_$_.test" -ItemType file
                                  Start-Sleep -Milliseconds 25 }
            }

            AfterEach {
               # $host.EnterNestedPrompt()
            }

            $archivePath = "$TestDrive\Archive.zip"
            It 'Should append the logs to an existing archive' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Newest 20 -ArchiveTo $archivePath
                Expand-Archive -Path $archivePath -DestinationPath $TestDrive\temp
                (Get-ChildItem -Path $TestDrive\temp).count | Should BeExactly 80
            }
        } # context


        Context 'Newest parameter combined with ArchiveTo parameter plus OverwriteArchive switch (archive file already exists)' {

            BeforeEach {
                
                # Archive creation in order to check if it's overwrited as it should.
                101..150 | Foreach { New-Item -Path "$TestDrive\file_$_.test" -ItemType file
                                  Start-Sleep -Milliseconds 25 }
                $archivePath = "$TestDrive\Archive.zip"
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Newest 15 -ArchiveTo $archivePath
                
                # Creating 50 additionnal files
                1..50 | Foreach { New-Item -Path "$TestDrive\file_$_.test" -ItemType file
                                  Start-Sleep -Milliseconds 25 }
            }

            AfterEach {
            }

            $archivePath = "$TestDrive\Archive.zip"
            It 'Should overwrite an existing archive' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Newest 20 -ArchiveTo $archivePath -OverwriteArchive
                Expand-Archive -Path $archivePath -DestinationPath $TestDrive\temp
                (Get-ChildItem -Path $TestDrive\temp).count | Should BeExactly 45  
            }
        } # context
    } # Describe

    Describe 'Daily Rotation' -Tag daily {
        Context 'Rotates the logs on a daily interval.' {

            BeforeEach {
                1..72 | Foreach { New-Item -Path "$TestDrive\file_$_.test" -ItemType file}
                $date = '2018/01/15 12:00:00' -as [datetime]
                Get-ChildItem $TestDrive\*.test | Sort-Object -Property LastWriteTime | foreach {$i=0} {$_.LastWriteTime = $date.AddHours(-$i); $i++}
            }

            AfterEach {
                Remove-Item -Path $TestDrive\* -force
            }

            Mock Get-Date { '2018/01/14 12:00:00' -as [datetime] }

            It 'There should be 24 files left in the directory after invoking the rotation function' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Daily
               
                # There should be 24 files left
                (Get-ChildItem -Path $TestDrive -Filter *.test).count | Should BeExactly 24
            } 
            
            It 'The Day property of the remaining files should be unique' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Daily
                (Get-ChildItem -Path $TestDrive -Filter *.test | Select-Object -ExpandProperty LastWriteTime | Select -ExpandProperty day -Unique).count | Should BeExactly 1
            }

            It 'The Day property of the remaining files should be 14' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Daily
                Get-ChildItem -Path $TestDrive -Filter *.test | Select-Object -ExpandProperty LastWriteTime | Select -ExpandProperty day -Unique | Should BeExactly 14
            }
        } # Context
    }

<#    Describe 'Weekly Rotation' -Tag weekly {
        Context 'Rotates the logs on a weekly interval.' {

            BeforeEach {
                1..500 | Foreach { New-Item -Path "$TestDrive\file_$_.test" -ItemType file }
                $date = '2018/01/15 12:00:00' -as [datetime]
                Get-ChildItem $TestDrive\*.test | Sort-Object -Property LastWriteTime | foreach {$i=0} {$_.LastWriteTime = $date.AddHours(-$i); $i++}
            }

            AfterEach {
                Remove-Item -Path $TestDrive\* -force
            }

            Mock Get-Date { '2018/01/14 12:00:00' -as [datetime] }

            it 'Should left only files created during the week' {
                $host.EnterNestedPrompt()
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Weekly
                $DateDayOfWeek = Get-FirstDayOfWeekDate -date (Get-Date)
                $res = Get-ChildItem -Path $TestDrive -Filter *.test | Where-Object { $_.LastWriteTime -ge $DateDayOfWeek }
                $res.count | Should Be 157
            }
        } # Context
    }
#>

    Describe 'Get-FirstDayOfWeekDate on countries where Monday is the first day of the week' {
        Context 'Monday' { 
            It 'Should return Monday of the same day' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 22 -Month 01 -Year 2018)
                $res.day | Should Be 22
            }
        }

        Context 'Tuesday' { 
            It 'Should return Monday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 23 -Month 01 -Year 2018)
                $res.day | Should Be 22
            }
        }

        Context 'Wednesday' { 
            It 'Should return Monday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 24 -Month 01 -Year 2018)
                $res.day | Should Be 22
            }
        }

        Context 'Thursday' { 
            It 'Should return Monday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 25 -Month 01 -Year 2018)
                $res.day | Should Be 22
            }
        }

        Context 'Friday' { 
            It 'Should return Monday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 26 -Month 01 -Year 2018)
                $res.day | Should Be 22
            }
        }

        Context 'Saturday' { 
            It 'Should return Monday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 27 -Month 01 -Year 2018)
                $res.day | Should Be 22
            }
        }
        
        Context 'Sunday' { 
            It 'Should return Monday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 28 -Month 01 -Year 2018)
                $res.day | Should Be 22
            }
        }
    } # Describe

    Describe 'Get-FirstDayOfWeekDate on countries where Sunday is the first day of the week' {

        Mock Get-FirstDayOfWeek { [dayofweek]::Sunday }

        Context 'Sunday' { 
            It 'Should return Sunday of the same day' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 21 -Month 01 -Year 2018)
                $res.day | Should Be 21
            }
        }

        Context 'Monday' { 
            It 'Should return Sunday of the same week ' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 22 -Month 01 -Year 2018)
                $res.day | Should Be 21
            }
        }

        Context 'Tuesday' { 
            It 'Should return Sunday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 23 -Month 01 -Year 2018)
                $res.day | Should Be 21
            }
        }

        Context 'Wednesday' { 
            It 'Should return Sunday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 24 -Month 01 -Year 2018)
                $res.day | Should Be 21
            }
        }

        Context 'Thursday' { 
            It 'Should return Sunday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 25 -Month 01 -Year 2018)
                $res.day | Should Be 21
            }
        }

        Context 'Friday' { 
            It 'Should return Sunday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 26 -Month 01 -Year 2018)
                $res.day | Should Be 21
            }
        }

        Context 'Saturday' { 
            It 'Should return Sunday of the same week' {
                $res = Get-FirstDayOfWeekDate -Date (Get-Date -Day 27 -Month 01 -Year 2018)
                $res.day | Should Be 21
            }
        }
    } # Describe

    Describe 'Monthly Rotation' -Tag monthly {
        Context 'Rotates the logs on a monthly interval.' {

            BeforeEach {
                1..500 | Foreach { New-Item -Path "$TestDrive\file_$_.test" -ItemType file }
                $date = '2018/01/15 12:00:00' -as [datetime]
                Get-ChildItem $TestDrive\*.test | Sort-Object -Property LastWriteTime | foreach {$i=0} {$_.LastWriteTime = $date.AddHours(-$i); $i++}
            }

            AfterEach {
                Remove-Item -Path $TestDrive\* -force
            }

            Mock Get-Date { '2018/01/14 12:00:00' -as [datetime] }

            it 'Should be left only files created since the begining of the month => 325 files' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Monthly
                $DateFirstDayOfMonth = Get-FirstDayOfMonthDate -date (Get-Date)
                
                $res = Get-ChildItem -Path $TestDrive -Filter *.test | Where-Object { $_.LastWriteTime -ge $DateFirstDayOfMonth }
                $res.count | Should Be 325
            }

            it 'All files should have the same month value in the LastWriteTime property' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Monthly
                $month = @(Get-ChildItem -Path $TestDrive -Filter *.test | Select-Object -Property @{n='month';e={$_.LastWriteTime.Month}} -Unique).count

                $month | Should Be 1

            }
        } # Context
    }

    Describe 'Yearly Rotation'  {
        Context 'Rotates the logs on a yearly interval.' {

            BeforeEach {
                1..500 | Foreach { New-Item -Path "$TestDrive\file_$_.test" -ItemType file }
                $date = '2019/01/01 00:00:00' -as [datetime]
                Get-ChildItem $TestDrive\*.test | Sort-Object -Property LastWriteTime | foreach {$i=1} {$_.LastWriteTime = $date.AddDays(-$i); $i++}
            }

            AfterEach {
                Remove-Item -Path $TestDrive\* -force -recurse
            }

            Mock Get-Date { '2018/01/14 12:00:00' -as [datetime] }

            it 'Should be left only files created since the beginning of the year => 365 files' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Yearly
                $DateFirstDayOfYear = '01/01/2018 00:00:00' -as [datetime]

                $res = Get-ChildItem -Path $TestDrive -Filter *.test | Where-Object { $_.LastWriteTime -ge $DateFirstDayOfYear }
                $res.count | Should Be 365
            }

            it 'All files should have the same year value in the LastWriteTime property' {
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Yearly
                $year = @(Get-ChildItem -Path $TestDrive -Filter *.test | Select-Object -Property @{n='year';e={$_.LastWriteTime.Year}} -Unique).count

                $year | Should Be 1
            }

            it 'Should create an archive file' {
                $archivePath = "$TestDrive\Archive.zip"
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Yearly -ArchiveTo $archivePath
                Test-Path -Path $archivePath | Should Be $True
                
            }

            it 'Archive should contain files' {
                $archivePath = "$TestDrive\Archive.zip"
                Invoke-EZLogRotation -Path $TestDrive -Filter *.test -Interval Yearly -ArchiveTo $archivePath
                Expand-Archive -Path $archivePath -DestinationPath $TestDrive\temp
                (Get-ChildItem -Path $TestDrive\temp).count | Should Not Be 0
            }


        } # Context

    } # Describe Yearly

}