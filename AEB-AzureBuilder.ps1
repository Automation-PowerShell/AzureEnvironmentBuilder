<#
.SYNOPSIS
AEB-AzureBuilder.ps1

.DESCRIPTION
Packaging Environment Builder - Azure Builder.
Wrtitten by Graham Higginson and Daniel Ames.

.NOTES
Written by      : Graham Higginson & Daniel Ames
Build Version   : v1

.LINK
More Info       : https://github.com/Automation-PowerShell/PackagingEnvironmentBuilder

#>

#region Setup
Set-Location $PSScriptRoot

    # Script Variables
$root = $PSScriptRoot
#$root = $pwd
$AEBScripts = "$root\AEB-Scripts"
$ExtraFiles = "$root\ExtraFiles"

    # Dot Source Variables
. $AEBScripts\ScriptVariables.ps1
. $AEBScripts\ClientLoadVariables.ps1

    # Dot Source Functions
. $AEBScripts\ScriptCoreFunctions.ps1
. $AEBScripts\ScriptEnvironmentFunctions.ps1
. $AEBScripts\ScriptDesktopFunctions.ps1
. $AEBScripts\ScriptServerFunctions.ps1
#. $AEBScripts\ClientLoadFunctions.ps1

    # Load Azure Modules and Connect
ConnectTo-Azure

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

#region Main
Write-AEBLog "Running AEB-AzureBuilder.ps1"
if($isProd) { Write-Warning "Are you sure you want to rebuild the Packaging Environment?  OK to Continue?" -WarningAction Inquire }

if($RequireCreate) {
        # Create Resource Groups
    if($RequireResourceGroups -and !$UseTerraform) {
        $RG = New-AzResourceGroup -Name $RGNamePROD -Location $Location
        if ($RG.ResourceGroupName -eq $RGNamePROD) {Write-AEBLog "PROD Resource Group created successfully"}Else{Write-AEBLog "*** Unable to create PROD Resource Group! ***" -Level Error }
        if (!($RGNameDEV -match $RGNamePROD)) {
            $RG = New-AzResourceGroup -Name $RGNameDEV -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEV) { Write-AEBLog "DEV Resource Group created successfully" }Else { Write-AEBLog "*** Unable to create DEV Resource Group! ***" -Level Error }
        }
        if (!($RGNameDEV -match $RGNameDEVVNET)) {
            $RG = New-AzResourceGroup -Name $RGNameDEVVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEVVNET) { Write-AEBLog "DEV VNET Resource Group created successfully" }Else { Write-AEBLog "*** Unable to create DEV VNET Resource Group! ***" -Level Error }
        }
        if (!($RGNamePROD -match $RGNamePRODVNET)) {
            $RG = New-AzResourceGroup -Name $RGNamePRODVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNamePRODVNET) { Write-AEBLog "PROD VNET Resource Group created successfully" }Else { Write-AEBLog "*** Unable to create PROD VNET Resource Group! ***" -Level Error }
        }
        if (!($RGNamePROD -match $RGNameSTORE) -and $RequireStorageAccount) {
            $RG = New-AzResourceGroup -Name $RGNameSTORE -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameSTORE) { Write-AEBLog "STORE Resource Group created successfully" }Else { Write-AEBLog "*** Unable to create STORE Resource Group! ***" -Level Error }
        }
    }
    if ($UseTerraform) {
        $TerraformMainTemplate = Get-Content -Path ".\Terraform\Root Template\main.tf" | Set-Content -Path ".\Terraform\main.tf"
    }

        # Create RBAC groups and assignments
    CreateRBACConfig

        # Create VNet, NSG and rules
    ConfigureNetwork

        # Create Storage Account
    CreateStorageAccount

        # Create Packaging VM Script
    if ($UseTerraform) {
        TerraformBuild-VM
    }
    else {
        ScriptBuild-Create-VM
    }

        # Create Hyper-V Script
    if ($RequireHyperV) {
        if ($UseTerraform) {
            TerraformBuild-HVVM
        }
        else {
            ScriptBuild-HVVM
        }
    }

    if($UseTerraform) {
        Set-Location .\terraform
        $ARGUinit = "init"
        $ARGUplan = "plan -out .\terraform.tfplan"
        $ARGUapply = "apply -auto-approve .\terraform.tfplan"
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUinit -Wait -RedirectStandardOutput .\terraform-init.txt -RedirectStandardError .\terraform-error-init.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUplan -Wait -RedirectStandardOutput .\terraform-plan.txt -RedirectStandardError .\terraform-error-plan.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUapply -Wait -RedirectStandardOutput .\terraform-apply.txt -RedirectStandardError .\terraform-error-apply.txt
        Set-Location ..
    }
}

    # Update Storage
UpdateStorage


if ($RequireConfigure) {
    if ($RequireRBAC) {
            # Update RBAC
        UpdateRBAC
    }

        # Configure Packaging VM Script
    if ($UseTerraform) {
        TerraformConfigure-VM
    }
    else {
        ScriptBuild-Config-VM
    }

        # Configure Hyper-V Script
    if($RequireHyperV) {
        if ($UseTerraform) {
            TerraformConfigure-HVVM
        }
        else {
            ScriptConfigure-HVVM
        }
    }
}
Write-AEBLog "Completed AEB-AzureBuilder.ps1"
Write-AEBLog "============================================================================================================="
#endregion Main
