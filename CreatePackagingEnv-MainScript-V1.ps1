#region Setup
cd $PSScriptRoot

    # Dot Source Variables
. .\ScriptVariables.ps1
. .\ClientVariables-Dan.ps1

    # Dot Source Functions
. .\ScriptCoreFunctions.ps1
. .\ScriptEnvironmentFunctions.ps1

Import-Module Az.Compute, Az.Accounts, Az.Storage, Az.Network, Az.Resources -ErrorAction SilentlyContinue
if (!((Get-Module Az.Compute) -and (Get-Module Az.Accounts) -and (Get-Module Az.Storage) -and (Get-Module Az.Network) -and (Get-Module Az.Resources))) {
    Install-Module Az.Compute, Az.Accounts, Az.Storage, Az.Network, Az.Resources -Repository PSGallery -Scope CurrentUser -Force
    Import-Module AZ.Compute, Az.Accounts, Az.Storage, Az.Network, Az.Resources
}

Clear-AzContext -Force
Connect-AzAccount -Tenant $aztenant -Subscription $azSubscription
$SubscriptionId = (Get-AzContext).Subscription.Id
if (!($azSubscription -eq $SubscriptionId)) {
    Write-Error "Subscription ID Mismatch!!!!"
    exit
}
Get-AzContext | Rename-AzContext -TargetName "User" -Force
if ($RequireServicePrincipal) {
    Connect-AzAccount -Tenant $azTenant -Subscription $azSubscription -Credential $ServicePrincipalCred -ServicePrincipal
    Get-AzContext | Rename-AzContext -TargetName "StorageSP" -Force
    Get-AzContext -Name "User" | Select-AzContext
}

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

#region Main
#=======================================================================================================================================================
cd $PSScriptRoot
if($isProd) { Write-Warning "Are you sure you want to rebuild the Packaging Environment?  OK to Continue?" -WarningAction Inquire }

if($RequireCreate) {
        # Create Resource Groups
    if($RequireResourceGroups -and !$UseTerraform) {
        $RG = New-AzResourceGroup -Name $RGNamePROD -Location $Location
        if ($RG.ResourceGroupName -eq $RGNamePROD) {Write-Host "PROD Resource Group created successfully"}Else{Write-Host "*** Unable to create PROD Resource Group! ***"}
        if (!($RGNameDEV -match $RGNamePROD)) {
            $RG = New-AzResourceGroup -Name $RGNameDEV -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEV) { Write-Host "DEV Resource Group created successfully" }Else { Write-Host "*** Unable to create DEV Resource Group! ***" }
        }
        if (!($RGNameDEV -match $RGNameDEVVNET)) {
            $RG = New-AzResourceGroup -Name $RGNameDEVVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEVVNET) { Write-Host "DEV VNET Resource Group created successfully" }Else { Write-Host "*** Unable to create DEV VNET Resource Group! ***" }
        }
        if (!($RGNamePROD -match $RGNamePRODVNET)) {
            $RG = New-AzResourceGroup -Name $RGNamePRODVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNamePRODVNET) { Write-Host "PROD VNET Resource Group created successfully" }Else { Write-Host "*** Unable to create PROD VNET Resource Group! ***" }
        } 
        if (!($RGNamePROD -match $RGNameSTORE) -and $RequireStorageAccount) {
            $RG = New-AzResourceGroup -Name $RGNameSTORE -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameSTORE) { Write-Host "STORE Resource Group created successfully" }Else { Write-Host "*** Unable to create STORE Resource Group! ***" }
        }
    }
    if ($UseTerraform) {
        $TerraformMainTemplate = Get-Content -Path ".\Terraform\Root Template\main.tf" | Set-Content -Path ".\Terraform\main.tf"    
    }

        # Environment Script
    .\CreatePackagingEnv-Env-V2.ps1

        # Create Packaging VM Script
    .\CreatePackagingEnv-PackagingVms-V2.ps1

        # Create Hyper-V Script
    if ($RequireHyperV) {
        .\CreatePackagingEnv-HyperVServer-V1.ps1
    }

    if($UseTerraform) {
        cd .\terraform
        $ARGUinit = "init"
        $ARGUplan = "plan -out .\terraform.tfplan"
        $ARGUapply = "apply -auto-approve .\terraform.tfplan"
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUinit -Wait -RedirectStandardOutput .\terraform-init.txt -RedirectStandardError .\terraform-error-init.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUplan -Wait -RedirectStandardOutput .\terraform-plan.txt -RedirectStandardError .\terraform-error-plan.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUapply -Wait -RedirectStandardOutput .\terraform-apply.txt -RedirectStandardError .\terraform-error-apply.txt
        cd ..
    }
}

    # Update Storage
if($RequireUpdateStorage) {
    UpdateStorage
}

if ($RequireConfigure) {
    if ($RequireRBAC) {
            # Update RBAC
        UpdateRBAC
    }

        # Configure Packaging VM Script
    .\CreatePackagingEnv-PackagingVms-Configure.ps1

        # Configure Hyper-V Script
    if($RequireHyperV) {
        .\CreatePackagingEnv-HyperVServer-Configure.ps1
    }
}
$Date = Get-Date -Format yyyy-MM-dd
$Time = Get-Date -Format hh:mm
Write-Host "$Date - $Time -- All Scripts Completed"
#endregion Main