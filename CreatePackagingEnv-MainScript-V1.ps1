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

function UpdateStorage {
    if ($RequireUpdateStorage) {
        Try {
            $Key = Get-AzStorageAccountKey -ResourceGroupName $RGNameSTORE -AccountName $StorageAccountName
            $templates = Get-ChildItem -Path $ContainerScripts -Filter *tmpl* -File
            foreach ($template in $templates) {
                $content = Get-Content -Path "$ContainerScripts\$(($template).Name)"
                $content = $content.replace("xxxxx", $StorageAccountName)
                $content = $content.replace("sssss", $azSubscription)
                $content = $content.replace("yyyyy", $Key.value[0])
                $content = $content.replace("ddddd", $Domain)
                $content = $content.replace("ooooo", $OUPath)
                $content = $content.replace("rrrrr", $RGNameSTORE)
                $content = $content.replace("fffff", $FileShareName)
                $contentName = $template.Basename -replace "Tmpl"
                $contentName = $contentName + ".ps1"
                $content | Set-Content -Path "$ContainerScripts\$contentName"
            }     
        }
        Catch {
            Write-Error "An error occured trying to create the customised scripts for the packaging share."
            Write-Error $_.Exception.Message
        }
        . .\SyncFiles.ps1 -CallFromCreatePackaging -Recurse        # Sync Files to Storage Blob
        #. .\SyncFiles.ps1 -CallFromCreatePackaging                  # Sync Files to Storage Blob
        Write-Host "Storage Account has been Updated with files"
    }
}
function UpdateRBAC {
    Try {
        $OwnerGroup = Get-AzADGroup -DisplayName $rbacOwner
        $ContributorGroup = Get-AzADGroup -DisplayName $rbacContributor
        $ReadOnlyGroup = Get-AzADGroup -DisplayName $rbacReadOnly

        New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNamePROD | Out-Null
        New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNamePROD | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNamePROD | Out-Null
        if (!($RGNameDEV -match $RGNamePROD)) {
            New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNameDEV | Out-Null
            New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNameDEV | Out-Null
            New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNameDEV | Out-Null
        }
        if (!($RGNameSTORE -match $RGNamePROD)) {
            New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNameSTORE | Out-Null
            New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNameSTORE | Out-Null
            New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNameSTORE | Out-Null
        }
        Write-Host "Role Assignments Set"
    } Catch {
        Write-Error $_.Exception.Message
    }
}

#region Main
#=======================================================================================================================================================
cd $PSScriptRoot

if($RequireCreate) {
        # Create Resource Groups
    if($RequireResourceGroups -and !$UseTerraform) {
        $RG = New-AzResourceGroup -Name $RGNamePROD -Location $Location
        if ($RG.ResourceGroupName -eq $RGNamePROD) {Write-Host "PROD Resource Group created successfully"}Else{Write-Host "*** Unable to create PROD Resource Group! ***"}
        if (!($RGNameDEV -match $RGNamePROD)) {
            $RG = New-AzResourceGroup -Name $RGNameDEV -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEV) { Write-Host "DEV Resource Group created successfully" }Else { Write-Host "*** Unable to create DEV Resource Group! ***" }
        }
        if (!($RGNameDEV -match $RGNameDEVVNET)) {
            $RG = New-AzResourceGroup -Name $RGNameDEVVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameDEVVNET) { Write-Host "DEV VNET Resource Group created successfully" }Else { Write-Host "*** Unable to create DEV VNET Resource Group! ***" }
        }
        if (!($RGNamePROD -match $RGNamePRODVNET)) {
            $RG = New-AzResourceGroup -Name $RGNamePRODVNET -Location $Location
            if ($RG.ResourceGroupName -eq $RGNamePRODVNET) { Write-Host "PROD VNET Resource Group created successfully" }Else { Write-Host "*** Unable to create PROD VNET Resource Group! ***" }
        } 
        if (!($RGNamePROD -match $RGNameSTORE) -and $RequireStorageAccount) {
            $RG = New-AzResourceGroup -Name $RGNameSTORE -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameSTORE) { Write-Host "STORE Resource Group created successfully" }Else { Write-Host "*** Unable to create STORE Resource Group! ***" }
        }
    }
    if ($UseTerraform) {
        $TerraformMainTemplate = Get-Content -Path ".\Terraform\Root Template\main.tf" | Set-Content -Path ".\Terraform\main.tf"    
    }

        # Environment Script
    .\CreatePackagingEnv-Env-V2.ps1

        # Create Packaging VM Script
    .\CreatePackagingEnv-PackagingVms-V2.ps1

        # Create Hyper-V Script
    if ($RequireHyperV) {
        .\CreatePackagingEnv-HyperVServer-V1.ps1
    }

    if($UseTerraform) {
        cd .\terraform
        $ARGUinit = "init"
        $ARGUplan = "plan -out .\terraform.tfplan"
        $ARGUapply = "apply -auto-approve .\terraform.tfplan"
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUinit -Wait -RedirectStandardOutput .\terraform-init.txt -RedirectStandardError .\terraform-error-init.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUplan -Wait -RedirectStandardOutput .\terraform-plan.txt -RedirectStandardError .\terraform-error-plan.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUapply -Wait -RedirectStandardOutput .\terraform-apply.txt -RedirectStandardError .\terraform-error-apply.txt
        cd ..
    }
}

    # Update Storage
if($RequireUpdateStorage) {
    UpdateStorage
}

if ($RequireConfigure) {
    if ($RequireRBAC) {
            # Update RBAC
        UpdateRBAC
    }

        # Configure Packaging VM Script
    .\CreatePackagingEnv-PackagingVms-Configure.ps1

        # Configure Hyper-V Script
    if($RequireHyperV) {
        .\CreatePackagingEnv-HyperVServer-Configure.ps1
    }
}
Write-Host "All Scripts Completed"
#endregion Main