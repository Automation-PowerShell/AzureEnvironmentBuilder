function ConfigureHyperVVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNamePROD -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        $Date = Get-Date -Format yyyy-MM-dd
        $Time = Get-Date -Format hh:mm
        Write-Host "$Date - $Time -- Virtual Machine $VMName created successfully"

        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$SubscriptionId/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name "User" | Select-AzContext | Out-Null

            # Add Data disk to Hyper-V server
        $dataDiskName = $VMName + '_datadisk1'
        $diskConfig = New-AzDiskConfig -SkuName $dataDiskSKU -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $RGNamePROD
        Add-AzVMDataDisk -VM $VMCreate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1 -Verbose
        Update-AzVM -VM $VMCreate -ResourceGroupName $RGNamePROD -Verbose

        Restart-AzVm -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null
        Write-Host "Restarting VM..."
        Start-Sleep -Seconds 120
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Prevision.ps1" "Prevision.ps1"
        RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/ConfigureDataDisk.ps1" "ConfigureDataDisk.ps1"
        RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/EnableHyperV.ps1" "EnableHyperV.ps1"
        Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null    
        Write-Host "Restarting VM..."
        Start-Sleep -Seconds 120
        RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/ConfigHyperV.ps1" "ConfigHyperV.ps1"
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/DomainJoin.ps1" "DomainJoin.ps1"
        Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null    
        Write-Host "Restarting VM..."
        Start-Sleep -Seconds 120
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Build-VM.ps1" "Build-VM.ps1"
        RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Build-VMBase.ps1" "Build-VMBase.ps1"
    }
    Else {
        Write-Host "*** Unable to configure Virtual Machine $VMName! ***"
    }
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
$Date = Get-Date -Format yyyy-MM-dd
$Time = Get-Date -Format hh:mm
Write-Host "$Date - $Time -- Hyper-V Configure Script Completed"
#endregion Main