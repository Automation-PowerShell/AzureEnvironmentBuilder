$scriptname = "RunOnce.ps1"
$EventlogName = "Accenture"
$EventlogSource = "Configure RunOnce Script"

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting $scriptname Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading NuGet module"
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading Az.Storage module"
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"
Connect-AzAccount -identity -ErrorAction Stop -Subscription sssss

# Copy MapDrv.ps1 to local drive
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Atempting to download MapDrv.ps1 from Azure storage account to C:\Users\Public\Desktop"

$StorAcc = get-azstorageaccount -resourcegroupname rrrrr -name xxxxx
$Result = Get-AzStorageBlobContent -Container data -Blob "MapDrv.ps1" -destination "C:\Users\Public\Desktop" -context $StorAcc.context
If ($Result.Name -eq "MapDrv.ps1") {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "MapPackagingDrive" -Value "Powershell.exe -ExecutionPolicy Unrestricted -file `"C:\Users\Public\Desktop\MapDrv.ps1`"" -PropertyType "String"
}
Else {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message "Failed to download MapDrv.ps1 from Azure storage account to C:\Users\Public\Desktop"
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"