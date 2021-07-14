#region Setup
$scriptname = "Build-VMBase.ps1"                                # This file's filename
$EventlogName = "Accenture"                                     # Event Log Folder Name
$EventlogSource = "Hyper-V VM Base Build Script"                # Event Log Source Name

$VMDrive = "F:"                                                 # Specify the root disk drive to use
$VMFolder = "Hyper-V"                                           # Specify the root folder to use
$VMMachineFolder = "Virtual Machines"                           # Specify the folder to store the VM data
$VHDFolder = "Virtual Hard Disks"                               # Specify the folder to store the VHDs
$VMCheckpointFolder = "Checkpoints"                             # Specify the folder to store the Checkpoints
$VMCount = 1                                                    # Specify number of VMs to be provisioned
$VmNamePrefix = "BASE-"                                         # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 100                                            # Specifies the second part of the VM name (usually numeric)
$VMRamSize = 4GB
$VMVHDSize = 60GB
$VMCPUCount = 4
$VMSwitchName = "Packaging Switch"
$VMNetNATName = "LocalNAT"
$VMNetNATPrefix = "192.168.0.0/24"
$VMNetNATHost = "192.168.0.1"
$VMNetNATPrefixLength = 24
$VMHostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet 2").IPAddress

$Domain = "ddddd"
$OUPath = "ooooo"
$TempFileStore = "C:\Windows\Temp"

#$IPAddress = ""
#$IPSubnetPrefix = "24"
#$IPGateway = "192.168.0.1"
#$IPDNS = @("10.21.224.10","10.21.224.11","10.21.239.196")

cd $PSScriptRoot
#endregion Setup

function Delete-VM {
    Param([Parameter(Mandatory)][int]$VmNumber)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
        break
    }
    $VMName = "$VmNamePrefix$VmNumber"
    $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue | select *
    
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
    Param([Parameter(Mandatory = $true)][int]$VmNumber)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
        break
    }
    $VMName = "$VmNamePrefix$VmNumber"
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM $VMName"
    
    $VM = @{
        Name = $VMName
        MemoryStartupBytes = $VMRamSize
        Generation = 1
        #NewVHDPath = "$VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx"
        #NewVHDSizeBytes = $VMVHDSize
        BootDevice = "CD"
        Path = "$VMDrive\$VMFolder\$VMMachineFolder\$VMName"
        SwitchName = (Get-VMSwitch -Name $VMSwitchName).Name
    }

    #$VMObject = New-VM @VM -Verbose -ErrorAction Stop
    $VMObject = New-VM @VM -NoVHD -Verbose -ErrorAction Stop
    
    New-Item -Path $VMDrive\$VMFolder\$VHDFolder\ -Name $VMName -ItemType Directory -Force -Verbose | Out-null
    Copy-Item -Path $VMDrive\$VMFolder\Media\basedisk.vhdx -Destination $VMDrive\$VMFolder\$VHDFolder\$VMName\$VMName.vhdx -Force -Verbose
    
    $VMObject | Set-VM -ProcessorCount $VMCPUCount
    $VMObject | Set-VM -StaticMemory
    $VMObject | Set-VM -CheckpointType Disabled
    #$VMObject | Set-VM -SnapshotFileLocation "$VMDrive\$VMFolder\$VMCheckpointFolder"
    #Set-VMDvdDrive -VMName $VMName -Path "F:\Hyper-V\Media\en_windows_10_business_editions_version_20h2_updated_dec_2020_x64_dvd_2af15d50.iso"
    $VMObject | Add-VMHardDiskDrive -Path $VMDrive\$VMFolder\$VHDFolder\$VMName\$VMName.vhdx
    
    #$Date = Get-Date -Format yyyy-MM-dd
    #$Time = Get-Date -Format HH:mm
    #$VMObject | Checkpoint-VM -SnapshotName "Base Config ($Date - $Time)"

    $VMObject | Start-VM -Verbose -ErrorAction Stop
    Start-Sleep -Seconds 360

    
        # Static IP Address
    <#Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
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
        if(!(Test-Connection $VMHostIP -Quiet)) { Write-Error "Networking Issue" }
        if(!(Test-Connection "google.com" -Quiet)) { Write-Error "DNS Issue" }
    }
    if($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }#>

        # VM Customisations
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
            # Cleanup and Rename Host
        Get-AppxPackage -Name Microsoft.MicrosoftOfficeHub | Remove-AppxPackage
        Rename-Computer -NewName $Using:VMName -LocalCredential $Using:LocalAdminCred -Restart -Verbose

            # Map Packaging Share
        #$source = $source = "X:\EUC Applications\Packaging Environment Build Files\Prevision"
        #cmd.exe /C cmdkey /add:`"xxxxx.file.core.windows.net`" /user:`"Azure\xxxxx`" /pass:`"yyyyy`"
        #New-PSDrive -Name X -PSProvider FileSystem -Root "\\xxxxx.file.core.windows.net\pkgazfiles01" -Persist
        #Copy-Item -Path $source\MapDrv.ps1 -Destination "C:\Users\Public\Desktop" -Force
        #New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "MapPackagingDrive" -Value "Powershell.exe -ExecutionPolicy Unrestricted -file `"C:\Users\Public\Desktop\MapDrv.ps1`"" -PropertyType "String"
                
            # Autopilot Hardware ID
        New-Item -Type Directory -Path "C:\HWID" -Force
        Set-Location -Path "C:\HWID"
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -ErrorAction Stop
        #Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
        Install-Script -Name Get-WindowsAutoPilotInfo -Force -ErrorAction Stop
        Get-WindowsAutoPilotInfo.ps1 -OutputFile AutoPilotHWID.csv
            
            # Upload AutoPilotHWID
        #mkdir -path "X:\EUC Applications\Packaging Environment Build Files\Autpilot IDs" -Name $env:COMPUTERNAME -Force
        #Copy-Item -Path "C:\HWID\AutoPilotHWID.csv" -Destination "X:\EUC Applications\Packaging Environment Build Files\Autpilot IDs\$env:COMPUTERNAME" -Force
    
            # Add Windows Capibilities Back In
        Add-WindowsCapability -Online -Name Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0
        Add-WindowsCapability -Online -Name App.StepsRecorder~~~~0.0.1.0
        Add-WindowsCapability -Online -Name Microsoft.Windows.Notepad~~~~0.0.1.0
        Add-WindowsCapability -Online -Name Microsoft.Windows.MSPaint~~~~0.0.1.0
        Add-WindowsCapability -Online -Name Microsoft.Windows.WordPad~~~~0.0.1.0
    }
    if($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }  
    Start-Sleep -Seconds 90

        # Disable IPV6 and Domain Join
    <#Remove-Variable erroric -ErrorAction SilentlyContinue
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
    Start-Sleep -Seconds 90#>

    <#    # Post Domain Join - LocalCred wont work anymore.
        # Firewall Changes
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $DomainUserCred -ErrorVariable erroric -ScriptBlock {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        #netsh advfirewall firewall add rule name="allow RemoteDesktop" dir=in protocol=TCP localport=3389 action=allow
        #New-NetFirewallRule -DisplayName "Restrict_RDP_access" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress 192.168.1.0/24,192.168.2.100 -Action Allow
        #Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1
        net localgroup "Remote Desktop Users" /add "Domain Users"
    }
    if($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }
    #> 

    #$Date = Get-Date -Format yyyy-MM-dd
    #$Time = Get-Date -Format HH:mm
    #$VMObject | Checkpoint-VM -SnapshotName "Domain Joined ($Date - $Time)"
    #$VMNumber = $VMName.Trim($VmNamePrefix)

    #$IPAddress = ($VMListData | where {$_.Name -eq $VMName}).IPAddress
    $MACAddress = $VMObject.NetworkAdapters.MacAddress
    $IPAddress = (Get-DhcpServerv4Scope | Get-DhcpServerv4Lease | where {($_.ClientId -replace "-") -eq $MACAddress}).IPAddress.IPAddressToString
    
    if(!(Get-NetNatStaticMapping -NatName $VMNetNATName -ErrorAction SilentlyContinue | where {$_.ExternalPort -like "*$VMNumber"})) {
        Add-NetNatStaticMapping -ExternalIPAddress "0.0.0.0" -ExternalPort 50$VMNumber -InternalIPAddress $IPAddress -InternalPort 3389 -NatName $VMNetNATName -Protocol TCP -ErrorAction Stop | Out-Null
    }
    Start-Sleep -Seconds 120
    $VMObject | Stop-VM -Force -TurnOff -Verbose -ErrorAction Stop
    Convert-VHD -Path $VMDrive\$VMFolder\$VHDFolder\$VMName\$VMName.vhdx -DestinationPath $VMDrive\$VMFolder\Media\$VMName.vhdx -VHDType Dynamic -Verbose
}

#region Main
# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource -ErrorAction SilentlyContinue
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Loading NuGet module"
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Loading Az.Storage module"
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Attempting to connect to Azure"    
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Copy files to machine
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Atempting to download DomainJoin.xml from Azure storage account to $TempFileStore"
$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrrr -Name xxxxx
$passwordFile1 = Get-AzStorageBlobContent -Container data -Blob "./HyperVLocalAdmin.xml" -Destination "$TempFileStore" -Context $StorAcc.context
$passwordFile2 = Get-AzStorageBlobContent -Container data -Blob "./DomainJoin.xml" -Destination "$TempFileStore" -Context $StorAcc.context
$passwordFile3 = Get-AzStorageBlobContent -Container data -Blob "./DomainUser.xml" -Destination "$TempFileStore" -Context $StorAcc.context
#$hypervFile = Get-AzStorageBlobContent -Container data -Blob "./hyperv-vms.xml" -Destination "$TempFileStore" -Context $StorAcc.context
#$VMListData = Import-Csv $TempFileStore\hyperv-vms.csv
$keyFile = Get-AzStorageBlobContent -Container data -Blob "./my.key" -Destination "$TempFileStore" -Context $StorAcc.context
$myKey = Get-Content "$TempFileStore\my.key"

# Create Credential
$LocalAdminUser = "DESKTOP-7O8HROP\administrator"
$LocalAdminPassword = Import-Clixml $TempFileStore\HyperVLocalAdmin.xml | ConvertTo-SecureString -Key $myKey
$LocalAdminCred = New-Object System.Management.Automation.PSCredential ($LocalAdminUser, $LocalAdminPassword)

$DomainUserUser = "wella\T1-Daniel.Ames"
$DomainUserPassword = Import-Clixml $TempFileStore\DomainUser.xml | ConvertTo-SecureString -Key $myKey
$DomainUserCred = New-Object System.Management.Automation.PSCredential ($DomainUserUser, $DomainUserPassword)

$DomainJoinUser = "wella\svc_PackagingDJ"
$DomainJoinPassword = Import-Clixml $TempFileStore\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
$DomainJoinCred = New-Object System.Management.Automation.PSCredential ($DomainJoinUser, $DomainJoinPassword)

# Import Hyper-V Module
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Importing Hyper-V Module"
Import-Module Hyper-V -Force -ErrorAction Stop

# Create Switch
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM Switch"
$VMSwitch = Get-VMSwitch -Name $VMSwitchName
if(!$VMSwitch) {
    New-VMSwitch -Name $VMSwitchName -SwitchType Internal -ErrorAction Stop
    #New-VMSwitch -Name $VMSwitchName -NetAdapterName "Ethernet"
}
New-NetNat -Name $VMNetNATName -InternalIPInterfaceAddressPrefix $VMNetNATPrefix
Get-NetAdapter "vEthernet ($VMSwitchName)" | New-NetIPAddress -IPAddress $VMNetNATHost -AddressFamily IPv4 -PrefixLength $VMNetNATPrefixLength

# Create VMs
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VMs"
$i=0
while ($i -lt $VMCount) {
    $VMNumber = $VmNumberStart+$i
    Delete-VM -VmNumber $VMNumber
    Create-VM -VmNumber $VMNumber
    $i++
}


#Get-NetNatStaticMapping | select StaticMappingID,ExternalIPAddress,ExternalPort,InternalIPAddress,InternalPort | Export-CSV -Path "$TempFileStore\netnatmapping.csv" -Force -NoTypeInformation
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Completed $scriptname"
#endregion Main