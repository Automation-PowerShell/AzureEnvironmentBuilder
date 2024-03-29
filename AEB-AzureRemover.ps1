﻿<#
.SYNOPSIS
AEB-AzureRemover.ps1

.DESCRIPTION
Azure Environment Builder - Azure Remover.
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
$AEBClientFiles= "$root\AEB-ClientFiles"
$AEBScripts = "$root\AEB-Scripts"
$ExtraFiles = "$root\ExtraFiles"

# Dot Source Variables
#. $AEBScripts\ScriptVariables.ps1
. $AEBScripts\ClientLoadVariables.ps1

# Dot Source Functions
. $AEBScripts\ScriptCoreFunctions.ps1

# Load Azure Modules and Connect
ConnectTo-Azure

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true'  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

#region Main
Write-AEBLog 'Running AEB-AzureRemover.ps1'
if ($clientSettings.isProd) { Write-Warning 'Are you sure you want to delete the Azure Environment?  OK to Continue?' -WarningAction Inquire }
Write-Warning 'Are you sure you want to delete the Azure Environment?  OK to Continue?' -WarningAction Inquire

if (!($clientSettings.isProd) -and $clientSettings.RequireUserGroups) {
    Remove-AzADGroup -DisplayName $clientSettings.rbacOwner -ErrorAction Ignore -Verbose
    Remove-AzADGroup -DisplayName $clientSettings.rbacContributor -ErrorAction Ignore -Verbose
    Remove-AzADGroup -DisplayName $clientSettings.rbacReadOnly -ErrorAction Ignore -Verbose
}
Remove-AzResourceGroup -Name $clientSettings.RGNameDEV -Force -ErrorAction Ignore -Verbose
Remove-AzResourceGroup -Name $clientSettings.RGNamePROD -Force -ErrorAction Ignore -Verbose
if (!($clientSettings.isProd)) {
    #Remove-AzResourceGroup -Name $RGNameDEVVNET -Force -ErrorAction Ignore -Verbose         # Dont want to do this is a Production Environment
    #Remove-AzResourceGroup -Name $RGNamePRODVNET -Force -ErrorAction Ignore -Verbose        # Dont want to do this is a Production Environment
}
Write-AEBLog 'Completed AEB-AzureRemover.ps1'
Write-AEBLog '============================================================================================================='
#endregion
