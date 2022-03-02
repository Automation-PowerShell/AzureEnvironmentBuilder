$scriptname = "Jumpbox.ps1"
$EventlogName = "Accenture"
$EventlogSource = "Jumpbox Config Script"

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

# Install Active Directory Tools
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Add Active Directory Tools Capability"
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

# Install GPMC
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Add GPMC Capability"
Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"