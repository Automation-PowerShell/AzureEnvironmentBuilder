$app = "AdminStudio"
$zip = $false
$filename = "AdminStudio2020R2SP1.exe"
$exefilename = "AdminStudio2020R2SP1.exe"
$Argument = "/silent"

$EventlogName = "Accenture"
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
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting VM AdminStudio Build Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading NuGet module"
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading Az.Storage module"
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"    
Connect-AzAccount -identity -ErrorAction Stop -Subscription ssss

# Copy AdminStudio exe to local drive and install
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Atempting to download $app from Azure storage account to C:\Windows\Temp"
$StorAcc = get-azstorageaccount -resourcegroupname rrrr -name xxxx
$Result = Get-AzStorageBlobContent -Container data -Blob "./Media/$filename" -destination "c:\Windows\temp\" -context $StorAcc.context
If ($Result.Name -eq "Media/$filename") {
    cd C:\Windows\Temp\Media\
    Start-Process -FilePath "$exefilename" -ArgumentList $Argument -Wait -ErrorAction Stop
}
Else {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message "Failed to download $app"
}
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $app Install Script"