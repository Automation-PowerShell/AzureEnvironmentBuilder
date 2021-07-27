Param(
    [Parameter(Mandatory = $false)][string]$VMName = "",
    [Parameter(Mandatory = $false)][ValidateSet("Standard", "AdminStudio", "Jumpbox","Core")][string]$Spec = "Standard"
)

#region Setup
cd $PSScriptRoot

    # Script Variables
$root = $PSScriptRoot
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
    $VMName = ($VMlist | where { $_.Name -notin $VMListExclude  } | select Name | ogv -Title "Select Virtual Machine to Rebuild" -PassThru).Name
    if (!$VMName) {exit}
    $VMSpec = @("Standard","AdminStudio","Jumpbox","Core")
    $Spec = $VMSpec | ogv -Title "Select Virtual Machine Spec" -PassThru
}
Write-Warning "This Script is about to Rebuild: $VMName with Spec: $Spec.  OK to Continue?" -WarningAction Inquire

    #Write-Log "Syncing Files"
UpdateStorage

Write-Log "Rebuilding: $VMName with Spec: $Spec"
ScriptRebuild-Create-VM
ScriptRebuild-Config-VM
Write-Log "Completed PEB-RebuildAzureVM.ps1"
Write-Log "============================================================================================================="
#endregion Main
