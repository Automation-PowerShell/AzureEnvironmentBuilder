$scriptname = 'EnableDomainController.ps1'
$EventlogName = 'AEB'
$EventlogSource = 'Enable Domain Controller Script'

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource -ErrorAction SilentlyContinue
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Starting $scriptname Install Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading NuGet module'
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading Az.Storage module'
Install-Module -Name Az.Storage, Az.KeyVault -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Attempting to connect to Azure'
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Enable Domain Controller Role
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Enable Domain Controller'
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
