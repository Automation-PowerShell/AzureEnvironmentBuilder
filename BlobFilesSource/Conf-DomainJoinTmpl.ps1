$Domain = 'ddddd'
$OUPath = 'ooooo'

$scriptname = 'DomainJoin.ps1'
$EventlogName = 'AEB'
$EventlogSource = 'VM Domain Join Script'

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Starting $scriptname Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading NuGet module'
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading Az Modules'
Install-Module -Name Az.Storage, Az.KeyVault -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Attempting to connect to Azure'
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Create Credential
$DJUser = 'ddddd\AppPackager'
$DJPassword = (Get-AzKeyVaultSecret -VaultName kkkkk -Name 'DomainJoin').SecretValue
$DomainJoinCred = New-Object System.Management.Automation.PSCredential ($DJUser, $DJPassword)

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Joining Domain'
Disable-NetAdapterBinding -Name '*' -ComponentID ms_tcpip6
$joined = $false
$attempts = 0
while ($joined -eq $false) {
    $joined = $true
    $attempts++
    try {
        Add-Computer -DomainName $Domain -Credential $DomainJoinCred -OUPath $OUPath -Restart -Verbose -ErrorAction Stop
    }
    catch {
        $joined = $false
        if ($attempts -eq 20) {
            Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
            break
        }
        Start-Sleep -Seconds 5
    }
}
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
