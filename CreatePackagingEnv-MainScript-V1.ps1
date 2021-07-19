#region Setup
cd $PSScriptRoot

    # Dot Source Variables
. .\ScriptVariables.ps1
. .\ClientLoadVariables.ps1

    # Dot Source Functions
. .\ScriptCoreFunctions.ps1
. .\ScriptEnvironmentFunctions.ps1
. .\ScriptPackagingFunctions.ps1
. .\ScriptHyperVFunctions.ps1
. .\ClientLoadFunctions.ps1

    # Load Azure Modules and Connect
ConnectTo-Azure

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

#region Main
Write-Log "Running CreatePackagingEnv-MainScript-V1.ps1"
cd $PSScriptRoot
if($isProd) { Write-Warning "Are you sure you want to rebuild the Packaging Environment?  OK to Continue?" -WarningAction Inquire }

if($RequireCreate) {
        # Create Resource Groups
    if($RequireResourceGroups -and !$UseTerraform) {
        $RG = New-AzResourceGroup -Name $RGNamePROD -Location $Location
        if ($RG.ResourceGroupName -eq $RGNamePROD) {Write-Log "PROD Resource Group created successfully"}Else{Write-Log "*** Unable to create PROD Resource Group! ***" -Level Error }
        if (!($RGNameDEV -match $RGNamePROD)) {
            $RG = New-AzResourceGroup -Name $RGNameDEV -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEV) { Write-Log "DEV Resource Group created successfully" }Else { Write-Log "*** Unable to create DEV Resource Group! ***" -Level Error }
        }
        if (!($RGNameDEV -match $RGNameDEVVNET)) {
            $RG = New-AzResourceGroup -Name $RGNameDEVVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEVVNET) { Write-Log "DEV VNET Resource Group created successfully" }Else { Write-Log "*** Unable to create DEV VNET Resource Group! ***" -Level Error }
        }
        if (!($RGNamePROD -match $RGNamePRODVNET)) {
            $RG = New-AzResourceGroup -Name $RGNamePRODVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNamePRODVNET) { Write-Log "PROD VNET Resource Group created successfully" }Else { Write-Log "*** Unable to create PROD VNET Resource Group! ***" -Level Error }
        } 
        if (!($RGNamePROD -match $RGNameSTORE) -and $RequireStorageAccount) {
            $RG = New-AzResourceGroup -Name $RGNameSTORE -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameSTORE) { Write-Log "STORE Resource Group created successfully" }Else { Write-Log "*** Unable to create STORE Resource Group! ***" -Level Error }
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
Write-Log "Completed CreatePackagingEnv-MainScript-V1.ps1"
Write-Log "============================================================================================================="
#endregion Main
