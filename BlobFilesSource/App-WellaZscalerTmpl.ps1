$app = 'Zscaler_3.2.0.87_x86_R01'
$zip = $true
$filename = 'Zscaler_3.2.0.87_x86_R01.zip'
$exefilename = '.\Install.ps1'

$EventLogName = 'AEB'
$EventLogSource = "$app Install Script"

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
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
    $Result = Get-AzStorageBlobContent -Container data -Blob "./Media/$filename" -Destination 'c:\Windows\temp\' -Context $StorAcc.context
    If ($Result.Name -eq "Media/$filename") {
        Expand-Archive -Path "C:\Windows\Temp\Media\$filename" -DestinationPath C:\Windows\Temp\Media\ -Force
        Set-Location C:\Windows\Temp\Media\$app\
        . .\$exefilename
    }
    Else {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download $app"
    }
}
else {
    $Result = Get-AzStorageBlobContent -Container data -Blob "./Media/$filename" -Destination 'c:\Windows\temp\' -Context $StorAcc.context
    If ($Result.Name -eq "Media/$filename") {
        Set-Location C:\Windows\Temp\Media\
        . .\$exefilename
    }
    Else {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download $app"
    }
}
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $app Install Script"