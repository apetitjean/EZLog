---
external help file: EZLog-help.xml
Module Name: EZLog
online version:
schema: 2.0.0
---

# Invoke-EZLogRotation

## SYNOPSIS
Clean up old log files in order to keep only the most recent ones.

## SYNTAX

### set1
```
Invoke-EZLogRotation [-Path] <String> [-Filter] <String> -Newest <Int32> [-ArchiveTo <String>]
 [-OverwriteArchive] [<CommonParameters>]
```

### set2
```
Invoke-EZLogRotation [-Path] <String> [-Filter] <String> [-Interval] <Interval> [-ArchiveTo <String>]
 [-OverwriteArchive] [<CommonParameters>]
```

## DESCRIPTION
Ancient logs files are either deleted or archived into a Zip file.

Options are available to specify how many newest files to keep. 
It's also possible to determine a time interval for the logs to keep (daily, monthly, yearly)

## EXAMPLES

### EXAMPLE 1
```
Invoke-EZLogRotation -Path C:\LogFiles\*.log -Newest 15
```

Only keeps the latest 15 newest *.log files in the C:\LogFiles directory.
Older files will be deleted.

### EXAMPLE 2
```
Invoke-EZLogRotation -Path C:\LogFiles\*.log -Newest 15 -ArchiveTo C:\LogFiles\archive.zip
```

Only keeps the latest 15 newest *.log files in the C:\LogFiles directory.
Before deletion, older files 
will be archived into the C:\LogFiles\archive.zip.
If the archive.zip file already exists, logs will be appended to it.

### EXAMPLE 3
```
Invoke-EZLogRotation -Path C:\LogFiles\*.log -Newest 15 -ArchiveTo C:\LogFiles\archive.zip -OverwriteArchive
```

Only keeps the latest 15 newest *.log files in the C:\LogFiles directory.
Before deletion, older files 
will be archived into the C:\LogFiles\archive.zip.
If the archive.zip file already exists it will be overwritten.

### EXAMPLE 4
```
Invoke-EZLogRotation -Path C:\LogFiles\*.log -Interval Daily
```

Only keeps the *.log files of the day in the C:\LogFiles directory.
Older files will be deleted.

### EXAMPLE 5
```
Invoke-EZLogRotation -Path C:\LogFiles\*.log -Interval Monthly
```

Only keeps the *.log files of the month in the C:\LogFiles directory.
Older files will be deleted.

### EXAMPLE 6
```
Invoke-EZLogRotation -Path C:\LogFiles\*.log -Interval Monthly -ArchiveTo C:\LogFiles\archive.zip -Overwrite
```

Only keeps the *.log files of the month in the C:\LogFiles directory.
Older files will be archived monthly.

### EXAMPLE 7
```
Invoke-EZLogRotation -Path C:\LogFiles\*.log -Interval Yearly
```

Only keeps the *.log files of the current year in the C:\LogFiles directory matching the pattern *.log.
Older files will be deleted.

## PARAMETERS

### -Path
Directory containing the logs to rotate.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Pattern to identify the logs to rotate.
Ex : *.log, *ezlog*.txt, etc.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Newest
Specify how many files to keep in the directory.
The files are sorted by the LastWriteTime attribute
and only the newest files determined by this parameter are kept.
Other files are deleted or archived.

```yaml
Type: Int32
Parameter Sets: set1
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interval
Specify the periodicy of the rotation.
Possible values are : Daily, Monthly, Yearly

Daily   : Keep only the logs of the day
Monthly : Keep only the logs of the month
Yearly  : Keep only the logs of the year

```yaml
Type: Interval
Parameter Sets: set2
Aliases:
Accepted values: Daily, Monthly, Yearly

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ArchiveTo
Indicate if the old logs need to be archived in a Zip before before deletion.

If not specified, old logs are deleted.

If specified, you must indicate a file path containing the .zip extension.
Eg.
: C:\logs\archive.zip

If the archive file already exists, logs will be append to it.
If you want to overwrite it you can use 
the -OverwriteArchive switch.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverwriteArchive
Works in association with -ArchiveTo.
If specified, it overwrites an archive if it already exists.

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
AUTHOR: Arnaud PETITJEAN
LASTEDIT: 2018/04/03

## RELATED LINKS
