$scriptname = 'EnableDomainController2.ps1'
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
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading Az Modules'
Install-Module -Name Az.Storage, Az.KeyVault, Az.Network, Az.Compute -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Attempting to connect to Azure'
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Enable Domain Controller Role
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Enable Domain Controller 2'
$domain = 'ddddd'
$domainSplit = $domain.Split('.')
$LocalAdminPassword = (Get-AzKeyVaultSecret -VaultName kkkkk -Name 'HyperVLocalAdmin').SecretValue
Import-Module ADDSDeployment
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath 'C:\Windows\NTDS' -DomainMode 'WinThreshold' -DomainName $domain -DomainNetbiosName $($domainSplit[-2]) -ForestMode 'WinThreshold' -InstallDns:$true -LogPath 'C:\Windows\NTDS' -NoRebootOnCompletion:$true -SysvolPath 'C:\Windows\SYSVOL' -Force:$true -SafeModeAdministratorPassword $LocalAdminPassword

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
