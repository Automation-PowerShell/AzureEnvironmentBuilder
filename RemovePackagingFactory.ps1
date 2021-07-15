#region Setup
cd $PSScriptRoot
. .\ScriptVariables.ps1
. .\ClientVariables-Dan.ps1

Import-Module Az.Compute, Az.Accounts, Az.Storage, Az.Network, Az.Resources -ErrorAction SilentlyContinue
if (!((Get-Module Az.Compute) -and (Get-Module Az.Accounts) -and (Get-Module Az.Storage) -and (Get-Module Az.Network) -and (Get-Module Az.Resources))) {
    Install-Module Az.Compute, Az.Accounts, Az.Storage, Az.Network, Az.Resources -Repository PSGallery -Scope CurrentUser -Force
    Import-Module AZ.Compute, Az.Accounts, Az.Storage, Az.Network, Az.Resources
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
#endregion


#region old
#del $ContainerScripts\MapDrv.ps1
#del $ContainerScripts\RunOnce.ps1
#del $ContainerScripts\AdminStudio.ps1
#Remove-AzAdGroup -DisplayName "Packaging-Owner-RBAC" -Force
#Remove-AzAdGroup -DisplayName "Packaging-Contributor-RBAC" -Force
#Remove-AzAdGroup -DisplayName "Packaging-ReadOnly-RBAC" -Force
#endregion
