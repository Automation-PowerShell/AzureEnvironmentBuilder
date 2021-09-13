<#
.SYNOPSIS
PEB-AzureRemiver.ps1

.DESCRIPTION
Packaging Environment Builder - Azure Remover.
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
$PEBScripts = "$root\PEB-Scripts"

    # Dot Source Variables
. $PEBScripts\ScriptVariables.ps1
. $PEBScripts\ClientLoadVariables.ps1

    # Dot Source Functions
. $PEBScripts\ScriptCoreFunctions.ps1

    # Load Azure Modules and Connect
ConnectTo-Azure

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

#region Main
Write-PEBLog "Running PEB-AzureRemover.ps1"
if($isProd) { Write-Warning "Are you sure you want to delete the Packaging Environment?  OK to Continue?" -WarningAction Inquire }

if(!($isProd) -and $RequireUserGroups) {
    Remove-AzAdGroup -DisplayName $rbacOwner -ErrorAction Ignore  -Force -Verbose
    Remove-AzAdGroup -DisplayName $rbacContributor -ErrorAction Ignore  -Force -Verbose
    Remove-AzAdGroup -DisplayName $rbacReadOnly -ErrorAction Ignore  -Force -Verbose
}
Remove-AzResourceGroup -Name $RGNameDEV -Force -ErrorAction Ignore -Verbose
Remove-AzResourceGroup -Name $RGNamePROD -Force -ErrorAction Ignore -Verbose
if(!($isProd)) {
    Remove-AzResourceGroup -Name $RGNameDEVVNET -Force -ErrorAction Ignore -Verbose         # Dont want to do this is a Production Environment
    Remove-AzResourceGroup -Name $RGNamePRODVNET -Force -ErrorAction Ignore -Verbose        # Dont want to do this is a Production Environment
}
Write-PEBLog "Completed PEB-AzureRemover.ps1"
Write-PEBLog "============================================================================================================="
#endregion
