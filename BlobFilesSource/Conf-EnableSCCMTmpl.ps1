$scriptname = 'EnableHyperV.ps1'
$EventlogName = 'Accenture'
$EventlogSource = 'Enable Hyper-V Script'

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
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
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Configuring System'
#$LocalAdminPassword = (Get-AzKeyVaultSecret -VaultName kkkkk -Name 'HyperVLocalAdmin').SecretValue
Install-WindowsFeature -Name RDC
# Post Steps
# Install SQL Server
# Change SQL Logon to LocalSystem
# Install ADK components


Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
