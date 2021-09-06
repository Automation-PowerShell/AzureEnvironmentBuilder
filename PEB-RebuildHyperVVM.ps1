<#
.SYNOPSIS
PEB-RebuildHyperVVM.ps1

.DESCRIPTION
Packaging Environment Builder - Rebuild HyperV VM.
Wrtitten by Graham Higginson and Daniel Ames.

.NOTES
Written by      : Graham Higginson & Daniel Ames
Build Version   : 0.1 Alpha

.LINK
More Info       : https://github.com/satsuk81/PackagingEnvironmentBuilder

#>

Param(
    [Parameter(Mandatory = $false)][string]$RVMVMName = ""
)

#region Setup
Set-Location $PSScriptRoot

    # Dot Source Variables
. .\ScriptVariables.ps1
. .\ClientLoadVariables.ps1

$scriptname = "RebuildHyperVVM.ps1"                             # This file's filename
$EventlogName = "Accenture"                                     # Event Log Folder Name
$EventlogSource = "Hyper-V VM Rebuild Script"                   # Event Log Source Name

$VMDrive = "F:"                                                 # Specify the root disk drive to use
$VMFolder = "Virtual Machines"                                  # Specify the folder to store the VM data
$VHDFolder = "Virtual Hard Disks"                               # Specify the folder to store the VHDs
$VMCheckpointFolder = "Checkpoints"                             # Specify the folder to store the Checkpoints
$VmNamePrefix = "EUC-UAT-"
$VMRamSize = 4GB
$VMVHDSize = 100GB
$VMCPUCount = 4
$VMSwitchName = "Packaging Switch"
$VMHostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet 2").IPAddress

    # For Static IP Configuration
$IPAddress = ""
$IPSubnetPrefix = "24"
$IPGateway = "192.168.0.1"
$IPDNS = @("10.21.224.10","10.21.224.11","10.21.239.196")

Set-Location $PSScriptRoot
$VMListData = Import-Csv .\hyperv-vms.csv

if($LocalCred) {Remove-Variable LocalCred;$LocalCred = Get-Credential -Credential $LocalCredUser;$LocalCred | Export-CliXml -Path .\LocalCred.xml} else{$LocalCred = Get-Credential -Credential $LocalCredUser;$LocalCred | Export-CliXml -Path .\LocalCred.xml}
if($DomainCred) {Remove-Variable DomainCred;$DomainCred = Get-Credential -Credential $DomainCredUser;$DomainCred | Export-CliXml -Path .\DomainCred.xml} else{$DomainCred = Get-Credential -Credential $DomainCredUser;$DomainCred | Export-CliXml -Path .\DomainCred.xml}
if($DomainJoinCred) {Remove-Variable DomainJoinCred;$DomainJoinCred = Get-Credential -Credential $DomainJoinUser;$DomainJoinCred | Export-CliXml -Path .\DomainJoinCred.xml} else{$DomainJoinCred = Get-Credential -Credential $DomainJoinUser;$DomainJoinCred | Export-CliXml -Path .\DomainJoinCred.xml}
#$LocalCred = Import-CliXml -Path .\LocalCred.xml
#$DomainCred = Import-CliXml -Path .\DomainCred.xml
#$DomainJoinCred = Import-CliXml -Path .\DomainJoinCred.xml

if(!$DomainCred) {
    exit
}

New-EventLog -LogName $EventlogName -Source $EventlogSource -ErrorAction SilentlyContinue
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Importing Hyper-V Module"
Import-Module Hyper-V -Force -ErrorAction Stop
#endregion Setup

function Delete-VM {
    Param([Parameter(Mandatory)][string]$VMName)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
        break
    }
    $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue | Select-Object *

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
        #NewVHDPath = "$VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx"
        #NewVHDSizeBytes = $VMVHDSize
        BootDevice = "VHD"
        Path = "$VMDrive\Hyper-V\$VMFolder\$VMName"
        SwitchName = (Get-VMSwitch -Name $VMSwitchName).Name
    }

    $VMObject = New-VM @VM -NoVHD -Verbose -ErrorAction Stop

    New-Item -Path $VMDrive\Hyper-V\$VHDFolder\ -Name $VMName -ItemType Directory -Force -Verbose | Out-null
    Copy-Item -Path $VMDrive\Hyper-V\$VHDFolder\Media\Vanilla-Windows10-Base.vhdx -Destination $VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx -Force -Verbose

    $VMObject | Set-VM -ProcessorCount $VMCPUCount
    $VMObject | Set-VM -StaticMemory
    $VMObject | Set-VM -AutomaticCheckpointsEnabled $false
    $VMObject | Set-VM -SnapshotFileLocation "$VMDrive\Hyper-V\$VMCheckpointFolder"
    $VMObject | Add-VMHardDiskDrive -Path $VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx

    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format HH:mm
    $VMObject | Checkpoint-VM -SnapshotName "Base Config ($Date - $Time)"

    $VMObject | Start-VM -Verbose -ErrorAction Stop
    Start-Sleep -Seconds 120

    $IPAddress = ($VMListData | Where-Object {$_.Name -eq $VMName}).IPAddress

        # Pre Domain Join
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalCred -ErrorVariable erroric -ScriptBlock {
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
    }
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalCred -ErrorVariable erroric -ScriptBlock {
        Get-AppxPackage -Name Microsoft.MicrosoftOfficeHub | Remove-AppxPackage
        Rename-Computer -NewName $Using:VMName -LocalCredential $Using:LocalCred -Restart -Verbose
    }
    if($erroric) {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }
    Start-Sleep -Seconds 90
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalCred -ErrorVariable erroric -ScriptBlock {
        Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6
        $joined=$false
        $attempts = 0
        while($joined -eq $false) {
            $joined = $true
            $attempts++
            try {
                Add-Computer -LocalCredential $Using:LocalCred -DomainName $Using:Domain -Credential $Using:DomainJoinCred -Restart -Verbose -ErrorAction Stop -OUPath $Using:OUPath
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
    Invoke-Command -VMName $VMName -Credential $DomainCred -ErrorVariable erroric -ScriptBlock {
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
        cmd.exe /C cmdkey /add:`"wlprodeusprodpkgstr01.file.core.windows.net`" /user:`"Azure\wlprodeusprodpkgstr01`" /pass:`"s9joA/NOc94meybF/lasFWDB55fFx3JP0OEYddtYljpRswpjErowqz9wXZe2zVY1/CW1Aujle3ED1fEJtnsEvg==`"
        New-PSDrive -Name X -PSProvider FileSystem -Root "\\wlprodeusprodpkgstr01.file.core.windows.net\pkgazfiles01" -Persist
        Copy-Item -Path $source\MapDrv.ps1 -Destination "C:\Users\Public\Desktop" -Force
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "MapPackagingDrive" -Value "Powershell.exe -ExecutionPolicy Unrestricted -file `"C:\Users\Public\Desktop\MapDrv.ps1`"" -PropertyType "String"

            # Upload AutoPilotHWID
        mkdir -Path "X:\EUC Applications\Packaging Environment Build Files\Autpilot IDs" -Name $env:COMPUTERNAME -Force
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
    $Time = Get-Date -Format HH:mm
    $VMObject | Checkpoint-VM -SnapshotName "Domain Joined ($Date - $Time)"
    $VMNumber = $VMName.Trim($VmNamePrefix)
    if(!(Get-NetNatStaticMapping -NatName LocalNAT | Where-Object {$_.ExternalPort -like "*$VMNumber"})) {
        Add-NetNatStaticMapping -ExternalIPAddress "0.0.0.0" -ExternalPort 50$VMNumber -InternalIPAddress $IPAddress -InternalPort 3389 -NatName LocalNAT -Protocol TCP -ErrorAction Stop | Out-Null
    }
}

#region Main
Write-Output "Running PEB-RebuildHyperVVM.ps1"

if($RVMVMName -eq "") {
    #$VMList = Get-VM -Name *
    $VMList = $VMListData
    $RVMVMName = ($VMList | Where-Object { $_.Name -like "$VmNamePrefix*" } | Select-Object * | Out-GridView -Title "Select Virtual Machine to Rebuild" -OutputMode Single).Name
}

Write-Output "Rebuilding $RVMVMName"
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Rebuilding $RVMVMName VM"
Delete-VM -VMName $RVMVMName
Create-VM -VMName $RVMVMName
#Get-NetNatStaticMapping | select StaticMappingID,ExternalIPAddress,ExternalPort,InternalIPAddress,InternalPort | ConvertTo-JSON | Out-File -FilePath ".\netnatmapping.json"-Force
Get-NetNatStaticMapping | Select-Object StaticMappingID,ExternalIPAddress,ExternalPort,InternalIPAddress,InternalPort | Export-CSV -Path ".\netnatmapping.csv" -Force -NoTypeInformation
Write-Output "Completed PEB-RebuildHyperVVM.ps1"
#endregion Main