#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-PSDebug -Strict

Add-Type -TypeDefinition @"
    public enum MsgCategory
    {
       INF   = 0,
       WAR   = 1,
       ERR   = 2
    }

    public enum Interval
    {
       Daily   = 0,
       Monthly = 2,
       Yearly  = 3
    }
"@

Function Write-EZLog
{
    [cmdletBinding(DefaultParameterSetName="set2", SupportsShouldProcess=$False)]
    PARAM (
        [parameter(Mandatory=$true, ParameterSetName="set2", ValueFromPipeline=$false, position=0)]
        [MsgCategory]$Category,
       
        [parameter(Mandatory=$true, ParameterSetName="set2", ValueFromPipeline=$false, position=1)]
        [Alias("Msg")]
        [String]$Message,
       
        [parameter(Mandatory=$true, ParameterSetName="set1", ValueFromPipeline=$false)]
        [Switch]$Header,
       
        [parameter(Mandatory=$true, ParameterSetName="set3", ValueFromPipeline=$false)]
        [Switch]$Footer,

        [parameter(Mandatory=$true, ValueFromPipeline=$false)]
        [String]$LogFile,

        [parameter(Mandatory=$false, ValueFromPipeline=$false)]
        [Char]$Delimiter = $( if ((Get-Culture).TextInfo.ListSeparator -eq ' ')  {','} else {(Get-Culture).TextInfo.ListSeparator}), 

        [parameter(Mandatory=$false, ValueFromPipeline=$false)]
        [Switch]$ToScreen=$false
    )
   
    $Color = 'Cyan'

    $currentScriptName = $myinvocation.ScriptName
    $StartDate_str     = Get-Date -UFormat "%Y-%m-%d %H:%M:%S"

    if ($isLinux -or $isMacOS) {
        $currentUser     = $ENV:USER
        $currentComputer = uname -n
        $OSName          = uname -s
        $OSArchi         = uname -m
        $StrTerminator   = "`r"        
    }
    else {
        $currentUser     = $ENV:USERDOMAIN + '\' + $ENV:USERNAME
        $currentComputer = $ENV:COMPUTERNAME  
        $WmiInfos        = Get-CimInstance win32_operatingsystem
        $OSName          = $WmiInfos.caption
        $OSArchi         = $WmiInfos.OSArchitecture
        $StrTerminator     = "`r`n"       
    }
   
    Switch ($PsCmdlet.ParameterSetName)
    {
       "set1" # Header
       {
          $Message =  "+----------------------------------------------------------------------------------------+{0}"
          $Message += "Script fullname          : $currentScriptName{0}"
          $Message += "When generated           : $StartDate_str{0}"
          $Message += "Current user             : $currentUser{0}"
          $Message += "Current computer         : $currentComputer{0}"
          $Message += "Operating System         : $OSName{0}"
          $Message += "OS Architecture          : $OSArchi{0}"
          $Message += "+----------------------------------------------------------------------------------------+{0}"
          $Message += "{0}"

          $Message = $Message -f $StrTerminator
          # Log file creation
          [VOID] (New-Item -ItemType File -Path $LogFile -Force)
          Add-Content -Path $LogFile -Value $Message -NoNewline
          break
       }

       "set2" # Body
       {
           $date = Get-Date -UFormat "%Y-%m-%d %H:%M:%S"
           switch ($Category)
           {
               INF  { $Message = ("$date{0} INF{0} $Message{1}" -f $Delimiter, $StrTerminator); $Color = 'Cyan'   ; break }
               WAR  { $Message = ("$date{0} WAR{0} $Message{1}" -f $Delimiter, $StrTerminator); $Color = 'Yellow' ; break }
               ERR  { $Message = ("$date{0} ERR{0} $Message{1}" -f $Delimiter, $StrTerminator); $Color = 'Red'    ; break }
           }
            
           Add-Content -Path $LogFile -Value $Message -NoNewLine
           break
       }
                  
       "set3" # Footer
       {
          # Extracting start date from the file header
          [VOID]( (Get-Content $LogFile -TotalCount 3)[-1] -match '^When generated\s*: (?<date>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})$' )
          if ($Matches.date -eq $null)
          {
             throw "Cannot get the start date from the header. Please check if the file header is correctly formatted."
          }
          $StartDate   = [DateTime]$Matches.date
          $EndDate     = Get-Date
          $EndDate_str = Get-Date $EndDate -UFormat "%Y-%m-%d %H:%M:%S"

          $duration_TotalSeconds = [int](New-TimeSpan -Start $StartDate -End $EndDate | Select-Object -ExpandProperty TotalSeconds)
          $duration_TotalMinutes = (New-TimeSpan -Start $StartDate -End $EndDate | Select-Object -ExpandProperty TotalMinutes)
          $duration_TotalMinutes = [MATH]::Round($duration_TotalMinutes, 2)

          $Message = "{0}"
          $Message += "+----------------------------------------------------------------------------------------+{0}"
          $Message += "End time                 : $EndDate_str{0}"
          $Message += "Total duration (seconds) : $duration_TotalSeconds{0}"
          $Message += "Total duration (minutes) : $duration_TotalMinutes{0}"
          $Message += "+----------------------------------------------------------------------------------------+{0}"
          
          $Message = $Message -f $StrTerminator

          # Append the footer to the log file
          Add-Content -Path $LogFile -Value $Message -NoNewLine
          break
       }
   } # End switch

   if ($ToScreen)
   {
       Write-Host $Message -ForegroundColor $Color
   }
}

Function Get-Log
{
    Param ($file)
    
    $content = Get-Content -Path $file
    $index = 0
    $sepPos = @()
    foreach ($line in $content)
    {
        if ($line -like '+-*-+')
        {
            $sepPos += $index
        }
        $index++
    }
    
    $result = (Get-Content $file)[(($SepPos[1])+1)..(($SepPos[2])-1)]
    $result -ne '' # Blank lines exclusion
}


Function ConvertFrom-EZlog
{
    Param ( 
       [parameter(Mandatory=$true, ValueFromPipeline=$true, position=0)]
       [Alias("Path")]
       [string]$FilePath
    )

    begin
    {
        
    }

    process
    {
        $result = @{
            Header = @{  ScriptFullname   = ''
                         WhenGenerated    = ''
                         CurrentUser      = ''
                         CurrentComputer  = ''
                         OperatingSystem  = ''
                         OSArchitecture   = ''
                    }
            Events = @()
            Footer = @{  EndTime          = ''
                         Duration         = ''
            }
        }

        $header = Get-Content -Path $FilePath | Select-Object -Skip 1  -First 6
        
        $result.Header.ScriptFullname  = $( $null = $header[0] -match '(?<Name>.+?)(:\s{1})(?<Value>.+)?' 
                                            if ( $matches ) 
                                            {
                                               $matches.Value   
                                            }
                                          )
        $result.Header.WhenGenerated   = $( $null = $header[1] -match '(?<Name>.+?)(:\s{1})(?<Value>.+)?'
                                            if ( $matches ) 
                                            {
                                               [DateTime]($matches.Value)
                                            }
                                          )
        
        $result.Header.CurrentUser     = $( $null = $header[2] -match '(?<Name>.+?)(:\s{1})(?<Value>.+)?'
                                            if ( $matches ) 
                                            {
                                               $matches.Value
                                            }
                                          )

        $result.Header.CurrentComputer  = $( $null = $header[3] -match '(?<Name>.+?)(:\s{1})(?<Value>.+)?'
                                            if ( $matches ) 
                                            {
                                               $matches.Value
                                            }
                                          )
                                                  
        $result.Header.OperatingSystem = $( $null = $header[4] -match '(?<Name>.+?)(:\s{1})(?<Value>.+)?'
                                            if ($matches) 
                                            {
                                               $matches.Value
                                            }
                                          )
        $result.Header.OSArchitecture  = $( $null = $header[5] -match '(?<Name>.+?)(:\s{1})(?<Value>.+)?'
                                            if ($matches) 
                                            {
                                               $matches.Value
                                            }
                                          )
    
        $footer = Get-Content -Path $FilePath | Select-Object -Skip 1  -Last 3
        $result.Footer.EndTime         = $( $null = $footer[0] -match '(?<Name>.+?)(:\s{1})(?<Value>.+)?'
                                            if ($matches) 
                                            {
                                               [DateTime]($matches.Value)
                                            }
                                          )

        $result.Footer.Duration        = New-TimeSpan -Start $result.Header.WhenGenerated -End $result.Footer.EndTime



        $LogMessages = Get-Log -file $FilePath  
        $separator   = $LogMessages[0][19]
        foreach ($log in $LogMessages)
        {
            $res = $log -split $separator
            $result.Events += [PSCustomObject]@{
                                    Date     = $res[0] -as [DateTime]
                                    Category = $res[1].Trim()
                                    Message  = $res[2].Trim()
                                }
        }
    }

    end
    {
        $result
    }
}

Function Invoke-EZLogRotation
{
    [cmdletBinding(DefaultParameterSetName='set1', SupportsShouldProcess=$False)]
    PARAM (
        [parameter(Mandatory=$true, position=0)]
        [String]$Path,
       
        [parameter(Mandatory=$true, position=1)]
        [String]$Filter,

        [parameter(Mandatory=$true, ParameterSetName="set1", ValueFromPipeline=$false)]
        [Int]$Newest,

        [parameter(Mandatory=$true, ParameterSetName="set2", ValueFromPipeline=$false, position=1)]
        [Interval]$Interval,
       
        [parameter(Mandatory=$false)]
        [ValidateScript({$_ -like '*.zip'})] 
        [String]$ArchiveTo,
        
        [parameter(Mandatory=$false)]
        [Switch]$OverwriteArchive
    )

    Switch ($PSCmdlet.ParameterSetName) {

        'Set1' {
            $filesToRemove = Get-ChildItem -Path $Path -Filter $Filter | Sort-Object -Property LastWriteTime -Descending | 
                    Select-Object -Skip $Newest
        }
        
        'Set2' {
            Switch ($Interval) {
                'Daily' { $filesToKeep =  Get-ChildItem -Path $Path -Filter $Filter | 
                                             Where-Object { $_.LastWriteTime.Year  -eq (Get-Date).Year -and 
                                                            $_.LastWriteTime.Month -eq (Get-Date).Month -and
                                                            $_.LastWriteTime.Day   -eq (Get-Date).Day }
                          $filesToRemove = Get-ChildItem "$Path\$Filter" -Exclude $filesToKeep
                          Break
                        }
            <#    'Weekly' { $filesToKeep =  Get-ChildItem -Path $Path -Filter $Filter | 
                                             Where-Object { $_.LastWriteTime -ge (Get-FirstDayOfWeekDate) -and
                                                            $_.LastWriteTime -le (Get-Date) }
                          $filesToRemove = Get-ChildItem "$Path\$Filter" -Exclude $filesToKeep
                          Break
                        }
            #>
                'Monthly' { $filesToKeep =  Get-ChildItem -Path $Path -Filter $Filter | 
                                             Where-Object { $_.LastWriteTime -ge (Get-FirstDayOfMonthDate) -and
                                                            $_.LastWriteTime -le (Get-Date) }
                          $filesToRemove = Get-ChildItem "$Path\$Filter" -Exclude $filesToKeep
                          Break
                        }
                'Yearly' { $filesToKeep =  Get-ChildItem -Path $Path -Filter $Filter | 
                                             Where-Object { $_.LastWriteTime.Year -eq (Get-Date).Year }
                          $filesToRemove = Get-ChildItem "$Path\$Filter" -Exclude $filesToKeep
                          Break
                        }                        
            }
        }
    }

    if ($ArchiveTo -and $OverwriteArchive) {
        $filesToRemove | Compress-Archive -DestinationPath $ArchiveTo -CompressionLevel Optimal -Force
    }
    elseif ($ArchiveTo) {
        $filesToRemove | Compress-Archive -DestinationPath $ArchiveTo -CompressionLevel Optimal -Update
    }
    
    $filesToRemove | Remove-Item

}

Function Get-FirstDayOfWeek 
{

    (Get-Culture).DateTimeFormat.FirstDayOfWeek

}

Function Get-FirstDayOfWeekDate
{
    Param ( [Datetime]$date = (Get-Date) )

    if ( ( (Get-FirstDayOfWeek) -eq [DayOfWeek]::Monday) -and ($date.DayOfWeek -eq [DayOfWeek]::Sunday) ) {
        $nbJoursARetirer = 6 
    } 
    elseif ( ( (Get-FirstDayOfWeek) -eq [DayOfWeek]::Sunday) -and ($date.DayOfWeek -eq [DayOfWeek]::Sunday) ) {
        $nbJoursARetirer = 0 
    }
    else {
        $nbJoursARetirer = [int]$date.DayOfWeek - [int](Get-FirstDayOfWeek)
    }

    $date = $date.AddDays(-$nbJoursARetirer)
    New-Object -TypeName datetime $date.Year, $date.Month, $date.Day, 0, 0, 0, 0
}

Function Get-FirstDayOfMonthDate
{
    Param ( [Datetime]$date = (Get-Date) )

    New-Object -TypeName datetime $date.Year, $date.Month, 1, 0, 0, 0, 0
}