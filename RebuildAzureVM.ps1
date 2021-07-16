Param(
    [Parameter(Mandatory = $false)][string]$VMName = "",
    [Parameter(Mandatory = $false)][ValidateSet('Standard', 'AdminStudio', 'Jumpbox')][string]$Spec = "Standard"
)

#region Setup
cd $PSScriptRoot

    # Dot Source Variables
. .\ScriptVariables.ps1
. .\ClientVariables-Template.ps1
        
    # Dot Source Functions
. .\ScriptCoreFunctions.ps1
. .\ScriptEnvironmentFunctions.ps1
. .\ScriptPackagingFunctions.ps1
. .\ScriptHyperVFunctions.ps1
. .\ClientHyperVFunctions-Template.ps1
. .\ClientPackagingFunctions-Template.ps1

Import-Module Az.Compute,Az.Accounts,Az.Storage,Az.Network,Az.Resources -ErrorAction SilentlyContinue
if(!((Get-Module Az.Compute) -and (Get-Module Az.Accounts) -and (Get-Module Az.Storage) -and (Get-Module Az.Network) -and (Get-Module Az.Resources))) {
    Install-Module Az.Compute,Az.Accounts,Az.Storage,Az.Network,Az.Resources -Repository PSGallery -Scope CurrentUser -Force
    Import-Module AZ.Compute,Az.Accounts,Az.Storage,Az.Network,Az.Resources
}

Clear-AzContext -Force
Connect-AzAccount -Tenant $aztenant -Subscription $azSubscription
$SubscriptionId = (Get-AzContext).Subscription.Id
if (!($azSubscription -eq $SubscriptionId)) {
    Write-Error "Subscription ID Mismatch!!!!"
    exit
}
Get-AzContext | Rename-AzContext -TargetName "User" -Force
if ($RequireServicePrincipal) {
    Connect-AzAccount -Tenant $azTenant -Subscription $azSubscription -Credential $ServicePrincipalCred -ServicePrincipal
    Get-AzContext | Rename-AzContext -TargetName "StorageSP" -Force
    Get-AzContext -Name "User" | Select-AzContext
}

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

#region Main
Write-Log "Running RebuildAzureVM.ps1"
if($VMName -eq "") {
    $VMList = Get-AzVM -Name * -ResourceGroupName $RGNameDEV -ErrorAction SilentlyContinue
    $VMName = ($VMlist | where { $_.Name -notin $VMListExclude  } | select Name | ogv -Title "Select Virtual Machine to Rebuild" -PassThru).Name
    if (!$VMName) {exit}
    $VMSpec = @("Standard","AdminStudio","Jumpbox")
    $Spec = $VMSpec | ogv -Title "Select Virtual Machine Spec" -PassThru
}
Write-Warning "This Script is about to Rebuild: $VMName with Spec: $Spec.  OK to Continue?" -WarningAction Inquire

#Write-Log "Syncing Files"
UpdateStorage

Write-Log "Rebuilding: $VMName with Spec: $Spec"
ScriptBuild-Create-VM
ScriptBuild-Config-VM
Write-Log "Completed RebuildAzureVM.ps1"
#endregion Main