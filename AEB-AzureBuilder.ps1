<#
.SYNOPSIS
AEB-AzureBuilder.ps1

.DESCRIPTION
Azure Environment Builder - Azure Builder.
Wrtitten by Graham Higginson and Daniel Ames.

.NOTES
Written by      : Graham Higginson & Daniel Ames
Build Version   : v3
Comment         : Adding Workplace Services Client
Comment         : Cleaning up code formating quality

.LINK
More Info       : https://github.com/Automation-PowerShell/AzureEnvironmentBuilder

#>

#region Setup
Set-Location $PSScriptRoot

# Script Variables
$root = $PSScriptRoot
#$root = $pwd
$AEBScripts = "$root\AEB-Scripts"
$ExtraFiles = "$root\ExtraFiles"

# Dot Source Variables
. $AEBScripts\ClientLoadVariables.ps1

# Dot Source Functions
. $AEBScripts\ScriptCoreFunctions.ps1
. $AEBScripts\ScriptEnvironmentFunctions.ps1
. $AEBScripts\ScriptDesktopFunctions.ps1
. $AEBScripts\ScriptServerFunctions.ps1

Setup
#endregion Setup

#region Main
Write-AEBLog 'Running AEB-AzureBuilder.ps1'
if ($clientSettings.isProd) { Write-Warning 'Are you sure you want to rebuild the Azure Environment?  OK to Continue?' -WarningAction Inquire }

if ($clientSettings.RequireCreate) {
    # Create Resource Groups
    CreateResourceGroups

    # Create RBAC groups and assignments
    CreateRBACConfig

    # Create VNet, NSG and rules
    ConfigureNetwork

    # Create Storage Account
    CreateStorageAccount

    # Create Key Vault
    CreateKeyVault

    # Create Server Script
    if ($clientSettings.UseTerraform) {
        TerraformBuild-HVVM
    }
    else {
        ScriptBuild-Create-Server
    }

    # Create Desktop VM Script
    if ($clientSettings.UseTerraform) {
        TerraformBuild-VM
    }
    else {
        ScriptBuild-Create-VM
    }

    if ($clientSettings.UseTerraform) {
        Set-Location .\terraform
        $ARGUinit = 'init'
        $ARGUplan = 'plan -out .\terraform.tfplan'
        $ARGUapply = 'apply -auto-approve .\terraform.tfplan'
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUinit -Wait -RedirectStandardOutput .\terraform-init.txt -RedirectStandardError .\terraform-error-init.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUplan -Wait -RedirectStandardOutput .\terraform-plan.txt -RedirectStandardError .\terraform-error-plan.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUapply -Wait -RedirectStandardOutput .\terraform-apply.txt -RedirectStandardError .\terraform-error-apply.txt
        Set-Location ..
    }
}

# Update Storage
UpdateStorage


if ($clientSettings.RequireConfigure) {
    if ($clientSettings.RequireRBAC) {
        # Update RBAC
        UpdateRBAC
    }

    # Configure Server Script
    if ($clientSettings.UseTerraform) {
        TerraformConfigure-HVVM
    }
    else {
        ScriptBuild-Config-Server
    }

    # Configure Desktop VM Script
    if ($clientSettings.UseTerraform) {
        TerraformConfigure-VM
    }
    else {
        ScriptBuild-Config-VM
    }
}

Write-AEBLog 'Completed AEB-AzureBuilder.ps1'
Write-AEBLog '============================================================================================================='
#endregion Main
