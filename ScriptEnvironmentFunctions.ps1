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
        Write-Log "Storage Account has been Updated with files"
    }
}
function UpdateRBAC {
    Try {
        $OwnerGroup = Get-AzADGroup -DisplayName $rbacOwner
        $ContributorGroup = Get-AzADGroup -DisplayName $rbacContributor
        $ReadOnlyGroup = Get-AzADGroup -DisplayName $rbacReadOnly

        New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNamePROD -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNamePROD -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNamePROD -ErrorAction Ignore | Out-Null
        if (!($RGNameDEV -match $RGNamePROD)) {
            New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNameDEV -ErrorAction Ignore | Out-Null
            New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNameDEV -ErrorAction Ignore | Out-Null
            New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNameDEV -ErrorAction Ignore | Out-Null
        }
        if (!($RGNameSTORE -match $RGNamePROD)) {
            New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNameSTORE -ErrorAction Ignore | Out-Null
            New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNameSTORE -ErrorAction Ignore | Out-Null
            New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNameSTORE -ErrorAction Ignore | Out-Null
        }
        Write-Log "Role Assignments Set"
    } Catch {
        Write-Error $_.Exception.Message
    }
}