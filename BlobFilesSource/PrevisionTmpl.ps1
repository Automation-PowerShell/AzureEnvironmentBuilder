$scriptname = "Prevision.ps1"
$EventlogName = "Accenture"
$EventlogSource = "Prevision Script"

Set-Location $PSScriptRoot
$source = "X:\EUC Applications\Packaging Environment Build Files\Prevision"
$modules = "D:\Modules"

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

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Mapping X:\ Drive"
cmd.exe /C cmdkey /add:`"xxxxx.file.core.windows.net`" /user:`"Azure\xxxxx`" /pass:`"yyyyy`"
New-PSDrive -Name X -PSProvider FileSystem -Root "\\xxxxx.file.core.windows.net\fffff" -Persist

    # Import ZScaler Cert
Import-Certificate -FilePath "$source\ZscalerRootCertificate-2048-SHA256.crt" -CertStoreLocation Cert:\LocalMachine\Root

<#    # Install NuGet Module
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading NuGet module"
Expand-Archive -Path $source\Modules\nuget.zip -DestinationPath "C:\Program Files\PackageManagement\ProviderAssemblies" -Force
Import-PackageProvider -Name NuGet

    # Create Local Repository
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Creating Local Repo"
if(!(Test-Path -Path D:\Modules)) {
    mkdir -Path D:\ -Name Modules -Force
}
if(!(Get-PSRepository -Name localrepo)) {
    Register-PSRepository -Name 'localrepo' -SourceLocation $modules -InstallationPolicy Trusted
}

    # Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading Az.Accounts module"
if(!(Get-Module -Name az.accounts)) {
    Copy-Item -Path $source\Modules\az.accounts.2.2.6.nupkg -Destination $modules -Force
    Install-Module az.accounts -Repository localrepo
    Import-Module az.accounts
}
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading Az.Storage module"
if(!(Get-Module -Name az.storage)) {
    Copy-Item -Path $source\Modules\az.storage.3.4.0.nupkg -Destination $modules -Force
    Install-Module az.storage -Repository localrepo
    Import-Module az.storage
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"
Connect-AzAccount -identity -ErrorAction Stop -Subscription sssss

    # Copy MapDrv.ps1 to Desktop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Atempting to download MapDrv.ps1 from Azure storage account to C:\Users\Public\Desktop"
$StorAcc = get-azstorageaccount -resourcegroupname rg-wl-prod-packaging -name wlprodeusprodpkgstr01
$Result = Get-AzStorageBlobContent -Container data -Blob "MapDrv.ps1" -destination "c:\Users\Public\Desktop" -context $StorAcc.context
#>
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
