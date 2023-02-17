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
  ConnectTo-Azure
}

$mergedTags = @{
  'Application' = 'AEB';
}

#$mergedTags = @{
#  'Application' = 'AEB';
#  'AEB-Client' = 'TestClient1'
#  'AEB-Environment' = 'Dev'
#}

$csvfile = './subscriptions-resourcegroups.csv'
$csvpath = Split-Path -Path $csvfile -Parent
$Import = Import-Csv -Path $csvfile
$subscriptions = $Import.Sub | Sort-Object -Unique

$selectedSub = $subscriptions | Out-GridView -OutputMode Single
Write-Host "##vso[task.LogIssue type=warning;]Switching Subscription to $($selectedSub)"
Select-AzSubscription -Subscription $selectedSub | Out-Null
$rgs = Get-AzResourceGroup | Select-Object ResourceGroupName
$selectedRG = $rgs | Out-GridView -OutputMode Single

$resources = Get-AzResource -ResourceGroupName $selectedRG.ResourceGroupName
$selectedResources = ($resources | Select-Object -Property @(
    'Name'
    @{Name = 'Appliction'; Expression = { ($_.Tags.Application) } }
    @{Name = 'Environment'; Expression = { ($_.Tags.Environment) } }
    @{Name = 'AEB-Application'; Expression = { ($_.Tags.'AEB-Application') } }
    @{Name = 'AEB-Client'; Expression = { ($_.Tags.'AEB-Client') } }
    @{Name = 'AEB-Environment'; Expression = { ($_.Tags.'AEB-Environment') } }
    'Id' ) | Sort-Object -Property Name | Out-GridView -OutputMode Multiple)

foreach ($id in $selectedResources.Id) {
  Update-AzTag -ResourceId $id -Tag $mergedTags -Operation Merge -Verbose
}

#$rgID = (Get-AzResourceGroup -ResourceGroupName $selectedRG).ResourceId
#Update-AzTag -ResourceId $rgID -Tag $mergedTags -Operation Merge -Verbose
