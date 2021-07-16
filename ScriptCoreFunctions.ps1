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
        Write-Log "*** Unable to configure Virtual Machine $VMName with $Blob ***"
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

