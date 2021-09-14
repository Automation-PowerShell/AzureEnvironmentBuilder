<#function RunVMConfig($ResourceGroup, $VMName, $BlobFilePath, $Blob) {
    $Params = @{
        ResourceGroupName   = $ResourceGroup
        VMName              = $VMName
        Location            = $Location
        #StorageAccountName  = $StorageAccountName
        #StorageAccountKey   = $Keys.value[0]
        FileUri             = $BlobFilePath
        Run                 = $Blob
        Name                = "ConfigureVM"
    }

    $global:VMConfigure = Set-AzVMCustomScriptExtension @Params -ErrorAction SilentlyContinue
    if ($VMConfigure.IsSuccessStatusCode -eq $True) {
        Write-PEBLog "VM: $VMName configured with $Blob successfully"
    }
    else {
        Write-PEBLog "*** VM: $VMName - Unable to configure Virtual Machine with $Blob ***" -Level Error
    }
}#>

function RunVMConfig($ResourceGroup, $VMName, $BlobFilePath, $Blob) {
    $Params = @{
        ContainerName       = $ContainerName
        ResourceGroupName   = $ResourceGroup
        VMName              = $VMName
        Location            = $Location
        StorageAccountName  = $StorageAccountName
        StorageAccountKey   = $Keys.value[0]
        Filename            = $Blob
        Run                 = $Blob
        Name                = "ConfigureVM2"
    }

    $global:VMConfigure = Set-AzVMCustomScriptExtension @Params -ErrorAction SilentlyContinue
    if ($VMConfigure.IsSuccessStatusCode -eq $True) {
        Write-PEBLog "VM: $VMName configured with $Blob successfully"
    }
    else {
        Write-PEBLog "*** VM: $VMName - Unable to configure Virtual Machine with $Blob ***" -Level Error
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

function Write-LogFile {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$String,
        [Parameter(Position = 1, Mandatory)][ValidateSet('Info', 'Error', 'Debug')][String]$Level
    )
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format HH:mm
    $String = "$Date - $Time -- $String"
    $logfile = "$root\PEB.log"
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

function Write-LogCMFile {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$String,
        [Parameter(Position = 1, Mandatory)][ValidateSet('Info', 'Error', 'Debug')][String]$Level
    )
    $Date = Get-Date -Format MM-dd-yyyy
    $Time = Get-Date -Format HH:mm:ss
    $logfile = "$root\PEB.log"
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
        Remove-Item -Path C:\Temp\PEBgit -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        mkdir -Path C:\Temp -Name "PEBgit" -Force | Out-Null
        Set-Location c:\temp\PEBgit\
        & git init *>&1 | Out-Null
        & git pull $gitlog *>&1 | Out-Null
        if(!(Test-Path -Path $logfile)) {
            Write-Output "" | Out-File -FilePath $logfile -Append -Force -Encoding ascii
        }
        & git add PEB.log -f *>&1 | Out-Null
        & git branch -M main *>&1 | Out-Null
        & git remote add origin $gitlog *>&1 | Out-Null
    }
    Set-Location c:\temp\PEBgit\
    $Script:gitNotFirstRun = $true
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
    Set-Location $root
}

function Write-PEBLog {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$String,
        [ValidateSet('Info', 'Error', 'Debug')][String]$Level = "Info"
    )

    Write-LogScreen -String $String -Level $Level
    if(!($isProd)) {
        Write-LogCMFile -String $String -Level $Level
        Write-LogGit -String $String -Level $Level
    }
    else {
        Write-LogFile -String $String -Level $Level
    }
}

function Write-DumpLine {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$varname,
        [Parameter(Position = 1, Mandatory)][String]$varvalue
    )
    $String = "$varname : $varvalue"
    Write-LogScreen -String $String -Level Debug
    if(!($isProd)) {
        Write-LogCMFile -String $String -Level Debug
        Write-LogGit -String $String -Level Debug
    }
    else {
        Write-LogFile -String $String -Level Debug
    }
}

function Write-Dump {
    Param(
        [Parameter(Position = 0)][object]$object1,
        [Parameter(Position = 1)][object]$object2,
        [Parameter(Position = 2)][object]$object3,
        [Parameter(Position = 3)][object]$object4,
        [Parameter(Position = 4)][object]$object5
    )
    Write-PEBLog -String "*** Write-Dump ***" -Level Debug
    Write-DumpLine '$?' $?
    Write-DumpLine '$azSubscription' $azSubscription
    Write-DumpLine '$RGNameSTORE' $RGNameSTORE
    Write-DumpLine '$StorageAccountName' $StorageAccountName
    Write-DumpLine '$VMName' $VMName
    Write-DumpLine '$RequireServicePrincipal' $RequireServicePrincipal
    Write-DumpLine '$RequireRBAC' $RequireRBAC
    Write-DumpLine '(Get-AzContext).Name' (Get-AzContext).Name
    if($object1){Write-DumpLine '$object1' $object1}
    if($object2){Write-DumpLine '$object2' $object2}
    if($object3){Write-DumpLine '$object3' $object3}
    if($object4){Write-DumpLine '$object4' $object4}
    if($object5){Write-DumpLine '$object5' $object5}
    if($Error[0]){Write-DumpLine '$Error[0]' $Error[0]}
    if($Error[1]){Write-DumpLine '$Error[1]' $Error[1]}
    if($Error[2]){Write-DumpLine '$Error[2]' $Error[2]}
    Write-PEBLog "=============================================================================================================" -Level Debug
    exit
}

function ConnectTo-Azure {
    Import-Module Az.Accounts,Az.Compute,Az.Storage,Az.Network,Az.Resources -ErrorAction SilentlyContinue
    if (!((Get-Module Az.Accounts) -and (Get-Module Az.Compute) -and (Get-Module Az.Storage) -and (Get-Module Az.Network) -and (Get-Module Az.Resources))) {
    Install-Module Az.Accounts,Az.Compute,Az.Storage,Az.Network,Az.Resources -Repository PSGallery -Scope CurrentUser -Force
        Import-Module Az.Accounts,AZ.Compute,Az.Storage,Az.Network,Az.Resources
    }

    Clear-AzContext -Force
    Connect-AzAccount -Tenant $aztenant -Subscription $azSubscription | Out-Null
    $SubscriptionId = (Get-AzContext).Subscription.Id
    if (!($azSubscription -eq $SubscriptionId)) {
        Write-PEBLog "*** Subscription ID Mismatch!!!! ***" -Level Error
        exit
    }
    Get-AzContext | Rename-AzContext -TargetName "User" -Force | Out-Null
    if ($RequireServicePrincipal) {
        Connect-AzAccount -Tenant $azTenant -Subscription $azSubscription -Credential $ServicePrincipalCred -ServicePrincipal | Out-Null
        Get-AzContext | Rename-AzContext -TargetName "StorageSP" -Force | Out-Null
        Get-AzContext -Name "User" | Select-AzContext | Out-Null
    }
    $script:Keys = Get-AzStorageAccountKey -ResourceGroupName $RGNameSTORE -AccountName $StorageAccountName
}
