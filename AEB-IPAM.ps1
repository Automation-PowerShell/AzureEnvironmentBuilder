<#
.SYNOPSIS
AEB-Retagger.ps1

.DESCRIPTION
Azure Environment Builder - Retagger.
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
$AEBClientFiles= "$root\AEB-ClientFiles"
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
    #ConnectTo-Azure
    #Connect-AzAccount -Tenant $clientSettings.azTenant
    Select-AzSubscription -Subscription $clientSettings.azSubscription -Tenant $clientSettings.azTenant
    #az login --tenant $clientSettings.azTenant
    az account set --subscription $clientSettings.azSubscription
}
#endregion

<#$ResourceNames = @{
    appServiceName        = 'as-' + $clientSettings.ClientName + '-01'
    appServicePlanName    = 'asp-' + $clientSettings.ClientName + '-01'
    cosmosAccountName     = 'ca-' + $clientSettings.ClientName + '-01'
    cosmosContainerName   = 'mycon01'
    cosmosDatabaseName    = 'mydb01'
    keyVaultName          = 'kv-' + $clientSettings.ClientName + '-01'
    workspaceName         = 'law-' + $clientSettings.ClientName + '-01'
    managedIdentityName   = 'id-' + $clientSettings.ClientName + '-01'
    resourceGroupName     = $clientSettings.rgs.STORE.RGName
    storageAccountName    = 'sa' + $clientSettings.ClientName + '01'
    containerRegistryName = 'acr-' + $clientSettings.ClientName + '-01'
}#>

$ResourceNames = @{
    appServiceName        = 'as-' + 'ws-ipam-dev' + '-01'
    appServicePlanName    = 'asp-' + 'ws-ipam-dev' + '-01'
    cosmosAccountName     = 'ca-' + 'ws-ipam-dev' + '-01'
    cosmosContainerName   = 'mycon01'
    cosmosDatabaseName    = 'mydb01'
    keyVaultName          = 'kv-' + 'ws-ipam-dev' + '-01'
    workspaceName         = 'law-' + 'ws-ipam-dev' + '-01'
    managedIdentityName   = 'id-' + 'ws-ipam-dev' + '-01'
    resourceGroupName     = 'rg-ipam-dev-001'
    storageAccountName    = 'sa' + 'ws-ipam-dev' + '01'
    containerRegistryName = 'acr-' + 'ws-ipam-dev' + '-01'
}

Get-Item -Path ./ipam | Remove-Item -Recurse -Force
git clone https://github.com/Azure/ipam.git
Set-Location ./ipam/deploy
./deploy.ps1 `
    -Location $clientSettings.location `
    -ResourceNames $ResourceNames #`
    #-PrivateAcr `
    #-ParameterFile ./main.parameters.json