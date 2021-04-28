#region Setup
$scriptname = "Build-VM.ps1"                                    # This file's filename
$EventlogName = "Accenture"                                     # Event Log Folder Name
$EventlogSource = "Hyper-V VM Build Script"                     # Event Log Source Name

$VMDrive = "F:"                                                 # Specify the root disk drive to use
$VMFolder = "Virtual Machines"                                  # Specify the folder to store the VM data
$VHDFolder = "Virtual Hard Disks"                               # Specify the folder to store the VHDs
$VMCheckpointFolder = "Checkpoints"                             # Specify the folder to store the Checkpoints
$VMCount = 12                                                    # Specify number of VMs to be provisioned
$VmNamePrefix = "EUC-UAT-"                                      # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 101                                            # Specifies the second part of the VM name (usually numeric)
$VMRamSize = 4GB
$VMVHDSize = 100GB
$VMCPUCount = 4
$VMSwitchName = "Packaging Switch"
$VMNetNATName = "LocalNAT"
$VMNetNATPrefix = "192.168.0.0/24"
$VMNetNATHost = "192.168.0.1"
$VMNetNATPrefixLength = 24
$VMHostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet").IPAddress

$Domain = "dddd"
$OUPath = "oooo"

$IPAddress = ""
$IPSubnetPrefix = "24"
$IPGateway = "192.168.0.1"
$IPDNS = @("10.21.224.10","10.21.224.11","10.21.239.196")

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
        Remove-Item -Path "$VMDrive\Hyper-V\$VMFolder\$VMName" -Recurse -Force
        Remove-Item -Path "$VMDrive\Hyper-V\$VHDFolder\$VMName" -Recurse -Force
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
        BootDevice = "VHD"
        Path = "$VMDrive\Hyper-V\$VMFolder\$VMName"
        SwitchName = (Get-VMSwitch -Name $VMSwitchName).Name
    }

    $VMObject = New-VM @VM -NoVHD -Verbose -ErrorAction Stop
    
    New-Item -Path $VMDrive\Hyper-V\$VHDFolder\ -Name $VMName -ItemType Directory -Force -Verbose | Out-null
    Copy-Item -Path $VMDrive\Hyper-V\$VHDFolder\Media\Vanilla-Windows10-Base+CERT.vhdx -Destination $VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx -Force -Verbose
    
    $VMObject | Set-VM -ProcessorCount $VMCPUCount
    $VMObject | Set-VM -StaticMemory
    $VMObject | Set-VM -AutomaticCheckpointsEnabled $false
    $VMObject | Set-VM -SnapshotFileLocation "$VMDrive\Hyper-V\$VMCheckpointFolder"
    $VMObject | Add-VMHardDiskDrive -Path $VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx
    
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format hh:mm
    $VMObject | Checkpoint-VM -SnapshotName "Base Config ($Date - $Time)"

    $VMObject | Start-VM -Verbose -ErrorAction Stop
    Start-Sleep -Seconds 120

    $IPAddress = ($VMListData | where {$_.Name -eq $VMName}).IPAddress

        # Pre Domain Join
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalAdminCred -ErrorVariable erroric -ScriptBlock {
        $NetAdapter = Get-NetAdapter -Physical | where {$_.Status -eq "Up"}
        if (($NetAdapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
            $NetAdapter | Remove-NetIPAddress -AddressFamily IPv4 -Confirm:$false
        }
        if (($NetAdapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
            $NetAdapter | Remove-NetRoute -AddressFamily IPv4 -Confirm:$false
        }
        $NetAdapter | New-NetIPAddress -AddressFamily IPv4 -IPAddress $Using:IPAddress -PrefixLength $Using:IPSubnetPrefix -DefaultGateway $Using:IPGateway | Out-Null
        $NetAdapter | Set-DnsClientServerAddress -ServerAddresses $Using:IPDNS | Out-Null
        Start-Sleep -Seconds 60
        if(!(Test-Connection $VMHostIP -Quiet)) { Write-Error "Networking Issue" }
        #if(!(Test-Connection "google.com" -Quiet)) { Write-Error "DNS Issue" }
    }
    if($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }
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
        # Post Domain Join - LocalCred wont work anymore.
    Start-Sleep -Seconds 90
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $DomainUserCred -ErrorVariable erroric -ScriptBlock {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        #netsh advfirewall firewall add rule name="allow RemoteDesktop" dir=in protocol=TCP localport=3389 action=allow
        #New-NetFirewallRule -DisplayName "Restrict_RDP_access" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress 192.168.1.0/24,192.168.2.100 -Action Allow
        #Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1
        net localgroup "Remote Desktop Users" /add "Domain Users"
        
            # Autopilot Hardware ID
        New-Item -Type Directory -Path "C:\HWID" -Force
        Set-Location -Path "C:\HWID"
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -ErrorAction Stop
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
        Install-Script -Name Get-WindowsAutoPilotInfo -Force -ErrorAction Stop
        Get-WindowsAutoPilotInfo.ps1 -OutputFile AutoPilotHWID.csv

            # Map Packaging Share
        $source = $source = "X:\EUC Applications\Packaging Environment Build Files\Prevision"
        cmd.exe /C cmdkey /add:`"xxxx.file.core.windows.net`" /user:`"Azure\xxxx`" /pass:`"yyyyy`"
        New-PSDrive -Name X -PSProvider FileSystem -Root "\\xxxx.file.core.windows.net\pkgazfiles01" -Persist
        Copy-Item -Path $source\MapDrv.ps1 -Destination "C:\Users\Public\Desktop" -Force
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "MapPackagingDrive" -Value "Powershell.exe -ExecutionPolicy Unrestricted -file `"C:\Users\Public\Desktop\MapDrv.ps1`"" -PropertyType "String"

            # Upload AutoPilotHWID
        mkdir -path "X:\EUC Applications\Packaging Environment Build Files\Autpilot IDs" -Name $env:COMPUTERNAME -Force
        Copy-Item -Path "C:\HWID\AutoPilotHWID.csv" -Destination "X:\EUC Applications\Packaging Environment Build Files\Autpilot IDs\$env:COMPUTERNAME" -Force

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
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format hh:mm
    $VMObject | Checkpoint-VM -SnapshotName "Domain Joined ($Date - $Time)"
    #$VMNumber = $VMName.Trim($VmNamePrefix)
    if(!(Get-NetNatStaticMapping -NatName $VMNetNATName -ErrorAction SilentlyContinue | where {$_.ExternalPort -like "*$VMNumber"})) {
        Add-NetNatStaticMapping -ExternalIPAddress "0.0.0.0" -ExternalPort 50$VMNumber -InternalIPAddress $IPAddress -InternalPort 3389 -NatName $VMNetNATName -Protocol TCP -ErrorAction Stop | Out-Null
    }
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
Connect-AzAccount -Identity -ErrorAction Stop -Subscription ssss

# Copy files to machine
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Atempting to download DomainJoin.xml from Azure storage account to C:\Windows\Temp"
$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrr -Name xxxx
$passwordFile1 = Get-AzStorageBlobContent -Container data -Blob "./HyperVLocalAdmin.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
$passwordFile2 = Get-AzStorageBlobContent -Container data -Blob "./DomainJoin.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
$passwordFile3 = Get-AzStorageBlobContent -Container data -Blob "./DomainUser.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
$hypervFile = Get-AzStorageBlobContent -Container data -Blob "./hyperv-vms.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
$VMListData = Import-Csv c:\windows\temp\hyperv-vms.csv
$keyFile = Get-AzStorageBlobContent -Container data -Blob "./my.key" -Destination "c:\Windows\temp\" -Context $StorAcc.context
$myKey = Get-Content "c:\Windows\Temp\my.key"

# Create Credential
$LocalAdminUser = "DESKTOP-7O8HROP\admin"
$LocalAdminPassword = Import-Clixml c:\Windows\temp\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
$LocalAdminCred = New-Object System.Management.Automation.PSCredential ($LocalAdminUser, $LocalAdminPassword)

$DomainUserUser = "wella\T1-Daniel.Ames"
$DomainUserPassword = Import-Clixml c:\Windows\temp\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
$DomainUserCred = New-Object System.Management.Automation.PSCredential ($DomainUserUser, $DomainUserPassword)

$DomainJoinUser = "wella\svc_PackagingDJ"
$DomainJoinPassword = Import-Clixml c:\Windows\temp\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
$DomainJoinCred = New-Object System.Management.Automation.PSCredential ($DomainJoinUser, $DomainJoinPassword)

# Import Hyper-V Module
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Importing Hyper-V Module"
Import-Module Hyper-V -Force -ErrorAction Stop

# Create Switch
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM Switch"
$VMSwitch = Get-VMSwitch -Name $VMSwitchName
if(!$VMSwitch) {
    New-VMSwitch -Name $VMSwitchName -SwitchType Internal -ErrorAction Stop
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
Get-NetNatStaticMapping | select StaticMappingID,ExternalIPAddress,ExternalPort,InternalIPAddress,InternalPort | Export-CSV -Path "c:\windows\temp\netnatmapping.csv" -Force -NoTypeInformation
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Completed $scriptname"
#endregion Main