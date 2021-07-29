function UpdateStorage {
    if ($RequireUpdateStorage) {
        Try {
            $Key = Get-AzStorageAccountKey -ResourceGroupName $RGNameSTORE -AccountName $StorageAccountName
            $templates = Get-ChildItem -Path $BlobFilesSource -Filter *tmpl* -File
            foreach ($template in $templates) {
                $content = Get-Content -Path "$BlobFilesSource\$(($template).Name)"
                $content = $content.replace("xxxxx", $StorageAccountName)
                $content = $content.replace("sssss", $azSubscription)
                $content = $content.replace("yyyyy", $Key.value[0])
                $content = $content.replace("ddddd", $Domain)
                $content = $content.replace("ooooo", $OUPath)
                $content = $content.replace("rrrrr", $RGNameSTORE)
                $content = $content.replace("fffff", $FileShareName)
                $contentName = $template.Basename -replace "Tmpl"
                $contentName = $contentName + ".ps1"
                $content | Set-Content -Path "$BlobFilesDest\$contentName"
            }     
        }
        Catch {
            Write-Log "*** An error occured trying to create the customised scripts for the Storage Blob ***" -Level Error
        }
        . $PEBScripts\PEB-SyncFiles.ps1 -CallFromCreatePackaging -Recurse        # Sync Files to Storage Blob
        #. $PEBScripts\PEB-SyncFiles.ps1 -CallFromCreatePackaging                  # Sync Files to Storage Blob
        Write-Log "Storage Account has been Updated with files"
    }
}
function UpdateRBAC {
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
}