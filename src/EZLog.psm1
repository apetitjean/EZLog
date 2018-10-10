#Requires -Version 5.0
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
<#
.SYNOPSIS
   Utility cmdlet to write logs to disk in an easy and pragmatic way. 

.DESCRIPTION
   This cmdlet allows to write timestamped and nice formatted logs with a header and footer. 
   It also allows to specify if the log entry being written is an info, a warning or an error.
   
   The header contains the following information :
       - full script path of the caller, 
       - account under the script was run,
       - computer name of the machine whose executed the script,
       - and more...
   The footer contains the elapsed time from the beginning of the log session.

.PARAMETER Header
    Mandatory switch to start a log session.

.PARAMETER Category
    Category can be one of the following value : INF, WAR, ERR

.PARAMETER Message 
    Specify the content of the data to log.

.PARAMETER Footer
    Mandatory switch to end a log session. If you omit to close your log session, you won't know how much time 
    your script was running.

.EXAMPLE
   First thing to do is write a header and define a log file where the data will be written.

   Write-EZLog -Header -LogFile C:\logs\mylogfile.log
   
   Next, anywhere in your script when you need to write a log, do one of the folowing command:

   Write-EZLog -Category INF -Message 'This is an info to be written in the log file' -LogFile C:\logs\mylogfile.log
   Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file' -LogFile C:\logs\mylogfile.log
   Write-EZLog -Category ERR -Message 'This is an error to be written in the log file' -LogFile C:\logs\mylogfile.log

   Finaly, to close your logfile you need to write a footer, just do that:

   Write-EZLog -Footer -LogFile C:\logs\mylogfile.log

.EXAMPLE
   If you want to see the logs in the PowerShell console whereas they are still written to disk, 
   you can specify the -ToScreen switch.
   Info entries will be written in cyan color, Yellow for warnings, and Red for the errors.

   Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file' -ToScreen -LogFile C:\logs\mylogfile.log

.NOTES
   AUTHOR: Arnaud PETITJEAN - arnaud@powershell-scripting.com
   LASTEDIT: 2018/03/30

#>
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
        [Switch]$ToScreen
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
<#
.SYNOPSIS
   Cmdlet that convert an EZLog file to a set of objects.

.DESCRIPTION
   This cmdlet allows from a log file generated by EZLog to get an object. 
   The goal is to be able to easily filter on events with a single Where-Object and
   get to the info stored in the header and in the footer. 

   Furthermore it eases the ability to transform the data to JSON if piped to ConvertTo-JSON.

.PARAMETER FilePath
    Specify the log file's path.

.EXAMPLE
   ConvertFrom-EZlog -FilePath C:\temp\mylog.log

   Returns an object from the log file.

.EXAMPLE
   ConvertFrom-EZlog -FilePath C:\temp\mylog.log | ConvertTo-JSON

   Get a JSON format from a logfile.

.NOTES
   AUTHOR: Arnaud PETITJEAN - arnaud@powershell-scripting.com
   LASTEDIT: 2016/11/15
#>

    Param ( 
       [parameter(Mandatory=$true, ValueFromPipeline=$true, position=0)]
       [Alias("Path")]
       [string]$FilePath

     #  [parameter(Mandatory=$false, ValueFromPipeline=$false)]
     #  [switch]$ToJson
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
<#
.SYNOPSIS
   Clean up old log files in order to keep only the most recent ones.

.DESCRIPTION
   Ancient logs files are either deleted or archived into a Zip file.

   Options are available to specify how many newest files to keep. 
   It's also possible to determine a time interval for the logs to keep (daily, monthly, yearly)

.PARAMETER Path
    Directory containing the logs to rotate.

.PARAMETER Filter
    Pattern to identify the logs to rotate. Ex : *.log, *ezlog*.txt, etc.

.PARAMETER Newest 
    Specify how many files to keep in the directory. The files are sorted by the LastWriteTime attribute
    and only the newest files determined by this parameter are kept. Other files are deleted or archived.

.PARAMETER Interval
    Specify the periodicy of the rotation.
    Possible values are : Daily, Monthly, Yearly

    Daily   : Keep only the logs of the day
    Monthly : Keep only the logs of the month
    Yearly  : Keep only the logs of the year

.PARAMETER ArchiveTo
    Indicate if the old logs need to be archived in a Zip before before deletion.

    If not specified, old logs are deleted.

    If specified, you must indicate a file path containing the .zip extension.
    Eg. : C:\logs\archive.zip

    If the archive file already exists, logs will be append to it. If you want to overwrite it you can use 
    the -OverwriteArchive switch.

.PARAMETER OverwriteArchive
    Works in association with -ArchiveTo.
    If specified, it overwrites an archive if it already exists.

.EXAMPLE
    Invoke-EZLogRotation -Path C:\LogFiles\*.log -Newest 15

    Only keeps the latest 15 newest *.log files in the C:\LogFiles directory. Older files will be deleted.

.EXAMPLE
    Invoke-EZLogRotation -Path C:\LogFiles\*.log -Newest 15 -ArchiveTo C:\LogFiles\archive.zip

    Only keeps the latest 15 newest *.log files in the C:\LogFiles directory. Before deletion, older files 
    will be archived into the C:\LogFiles\archive.zip.
    If the archive.zip file already exists, logs will be appended to it.

.EXAMPLE
    Invoke-EZLogRotation -Path C:\LogFiles\*.log -Newest 15 -ArchiveTo C:\LogFiles\archive.zip -OverwriteArchive

    Only keeps the latest 15 newest *.log files in the C:\LogFiles directory. Before deletion, older files 
    will be archived into the C:\LogFiles\archive.zip.
    If the archive.zip file already exists it will be overwritten.

.EXAMPLE
    Invoke-EZLogRotation -Path C:\LogFiles\*.log -Interval Daily 

    Only keeps the *.log files of the day in the C:\LogFiles directory. Older files will be deleted.
    
.EXAMPLE
    Invoke-EZLogRotation -Path C:\LogFiles\*.log -Interval Monthly

    Only keeps the *.log files of the month in the C:\LogFiles directory. Older files will be deleted.

.EXAMPLE
    Invoke-EZLogRotation -Path C:\LogFiles\*.log -Interval Monthly -ArchiveTo C:\LogFiles\archive.zip -Overwrite

    Only keeps the *.log files of the month in the C:\LogFiles directory. Older files will be archived monthly.

.EXAMPLE
    Invoke-EZLogRotation -Path C:\LogFiles\*.log -Interval Yearly 

    Only keeps the *.log files of the current year in the C:\LogFiles directory matching the pattern *.log. Older files will be deleted.

.NOTES
   AUTHOR: Arnaud PETITJEAN
   LASTEDIT: 2018/04/03

#>
    [cmdletBinding(DefaultParameterSetName="", SupportsShouldProcess=$False)]
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
