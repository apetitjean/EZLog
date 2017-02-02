#Requires -Version 2.0
$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @"
    public enum MsgCategory
    {
       INF   = 0,
       WAR   = 1,
       ERR   = 2
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

   Write-EZLog -Category INF -Message 'This is an info to be written in the log file'
   Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file'
   Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'

   Finaly, to close your logfile you need to write a footer, just do that:

   Write-EZLog -Footer

.EXAMPLE
   If you want to see the logs in the PowerShell console whereas they are still written to disk, 
   you can specify the -ToScreen switch.
   Info entries will be written in cyan color, Yellow for warnings, and Red for the errors.

   Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file' -ToScreen

.NOTES
   AUTHOR: Arnaud PETITJEAN - arnaud@powershell-scripting.com
   LASTEDIT: 2016/09/21

#>
    [cmdletBinding(DefaultParameterSetName="set1", SupportsShouldProcess=$False)]
    PARAM (
        [parameter(Mandatory=$true, ParameterSetName="set1", ValueFromPipeline=$false, position=0)]
        [MsgCategory]$Category,
       
        [parameter(Mandatory=$true, ParameterSetName="set1", ValueFromPipeline=$false, position=1)]
        [Alias("Msg")]
        [String]$Message,
       
        [parameter(Mandatory=$true, ParameterSetName="set2", ValueFromPipeline=$false)]
        [Switch]$Header,
       
        [parameter(Mandatory=$true, ParameterSetName="set3", ValueFromPipeline=$false)]
        [Switch]$Footer,

        [parameter(Mandatory=$true, ParameterSetName="set2", ValueFromPipeline=$false)]
        [String]$LogFile,

        [parameter(Mandatory=$false, ParameterSetName="set2", ValueFromPipeline=$false)]
        [Char]$Delimiter = $( if ((Get-Culture).TextInfo.ListSeparator -eq ' ')  {','} else {(Get-Culture).TextInfo.ListSeparator}), 

        [parameter(Mandatory=$false, ValueFromPipeline=$false)]
        [Switch]$ToScreen=$false
    )
   
    $Color = 'Cyan'
        
    Switch ($PsCmdlet.ParameterSetName)
    {
       "set1"
       {
           $date = Get-Date -UFormat "%Y-%m-%d %H:%M:%S"
           $Delimiter = $Global:Delimiter
           switch ($Category)
           {
               INF  { $Message = ("$date{0} INF{0} $Message" -f $Global:EZLogDelimiter); $Color = 'Cyan'   ; break }
               WAR  { $Message = ("$date{0} WAR{0} $Message" -f $Global:EZLogDelimiter); $Color = 'Yellow' ; break }
               ERR  { $Message = ("$date{0} ERR{0} $Message" -f $Global:EZLogDelimiter); $Color = 'Red'    ; break }
           }
            
           Add-Content -Path $Global:EZLogFile -Value $Message
           break
       }
         
       "set2"
       {
          New-Variable -Name EZLogFile -Value $LogFile -Option ReadOnly -Visibility Public -Scope Global -force
          New-Variable -Name EZLogDelimiter -Value $Delimiter -Option ReadOnly -Visibility Public -Scope Global -force

          $currentScriptName = $myinvocation.ScriptName
          $currentUser       = $ENV:USERDOMAIN + '\' + $ENV:USERNAME
          $currentComputer   = $ENV:COMPUTERNAME
          $StartDate_str     = Get-Date -UFormat "%Y-%m-%d %H:%M:%S"

          if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
            $WmiInfos        = Get-WmiObject win32_operatingsystem
            $OSName          = $WmiInfos.caption
            $OSArchi         = $WmiInfos.OSArchitecture
          } elseif (Get-Command uname -ErrorAction SilentlyContinue) {
            $OSName        = uname -s
            $OSArchi       = uname -m
          } else {
            $OSName        = $OSArchi = 'Unknown'
          }
          $Message           = @"
+----------------------------------------------------------------------------------------+
Script fullname          : $currentScriptName
When generated           : $StartDate_str
Current user             : $currentUser
Current computer         : $currentComputer
Operating System         : $OSName
OS Architecture          : $OSArchi
+----------------------------------------------------------------------------------------+

"@
          # Log file creation
          [VOID] (New-Item -ItemType File -Path $Global:EZLogFile -Force)
          Add-Content -Path $Global:EZLogFile -Value $Message
          break
       }
                  
       "set3"
       {
          # Extracting start date from the file header
          [VOID]( (Get-Content $Global:EZLogFile -TotalCount 3)[-1] -match '^When generated\s*: (?<date>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})$' )
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
          $Message = @"

+----------------------------------------------------------------------------------------+
End time                 : $EndDate_str
Total duration (seconds) : $duration_TotalSeconds
Total duration (minutes) : $duration_TotalMinutes
+----------------------------------------------------------------------------------------+
"@
          # Append the footer to the log file
          Add-Content -Path $Global:EZLogFile -Value $Message
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
                         TimeSpan         = ''
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

        $result.Footer.TimeSpan        = New-TimeSpan -Start $result.Header.WhenGenerated -End $result.Footer.EndTime



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