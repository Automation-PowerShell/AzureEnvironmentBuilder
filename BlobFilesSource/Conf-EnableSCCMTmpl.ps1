$scriptname = 'EnableSCCM.ps1'
$EventlogName = 'AEB'
$EventlogSource = 'Enable SCCM Script'

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Starting $scriptname Install Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading NuGet module'
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Loading Az.Storage module'
Install-Module -Name Az.Storage, Az.KeyVault -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Attempting to connect to Azure'
Connect-AzAccount -Identity -ErrorAction Stop -Subscription sssss

# Enable Domain Controller Role
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message 'Configuring System'
Install-WindowsFeature -Name RDC
Install-WindowsFeature -Name BITS
Install-WindowsFeature -Name NET-Framework-Core       # Install .NET 3.5
dism.exe /online /norestart /enable-feature /ignorecheck /featurename:"IIS-WebServerRole" /featurename:"IIS-WebServer" /featurename:"IIS-CommonHttpFeatures" /featurename:"IIS-StaticContent" /featurename:"IIS-DefaultDocument" /featurename:"IIS-DirectoryBrowsing" /featurename:"IIS-HttpErrors" /featurename:"IIS-HttpRedirect" /featurename:"IIS-WebServerManagementTools" /featurename:"IIS-IIS6ManagementCompatibility" /featurename:"IIS-Metabase" /featurename:"IIS-WindowsAuthentication" /featurename:"IIS-WMICompatibility" /featurename:"IIS-ISAPIExtensions" /featurename:"IIS-ManagementScriptingTools" /featurename:"MSRDC-Infrastructure" /featurename:"IIS-ManagementService"
# Post Steps
# Install SQL Server
# Change SQL Logon to LocalSystem
# Install ADK components
# Create System Management container in System in ADSI
# Set MECM Computer as administrator on client devices

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
