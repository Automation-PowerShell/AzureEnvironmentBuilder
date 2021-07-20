function RunVMConfig($ResourceGroup, $VMName, $BlobFilePath, $Blob) {
    $Params = @{
        ResourceGroupName = $ResourceGroup
        VMName            = $VMName
        Location          = $Location
        FileUri           = $BlobFilePath
        Run               = $Blob
        Name              = "ConfigureVM"
    }

    $VMConfigure = Set-AzVMCustomScriptExtension @Params
    if ($VMConfigure.IsSuccessStatusCode -eq $True) {
        Write-Log "Virtual Machine $VMName configured with $Blob successfully"
    }
    else {
        Write-Log "*** Unable to configure Virtual Machine $VMName with $Blob ***" -Level Error
    }
}

function Write-LogScreen {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$String,
        [Parameter(Position = 1, Mandatory)][ValidateSet('Info', 'Error', 'Debug')][String]$Level
    )
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format HH:mm
    $String = "$Date - $Time -- $String"
    try {
        switch ($Level) {
            "Info" { 
                Write-Host $String
            }

            "Error" { 
                $String = "ERROR: $String"
                Write-Host $String -ForegroundColor Red
            }

            "Debug" {
                $String = "DEBUG: $String"
                Write-Host $String -ForegroundColor Green
            }
        }
    }
    catch {

    }
}

function Write-LogFile {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$String,
        [Parameter(Position = 1, Mandatory)][ValidateSet('Info', 'Error', 'Debug')][String]$Level
    )
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format HH:mm
    $String = "$Date - $Time -- $String"
    $logfile = ".\PEB.log"
    try {
        switch ($Level) {
            "Info" {
                $String = "$String"
                $string | Out-File -FilePath $logfile -Append -Force -Encoding ascii
            }

            "Error" { 
                $String = "ERROR: $String"
                $string | Out-File -FilePath $logfile -Append -Force -Encoding ascii
            }

            "Debug" {
                $String = "DEBUG: $String"
                $string | Out-File -FilePath $logfile -Append -Force -Encoding ascii
            }
        }
    }
    catch {

    }
}

function Write-LogCMFile {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$String,
        [Parameter(Position = 1, Mandatory)][ValidateSet('Info', 'Error', 'Debug')][String]$Level
    )
    $Date = Get-Date -Format MM-dd-yyyy
    $Time = Get-Date -Format HH:mm:ss
    $logfile = ".\PEB.log"
    try {
        switch ($Level) {
            "Info" {
                $String = "<![LOG[$String]LOG]!><time=`"$Time.000-60`" date=`"$Date`" component=`"$azTenant`" context=`"`" type=`"1`" thread=`"`" file=`"`">"
                $string | Out-File -FilePath $logfile -Append -Force -Encoding utf8
            }

            "Error" { 
                $String = "<![LOG[$String]LOG]!><time=`"$Time.000-60`" date=`"$Date`" component=`"$azTenant`" context=`"`" type=`"3`" thread=`"`" file=`"`">"
                $string | Out-File -FilePath $logfile -Append -Force -Encoding utf8
            }

            "Debug" {
                $String = "<![LOG[$String]LOG]!><time=`"$Time.000-60`" date=`"$Date`" component=`"$azTenant`" context=`"`" type=`"2`" thread=`"`" file=`"`">"
                $string | Out-File -FilePath $logfile -Append -Force -Encoding utf8
            }
        }
    }
    catch {

    }
}

function Write-LogGit {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$String,
        [Parameter(Position = 1, Mandatory)][ValidateSet('Info', 'Error', 'Debug')][String]$Level
    )
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format HH:mm
    $String = "$Date - $Time -- $String"
    $logfile = "c:\temp\PEBgit\PEB.log"
    if(!$gitNotFirstRun) {
        rmdir -Path C:\Temp\PEBgit -Force -Recurse | Out-Null
        mkdir -Path C:\Temp -Name "PEBgit" -Force | Out-Null
        cd c:\temp\PEBgit\
        & git init *>&1 | Out-Null
        & git pull https://github.com/satsuk81/log.git *>&1 | Out-Null
        if(!(Test-Path -Path $logfile)) {
            Write-Output "" | Out-File -FilePath $logfile -Append -Force -Encoding ascii
        }
        & git add PEB.log -f *>&1 | Out-Null
        & git branch -M main *>&1 | Out-Null
        & git remote add origin https://github.com/satsuk81/log.git *>&1 | Out-Null
    }
    cd c:\temp\PEBgit\
    $Script:gitNotFirstRun = $true
    try {
        switch ($Level) {
            "Info" {
                $String = "$azTenant / $String"
                $string | Out-File -FilePath $logfile -Append -Force -Encoding ascii
                & git commit -a -m "$Date" *>&1 | Out-Null
                & git push -u origin main *>&1 | Out-Null
            }

            "Error" { 
                $String = "ERROR: $azTenant / $String"
                $string | Out-File -FilePath $logfile -Append -Force -Encoding ascii
                & git commit -a -m "$Date" *>&1 | Out-Null
                & git push -u origin main *>&1 | Out-Null
            }

            "Debug" {
                $String = "DEBUG: $azTenant / $String"
                $string | Out-File -FilePath $logfile -Append -Force -Encoding ascii
                & git commit -a -m "$Date" *>&1 | Out-Null
                & git push -u origin main *>&1 | Out-Null
            }
        }
    }
    catch {

    }
    cd $PSScriptRoot
}

function Write-Log {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$String,
        [ValidateSet('Info', 'Error', 'Debug')][String]$Level = "Info"
    )

    try {
        Write-LogScreen -String $String -Level $Level
        if(!($isProd)) {
            Write-LogCMFile -String $String -Level $Level
            Write-LogGit -String $String -Level $Level
        }
        else {
            Write-LogFile -String $String -Level $Level
        }
    }
    catch {

    }
}

function ConnectTo-Azure {
    Import-Module Az.Compute,Az.Accounts,Az.Storage,Az.Network,Az.Resources -ErrorAction SilentlyContinue
    if (!((Get-Module Az.Compute) -and (Get-Module Az.Accounts) -and (Get-Module Az.Storage) -and (Get-Module Az.Network) -and (Get-Module Az.Resources))) {
    Install-Module Az.Compute,Az.Accounts,Az.Storage,Az.Network,Az.Resources -Repository PSGallery -Scope CurrentUser -Force    
        Import-Module AZ.Compute,Az.Accounts,Az.Storage,Az.Network,Az.Resources
    }

    Clear-AzContext -Force
    Connect-AzAccount -Tenant $aztenant -Subscription $azSubscription | Out-Null
    $SubscriptionId = (Get-AzContext).Subscription.Id
    if (!($azSubscription -eq $SubscriptionId)) {
        Write-Error "Subscription ID Mismatch!!!!"
        exit
    }
    Get-AzContext | Rename-AzContext -TargetName "User" -Force | Out-Null
    if ($RequireServicePrincipal) {
        Connect-AzAccount -Tenant $azTenant -Subscription $azSubscription -Credential $ServicePrincipalCred -ServicePrincipal | Out-Null
        Get-AzContext | Rename-AzContext -TargetName "StorageSP" -Force | Out-Null
        Get-AzContext -Name "User" | Select-AzContext | Out-Null
    }
}
