$app = 'Tanium_Client_7.4.8.1042-1'
$zip = $false
$filename = 'TaniumClient-7.4.8.1042-1.windows.x86_64.exe'
$exefilename = 'TaniumClient-7.4.8.1042-1.windows.x86_64.exe'
$Argument = ''

$EventLogName = 'AEB'
$EventLogSource = "$app Install Script"

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource -ErrorAction SilentlyContinue
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Starting $app Install Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading NuGet module'
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading Az.Storage module'
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Attempting to connect to Azure'
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Copy zip file to local drive and install
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Atempting to download $app from Azure storage account to C:\Windows\Temp"

$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrrr -Name xxxxx
if ($zip) {
    $Result = Get-AzStorageBlobContent -Container data -Blob "./Media/$filename" -Destination 'c:\Windows\temp\' -Context $StorAcc.context -Force
    if ($Result.Name -eq "Media/$filename") {
        Expand-Archive -Path "C:\Windows\Temp\Media\$filename" -DestinationPath C:\Windows\Temp\Media\$app\ -Force
        Set-Location C:\Windows\Temp\Media\$app\
        if ($Argument -eq '') {
            Start-Process -FilePath $exefilename -Wait
        }
        else {
            Start-Process -FilePath $exefilename -ArgumentList $Argument -Wait
        }
    }
    else {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download $app"
    }
}
else {
    $Result = Get-AzStorageBlobContent -Container data -Blob "./Media/$filename" -Destination 'c:\Windows\temp\' -Context $StorAcc.context -Force
    if ($Result.Name -eq "Media/$filename") {
        Set-Location C:\Windows\Temp\Media\
        if ($Argument -eq '') {
            Start-Process -FilePath $exefilename -Wait
        }
        else {
            Start-Process -FilePath $exefilename -ArgumentList $Argument -Wait
        }
    }
    else {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download $app"
    }
}
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $app Install Script"