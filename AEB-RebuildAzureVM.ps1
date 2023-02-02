<#
.SYNOPSIS
AEB-RebuildAzureVM.ps1

.DESCRIPTION
Azure Environment Builder - Rebuild Azure VM.
Wrtitten by Graham Higginson and Daniel Ames.

.NOTES
Written by      : Graham Higginson & Daniel Ames
Build Version   : v3

.LINK
More Info       : https://github.com/Automation-PowerShell/AzureEnvironmentBuilder

#>

Param(
    [Parameter(Mandatory = $false)][string]$VMName = '',
    [Parameter(Mandatory = $false)][ValidateSet('Standard', 'Packaging', 'AdminStudio', 'Jumpbox', 'Core')][string]$Spec = 'Standard'
)

#region Setup
Set-Location $PSScriptRoot

# Script Variables
$root = $PSScriptRoot
#$root = $pwd
$AEBScripts = "$root\AEB-Scripts"
$ExtraFiles = "$root\ExtraFiles"

# Dot Source Variables
#. $AEBScripts\ScriptVariables.ps1
. $AEBScripts\ClientLoadVariables.ps1

# Dot Source Functions
. $AEBScripts\ScriptCoreFunctions.ps1
. $AEBScripts\ScriptEnvironmentFunctions.ps1
. $AEBScripts\ScriptDesktopFunctions.ps1
. $AEBScripts\ScriptServerFunctions.ps1
#. $AEBScripts\ClientLoadFunctions.ps1

# Load Azure Modules and Connect
ConnectTo-Azure

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true'  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

#region Main
Write-AEBLog 'Running AEB-RebuildAzureVM.ps1'
if ($VMName -eq '') {
    $VMList = Get-AzVM -Name * -ResourceGroupName $RGNameDEV -ErrorAction SilentlyContinue
    $VMName = ($VMlist | Where-Object { $_.Name -notin $VMListExclude } | Select-Object Name | Out-GridView -Title 'Select Virtual Machine to Rebuild' -OutputMode Single).Name
    if (!$VMName) { exit }
    $VMSpec = @('Desktop-Standard', 'Desktop-Packaging', 'Desktop-AdminStudio', 'Desktop-Jumpbox', 'Desktop-Core')
    $Spec = $VMSpec | Out-GridView -Title 'Select Virtual Machine Spec' -OutputMode Single
}
Write-Warning "This Script is about to Rebuild: $VMName with Spec: $Spec.  OK to Continue?" -WarningAction Inquire

# Update Storage
UpdateStorage

Write-AEBLog "Rebuilding: $VMName with Spec: $Spec"
ScriptRebuild-Create-VM
ScriptRebuild-Config-VM
Write-AEBLog 'Completed AEB-RebuildAzureVM.ps1'
Write-AEBLog '============================================================================================================='
#endregion Main
