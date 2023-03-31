<#
.SYNOPSIS
AEB-BastionCommission.ps1

.DESCRIPTION
Azure Environment Builder - Bastion Commission
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
$AEBClientFiles = "$root\AEB-ClientFiles"
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
    #Connect-AzAccount
    ConnectTo-Azure
}

#Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true'  # Turns off Breaking Changes warnings for Cmdlets
Update-AzConfig -DisplayBreakingChangeWarning $false
#endregion Setup

function AEBCommission {
    Write-AEBLog 'Running AEB-BastionCommission.ps1'
    foreach ($environment in $clientSettings.vnets.GetEnumerator().Name) {
        $resourceCheck = Get-AzResource -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name "$($clientSettings.bastions.$environment.BastionName)-pip" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if (!$resourceCheck) {
            Write-AEBLog "Commissioning Bastion for $environment VNETS in RG: $($clientSettings.rgs.$environment.RGNameVNET)"
            $publicip = New-AzPublicIpAddress -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name "$($clientSettings.bastions.$environment.BastionName)-pip" -Location $clientSettings.location -AllocationMethod Static -Sku Standard
            Start-Sleep -Seconds 10
            $resource = New-AzBastion -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name $clientSettings.bastions.$environment.BastionName `
                -PublicIpAddressRgName $clientSettings.rgs.$environment.RGNameVNET -PublicIpAddressName "$($clientSettings.bastions.$environment.BastionName)-pip" `
                -VirtualNetworkRgName $clientSettings.rgs.$environment.RGNameVNET -VirtualNetworkName $clientSettings.vnets.$environment[0] `
                -Sku Basic -Tag $clientSettings.tags -AsJob
        }
        else {
            Write-AEBLog "Bastion for $environment VNETs in RG: $($clientSettings.rgs.$environment.RGNameVNET) not required"
        }
    }

    Write-AEBLog 'Completed AEB-BastionCommission.ps1'
    Write-AEBLog '============================================================================================================='
}

function AVAWSCommission {
    $bastionList = @{
        '6745a72d-32fc-4525-b5e9-80119fa1606b' = @(
            'rg-AccessCapture-Dev'
            'rg-TestClient0'
        )
        '205cb73d-d832-401b-96c9-99dfd5549a15' = @(
            'rg-TestClient0'
        )
    }

    foreach ($sub in $bastionList.Keys) {
        Select-AzSubscription -Subscription $sub | Out-Null
        foreach ($rg in $bastionList.$sub) {
            $local:resourceCheck = Get-AzResource -ResourceGroupName $rg -Name 'bastion-*-pip' -Verbose
            if (!$resourceCheck) {
                $local:vnet = Get-AzVirtualNetwork -ResourceGroupName $rg | Select-Object -First 1 -Verbose
                $local:publicip = New-AzPublicIpAddress -ResourceGroupName $rg -Name "bastion-$rg-pip" -Location 'uksouth' -AllocationMethod Static -Sku Standard -Verbose
                Start-Sleep -Seconds 10
                New-AzBastion -ResourceGroupName $rg -Name "bastion-$rg" `
                    -PublicIpAddressRgName $rg -PublicIpAddressName "bastion-$rg-pip" `
                    -VirtualNetworkRgName $rg -VirtualNetworkName $vnet.Name `
                    -Sku Basic -AsJob -Verbose
            }
        }
    }
}

#AVAWSCommission
AEBCommission