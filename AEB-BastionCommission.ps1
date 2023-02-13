﻿<#
.SYNOPSIS
AEB-BastionCommission.ps1

.DESCRIPTION
Azure Environment Builder - Bastion Commission
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
    ConnectTo-Azure
}

#Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true'  # Turns off Breaking Changes warnings for Cmdlets
Update-AzConfig -DisplayBreakingChangeWarning $false
#endregion Setup

#region Main
Write-AEBLog 'Running AEB-BastionCommission.ps1'
foreach ($environment in $clientSettings.vnets.GetEnumerator().Name) {
    $resourceCheck = Get-AzResource -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name "$($clientSettings.bastions.$environment.BastionName)-pip" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if (!$resourceCheck) {
        Write-AEBLog "Commissioning Bastion for $environment VNETS in RG: $($clientSettings.rgs.$environment.RGNameVNET)"
        $publicip = New-AzPublicIpAddress -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name "$($clientSettings.bastions.$environment.BastionName)-pip" -Location $clientSettings.location -AllocationMethod Static -Sku Standard
        $resource = New-AzBastion -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name $clientSettings.$clientSettings.bastions.$environment.BastionName `
            -PublicIpAddressRgName $clientSettings.rgs.$environment.RGNameVNET -PublicIpAddressName "$($clientSettings.bastions.$environment.BastionName)-pip" `
            -VirtualNetworkRgName $clientSettings.rgs.$environment.RGNameVNET -VirtualNetworkName $clientSettings.vnets.$environment[0] `
            -Sku Basic -AsJob
    }
    else {
        Write-AEBLog "Bastion for $environment VNETs in RG: $($clientSettings.rgs.$environment.RGNameVNET) not required"
    }
}

Write-AEBLog 'Completed AEB-BastionCommission.ps1'
Write-AEBLog '============================================================================================================='
#endregion Main
