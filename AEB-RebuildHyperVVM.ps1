<#
.SYNOPSIS
AEB-RebuildHyperVVM.ps1

.DESCRIPTION
Azure Environment Builder - Rebuild HyperV VM.
Wrtitten by Graham Higginson and Daniel Ames.

.NOTES
Written by      : Graham Higginson & Daniel Ames
Build Version   : v2

.LINK
More Info       : https://github.com/Automation-PowerShell/AzureEnvironmentBuilder
#>

Param(
    [Parameter(Mandatory = $false)][string]$RVMVMName = ""
)

#region Setup
Set-Location $PSScriptRoot

#$azSubscription = "743e9d63-59c8-42c3-b823-28bb773a88a6"       # Visual Studio Professional
$azSubscription = "7660dc8a-b807-45fd-817f-a5df6f70204b"        # Visual Studio Professional Subscription 2
$VaultName = "keyvault-dames10"
$Domain = "space"
$OUPath = "OU=Workstations,OU=Computers,OU=Space,DC=space,DC=dan"
$RGNameSTORE = "rg-euc-packaging-store"                         # Storage Account Resource Group name
$StorageAccountName = "storageeucpackaging10"                   # Storage account name (if used) (24 chars maximum)

$HyperVLocalAdminUser = "administrator"
$DomainJoinUser = "wella\svc_PackagingDJ"
$DomainUserUser = "wella\T1-Daniel.Ames"

$scriptname = "RebuildHyperVVM.ps1"                             # This file's filename
$EventlogName = "Accenture"                                     # Event Log Folder Name
$EventlogSource = "Hyper-V VM Rebuild Script"                   # Event Log Source Name

$VMDrive = "F:"                                                 # Specify the root disk drive to use
$VMFolder = "Hyper-V"
$VMMachineFolder = "Virtual Machines"                           # Specify the folder to store the VM data
$VHDFolder = "Virtual Hard Disks"                               # Specify the folder to store the VHDs
$VMCheckpointFolder = "Checkpoints"                             # Specify the folder to store the Checkpoints
$VmNamePrefix = "EUC-UAT-"
$VMRamSize = 4GB
$VMVHDSize = 100GB
$VMCPUCount = 4
$VMSwitchName = "Packaging Switch"
Try {$VMHostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet").IPAddress}
Catch {$VMHostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet 2").IPAddress}

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
Install-Module -Name Az.Storage,Az.KeyVault -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"
Connect-AzAccount -identity -ErrorAction Stop -Subscription $azSubscription

# Get Storage Account Key
$Keys = Get-AzStorageAccountKey -ResourceGroupName $RGNameSTORE -AccountName $StorageAccountName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
$StorageAccountKey = $Keys.value[0]

# Get Passwords from KeyVault
$LocalAdminPassword = (Get-AzKeyVaultSecret -VaultName $VaultName -Name "HyperVLocalAdmin").SecretValue
$LocalAdminCred = New-Object System.Management.Automation.PSCredential ($HyperVLocalAdminUser, $LocalAdminPassword)
$DomainJoinPassword = (Get-AzKeyVaultSecret -VaultName $VaultName -Name "DomainJoin").SecretValue
$DomainJoinCred = New-Object System.Management.Automation.PSCredential ($DomainJoinUser, $DomainJoinPassword)
$DomainUserPassword = (Get-AzKeyVaultSecret -VaultName $VaultName -Name "DomainUser").SecretValue
$DomainUserCred = New-Object System.Management.Automation.PSCredential ($DomainUserUser, $DomainUserPassword)

if(!$DomainUserCred) {
    exit
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Importing Hyper-V Module"
Import-Module Hyper-V -Force -ErrorAction Stop
#endregion Setup

function Delete-VM {
    Param([Parameter(Mandatory = $true)][string]$VMName)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
        break
    }
    #$VMName = "$VmNamePrefix$VmNumber"
    $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue | Select-Object *

    if($VM) {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Removing VM $VMName"
        if($VM.State -eq "Running") {
            Stop-VM -Name $VMName -Force -TurnOff -Verbose -ErrorAction Stop
        }
        Remove-VM -Name $VMName -Force -Verbose -ErrorAction Stop
        Remove-Item -Path "$VMDrive\$VMFolder\$VMMachineFolder\$VMName" -Recurse -Force
        Remove-Item -Path "$VMDrive\$VMFolder\$VHDFolder\$VMName" -Recurse -Force
    }
}

function Create-VM {
    Param([Parameter(Mandatory = $true)][string]$VMName)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
        break
    }
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM $VMName"

    $VM = @{
        Name = $VMName
        MemoryStartupBytes = $VMRamSize
        Generation = 1
        BootDevice = "VHD"
        Path = "$VMDrive\$VMFolder\$VMMachineFolder\$VMName"
        SwitchName = (Get-VMSwitch -Name $VMSwitchName).Name
    }

    $VMObject = New-VM @VM -NoVHD -Verbose -ErrorAction Stop
    Convert-VHD -Path $VMDrive\$VMFolder\Media\base-100.vhdx -DestinationPath $VMDrive\$VMFolder\$VHDFolder\$VMName\$VMName.vhdx -VHDType Dynamic -Verbose

    $VMObject | Set-VM -ProcessorCount $VMCPUCount
    $VMObject | Set-VM -StaticMemory
    $VMObject | Set-VM -AutomaticCheckpointsEnabled $false
    $VMObject | Set-VM -SnapshotFileLocation "$VMDrive\$VMFolder\$VMCheckpointFolder"
    $VMObject | Add-VMHardDiskDrive -Path $VMDrive\$VMFolder\$VHDFolder\$VMName\$VMName.vhdx

    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format HH:mm
    $VMObject | Checkpoint-VM -SnapshotName "Base Config ($Date - $Time)"
    $VMObject | Start-VM -Verbose -ErrorAction Stop

        # Pre Domain Join
    Start-Sleep -Seconds 180
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
        Get-AppxPackage -Name Microsoft.MicrosoftOfficeHub | Remove-AppxPackage
        Rename-Computer -NewName $Using:VMName -LocalCredential $Using:LocalAdminCred -Restart -Verbose
    }
    if($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }
    Start-Sleep -Seconds 90
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
            # Enable Remote Desktop
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        #net localgroup "Remote Desktop Users" /add "Domain Users"

            # Autopilot Hardware ID
        New-Item -Type Directory -Path "C:\HWID" -Force
        Set-Location -Path "C:\HWID"
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -ErrorAction Stop
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
        Install-Script -Name Get-WindowsAutoPilotInfo -Force -ErrorAction Stop
        Get-WindowsAutoPilotInfo.ps1 -OutputFile AutoPilotHWID.csv

            # Map Packaging Share
        cmd.exe /C cmdkey /add:`"$Using:StorageAccountName.file.core.windows.net`" /user:`"Azure\$Using:StorageAccountName`" /pass:`"$Using:StorageAccountKey`"
        New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$Using:StorageAccountName.file.core.windows.net\pkgazfiles01" -Persist

            # Upload AutoPilotHWID
        mkdir -Path "Z:\EUC Applications\Packaging Environment Build Files\Autpilot IDs" -Name $env:COMPUTERNAME -Force
        Copy-Item -Path "C:\HWID\AutoPilotHWID.csv" -Destination "Z:\EUC Applications\Packaging Environment Build Files\Autpilot IDs\$env:COMPUTERNAME" -Force
    }
    if($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

        # Join Domain
    Start-Sleep -Seconds 10
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
        Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6
        $joined=$false
        $attempts = 0
        while($joined -eq $false) {
            $joined = $true
            $attempts++
            try {
                Add-Computer -LocalCredential $Using:LocalAdminCred -DomainName $Using:Domain -Credential $Using:DomainJoinCred -Restart -Verbose -ErrorAction Stop -OUPath $Using:OUPath
                # -NewName $CP -OUPath $OU
            } catch {
                $joined = $false
                Write-Output $_.Exception.Message
                if($attempts -eq 20) {
                    throw "Cannot Join the Domain"
                    break
                }
                Start-Sleep -Seconds 5
            }
        }
    }
    if($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

        # Post Domain Join
    Start-Sleep -Seconds 90
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $DomainUserCred -ErrorVariable erroric -ScriptBlock {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        net localgroup "Remote Desktop Users" /add "Domain Users"
    }
    if($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format HH:mm
    $VMObject | Checkpoint-VM -SnapshotName "Domain Joined ($Date - $Time)"
    $VMNumber = $VMName.Trim($VmNamePrefix)
    $MACAddress = $VMObject.NetworkAdapters.MacAddress
    $IPAddress = (Get-DhcpServerv4Scope | Get-DhcpServerv4Lease | Where-Object {($_.ClientId -replace "-") -eq $MACAddress}).IPAddress.IPAddressToString
    if(!(Get-NetNatStaticMapping -NatName LocalNAT | Where-Object {$_.ExternalPort -like "*$VMNumber"})) {
        Add-NetNatStaticMapping -ExternalIPAddress "0.0.0.0" -ExternalPort 55$VMNumber -InternalIPAddress $IPAddress -InternalPort 3389 -NatName LocalNAT -Protocol TCP -ErrorAction Stop | Out-Null
    }
    else {
        Get-NetNatStaticMapping -NatName LocalNAT | Where-Object {$_.ExternalPort -like "*$VMNumber"} | Remove-NetNatStaticMapping -Confirm:$false | Out-Null
        Add-NetNatStaticMapping -ExternalIPAddress "0.0.0.0" -ExternalPort 55$VMNumber -InternalIPAddress $IPAddress -InternalPort 3389 -NatName LocalNAT -Protocol TCP -ErrorAction Stop | Out-Null
    }

    $DHCPScope = Get-DhcpServerv4Scope
    Add-DhcpServerv4Reservation -ScopeId $DHCPScope.ScopeId -IPAddress $IPAddress -ClientId $MACAddress -Description "Reservation for UAT device"
}

#region Main
Write-Output "Running AEB-RebuildHyperVVM.ps1"
if($RVMVMName -eq "") {
    $VMList = Get-VM -Name * | Select-Object Name, Uptime, State
    #$VMList = $VMListData
    $RVMVMName = ($VMList | Where-Object { $_.Name -like "$VmNamePrefix*" } | Out-GridView -Title "Select Virtual Machine to Rebuild" -OutputMode Single).Name
}

Write-Output "Rebuilding $RVMVMName"
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Rebuilding $RVMVMName VM"
Delete-VM -VMName $RVMVMName
Create-VM -VMName $RVMVMName
#Get-NetNatStaticMapping | select StaticMappingID,ExternalIPAddress,ExternalPort,InternalIPAddress,InternalPort | ConvertTo-JSON | Out-File -FilePath ".\netnatmapping.json"-Force
Get-NetNatStaticMapping | Select-Object StaticMappingID,ExternalIPAddress,ExternalPort,InternalIPAddress,InternalPort | Export-CSV -Path ".\netnatmapping.csv" -Force -NoTypeInformation
Write-Output "Completed AEB-RebuildHyperVVM.ps1"
#endregion Main

#region Old Code
    # Dot Source Variables
#. .\ScriptVariables.ps1
#. .\ClientLoadVariables.ps1

    # For Static IP Configuration
#$IPAddress = ""
#$IPSubnetPrefix = "24"
#$IPGateway = "192.168.0.1"
#$IPDNS = @("10.21.224.10","10.21.224.11","10.21.239.196")

    # Static IP Addresses
#$NetAdapter = Get-NetAdapter -Physical | where {$_.Status -eq "Up"}
#if (($NetAdapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
#    $NetAdapter | Remove-NetIPAddress -AddressFamily IPv4 -Confirm:$false
#}
#if (($NetAdapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
#    $NetAdapter | Remove-NetRoute -AddressFamily IPv4 -Confirm:$false
#}
#$NetAdapter | New-NetIPAddress -AddressFamily IPv4 -IPAddress $Using:IPAddress -PrefixLength $Using:IPSubnetPrefix -DefaultGateway $Using:IPGateway | Out-Null
#$NetAdapter | Set-DnsClientServerAddress -ServerAddresses $Using:IPDNS | Out-Null
#Start-Sleep -Seconds 60
#if(!(Test-Connection $VMHostIP -Quiet)) { Write-Error "Networking Issue" }
#if(!(Test-Connection "google.com" -Quiet)) { Write-Error "DNS Issue" }

    # Remote Desktop Config
#netsh advfirewall firewall add rule name="allow RemoteDesktop" dir=in protocol=TCP localport=3389 action=allow
#New-NetFirewallRule -DisplayName "Restrict_RDP_access" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress 192.168.1.0/24,192.168.2.100 -Action Allow
#Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1

    # Add Windows Capibilities Back In
#Add-WindowsCapability -Online -Name Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0
#Add-WindowsCapability -Online -Name App.StepsRecorder~~~~0.0.1.0
#Add-WindowsCapability -Online -Name Microsoft.Windows.Notepad~~~~0.0.1.0
#Add-WindowsCapability -Online -Name Microsoft.Windows.MSPaint~~~~0.0.1.0
#Add-WindowsCapability -Online -Name Microsoft.Windows.WordPad~~~~0.0.1.0

    # Map Packaging Share
#$source = "X:\EUC Applications\Packaging Environment Build Files\Prevision"
#Copy-Item -Path $source\MapDrv.ps1 -Destination "C:\Users\Public\Desktop" -Force
#New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "MapPackagingDrive" -Value "Powershell.exe -ExecutionPolicy Unrestricted -file `"C:\Users\Public\Desktop\MapDrv.ps1`"" -PropertyType "String"

#endregion Old Code