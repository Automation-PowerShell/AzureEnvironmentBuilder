$scriptname = "EnableHyperV.ps1"
$EventlogName = "Accenture"
$EventlogSource = "Enable Hyper-V Script"

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting $scriptname Install Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading NuGet module"
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading Az.Storage module"
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"    
Connect-AzAccount -identity -ErrorAction Stop -Subscription sssss

# Install Hyper-V
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Enable Hyper-V"
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

# Install Hyper-V Tools
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Enable Management Tools"
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

# Install RSAT
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Install RSAT Tools"
Install-WindowsFeature -Name RSAT-AD-Tools -IncludeAllSubFeature

# Install DHCP
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Install DHCP Tools"
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# Get Files from Blob
$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrrr -Name xxxxx
<#$Result1 = Get-AzStorageBlobContent -Container data -Blob "hyperv-vms.csv" -Destination "c:\Windows\temp\" -Context $StorAcc.context -Force
If ($Result1.Name -eq "hyperv-vms.csv") {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Successfully downloaded hyperv-vms.csv"
}
Else {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download hyperv-vms.csv"
}
$Result2 = Get-AzStorageBlobContent -Container data -Blob "Media/Vanilla-Windows10-Base+CERT.vhdx" -Destination "F:\Hyper-V\Virtual Hard Disks" -Context $StorAcc.context -Force
If ($Result2.Name -eq "Media/Vanilla-Windows10-Base+CERT.vhdx") {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Successfully downloaded Media/Vanilla-Windows10-Base+CERT.vhdx"
}
Else {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download Media/Vanilla-Windows10-Base+CERT.vhdx"
}#>
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
