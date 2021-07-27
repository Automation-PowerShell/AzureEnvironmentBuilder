﻿#region Setup
cd $PSScriptRoot

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
Write-Log "Running PEB-AzureRemover.ps1"
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
Write-Log "Completed PEB-AzureRemover.ps1"
Write-Log "============================================================================================================="
#endregion