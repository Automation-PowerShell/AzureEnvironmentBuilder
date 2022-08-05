<#
.SYNOPSIS
AEB-AzureRemover.ps1

.DESCRIPTION
Azure Environment Builder - Azure Remover.
Wrtitten by Graham Higginson and Daniel Ames.

.NOTES
Written by      : Graham Higginson & Daniel Ames
Build Version   : v2

.LINK
More Info       : https://github.com/Automation-PowerShell/AzureEnvironmentBuilder

#>

#region Setup
Set-Location $PSScriptRoot

    # Script Variables
$root = $PSScriptRoot
$AEBScripts = "$root\AEB-Scripts"
$ExtraFiles = "$root\ExtraFiles"

    # Dot Source Variables
#. $AEBScripts\ScriptVariables.ps1
. $AEBScripts\ClientLoadVariables.ps1

    # Dot Source Functions
. $AEBScripts\ScriptCoreFunctions.ps1

    # Load Azure Modules and Connect
ConnectTo-Azure

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

#region Main
Write-AEBLog "Running AEB-AzureRemover.ps1"
if($isProd) { Write-Warning "Are you sure you want to delete the Azure Environment?  OK to Continue?" -WarningAction Inquire }

if(!($isProd) -and $RequireUserGroups) {
    Remove-AzAdGroup -DisplayName $rbacOwner -ErrorAction Ignore -Verbose
    Remove-AzAdGroup -DisplayName $rbacContributor -ErrorAction Ignore -Verbose
    Remove-AzAdGroup -DisplayName $rbacReadOnly -ErrorAction Ignore -Verbose
}
Remove-AzResourceGroup -Name $RGNameDEV -Force -ErrorAction Ignore -Verbose
Remove-AzResourceGroup -Name $RGNamePROD -Force -ErrorAction Ignore -Verbose
if(!($isProd)) {
    Remove-AzResourceGroup -Name $RGNameDEVVNET -Force -ErrorAction Ignore -Verbose         # Dont want to do this is a Production Environment
    Remove-AzResourceGroup -Name $RGNamePRODVNET -Force -ErrorAction Ignore -Verbose        # Dont want to do this is a Production Environment
}
Write-AEBLog "Completed AEB-AzureRemover.ps1"
Write-AEBLog "============================================================================================================="
#endregion
