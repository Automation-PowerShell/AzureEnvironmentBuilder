#region Setup
Set-Location $PSScriptRoot

$scriptname = 'Build-VMBase.ps1'                                # This file's filename
$EventlogName = 'Accenture'                                     # Event Log Folder Name
$EventlogSource = 'Hyper-V VM Base Build Script'                # Event Log Source Name

$VMDrive = 'F:'                                                 # Specify the root disk drive to use
$VMFolder = 'Hyper-V'                                           # Specify the root folder to use
$VMMachineFolder = 'Virtual Machines'                           # Specify the folder to store the VM data
$VHDFolder = 'Virtual Hard Disks'                               # Specify the folder to store the VHDs
$VMCheckpointFolder = 'Checkpoints'                             # Specify the folder to store the Checkpoints
$VMCount = 1                                                    # Specify number of VMs to be provisioned
$VmNamePrefix = 'BASE-'                                         # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 100                                            # Specifies the second part of the VM name (usually numeric)
$VMRamSize = 4GB
$VMVHDSize = 60GB
$VMCPUCount = 4
$VMSwitchName = 'Packaging Switch'
$VMNetNATName = 'LocalNAT'
$VMNetNATPrefix = '192.168.0.0/24'
$VMNetNATHost = '192.168.0.1'
$VMNetNATPrefixLength = 24
$VMHostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Ethernet').IPAddress

$Domain = 'ddddd'
$OUPath = 'ooooo'
$TempFileStore = 'C:\Windows\Temp'
#endregion Setup

function Delete-VM {
    Param([Parameter(Mandatory)][int]$VmNumber)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
        break
    }
    $VMName = "$VmNamePrefix$VmNumber"
    $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue | Select-Object *

    if ($VM) {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Removing VM $VMName"
        if ($VM.State -eq 'Running') {
            Stop-VM -Name $VMName -Force -TurnOff -Verbose -ErrorAction Stop
        }
        Remove-VM -Name $VMName -Force -Verbose -ErrorAction Stop
        Remove-Item -Path "$VMDrive\$VMFolder\$VMMachineFolder\$VMName" -Recurse -Force
        Remove-Item -Path "$VMDrive\$VMFolder\$VHDFolder\$VMName" -Recurse -Force
    }
}

function Create-VM {
    Param([Parameter(Mandatory = $true)][int]$VmNumber)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
        break
    }
    $VMName = "$VmNamePrefix$VmNumber"
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM $VMName"

    $VM = @{
        Name               = $VMName
        MemoryStartupBytes = $VMRamSize
        Generation         = 1
        BootDevice         = 'CD'
        Path               = "$VMDrive\$VMFolder\$VMMachineFolder\$VMName"
        SwitchName         = (Get-VMSwitch -Name $VMSwitchName).Name
    }

    $VMObject = New-VM @VM -NoVHD -Verbose -ErrorAction Stop

    New-Item -Path $VMDrive\$VMFolder\$VHDFolder\ -Name $VMName -ItemType Directory -Force -Verbose | Out-Null
    #Copy-Item -Path $VMDrive\$VMFolder\Media\basedisk.vhdx -Destination $VMDrive\$VMFolder\$VHDFolder\$VMName\$VMName.vhdx -Force -Verbose
    Convert-VHD -Path $VMDrive\$VMFolder\Media\basedisk.vhdx -DestinationPath $VMDrive\$VMFolder\$VHDFolder\$VMName\$VMName.vhdx -VHDType Dynamic -Verbose

    $VMObject | Set-VM -ProcessorCount $VMCPUCount
    $VMObject | Set-VM -StaticMemory
    $VMObject | Set-VM -CheckpointType Disabled
    $VMObject | Set-VM -SnapshotFileLocation "$VMDrive\$VMFolder\$VMCheckpointFolder"
    $VMObject | Add-VMHardDiskDrive -Path $VMDrive\$VMFolder\$VHDFolder\$VMName\$VMName.vhdx

    $VMObject | Start-VM -Verbose -ErrorAction Stop
    Start-Sleep -Seconds 720

    # VM Customisations
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
        # Cleanup and Rename Host
        Get-AppxPackage -Name Microsoft.MicrosoftOfficeHub | Remove-AppxPackage
        Rename-Computer -NewName $Using:VMName -LocalCredential $Using:LocalAdminCred -Restart -Verbose
    }
    if ($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    }

    Start-Sleep -Seconds 120
    $MACAddress = $VMObject.NetworkAdapters.MacAddress
    $IPAddress = (Get-DhcpServerv4Scope | Get-DhcpServerv4Lease | Where-Object { ($_.ClientId -replace '-') -eq $MACAddress }).IPAddress.IPAddressToString
    if (!(Get-NetNatStaticMapping -NatName $VMNetNATName -ErrorAction SilentlyContinue | Where-Object { $_.ExternalPort -like "*$VMNumber" })) {
        Add-NetNatStaticMapping -ExternalIPAddress '0.0.0.0' -ExternalPort 55$VMNumber -InternalIPAddress $IPAddress -InternalPort 3389 -NatName $VMNetNATName -Protocol TCP -ErrorAction Continue | Out-Null
    }
    $VMObject | Stop-VM -Force -TurnOff -Verbose -ErrorAction Stop

    Start-Sleep -Seconds 180
    Convert-VHD -Path $VMDrive\$VMFolder\$VHDFolder\$VMName\$VMName.vhdx -DestinationPath $VMDrive\$VMFolder\Media\$VMName.vhdx -VHDType Dynamic -Verbose
}

#region Main
# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource -ErrorAction SilentlyContinue
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading NuGet module'
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading Az.Storage module'
Install-Module -Name Az.Storage, Az.KeyVault -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Attempting to connect to Azure'
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Get Passwords from KeyVault
$LocalAdminPassword = (Get-AzKeyVaultSecret -VaultName 'kkkkk' -Name 'HyperVLocalAdmin').SecretValue
$LocalAdminCred = New-Object System.Management.Automation.PSCredential ('aaaaa', $LocalAdminPassword)
$DomainJoinPassword = (Get-AzKeyVaultSecret -VaultName 'kkkkk' -Name 'DomainJoin').SecretValue
$DomainJoinCred = New-Object System.Management.Automation.PSCredential ('jjjjj', $DomainJoinPassword)
$DomainUserPassword = (Get-AzKeyVaultSecret -VaultName 'kkkkk' -Name 'DomainUser').SecretValue
$DomainUserCred = New-Object System.Management.Automation.PSCredential ('uuuuu', $DomainUserPassword)

<#    # Copy files to machine
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Atempting to download DomainJoin.xml from Azure storage account to $TempFileStore"
$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrrr -Name xxxxx
Get-AzStorageBlobContent -Container data -Blob "./HyperVLocalAdmin.xml" -Destination "$TempFileStore" -Context $StorAcc.context
Get-AzStorageBlobContent -Container data -Blob "./my.key" -Destination "$TempFileStore" -Context $StorAcc.context
$myKey = Get-Content "$TempFileStore\my.key"

    # Create Credential
$LocalAdminUser = "DESKTOP-7O8HROP\administrator"
$LocalAdminPassword = Import-Clixml $TempFileStore\HyperVLocalAdmin.xml | ConvertTo-SecureString -Key $myKey
$LocalAdminCred = New-Object System.Management.Automation.PSCredential ($LocalAdminUser, $LocalAdminPassword)
#>
# Import Hyper-V Module
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Importing Hyper-V Module'
Import-Module Hyper-V -Force -ErrorAction Stop

# Create Switch
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Creating VM Switch'
$VMSwitch = Get-VMSwitch -Name $VMSwitchName
if (!$VMSwitch) {
    New-VMSwitch -Name $VMSwitchName -SwitchType Internal -ErrorAction Stop
    #New-VMSwitch -Name $VMSwitchName -NetAdapterName "Ethernet"
}
New-NetNat -Name $VMNetNATName -InternalIPInterfaceAddressPrefix $VMNetNATPrefix
Get-NetAdapter "vEthernet ($VMSwitchName)" | New-NetIPAddress -IPAddress $VMNetNATHost -AddressFamily IPv4 -PrefixLength $VMNetNATPrefixLength

# Create VMs
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Creating VMs'
$i = 0
while ($i -lt $VMCount) {
    $VMNumber = $VmNumberStart + $i
    Delete-VM -VmNumber $VMNumber
    Create-VM -VmNumber $VMNumber
    $i++
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
#endregion Main
