function ConfigureHyperVVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNameUAT -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"

        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        #$Group = Get-AzADGroup -searchstring $rbacContributor
        #Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id

        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue
        Get-AzContext -Name "User" | Select-AzContext

            # Add Data disk to Hyper-V server
        $dataDiskName = $VMName + '_datadisk1'
        $diskConfig = New-AzDiskConfig -SkuName $dataDiskSKU -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $RGNamePROD
        Add-AzVMDataDisk -VM $VMCreate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
        Update-AzVM -VM $VMCreate -ResourceGroupName $RGNamePROD

        Restart-AzVm -ResourceGroupName $RGNamePROD -Name $VMName
        #RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/Prevision.ps1" "Prevision.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/ConfigureDataDisk.ps1" "ConfigureDataDisk.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/EnableHyperV.ps1" "EnableHyperV.ps1"
        Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null    
        Write-Host "Restarting VM..."
        Start-Sleep -Seconds 120
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        #RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/DomainJoin.ps1" "DomainJoin.ps1"
        #Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null    
        Write-Host "Restarting VM..."
        Start-Sleep -Seconds 120
        #RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/Build-VM.ps1" "Build-VM.ps1"
    }
    Else {
        Write-Host "*** Unable to configure Virtual Machine $VMName! ***"
    }
}

function RunVMConfig($VMName, $BlobFilePath, $Blob) {
    $Params = @{
        ResourceGroupName = $RGNamePROD
        VMName            = $VMName
        Location          = $Location
        FileUri           = $BlobFilePath
        Run               = $Blob
        Name              = "ConfigureVM"
    }

    $VMConfigure = Set-AzVMCustomScriptExtension @Params
    If ($VMConfigure.IsSuccessStatusCode -eq $True) { Write-Host "Virtual Machine $VMName configured with $Blob successfully" }Else { Write-Host "*** Unable to configure Virtual Machine $VMName with $Blob ***" }
}
function TerraformBuild {
        # Configure Hyper-V VMs
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VmHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-Host "Configuring $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            ConfigureHyperVVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild {
        # Configure Hyper-V VMs
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VmHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-Host "Configuring $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            ConfigureHyperVVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

#region Main
#=======================================================================================================================================================
if ($UseTerraform) {
    TerraformBuild
}
else {
    ScriptBuild
}
Write-Host "Hyper-V Configure Script Completed"
#endregion Main