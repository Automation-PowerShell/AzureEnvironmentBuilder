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
if ($isProd) { Write-Warning 'Are you sure you want to rebuild the Azure Environment?  OK to Continue?' -WarningAction Inquire }

if ($RequireCreate) {
    # Create Resource Groups
    if ($RequireResourceGroups -and !$UseTerraform) {
        $RG = New-AzResourceGroup -Name $RGNamePROD -Location $Location
        if ($RG.ResourceGroupName -eq $RGNamePROD) { Write-AEBLog 'PROD Resource Group created successfully' }Else { Write-AEBLog '*** Unable to create PROD Resource Group! ***' -Level Error }
        if (!($RGNameDEV -match $RGNamePROD)) {
            $RG = New-AzResourceGroup -Name $RGNameDEV -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEV) { Write-AEBLog 'DEV Resource Group created successfully' }Else { Write-AEBLog '*** Unable to create DEV Resource Group! ***' -Level Error }
        }
        if (!($RGNameDEV -match $RGNameDEVVNET)) {
            $RG = New-AzResourceGroup -Name $RGNameDEVVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEVVNET) { Write-AEBLog 'DEV VNET Resource Group created successfully' }Else { Write-AEBLog '*** Unable to create DEV VNET Resource Group! ***' -Level Error }
        }
        if (!($RGNamePROD -match $RGNamePRODVNET)) {
            $RG = New-AzResourceGroup -Name $RGNamePRODVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNamePRODVNET) { Write-AEBLog 'PROD VNET Resource Group created successfully' }Else { Write-AEBLog '*** Unable to create PROD VNET Resource Group! ***' -Level Error }
        }
        if (!($RGNamePROD -match $RGNameSTORE) -and $RequireStorageAccount) {
            $RG = Get-AzResourceGroup -Name $RGNameSTORE -ErrorAction SilentlyContinue
            if (!$RG) {
                $RG = New-AzResourceGroup -Name $RGNameSTORE -Location $Location
                if ($RG.ResourceGroupName -eq $RGNameSTORE) { Write-AEBLog 'STORE Resource Group created successfully' }Else { Write-AEBLog '*** Unable to create STORE Resource Group! ***' -Level Error }
            }
            else {
                Write-AEBLog 'STORE Resource Group already exists'
            }
        }
    }
    else {
        $RG = Get-AzResourceGroup -Name $RGNamePROD -ErrorAction SilentlyContinue
        if (!$RG) {
            Write-AEBLog '*** Resouce Groups are missing ***' -Level Error
            Write-Dump
        }
    }
    if ($UseTerraform) {
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

    # Create Desktop VM Script
    if ($UseTerraform) {
        TerraformBuild-VM
    }
    else {
        ScriptBuild-Create-VM
    }

    # Create Server Script
    if ($UseTerraform) {
        TerraformBuild-HVVM
    }
    else {
        ScriptBuild-Create-Server
    }

    if ($UseTerraform) {
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


if ($RequireConfigure) {
    if ($RequireRBAC) {
        # Update RBAC
        UpdateRBAC
    }

    # Configure Desktop VM Script
    if ($UseTerraform) {
        TerraformConfigure-VM
    }
    else {
        ScriptBuild-Config-VM
    }

    # Configure Server Script
    if ($UseTerraform) {
        TerraformConfigure-HVVM
    }
    else {
        ScriptBuild-Config-Server
    }
}
Write-AEBLog 'Completed AEB-AzureBuilder.ps1'
Write-AEBLog '============================================================================================================='
#endregion Main
