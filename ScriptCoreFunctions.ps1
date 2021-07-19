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
    $logfile = ".\PEB.log"
    try {
        switch ($Level) {
            "Info" { 
                $string | Out-File -FilePath $logfile -Append -Force
            }

            "Error" { 
                $String = "ERROR: $String"
                $string | Out-File -FilePath $logfile -Append -Force
            }

            "Debug" {
                $String = "DEBUG: $String"
                $string | Out-File -FilePath $logfile -Append -Force
            }
        }
    }
    catch {

    }
}

function Write-Log {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$String,
        [ValidateSet('Info', 'Error', 'Debug')][String]$Level = "Info"
    )

    try {
        $Date = Get-Date -Format yyyy-MM-dd
        $Time = Get-Date -Format HH:mm
        $String = "$Date - $Time -- $String"
        Write-LogScreen -String $String -Level $Level
        Write-LogFile -String $String -Level $Level
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
