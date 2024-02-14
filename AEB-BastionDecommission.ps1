﻿<#
.SYNOPSIS
AEB-BastionDecommission.ps1

.DESCRIPTION
Azure Environment Builder - Bastion Decommission.
Wrtitten by Graham Higginson and Daniel Ames.

.NOTES
Written by      : Graham Higginson & Daniel Ames
Build Version   : v3

.LINK
More Info       : https://github.com/Automation-PowerShell/AzureEnvironmentBuilder

#>

#region Setup
Set-Location $PSScriptRoot

# Script Variables
$root = $PSScriptRoot
#$root = $pwd
$AEBClientFiles = "$root\AEB-ClientFiles"
$AEBScripts = "$root\AEB-Scripts"
$ExtraFiles = "$root\ExtraFiles"

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
    #Connect-AzAccount
    ConnectTo-Azure
}

#Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true'  # Turns off Breaking Changes warnings for Cmdlets
Update-AzConfig -DisplayBreakingChangeWarning $false
#endregion Setup

function AEBDecommission {
    Write-AEBLog 'Running AEB-BastionDecommission.ps1'

    foreach ($environment in $clientSettings.vnets.GetEnumerator().Name) {
        $resourceCheck = Get-AzResource -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -ResourceName $clientSettings.bastions.$environment.BastionName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if ($resourceCheck) {
            Write-AEBLog "Decommissioning Bastion for $environment VNETS in RG: $($clientSettings.rgs.$environment.RGNameVNET)"
            Remove-AzBastion -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -ResourceName $clientSettings.bastions.$environment.BastionName -Force
            Remove-AzPublicIpAddress -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -ResourceName "$($clientSettings.bastions.$environment.BastionName)-pip" -Force
        }
    }

    Write-AEBLog 'Completed AEB-BastionDecommission.ps1'
    Write-AEBLog '============================================================================================================='
}

function AVAWSDecommission {
    $bastionList = @{
        '6745a72d-32fc-4525-b5e9-80119fa1606b' = @(
            'rg-AccessCapture-Dev'
            'rg-TestClient0'
        )
        '205cb73d-d832-401b-96c9-99dfd5549a15' = @(
            'rg-TestClient0'
        )
    }

    foreach ($sub in $bastionList.Keys) {
        Select-AzSubscription -Subscription $sub | Out-Null
        foreach ($rg in $bastionList.$sub) {
            $resourceCheck = Get-AzResource -ResourceGroupName $rg -Name 'bastion-*-pip'
            if ($resourceCheck) {
                Write-Host "Bastion Found: $($resourceCheck.Name)"
                Get-AzBastion -ResourceGroupName $rg -Name 'bastion-*' | Remove-AzBastion -Force
                Start-Sleep -Seconds 30
                Get-AzPublicIpAddress -ResourceGroupName $rg -Name 'bastion-*-pip' | Remove-AzPublicIpAddress -Force
            }
        }
    }
}

AVAWSDecommission