<#
.SYNOPSIS
AEB-TagExporter.ps1

.DESCRIPTION
Azure Environment Builder - Tag Exporter
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
    ConnectTo-Azure
}
#endregion

function Get-AllResourceGroups {
    $csvfile = './subscriptions-resourcegroups.csv'
    $csvpath = Split-Path -Path $csvfile -Parent
    $Import = Import-Csv -Path $csvfile
    $subscriptions = $Import.Sub | Sort-Object -Unique

    $resourcegroups = foreach ($sub in $subscriptions) {
        Write-Host "##vso[task.LogIssue type=warning;]Switching Subscription to $($sub)"
        Select-AzSubscription -Subscription $sub | Out-Null
        $rgs = Get-AzResourceGroup | Select-Object ResourceGroupName
        $results = foreach ($rg in $rgs) {
            @([PSCustomObject]@{
                    'Sub' = $sub
                    'RG'  = $rg.ResourceGroupName
                })
        }
        $results
    }
    $resourcegroups = $resourcegroups | Sort-Object -Property Sub, RG
    $resourcegroups | Export-Csv -Path $csvfile -NoTypeInformation
}

function Get-AllTags {
    $csvfile = './subscriptions-resourcegroups.csv'
    $csvpath = Split-Path -Path $csvfile -Parent
    $script:Import = Import-Csv -Path $csvfile

    $ImportHeaders = $Import[0].psobject.properties.name
    foreach ($Headers in $ImportHeaders) {
        if ($Headers -ne 'RG' -and $Headers -ne 'Sub') {
            $Header = $Header += $Headers
        }
    }

    $rgtotal = $import.Count
    $counter = 0
    $errorcount = 0

    $resourcegrouptags = foreach ($RG in $Import) {
        $skip = $false
        $counter++
        Write-Host '----------------------------------'
        Write-Host "RG: $($counter) out of $($rgtotal)"
        Write-Host '----------------------------------'

        <#$csub = Get-AzContext
        if (($csub.Subscription.Id) -ne ($RG.sub)) {
            try {
                Write-Host "##vso[task.LogIssue type=warning;]Switching Subscription to $($RG.sub)"
                Select-AzSubscription -Subscription $RG.sub | Out-Null
            }
            catch {
                Write-Host '##vso[task.LogIssue type=warning;]Error Selecting Subscription - Likely Subscription Permission Issue'
                Write-Host $Error[0]
                break
            }
        }#>

        try { $ResourceGroup = (Get-AzResourceGroup -Name $RG.RG -ErrorAction stop ) }
        catch {
            Write-Host '##vso[task.LogIssue type=warning;]Error Accessing Resource Group - Likely Resource Group Permission Issue'
            Write-Host $Error[0]
            $errorcount++
            $script:errorlist = $script:errorlist + ($RG.RG + ';' + $Error[0])
            $skip = $true
        }

        #if (!$skip -and $ResourceGroup.ResourceGroupName -match '^(\w+-rg-(core|sndbx|dev|test|preprod|prod)-\w+-\d+)$') {
        if (!$skip) {
            $Resources = Get-AzResource -ResourceGroupName $ResourceGroup.ResourceGroupName
            $resourcetags = @()
            $resourcetags += foreach ($r in $Resources) {
                #if ($r.tags.SERVICENAME -notmatch $ResourceGroup.tags.SERVICENAME) {
                #if ($r.tags.SERVICENAME -or $r.tags.servicename -or $r.tags.ServiceName  -or $r.tags.Servicename) {
                if ($r.tags) {
                    @([PSCustomObject]@{
                            'Type'            = 'Resource'
                            'SUB'             = $RG.Sub
                            'ResourceGroup'   = $r.ResourceGroupName
                            'Name'            = $r.Name
                            'ResourceType'    = $r.ResourceType
                            'Application'     = $r.tags.Application
                            'Environment'     = $r.tags.Environment
                            'AEB-Application' = $r.tags.'AEB-Application'
                            'AEB-Client'      = $r.tags.'AEB-Client'
                            'AEB-Environment' = $r.tags.'AEB-Environment'
                            'Keys'            = ($r.Tags.Keys) -join ', '
                            'Values'          = ($r.Tags.Values) -join ', '
                        } )
                }
            }
            if ($resourcetags.Count -ge 1) {
                $resourcetags += @([PSCustomObject]@{
                        'Type'            = 'ResourceGroup'
                        'SUB'             = $RG.sub
                        'ResourceGroup'   = $ResourceGroup.ResourceGroupName
                        'Name'            = $ResourceGroup.ResourceGroupName
                        'ResourceType'    = ''
                        'Application'     = $r.tags.Application
                        'Environment'     = $r.tags.Environment
                        'AEB-Application' = $r.tags.'AEB-Application'
                        'AEB-Client'      = $r.tags.'AEB-Client'
                        'AEB-Environment' = $r.tags.'AEB-Environment'
                        'Keys'            = ($r.Tags.Keys) -join ', '
                        'Values'          = ($r.Tags.Values) -join ', '
                    } )
            }
            else {
                $resourcetags = @([PSCustomObject]@{
                        'Type'            = 'ResourceGroup'
                        'SUB'             = $RG.sub
                        'ResourceGroup'   = $ResourceGroup.ResourceGroupName
                        'Name'            = $ResourceGroup.ResourceGroupName
                        'ResourceType'    = ''
                        'Application'     = $r.tags.Application
                        'Environment'     = $r.tags.Environment
                        'AEB-Application' = $r.tags.'AEB-Application'
                        'AEB-Client'      = $r.tags.'AEB-Client'
                        'AEB-Environment' = $r.tags.'AEB-Environment'
                        'Keys'            = ($r.Tags.Keys) -join ', '
                        'Values'          = ($r.Tags.Values) -join ', '
                    } )
            }
            $resourcetags
        }
    }
    Write-Host "Error Count: $errorcount"
    $datetime = Get-Date -Format 'yyyy-MM-dd HHmmss'
    $outputpath = $csvpath
    $resourcegrouptags | Export-Csv -Path $outputpath\$datetime.csv -NoTypeInformation
}

$script:errorlist = @()
#Get-AllResourceGroups
Get-AllTags
