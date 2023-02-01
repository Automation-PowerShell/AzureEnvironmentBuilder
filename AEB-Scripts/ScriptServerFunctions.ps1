function CreateStdSrv-Script($VMName) {
    $tags = @{}
    $names = $deviceSpecs.'Server-Standard'.Tags | Get-Member -MemberType NoteProperty | Select-Object Name -ExpandProperty Name
    foreach ($name in $names) {
        $value = $deviceSpecs.'Server-Standard'.Tags.$name
        $tags.Add($name, $value)
    }

    $Vnet = Get-AzVirtualNetwork -Name $VNetPROD -ResourceGroupName $RGNamePRODVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNamePROD -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNamePROD -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNamePROD -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.'Server-Standard'.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.'Server-Standard'.PublisherName -Offer $deviceSpecs.'Server-Standard'.Offer -Skus $deviceSpecs.'Server-Standard'.SKUS -Version $deviceSpecs.'Server-Standard'.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNamePROD -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}
function ConfigStdSrv-Script($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNamePROD -Name $VMName
    If ($VMCreate.ProvisioningState -eq 'Succeeded') {
        Write-AEBLog "VM: $VMName created successfully"

        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        Start-Sleep -Seconds 30
        if ($RequireServicePrincipal) {
            Get-AzContext -Name 'StorageSP' | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name 'User' | Select-AzContext | Out-Null
        Set-AzKeyVaultAccessPolicy -ObjectId $NewVm.Id -VaultName $keyVaultName -PermissionsToSecrets Get

        # Add Data disk to Server
        $dataDiskName = $VMName + '_datadisk1'
        $diskConfig = New-AzDiskConfig -SkuName $deviceSpecs.'Server-Standard'.dataDiskSKU -Location $location -CreateOption Empty -DiskSizeGB $deviceSpecs.'Server-Standard'.dataDiskSize
        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $RGNamePROD
        Add-AzVMDataDisk -VM $VMCreate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1 -Verbose | Out-Null
        Update-AzVM -VM $VMCreate -ResourceGroupName $RGNamePROD -Verbose | Out-Null

        Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null
        Write-AEBLog "VM: $VMName - Restarting VM for 120 Seconds..."
        Start-Sleep -Seconds 120

        ConfigureVM -VMName $VMName -VMSpec 'Server-Standard' -RG $RGNamePROD
    }
    Else {
        Write-AEBLog "*** VM: $VMName - Unable to configure Virtual Machine! ***" -Level Error
    }
}

function CreateHyperVVM-Script($VMName) {
    $tags = @{}
    $names = $deviceSpecs.'Server-HyperV'.Tags | Get-Member -MemberType NoteProperty | Select-Object Name -ExpandProperty Name
    foreach ($name in $names) {
        $value = $deviceSpecs.'Server-HyperV'.Tags.$name
        $tags.Add($name, $value)
    }

    $Vnet = Get-AzVirtualNetwork -Name $VNetPROD -ResourceGroupName $RGNamePRODVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNamePROD -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNamePROD -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNamePROD -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.'Server-HyperV'.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.'Server-HyperV'.PublisherName -Offer $deviceSpecs.'Server-HyperV'.Offer -Skus $deviceSpecs.'Server-HyperV'.SKUS -Version $deviceSpecs.'Server-HyperV'.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNamePROD -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}
function ConfigHyperVVM-Script($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNamePROD -Name $VMName
    If ($VMCreate.ProvisioningState -eq 'Succeeded') {
        Write-AEBLog "VM: $VMName created successfully"

        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        Start-Sleep -Seconds 30
        if ($RequireServicePrincipal) {
            Get-AzContext -Name 'StorageSP' | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name 'User' | Select-AzContext | Out-Null
        Set-AzKeyVaultAccessPolicy -ObjectId $NewVm.Id -VaultName $keyVaultName -PermissionsToSecrets Get

        # Add Data disk to Hyper-V server
        $dataDiskName = $VMName + '_datadisk1'
        $diskConfig = New-AzDiskConfig -SkuName $deviceSpecs.'Server-HyperV'.dataDiskSKU -Location $location -CreateOption Empty -DiskSizeGB $deviceSpecs.'Server-HyperV'.dataDiskSize
        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $RGNamePROD
        Add-AzVMDataDisk -VM $VMCreate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1 -Verbose | Out-Null
        Update-AzVM -VM $VMCreate -ResourceGroupName $RGNamePROD -Verbose | Out-Null

        Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null
        Write-AEBLog "VM: $VMName - Restarting VM for 120 Seconds..."
        Start-Sleep -Seconds 120

        ConfigureVM -VMName $VMName -VMSpec 'Server-HyperV' -RG $RGNamePROD
    }
    Else {
        Write-AEBLog "*** VM: $VMName - Unable to configure Virtual Machine! ***" -Level Error
    }
}

function ScriptBuild-Create-Server {
    # Build Standard Server VM
    if ($RequireStdSrv) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Server-Standard'.VMNumberStart
        While ($Count -le $NumberofStdSrvVMs) {
            Write-AEBLog "Creating $Count of $NumberofStdSrvVMs VMs"
            $VM = $deviceSpecs.'Server-Standard'.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateStdSrv-Script "$VM"
            }
            else {
                Write-AEBLog "*** VM: $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

    # Build Hyper-V Server VM
    if ($RequireHyperV) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Server-HyperV'.VMNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-AEBLog "Creating $Count of $NumberofHyperVVMs VMs"
            $VM = $deviceSpecs.'Server-HyperV'.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateHyperVVM-Script "$VM"
            }
            else {
                Write-AEBLog "*** VM: $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild-Config-Server {
    # Configure Standard Server
    if ($RequireStdSrv) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Server-Standard'.VMNumberStart
        While ($Count -le $NumberofStdSrvVMs) {
            Write-AEBLog "Configuring $Count of $NumberofStdSrvVMs VMs"
            $VM = $deviceSpecs.'Server-Standard'.VMNamePrefix + $VMNumberStart
            ConfigStdSrv-Script "$VM"
            $Count++
            $VMNumberStart++
        }
    }

    # Configure Hyper-V Server
    if ($RequireHyperV) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Server-HyperV'.VMNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-AEBLog "Configuring $Count of $NumberofHyperVVMs VMs"
            $VM = $deviceSpecs.'Server-HyperV'.VMNamePrefix + $VMNumberStart
            ConfigHyperVVM-Script "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function CreateHyperVVM-Terraform($VMName) {
    mkdir -Path '.\Terraform\' -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path '.\Terraform\template-server2019\variables.tf').Replace('xxxx', $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path '.\Terraform\template-server2019\main.tf') | Set-Content -Path ".\Terraform\$VMName\main.tf"

    $TerraformText = '
module ' + [char]34 + $VMName + [char]34 + ' {
  source = ' + [char]34 + './' + $VMName + [char]34 + '

  myterraformgroupName = module.environment.myterraformgroup.name
  myterraformsubnetID = module.environment.myterraformsubnet.id
  myterraformnsgID = module.environment.myterraformnsg.id
}'

    $TerraformMain = Get-Content -Path '.\Terraform\main.tf'
    $TerraformText | Add-Content -Path '.\Terraform\main.tf'
}

function TerraformBuild-HVVM {
    # Build Hyper-V Server VM
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VMHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-AEBLog "Creating $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart

            CreateHyperVVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function TerraformConfigure-HVVM {
    # Configure Hyper-V VMs
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VmHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-AEBLog "Configuring $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            ConfigureHyperVVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}