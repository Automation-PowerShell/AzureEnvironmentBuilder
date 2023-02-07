$scriptname = 'EnableDomainController3.ps1'
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
Install-Module -Name Az.Storage, Az.KeyVault -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Attempting to connect to Azure'
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Setting Up Domain
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Setting Up Domain'
$domain = 'ddddd'
$domain = $domain.Split('.')
New-ADOrganizationalUnit -Name 'EUC'
New-ADOrganizationalUnit -Name 'Users' -Path "OU=EUC,DC=$($domain[-2]),DC=$($domain[-1])"
New-ADOrganizationalUnit -Name 'Computers' -Path "OU=EUC,DC=$($domain[-2]),DC=$($domain[-1])"
New-ADOrganizationalUnit -Name 'Desktop' -Path "OU=Computers,OU=EUC,DC=$($domain[-2]),DC=$($domain[-1])"
New-ADOrganizationalUnit -Name 'Server' -Path "OU=Computers,OU=EUC,DC=$($domain[-2]),DC=$($domain[-1])"

# Adjusting Network Settings
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Adjusting Network Settings'
(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName 'localhost' -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0)
$vm = Get-AzVM -Name $env:COMPUTERNAME
$nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces.Id
$ip = $nic.IpConfigurations[0].PrivateIpAddress
$pip = $nic.IpConfigurations[0].PublicIpAddress
$subnet = Get-AzVirtualNetworkSubnetConfig -ResourceId $nic.IpConfigurations[0].Subnet.Id
$config = @{
    Name = 'ipconfig1'
    PrivateIpAddress = $ip
    PublicIPAddress = $pip
    Subnet = $subnet
}
$nic | Set-AzNetworkInterfaceIpConfig @config -Primary
$nic | Set-AzNetworkInterface

$vnet = Get-AzVirtualNetwork -Name $(($subnet.Id -split '/')[-3])
$iparray = @($ip)
$key = @{"DnsServers" = $iparray}
$vnet.DhcpOptions = $key
$vnet | Set-AzVirtualNetwork

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
