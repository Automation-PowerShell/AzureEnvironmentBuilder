function CreateHyperVVM-Terraform($VMName) {
    mkdir -Path ".\Terraform\" -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path ".\Terraform\template-server2019\variables.tf").Replace("xxxx", $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path ".\Terraform\template-server2019\main.tf") | Set-Content -Path ".\Terraform\$VMName\main.tf"

    $TerraformText = "
module " + [char]34 + $VMName + [char]34 + " {
  source = " + [char]34 + "./" + $VMName + [char]34 + "

  myterraformgroupName = module.environment.myterraformgroup.name
  myterraformsubnetID = module.environment.myterraformsubnet.id
  myterraformnsgID = module.environment.myterraformnsg.id
}"

    $TerraformMain = Get-Content -Path ".\Terraform\main.tf"
    $TerraformText | Add-Content -Path ".\Terraform\main.tf"
}

function CreateHyperVVM-Script($VMName) {
    $Vnet = Get-AzVirtualNetwork -Name $VNetPROD -ResourceGroupName $RGNamePRODVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNamePROD -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNamePROD -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNamePROD -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VmSizeHyperV -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.'Server-HyperV'.PublisherName -Offer $deviceSpecs.'Server-HyperV'.Offer -Skus $deviceSpecs.'Server-HyperV'.SKUS -Version $deviceSpecs.'Server-HyperV'.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNamePROD -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function TerraformBuild-HVVM {
        # Build Hyper-V Server VM
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VMHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-PEBLog "Creating $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart

            CreateHyperVVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild-HVVM {
        # Build Hyper-V Server VM
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VMHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-PEBLog "Creating $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateHyperVVM-Script "$VM"
            }
            else {
                Write-PEBLog "*** VM: $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }
}

function ConfigureHyperVVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNamePROD -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-PEBLog "VM $VMName created successfully"

        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name "User" | Select-AzContext | Out-Null

            # Add Data disk to Hyper-V server
        $dataDiskName = $VMName + '_datadisk1'
        $diskConfig = New-AzDiskConfig -SkuName $dataDiskSKU -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $RGNamePROD
        Add-AzVMDataDisk -VM $VMCreate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1 -Verbose | Out-Null
        Update-AzVM -VM $VMCreate -ResourceGroupName $RGNamePROD -Verbose | Out-Null

        Restart-AzVm -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null
        Write-PEBLog "VM: $VMName - Restarting VM..."
        Start-Sleep -Seconds 120
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Prevision.ps1" "Prevision.ps1"
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/RunOnce.ps1" "RunOnce.ps1"
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/ConfigureDataDisk.ps1" "ConfigureDataDisk.ps1"
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/EnableHyperV.ps1" "EnableHyperV.ps1"
        Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null
        Write-PEBLog "VM: $VMName - Restarting VM..."
        Start-Sleep -Seconds 120
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/ConfigHyperV.ps1" "ConfigHyperV.ps1"
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/DomainJoin.ps1" "DomainJoin.ps1"
        Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null
        Write-PEBLog "VM: $VMName - Restarting VM..."
        Start-Sleep -Seconds 120
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Build-VM.ps1" "Build-VM.ps1"
        #RunVMConfig "$RGNamePROD" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Build-VMBase.ps1" "Build-VMBase.ps1"
    }
    Else {
        Write-PEBLog "*** VM $VMName - Unable to configure Virtual Machine! ***" -Level Error
    }
}

function TerraformConfigure-HVVM {
        # Configure Hyper-V VMs
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VmHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-PEBLog "Configuring $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            ConfigureHyperVVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptConfigure-HVVM {
        # Configure Hyper-V VMs
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VmHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-PEBLog "Configuring $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            ConfigureHyperVVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}