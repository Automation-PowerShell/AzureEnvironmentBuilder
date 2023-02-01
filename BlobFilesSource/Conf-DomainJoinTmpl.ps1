$Domain = 'ddddd'
$OUPath = 'ooooo'

$scriptname = 'DomainJoin.ps1'
$EventlogName = 'Accenture'
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
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading Az.Storage module'
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Attempting to connect to Azure'
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Copy files to machine
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Atempting to download DomainJoin.xml from Azure storage account to C:\Windows\Temp'
$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrrr -Name xxxxx
$passwordFile = Get-AzStorageBlobContent -Container data -Blob './DomainJoin.xml' -Destination 'c:\Windows\temp\' -Context $StorAcc.context
$keyFile = Get-AzStorageBlobContent -Container data -Blob './my.key' -Destination 'c:\Windows\temp\' -Context $StorAcc.context
$myKey = Get-Content 'c:\Windows\Temp\my.key'

# Create Credential
$DJUser = 'wella\svc_PackagingDJ'
$DJPassword = Import-Clixml c:\Windows\temp\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
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
