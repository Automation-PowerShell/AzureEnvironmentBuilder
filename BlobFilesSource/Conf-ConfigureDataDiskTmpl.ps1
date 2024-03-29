﻿$scriptname = 'ConfigureDataDisk.ps1'
$EventlogName = 'AEB'
$EventlogSource = 'VM Configure Data Disk Script'

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    break
}

New-EventLog -LogName $EventlogName -Source $EventlogSource -ErrorAction SilentlyContinue
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"

$disks = Get-Disk | Where-Object partitionstyle -EQ 'raw' | Sort-Object number
$disks |
Initialize-Disk -PartitionStyle MBR -PassThru |
New-Partition -UseMaximumSize -DriveLetter 'F' |
Format-Volume -FileSystem NTFS -NewFileSystemLabel 'data1' -Confirm:$false -Force

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"