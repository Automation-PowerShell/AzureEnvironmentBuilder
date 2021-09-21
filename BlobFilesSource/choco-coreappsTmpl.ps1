$app = "choco-coreapps"
$args = "install vcredist2013 vcredist140 adobereader 7zip.install googlechrome dotnet3.5 laps choco install azure-information-protection-unified-labeling-client choco install clickshare-desktop --limitoutput"

$EventLogName = "Accenture"
$EventLogSource = "$app Install Script"

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting $app Install Script"

# Install Process
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Installing Apps"
Start-Process -FilePath "C:\ProgramData\chocolatey\bin\choco.exe" -ArgumentList $args -Wait

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $app Install Script"