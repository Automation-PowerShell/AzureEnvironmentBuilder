<#
.SYNOPSIS
PEB-RebuildAzureVM.ps1

.DESCRIPTION
Packaging Environment Builder - Rebuild Azure VM.
Wrtitten by Graham Higginson and Daniel Ames.

.NOTES
Written by      : Graham Higginson & Daniel Ames
Build Version   : 0.1 Alpha

.LINK
More Info       : https://github.com/satsuk81/PackagingEnvironmentBuilder

#>

Param(
    [Parameter(Mandatory = $false)][string]$VMName = "",
    [Parameter(Mandatory = $false)][ValidateSet("Standard", "AdminStudio", "Jumpbox","Core")][string]$Spec = "Standard"
)

#region Setup
Set-Location $PSScriptRoot

    # Script Variables
$root = $PSScriptRoot
#$root = $pwd
$PEBScripts = "$root\PEB-Scripts"

    # Dot Source Variables
. $PEBScripts\ScriptVariables.ps1
. $PEBScripts\ClientLoadVariables.ps1

    # Dot Source Functions
. $PEBScripts\ScriptCoreFunctions.ps1
. $PEBScripts\ScriptEnvironmentFunctions.ps1
. $PEBScripts\ScriptPackagingFunctions.ps1
. $PEBScripts\ScriptHyperVFunctions.ps1
. $PEBScripts\ClientLoadFunctions.ps1

    # Load Azure Modules and Connect
ConnectTo-Azure

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

#region Main
Write-Log "Running PEB-RebuildAzureVM.ps1"
if($VMName -eq "") {
    $VMList = Get-AzVM -Name * -ResourceGroupName $RGNameDEV -ErrorAction SilentlyContinue
    $VMName = ($VMlist | Where-Object { $_.Name -notin $VMListExclude  } | Select-Object Name | Out-GridView -Title "Select Virtual Machine to Rebuild" -OutputMode Single).Name
    if (!$VMName) {exit}
    $VMSpec = @("Standard","AdminStudio","Jumpbox","Core")
    $Spec = $VMSpec | Out-GridView -Title "Select Virtual Machine Spec" -OutputMode Single
}
Write-Warning "This Script is about to Rebuild: $VMName with Spec: $Spec.  OK to Continue?" -WarningAction Inquire

    # Update Storage
UpdateStorage

Write-Log "Rebuilding: $VMName with Spec: $Spec"
ScriptRebuild-Create-VM
ScriptRebuild-Config-VM
Write-Log "Completed PEB-RebuildAzureVM.ps1"
Write-Log "============================================================================================================="
#endregion Main
