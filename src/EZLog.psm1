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
.Synopsis
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

   PS > Write-EZLog -Header -LogFile C:\logs\mylogfile.log
   
   Next, anywhere in your script when you need to write a log, do one of the folowing command:

   PS > Write-EZLog -Category INF -Message 'This is an info to be written in the log file'
   PS > Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file'
   PS > Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'

   Finaly, to close your logfile you need to write a footer, just do that:

   PS > Write-EZLog -Footer

.EXAMPLE
   If you want to see the logs in the PowerShell console whereas they are still written to disk, 
   you can specify the -ToScreen switch.
   Info entries will be written in cyan color, Yellow for warnings, and Red for the errors.

   PS > Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file' -ToScreen

.NOTES
   AUTHOR: Arnaud PETITJEAN - arnaud@powershell-scripting.com
   VERSION: 1.1.0
   LASTEDIT: 2016/09/02

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
       
        [parameter(Mandatory=$false, ValueFromPipeline=$false)]
        [Switch]$ToScreen=$false
    )
   
    $Color = 'Cyan'
        
    Switch ($PsCmdlet.ParameterSetName)
    {
       "set1"
       {
           $date = Get-Date -UFormat "%Y/%m/%d %H:%M:%S"
           switch ($Category)
           {
               INF  { $Message = "$date; INF; $Message"; $Color = 'Cyan'   ; break }
               WAR  { $Message = "$date; WAR; $Message"; $Color = 'Yellow' ; break }
               ERR  { $Message = "$date; ERR; $Message"; $Color = 'Red'    ; break }
           }
            
           Add-Content -Path $Global:LogFile -Value $Message
 
           break
       }
         
       "set2"
       {
          New-Variable -Name LogFile -Value $LogFile -Option ReadOnly -Visibility Public -Scope Global -force
          $currentScriptName = $myinvocation.ScriptName
          $currentUser = $ENV:USERDOMAIN + '\' + $ENV:USERNAME
          $currentComputer = $ENV:COMPUTERNAME
          $StartDate_str = Get-Date -UFormat "%Y/%m/%d %H:%M:%S"
          $WmiInfos = Get-WmiObject win32_operatingsystem
          $OSName  = $WmiInfos.caption
          $OSSP    = $WmiInfos.csdversion
          $OSArchi = $WmiInfos.OSArchitecture
          $Message = @"
+----------------------------------------------------------------------------------------+

Nom du script          : $currentScriptName
Généré le              : $StartDate_str

Utilisateur courant    : $currentUser
Ordinateur  courant    : $currentComputer
Système d'exploitation : $OSName $OSSP
OS Architecture        : $OSArchi

+----------------------------------------------------------------------------------------+
"@
          # Création du fichier de log
          [VOID] (New-Item -ItemType File -Path $LogFile -Force)
          Add-Content -Path $LogFile -Value $Message
          break
       }
                  
       "set3"
       {
          # Analyse de l'entête du fichier de log pour extraire la date de début et conversion de la chaine en type [DateTime]
          [VOID]( (Get-Content $Global:logFile -TotalCount 4)[-1] -match '^Généré le\s*: (?<date>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})$' )   # On ignore le résultat boolean car ce qui nous intéresse est stockés dans $Matches
          if ($Matches.date -eq $null)
          {
             throw "Impossible de récupérer la date de début d'exécution. Vérifiez que le fichier de log possède bien une entête de fichier."
          }
          $StartDate = [DateTime]$Matches.date
          $EndDate = Get-Date
          $EndDate_str = Get-Date $EndDate -UFormat "%Y/%m/%d %H:%M:%S"

          $duration_TotalSeconds = [int](New-TimeSpan -Start $StartDate -End $EndDate | Select-Object -ExpandProperty TotalSeconds)
          $duration_TotalMinutes = (New-TimeSpan -Start $StartDate -End $EndDate | Select-Object -ExpandProperty TotalMinutes)
          $duration_TotalMinutes = [MATH]::Round($duration_TotalMinutes, 2)
          $Message = @"
+----------------------------------------------------------------------------------------+

Fin: $EndDate_str
Temps écoulé (en secondes): $duration_TotalSeconds
Temps écoulé (en minutes ): $duration_TotalMinutes

+----------------------------------------------------------------------------------------+
"@
          # Création du fichier de log
          Add-Content -Path $Global:LogFile -Value $Message
          break
       }
   } # End switch

   if ($ToScreen)
   {
       Write-Host $Message -ForegroundColor $Color
   }
}