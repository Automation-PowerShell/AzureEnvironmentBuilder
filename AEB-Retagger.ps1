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
  Connect-AzAccount -Tenant '9983e9de-6ceb-499b-a06c-e030f24bd236'
  Connect-AzAccount -Tenant '7233444a-1eb9-4092-a211-485856124eb6'
}
#endregion

#$selectedSub = Get-AzSubscription -TenantId $clientSettings.azTenant | Out-GridView -OutputMode Single -Title 'Select Subscription'
$selectedSub = Get-AzSubscription | Sort-Object -Property Name |  Out-GridView -OutputMode Single -Title 'Select Subscription'
Write-Host "##vso[task.LogIssue type=warning;]Switching Subscription to $($selectedSub)"
#Select-AzSubscription -Subscription $selectedSub -Tenant $clientSettings.azTenant | Out-Null
Select-AzSubscription -Subscription $selectedSub | Out-Null

$rgs = Get-AzResourceGroup | Select-Object ResourceGroupName | Sort-Object -Property ResourceGroupName
$selectedRG = $rgs | Out-GridView -OutputMode Single -Title 'Select Resource Group'
  if(!$selectedRG) {
    exit
  }

$resources = Get-AzResource -ResourceGroupName $selectedRG.ResourceGroupName
$selectedResources = ($resources | Select-Object -Property @(
    'Name'
    'ResourceType'
    @{Name = 'Appliction'; Expression = { ($_.Tags.Application) } }
    @{Name = 'Environment'; Expression = { ($_.Tags.Environment) } }
    @{Name = 'AEB-Application'; Expression = { ($_.Tags.'AEB-Application') } }
    @{Name = 'AEB-Client'; Expression = { ($_.Tags.'AEB-Client') } }
    @{Name = 'AEB-Environment'; Expression = { ($_.Tags.'AEB-Environment') } }
    @{Name = 'acp-ims-mde'; Expression = { ($_.Tags.'acp-ims-mde') } }
    @{Name = 'acp-ims-qualys'; Expression = { ($_.Tags.'acp-ims-qualys') } }
    @{Name = 'acp-ims-splunk'; Expression = { ($_.Tags.'acp-ims-splunk') } }
    @{Name = 'acp-ims-tanium'; Expression = { ($_.Tags.'acp-ims-tanium') } }
    'Id' ) | Sort-Object -Property Name | Out-GridView -OutputMode Multiple -Title 'Select Resources to Retag')
if(!$selectedResources) {
  exit
}


$selectedTags = (Get-AzResourceGroup -ResourceGroupName $selectedRG.ResourceGroupName).Tags | Out-GridView -OutputMode Multiple -Title 'Select Tag Pairs'
$mergedTags = @{}
foreach ($tag in $selectedTags) {
  $mergedTags.Add($tag.Name, $tag.Value)
}

foreach ($id in $selectedResources.Id) {
  Update-AzTag -ResourceId $id -Tag $mergedTags -Operation Merge | Select-Object *
}

$resources = Get-AzResource -ResourceGroupName $selectedRG.ResourceGroupName
$selectedResources = ($resources | Select-Object -Property @(
  'Name'
  'ResourceType'
  @{Name = 'Appliction'; Expression = { ($_.Tags.Application) } }
  @{Name = 'Environment'; Expression = { ($_.Tags.Environment) } }
  @{Name = 'AEB-Application'; Expression = { ($_.Tags.'AEB-Application') } }
  @{Name = 'AEB-Client'; Expression = { ($_.Tags.'AEB-Client') } }
  @{Name = 'AEB-Environment'; Expression = { ($_.Tags.'AEB-Environment') } }
  @{Name = 'acp-ims-mde'; Expression = { ($_.Tags.'acp-ims-mde') } }
  @{Name = 'acp-ims-qualys'; Expression = { ($_.Tags.'acp-ims-qualys') } }
  @{Name = 'acp-ims-splunk'; Expression = { ($_.Tags.'acp-ims-splunk') } }
  @{Name = 'acp-ims-tanium'; Expression = { ($_.Tags.'acp-ims-tanium') } }
    'Id' ) | Sort-Object -Property Name | Out-GridView -OutputMode None -Title 'Review Resources')

#$rgID = (Get-AzResourceGroup -ResourceGroupName $selectedRG).ResourceId
#Update-AzTag -ResourceId $rgID -Tag $mergedTags -Operation Merge -Verbose
