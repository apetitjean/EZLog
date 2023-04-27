---
external help file: EZLog-help.xml
Module Name: EZLog
online version:
schema: 2.0.0
---

# Write-EZLog

## SYNOPSIS
Utility cmdlet to write logs to disk in an easy and pragmatic way.

## SYNTAX

### set2 (Default)
```
Write-EZLog [-Category] <MsgCategory> [-Message] <String> -LogFile <String> [-Delimiter <Char>] [-ToScreen]
 [<CommonParameters>]
```

### set1
```
Write-EZLog [-Header] -LogFile <String> [-Delimiter <Char>] [-ToScreen] [<CommonParameters>]
```

### set3
```
Write-EZLog [-Footer] -LogFile <String> [-Delimiter <Char>] [-ToScreen] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet allows to write timestamped and nice formatted logs with a header and footer. 
It also allows to specify if the log entry being written is an info, a warning or an error.

The header contains the following information :
    - full script path of the caller, 
    - account under the script was run,
    - computer name of the machine whose executed the script,
    - and more...
The footer contains the elapsed time from the beginning of the log session.

## EXAMPLES

### EXAMPLE 1
```
First thing to do is write a header and define a log file where the data will be written.
```

Write-EZLog -Header -LogFile C:\logs\mylogfile.log

Next, anywhere in your script when you need to write a log, do one of the folowing command:

Write-EZLog -Category INF -Message 'This is an info to be written in the log file'
Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file'
Write-EZLog -Category ERR -Message 'This is an error to be written in the log file'

Finaly, to close your logfile you need to write a footer, just do that:

Write-EZLog -Footer

### EXAMPLE 2
```
If you want to see the logs in the PowerShell console whereas they are still written to disk, 
you can specify the -ToScreen switch.
Info entries will be written in cyan color, Yellow for warnings, and Red for the errors.
```

Write-EZLog -Category WAR -Message 'This is a warning to be written in the log file' -ToScreen

## PARAMETERS

### -Category
Category can be one of the following value : INF, WAR, ERR

```yaml
Type: MsgCategory
Parameter Sets: set2
Aliases:
Accepted values: INF, WAR, ERR

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Message
Specify the content of the data to log.

```yaml
Type: String
Parameter Sets: set2
Aliases: Msg

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Header
Mandatory switch to start a log session.

```yaml
Type: SwitchParameter
Parameter Sets: set1
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Footer
Mandatory switch to end a log session.
If you omit to close your log session, you won't know how much time 
your script was running.

```yaml
Type: SwitchParameter
Parameter Sets: set3
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogFile
Path to the log file to be created.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Delimiter
Specify a delimiter to be used in order to separate the fields in a log entry. 

```yaml
Type: Char
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $( if ((Get-Culture).TextInfo.ListSeparator -eq ' ')  {','} else {(Get-Culture).TextInfo.ListSeparator})
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToScreen
Displays the logs in the log file and in the console.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
AUTHOR: Arnaud PETITJEAN - arnaud@powershell-scripting.com
LASTEDIT: 2023/04/27

## RELATED LINKS
