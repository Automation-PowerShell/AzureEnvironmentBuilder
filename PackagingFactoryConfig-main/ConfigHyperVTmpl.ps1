$scriptname = "ConfigHyperV.ps1"
$EventlogName = "Accenture"
$EventlogSource = "Config Hyper-V Script"

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
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"    
Connect-AzAccount -identity -ErrorAction Stop -Subscription sssss

# Map Storage Account
cmd.exe /C cmdkey /add:`"xxxxx.file.core.windows.net`" /user:`"Azure\xxxxx`" /pass:`"yyyyy`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\xxxxx.file.core.windows.net\fffff" -Persist

# Configure DHCP
Import-Module DHCPServer -Force -ErrorAction Stop
Add-DhcpServerv4Scope -StartRange 192.168.0.100 -EndRange 192.168.0.199 -Name "UAT Scope" -State Active -SubnetMask 255.255.254.0
$DNSserver = (Get-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -AddressFamily IPv4).ServerAddresses
Set-DhcpServerv4OptionValue -DnsServer $DNSserver
Set-DhcpServerv4OptionValue -DnsDomain "space.dan"
Set-DhcpServerv4OptionValue -Router 192.168.0.1

# Hyper-v Settings and Files
mkdir -Path "F:\" -Name "Hyper-V" -Force
mkdir -Path "F:\Hyper-V" -Name "Virtual Hard Disks" -Force
mkdir -Path "F:\Hyper-V" -Name "Media" -Force
Copy-Item -Path "Z:\en_windows_10_business_editions_version_20h2_updated_dec_2020_x64_dvd_2af15d50.iso" -Destination "F:\Hyper-V\Media" -Force -Verbose

# Windows Image Tools
Install-Module -Name WindowsImageTools -Force -ErrorAction Stop
Import-Module WindowsImageTools -Force
$adminPassword = ConvertTo-SecureString "Password1234" -AsPlainText -Force  
$adminCred = New-Object System.Management.Automation.PSCredential ("administrator", $adminPassword)
New-UnattendXml -Path F:\Hyper-V\Media\Unattend.xml -AdminPassword $adminCred -logonCount 1 -enableAdministrator
New-DataVHD -Path F:\Hyper-V\Media\basedisk.vhdx -Size 60GB -DataFormat NTFS -Dynamic
#Mount-VHD -Path F:\Hyper-V\Media\basedisk.vhdx -PassThru | Get-Disk | Get-Partition | Get-Volume
Mount-VHD -Path F:\Hyper-V\Media\basedisk.vhdx -NoDriveLetter
#Install-WindowsFromWim -DiskNumber 0 -Index 3 -NoRecoveryTools -DiskLayout UEFI -WimPath "F:\Hyper-V\Media\en_windows_10_business_editions_version_20h2_updated_dec_2020_x64_dvd_2af15d50.iso"
Install-WindowsFromWim -DiskNumber 2 -DiskLayout BIOS -NoRecoveryTools -Unattend F:\Hyper-V\Media\unattend.xml -SourcePath "F:\Hyper-V\Media\en_windows_10_business_editions_version_20h2_updated_dec_2020_x64_dvd_2af15d50.iso"
Dismount-VHD -Path F:\Hyper-V\Media\basedisk.vhdx

# Get Files from Blob
$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrrr -Name xxxxx
<#$Result1 = Get-AzStorageBlobContent -Container data -Blob "hyperv-vms.csv" -Destination "c:\Windows\temp\" -Context $StorAcc.context -Force
If ($Result1.Name -eq "hyperv-vms.csv") {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Successfully downloaded hyperv-vms.csv"
}
Else {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download hyperv-vms.csv"
}
$Result2 = Get-AzStorageBlobContent -Container data -Blob "Media/Vanilla-Windows10-Base+CERT.vhdx" -Destination "F:\Hyper-V\Virtual Hard Disks" -Context $StorAcc.context -Force
If ($Result2.Name -eq "Media/Vanilla-Windows10-Base+CERT.vhdx") {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Successfully downloaded Media/Vanilla-Windows10-Base+CERT.vhdx"
}
Else {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download Media/Vanilla-Windows10-Base+CERT.vhdx"
}#>
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
