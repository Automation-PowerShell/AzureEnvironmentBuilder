$scriptname = "VMConfig.ps1"
$EventlogName = "Accenture"
$EventlogSource = "VM Configure Script"

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting $scriptname Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading NuGet module"
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading Az.Storage module"
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"
Connect-AzAccount -identity -ErrorAction Stop -Subscription sssss

# Copy files to machine
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Atempting to download HyperVLocalAdmin.xml from Azure storage account to C:\Windows\Temp"
$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrrr -Name xxxxx
$passwordFile = Get-AzStorageBlobContent -Container data -Blob "./HyperVLocalAdmin.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
$keyFile = Get-AzStorageBlobContent -Container data -Blob "./my.key" -Destination "c:\Windows\temp\" -Context $StorAcc.context
$myKey = Get-Content "c:\Windows\Temp\my.key"

# Create Local User Account
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Adding Standard User - eucuser"
$user = Get-LocalUser -Name eucuser -ErrorAction SilentlyContinue
$password = Import-Clixml c:\Windows\temp\HyperVLocalAdmin.xml | ConvertTo-SecureString -Key $myKey
if(!($user)) {
    $newuser = New-LocalUser -Name eucuser -AccountNeverExpires -Password $password -PasswordNeverExpires -UserMayNotChangePassword
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member $newuser
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
