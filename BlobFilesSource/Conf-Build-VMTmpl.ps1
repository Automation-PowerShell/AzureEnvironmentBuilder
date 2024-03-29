#region Setup
$scriptname = 'Build-VM.ps1'                                    # This file's filename
$EventlogName = 'AEB'                                           # Event Log Folder Name
$EventlogSource = 'Hyper-V VM Build Script'                     # Event Log Source Name

$VMDrive = 'F:'                                                 # Specify the root disk drive to use
$VMFolder = 'Hyper-V'
$VMMachineFolder = 'Virtual Machines'                           # Specify the folder to store the VM data
$VHDFolder = 'Virtual Hard Disks'                               # Specify the folder to store the VHDs
$VMCheckpointFolder = 'Checkpoints'                             # Specify the folder to store the Checkpoints
$VMCount = 2                                                    # Specify number of VMs to be provisioned
$VmNamePrefix = 'EUC-UAT-'                                      # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 101                                            # Specifies the second part of the VM name (usually numeric)
$VMRamSize = 4GB
$VMVHDSize = 100GB
$VMCPUCount = 2
$VMSwitchName = 'Packaging Switch'
$VMNetNATName = 'LocalNAT'
$VMNetNATPrefix = '192.168.0.0/24'
$VMNetNATHost = '192.168.0.1'
$VMNetNATPrefixLength = 24

Try { $VMHostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Ethernet').IPAddress }
Catch { $VMHostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Ethernet 2').IPAddress }

$Domain = 'ddddd'
$OUPath = 'ooooo'

$IPAddress = ''
$IPSubnetPrefix = '24'
$IPGateway = '192.168.0.1'
$IPDNS = @('10.21.224.10', '10.21.224.11', '10.21.239.196')

Set-Location $PSScriptRoot
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
        BootDevice         = 'VHD'
        Path               = "$VMDrive\$VMFolder\$VMMachineFolder\$VMName"
        SwitchName         = (Get-VMSwitch -Name $VMSwitchName).Name
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
    Start-Sleep -Seconds 240
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
        Get-AppxPackage -Name Microsoft.MicrosoftOfficeHub | Remove-AppxPackage
        Rename-Computer -NewName $Using:VMName -LocalCredential $Using:LocalAdminCred -Restart -Verbose
    }
    if ($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    }
    Start-Sleep -Seconds 90
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
        # Enable Remote Desktop
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-Name 'fDenyTSConnections' -Value 0
        Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
        #net localgroup "Remote Desktop Users" /add "Domain Users"

        # Autopilot Hardware ID
        New-Item -Type Directory -Path 'C:\HWID' -Force
        Set-Location -Path 'C:\HWID'
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -ErrorAction Stop
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
        Install-Script -Name Get-WindowsAutoPilotInfo -Force -ErrorAction Stop
        Get-WindowsAutoPilotInfo.ps1 -OutputFile AutoPilotHWID.csv

        # Map Packaging Share
        cmd.exe /C cmdkey /add:`"xxxxx.file.core.windows.net`" /user:`"Azure\xxxxx`" /pass:`"yyyyy`"
        New-PSDrive -Name Z -PSProvider FileSystem -Root '\\xxxxx.file.core.windows.net\pkgazfiles01' -Persist

        # Upload AutoPilotHWID
        mkdir -Path 'Z:\EUC Applications\Packaging Environment Build Files\Autpilot IDs' -Name $env:COMPUTERNAME -Force
        Copy-Item -Path 'C:\HWID\AutoPilotHWID.csv' -Destination "Z:\EUC Applications\Packaging Environment Build Files\Autpilot IDs\$env:COMPUTERNAME" -Force
    }
    if ($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    }

    # Join Domain
    Start-Sleep -Seconds 10
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
        Disable-NetAdapterBinding -Name '*' -ComponentID ms_tcpip6
        $joined = $false
        $attempts = 0
        while ($joined -eq $false) {
            $joined = $true
            $attempts++
            try {
                Add-Computer -LocalCredential $Using:LocalAdminCred -DomainName $Using:Domain -Credential $Using:DomainJoinCred -Restart -Verbose -ErrorAction Stop -OUPath $Using:OUPath
                # -NewName $CP -OUPath $OU
            }
            catch {
                $joined = $false
                Write-Output $_.Exception.Message
                if ($attempts -eq 20) {
                    throw 'Cannot Join the Domain'
                    break
                }
                Start-Sleep -Seconds 5
            }
        }
    }
    if ($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    }

    # Post Domain Join
    Start-Sleep -Seconds 90
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $DomainUserCred -ErrorVariable erroric -ScriptBlock {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-Name 'fDenyTSConnections' -Value 0
        Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
        net localgroup 'Remote Desktop Users' /add 'Domain Users'
    }
    if ($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    }

    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format HH:mm
    $VMObject | Checkpoint-VM -SnapshotName "Domain Joined ($Date - $Time)"
    #$VMNumber = $VMName.Trim($VmNamePrefix)
    $MACAddress = $VMObject.NetworkAdapters.MacAddress
    $IPAddress = (Get-DhcpServerv4Scope | Get-DhcpServerv4Lease | Where-Object { ($_.ClientId -replace '-') -eq $MACAddress }).IPAddress.IPAddressToString
    if (!(Get-NetNatStaticMapping -NatName LocalNAT | Where-Object { $_.ExternalPort -like "*$VMNumber" })) {
        Add-NetNatStaticMapping -ExternalIPAddress '0.0.0.0' -ExternalPort 55$VMNumber -InternalIPAddress $IPAddress -InternalPort 3389 -NatName LocalNAT -Protocol TCP -ErrorAction Stop | Out-Null
    }
    else {
        Get-NetNatStaticMapping -NatName LocalNAT | Where-Object { $_.ExternalPort -like "*$VMNumber" } | Remove-NetNatStaticMapping -Confirm:$false | Out-Null
        Add-NetNatStaticMapping -ExternalIPAddress '0.0.0.0' -ExternalPort 55$VMNumber -InternalIPAddress $IPAddress -InternalPort 3389 -NatName LocalNAT -Protocol TCP -ErrorAction Stop | Out-Null
    }

    $DHCPScope = Get-DhcpServerv4Scope
    Add-DhcpServerv4Reservation -ScopeId $DHCPScope.ScopeId -IPAddress $IPAddress -ClientId $MACAddress -Description 'Reservation for UAT device'

    Stop-VM -Name $VMName -Force -Verbose -ErrorAction Stop
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
$LocalAdminPassword = (Get-AzKeyVaultSecret -VaultName 'kkkkk' -Name 'HyperVLocalAdmin-Secret').SecretValue
$LocalAdminCred = New-Object System.Management.Automation.PSCredential ('aaaaa', $LocalAdminPassword)
$DomainJoinPassword = (Get-AzKeyVaultSecret -VaultName 'kkkkk' -Name 'DomainJoin-Secret').SecretValue
$DomainJoinCred = New-Object System.Management.Automation.PSCredential ('jjjjj', $DomainJoinPassword)
$DomainUserPassword = (Get-AzKeyVaultSecret -VaultName 'kkkkk' -Name 'DomainUser-Secret').SecretValue
$DomainUserCred = New-Object System.Management.Automation.PSCredential ('uuuuu', $DomainUserPassword)

<## Copy files to machine
Try {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Atempting to download DomainJoin.xml from Azure storage account to C:\Windows\Temp"
    $StorAcc = Get-AzStorageAccount -ResourceGroupName rrrrr -Name xxxxx
    $passwordFile1 = Get-AzStorageBlobContent -Container data -Blob "./HyperVLocalAdmin.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
    $passwordFile2 = Get-AzStorageBlobContent -Container data -Blob "./DomainJoin.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
    $passwordFile3 = Get-AzStorageBlobContent -Container data -Blob "./DomainUser.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
    #$hypervFile = Get-AzStorageBlobContent -Container data -Blob "./hyperv-vms.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
    #$VMListData = Import-Csv c:\windows\temp\hyperv-vms.csv
    $keyFile = Get-AzStorageBlobContent -Container data -Blob "./my.key" -Destination "c:\Windows\temp\" -Context $StorAcc.context
    $myKey = Get-Content "c:\Windows\Temp\my.key"
}
Catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Error downloading files from Storage Account"
}

# Create Credential
Try {
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Configuring Credentials"
$LocalAdminUser = "DESKTOP-7O8HROP\admin"
$LocalAdminPassword = Import-Clixml c:\Windows\temp\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
$LocalAdminCred = New-Object System.Management.Automation.PSCredential ($LocalAdminUser, $LocalAdminPassword)

$DomainUserUser = "ds\uitghi"
$DomainUserPassword = Import-Clixml c:\Windows\temp\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
$DomainUserCred = New-Object System.Management.Automation.PSCredential ($DomainUserUser, $DomainUserPassword)

$DomainJoinUser = "ds\uitghi"
$DomainJoinPassword = Import-Clixml c:\Windows\temp\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
$DomainJoinCred = New-Object System.Management.Automation.PSCredential ($DomainJoinUser, $DomainJoinPassword)
}
Catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Error configuring Credentials"
}#>

# Import Hyper-V Module
Try {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Importing Hyper-V Module'
    Import-Module Hyper-V -Force -ErrorAction Stop
}
Catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Error Importing Hyper-V Module'
}

<## Create Switch
Try {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM Switch"
    $VMSwitch = Get-VMSwitch -Name $VMSwitchName
    if(!$VMSwitch) {
    New-VMSwitch -Name $VMSwitchName -SwitchType Internal -ErrorAction Stop
    }
    New-NetNat -Name $VMNetNATName -InternalIPInterfaceAddressPrefix $VMNetNATPrefix
    Get-NetAdapter "vEthernet ($VMSwitchName)" | New-NetIPAddress -IPAddress $VMNetNATHost -AddressFamily IPv4 -PrefixLength $VMNetNATPrefixLength
}
Catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Error creating VM switch"
}#>

# Create VMs
Try {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Creating VMs'
    $i = 0
    while ($i -lt $VMCount) {
        $VMNumber = $VmNumberStart + $i
        Delete-VM -VmNumber $VMNumber
        Create-VM -VmNumber $VMNumber
        $i++
    }

    Get-NetNatStaticMapping | Select-Object StaticMappingID, ExternalIPAddress, ExternalPort, InternalIPAddress, InternalPort | Export-Csv -Path 'c:\windows\temp\netnatmapping.csv' -Force -NoTypeInformation
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
}
Catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Error creating VMs'
}
#endregion Main
