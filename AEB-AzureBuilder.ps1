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

if (!(Test-Path $ExtraFiles)) {
    $output = 'AEBScripts\ClientVariables-Template.ps1'
    '. $' | Out-File $AEBScripts\ClientLoadVariables.ps1 -NoNewline
    $output | Out-File $AEBScripts\ClientLoadVariables.ps1 -Append
    New-Item -Path $ExtraFiles -ItemType Directory -Force
    Write-Host 'New Run Detected.  Please review ClientVariable file is correct within ClientLoadVariables.ps1'
    exit
}

# Dot Source Variables
. $AEBScripts\ClientLoadVariables.ps1

# Dot Source Functions
. $AEBScripts\ScriptCoreFunctions.ps1
. $AEBScripts\ScriptEnvironmentFunctions.ps1
. $AEBScripts\ScriptDesktopFunctions.ps1
. $AEBScripts\ScriptServerFunctions.ps1

# Load Azure Modules and Connect
$script:devops = ${env:TF_BUILD}
if ($devops) {
    # ...
}
else {
    ConnectTo-Azure
}


#Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true'  # Turns off Breaking Changes warnings for Cmdlets
Update-AzConfig -DisplayBreakingChangeWarning $false
#endregion Setup

#region Main
Write-AEBLog 'Running AEB-AzureBuilder.ps1'
if ($clientSettings.isProd) { Write-Warning 'Are you sure you want to rebuild the Azure Environment?  OK to Continue?' -WarningAction Inquire }

if ($clientSettings.RequireCreate) {
    # Create Resource Groups
    if ($clientSettings.RequireResourceGroups -and !$clientSettings.UseTerraform) {
        $RG = New-AzResourceGroup -Name $clientSettings.rgs.PROD.RGName -Location $clientSettings.Location
        if ($RG.ResourceGroupName -eq $clientSettings.rgs.PROD.RGName) { Write-AEBLog 'PROD Resource Group created successfully' } else { Write-AEBLog '*** Unable to create PROD Resource Group! ***' -Level Error }
        if (!($clientSettings.rgs.DEV.RGName -match $clientSettings.rgs.PROD.RGName)) {
            $RG = New-AzResourceGroup -Name $clientSettings.rgs.DEV.RGName -Location $clientSettings.Location
            if ($RG.ResourceGroupName -eq $clientSettings.rgs.DEV.RGName) { Write-AEBLog 'DEV Resource Group created successfully' } else { Write-AEBLog '*** Unable to create DEV Resource Group! ***' -Level Error }
        }
        if (!($clientSettings.rgs.DEV.RGName -match $clientSettings.rgs.DEV.RGNameVNET)) {
            $RG = New-AzResourceGroup -Name $clientSettings.rgs.DEV.RGNameVNET -Location $clientSettings.Location
            if ($RG.ResourceGroupName -eq $clientSettings.$clientSettings.rgs.DEV.RGNameVNET) { Write-AEBLog 'DEV VNET Resource Group created successfully' } else { Write-AEBLog '*** Unable to create DEV VNET Resource Group! ***' -Level Error }
        }
        if (!($clientSettings.rgs.PROD.RGName -match $clientSettings.rgs.PROD.RGNameVNET)) {
            $RG = New-AzResourceGroup -Name $clientSettings.rgs.PROD.RGNameVNET -Location $clientSettings.Location
            if ($RG.ResourceGroupName -eq $clientSettings.rgs.PROD.RGNameVNET) { Write-AEBLog 'PROD VNET Resource Group created successfully' } else { Write-AEBLog '*** Unable to create PROD VNET Resource Group! ***' -Level Error }
        }
        if (!($clientSettings.rgs.PROD.RGName -match $clientSettings.rgs.STORE.RGName) -and $clientSettings.RequireStorageAccount) {
            $RG = Get-AzResourceGroup -Name $clientSettings.rgs.STORE.RGName -ErrorAction SilentlyContinue
            if (!$RG) {
                $RG = New-AzResourceGroup -Name $clientSettings.rgs.STORE.RGName -Location $clientSettings.Location
                if ($RG.ResourceGroupName -eq $clientSettings.rgs.STORE.RGName) { Write-AEBLog 'STORE Resource Group created successfully' } else { Write-AEBLog '*** Unable to create STORE Resource Group! ***' -Level Error }
            }
            else {
                Write-AEBLog 'STORE Resource Group already exists'
            }
        }
    }
    else {
        $RG = Get-AzResourceGroup -Name $clientSettings.rgs.PROD.RGName -ErrorAction SilentlyContinue
        if (!$RG) {
            Write-AEBLog '*** Resouce Groups are missing ***' -Level Error
            Write-Dump
        }
    }
    if ($clientSettings.UseTerraform) {
        $TerraformMainTemplate = Get-Content -Path '.\Terraform\Root Template\main.tf' | Set-Content -Path '.\Terraform\main.tf'
    }

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
