[![Build status](https://ci.appveyor.com/api/projects/status/uk66ctiqlf8ntpb2?svg=true)](https://ci.appveyor.com/project/apetitjean/ezlog)

# EZLog
## A very easy and pragmatic PowerShell log module for admins in a hurry.  

The EZLog module is a **lightweight** set of functions aimed at providing **nice looking and professional log files**.
But wait! There's no need to recall multiple commands, everything is done with only one command : **Write-EZLog**.

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
When generated           : 2016-09-14 23:23:16
Current user             : DESKTOP-31O7OD0\Arnaud
Current computer         : DESKTOP-31O7OD0
Operating System         : Microsoft Windows 10 Entreprise 2016 LTSB 
OS Architecture          : 64 bits
+----------------------------------------------------------------------------------------+

2016-09-14 23:23:19; INF; This is a regular information message. Will be displayed in Cyan color in the console.
2016-09-14 23:23:20; WAR; This is a warning message. Will be displayed in Yellow color in the console.
2016-09-14 23:23:23; ERR; This is an error message. Will be displayed in red color in the console.

+----------------------------------------------------------------------------------------+
End time                 : 2016-09-14 23:23:25
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
   First thing to do is write a header and define a log file where the data will be written.

```PowerShell
   Write-EZLog -Header -LogFile C:\logs\mylogfile.log
```   
   Next, anywhere in your script when you need to write a log, do one of the folowing command:

```PowerShell
   Write-EZLog -Category INF -Message 'This is an info to be written in the log file'
   Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file'
   Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'
```

   Finaly, to close your logfile you need to write a footer, just do that:

```PowerShell
   Write-EZLog -Footer
```
### EXAMPLE 2
   If you want to see the logs in the PowerShell console whereas they are still written to disk, 
   you can specify the -ToScreen switch.
   Info entries will be written in cyan color, Yellow for warnings, and Red for the errors.

```PowerShell
   Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file' -ToScreen
```

### EXAMPLE 3
   You can change the default delimiter (which is the one defined in the Regional Settings of Windows) by specifying the -Delimiter parameter explicity.

```PowerShell
   Write-EZLog -Header -LogFile C:\logs\mylogfile.log -Delimiter '`t'
```   

   In this example, we use the tab character.
  
---
## Prerequisites

Windows PowerShell v2+  
Well formated Brain.