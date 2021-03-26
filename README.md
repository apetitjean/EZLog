[![Build status](https://ci.appveyor.com/api/projects/status/uk66ctiqlf8ntpb2?svg=true)](https://ci.appveyor.com/project/apetitjean/ezlog)

# EZLog
## A very easy and pragmatic PowerShell log module for admins in a hurry...  

The EZLog module is a **lightweight** set of functions aimed at providing **nice looking and professional log files**.
But wait! There's no need to recall multiple commands, everything is done with only one command : `Write-EZLog`.  
So anywhere in a script you need to write a log on disk or/and to display an information on your screen, all you need to do is just to call `Write-EZLog` along with your message.

That said, you also have these utility commands at your disposal:
- `ConvertFrom-EZLog` : convert a log file into an object. This could be very useful to parse logs in a directory or to convert a raw log file into a JSON file.
- `Invoke-EZLogRotation` : provide log rotation. You can trim the logs based on a number of files to keep or on a regular basis (daily, weekly, monthly or yearly).

**Note:** `Invoke-EZLogRotation` can also be used with whatever log files, it's not limited to rotate logs that have been created with this module.

EZLog allows to write timestamped and nice formatted logs with a header and footer.
It also allows to specify if the log entry being written is an info, a warning or an error.
   
The header contains the following information:
   - full script path of the caller,   
   - account under the script was run,  
   - computer name of the machine whose executed the script,  
   - and more...
The footer contains the elapsed time from the beginning of the log session.

Let show you a quick example of a result log file:

```Text
+----------------------------------------------------------------------------------------+
Script fullname          : C:\Users\Arnaud\Documents\GitRepo\Temp\script_example.ps1
When generated           : 2018-03-14 23:23:16
Current user             : DESKTOP-31O7OD0\Arnaud
Current computer         : DESKTOP-31O7OD0
Operating System         : Microsoft Windows 10 Entreprise 2016 LTSB 
OS Architecture          : 64 bits
+----------------------------------------------------------------------------------------+

2016-09-14 23:23:19; INF; This is a regular information message. Will be displayed in Cyan color in the console.
2016-09-14 23:23:20; WAR; This is a warning message. Will be displayed in Yellow color in the console.
2016-09-14 23:23:23; ERR; This is an error message. Will be displayed in red color in the console.

+----------------------------------------------------------------------------------------+
End time                 : 2018-03-14 23:23:25
Total duration (seconds) : 9
Total duration (minutes) : 0.15
+----------------------------------------------------------------------------------------+
```

Along with writing logs to a text file, you can also - if you want to - display the logs in the console. 
Each category of log event (Info, Warning, Error) has it's own color, so it's easy to distinguish errors or warnings among regular info messages.    

This is how it can look like in the console if you add the -ToScreen switch:
![ezlog_screenshot_01](https://cloud.githubusercontent.com/assets/10902523/23906931/d280dae8-08cf-11e7-868b-c0f737633e2a.png)

EZLog does not provide all the bells and whistles NxLog can offer, but instead **EZLog** is **very efficient** and super **mega easy to use**.

---
## How to use EZLog?

### EXAMPLE 1
   First thing to do is write a header and define a log file where the data will be written to. You have to specify the log file parameter on every command unless you use the `$PSDefaultParameterValues` variable as shown in example 2.

```PowerShell
   Write-EZLog -Header -LogFile C:\logs\mylogfile.log
```   
   Next, anywhere in your script when you need to write a log, do one of the folowing command:

```PowerShell
   Write-EZLog -Category INF -Message 'This is an info to be written in the log file'   -LogFile C:\logs\mylogfile.log
   Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file' -LogFile C:\logs\mylogfile.log
   Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'  -LogFile C:\logs\mylogfile.log
```

   Finaly, to close your logfile you need to write a footer, just do that:

```PowerShell
   Write-EZLog -Footer -LogFile C:\logs\mylogfile.log
```

This way you will get a nice footer on your log file and you also get the total duration of your script, which could be a valuable information in many cases!

### EXAMPLE 2
   To avoid specifying the parameters everytime you call `Write-EZLog`, you can use the `$PSDefaultParametersValue` variable of PowerShell.
   
   In addition, EZLog allows you to specify any delimiter character. So we can define it only once at the beginning of a script, like below:

```PowerShell
   $LogFile = 'C:\logs\mylogfile.log'
   $PSDefaultParameterValues = @{ 'Write-EZLog:LogFile'   = $LogFile ;
                                  'Write-EZLog:Delimiter' = ';'
                                }
   
   Write-EZLog -Header
   Write-EZLog -Category INF -Message 'This is an info to be written in the log file'
   Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file' 
   Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'
   Write-EZLog -Footer 
```

### EXAMPLE 3
   If you want to see the logs in the PowerShell console whereas they are still written to disk, 
   you can specify the `-ToScreen` switch.
   Info entries will be written in cyan color, Yellow for warnings, and Red for the errors.

```PowerShell
   $PSDefaultParameterValues = @{ 'Write-EZLog:LogFile'   = $LogFile ;
                                  'Write-EZLog:Delimiter' = ';' ;
                                  'Write-EZLog:ToScreen'  = $true }

   Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file'
```

### EXAMPLE 4
   `ConvertFrom-EZLog` is an utility function that is used to convert an EZLog file to a PowerShell object.

```PowerShell
   PS > $r = ConvertFrom-EZLog -Filepath C:\temp\logfile.log
   PS > $r

   Name   Value
   ----   -----
   Events {@{Date=3/30/2018 3:37:28 PM; Category=INF; Message=This is a test},...
   Footer {Duration, EndTime}
   Header {WhenGenerated, ScriptFullname, CurrentUser, CurrentComputer...}

   PS > $r.Header

    Name                           Value
    ----                           -----
    WhenGenerated                  3/30/2018 3:36:55 PM
    ScriptFullname                 C:\Temp\script_example.ps1
    CurrentUser                    DEVWK1\Arnaud
    CurrentComputer                DEVWK1
    OSArchitecture                 64-bit
    OperatingSystem                Microsoft Windows 10 Enterprise N


    PS > $r.footer

    Name                           Value
    ----                           -----
    Duration                       00:16:01
    EndTime                        3/30/2018 3:52:56 PM


    PS > $r.Events

    Date                 Category Message
    ----                 -------- -------
    3/30/2018 3:37:28 PM INF      This is a test
    3/30/2018 3:51:56 PM INF      This is a 2nd test
    3/30/2018 3:52:15 PM WAR      Attention needed!

```   

   As you can see, once a log file is converted into an object, it is super easy to manipulate the data without parsing the log with `Select-String` (grep equivalent).

### EXAMPLE 5
   `ConvertFrom-EZLog` combined with `ConvertTo-Json` could also be very useful.

```PowerShell
   PS > ConvertFrom-EZLog -Filepath C:\temp\logfile.log | ConverTo-Json
   {
    "Events":  [
                   {
                       "Date":  "\/Date(1522417048000)\/",
                       "Category":  "INF",
                       "Message":  "This is a test"
                   },
                   {
                       "Date":  "\/Date(1522417916000)\/",
                       "Category":  "INF",
                       "Message":  "This is a 2nd test"
                   },
                   {
                       "Date":  "\/Date(1522417935000)\/",
                       "Category":  "WAR",
                       "Message":  "Attention needed!"
                   }
               ],
    "Footer":  {
                   "Duration":  {
                                    "Ticks":  9610000000,
                                    "Days":  0,
                                    "Hours":  0,
                                    "Milliseconds":  0,
                                    "Minutes":  16,
                                    "Seconds":  1,
                                    "TotalDays":  0.011122685185185185,
                                    "TotalHours":  0.26694444444444443,
                                    "TotalMilliseconds":  961000,
                                    "TotalMinutes":  16.016666666666666,
                                    "TotalSeconds":  961
                                },
                   "EndTime":  "\/Date(1522417976000)\/"
               },
    "Header":  {
                   "WhenGenerated":  "\/Date(1522417015000)\/",
                   "ScriptFullname":  "C:\\Temp\\script_example.ps1",
                   "CurrentUser":  "DEVWK1\\Arnaud",
                   "CurrentComputer":  "DEVWK1",
                   "OSArchitecture":  "64-bit",
                   "OperatingSystem":  "Microsoft Windows 10 Enterprise N"
               }
}
```   

### EXAMPLE 6
   A log module without a good rotation cmdlet wouldn't be complete, this is why I implemented one ;-)

   To rotate logs means to remove old log files. The periodicity of the rotation is passed to the `-Interval` parameter. You can specify the folowing values : `daily`, `weekly`, `monthly`, `yearly`.  
   Instead of using `-Interval`, with `-Newest` you can simply specify the number of newest log files you want to keep.  

   Moreover instead of just swipe out the old log files, you can choose to archive them in a Zip file. This is done with the `-ArchiveTo` and `-OverwriteArchive` parameters. The first parameter is used to specify the Zip file you want to create. If there's an existing file the logs will be appended by default. If you specify the switch `-OverwriteArchive`, as the name suggests, an existing archive file would be overwritten.

```PowerShell
    PS > Invoke-EZLogRotation -Path C:\LogFiles\*.log -Newest 15 -ArchiveTo C:\LogFiles\archive.zip
```

Keep only the latest 15 newest *.log files in the C:\LogFiles directory. Before deletion, older files
will be archived into the C:\LogFiles\archive.zip.
If the archive.zip file already exists, logs will be appended to it.

### EXAMPLE 7
   In this example, we will only keep the *.log files of the month in the C:\LogFiles directory. Older files will be deleted.   

```PowerShell
    PS > Invoke-EZLogRotation -Path C:\LogFiles\*.log -Interval Monthly
```

---
## Prerequisites

Windows PowerShell v5+  
PowerShell Core v6+  
Well formated Brain ;-)