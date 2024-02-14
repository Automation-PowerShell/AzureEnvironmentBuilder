$scriptname = 'Conf-Accenture-Policy-Compliance.ps1'
$scriptfile = 'Conf-Accenture-Policy-Compliance-Script.ps1'
$EventlogName = 'AEB'
$EventlogSource = 'Configure Accnture Policy Compliance'

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource -ErrorAction SilentlyContinue
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Starting $scriptname Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading NuGet module'
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading Az.Storage module'
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Attempting to connect to Azure'
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Copy $scriptfile to local drive
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Atempting to download $scriptfile from Azure storage account to C:\Windows\Temp"

$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrrr -Name xxxxx
$Result = Get-AzStorageBlobContent -Container data -Blob $scriptfile -Destination 'C:\Windows\Temp' -Context $StorAcc.context -Force
if ($Result.Name -eq $scriptfile) {
    . C:\Windows\Temp\$scriptfile
}
else {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download $scriptfile from Azure storage account to C:\Windows\Temp"
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"