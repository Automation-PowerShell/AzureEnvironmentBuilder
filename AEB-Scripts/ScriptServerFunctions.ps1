function ScriptBuild-Create-Server {
    # Build Standard Server VM
    if ($RequireStdSrv) {
        $Count = 1
        $deviceType = 'Server-Standard'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $NumberofStdSrvVMs) {
            Write-AEBLog "Creating $Count of $NumberofStdSrvVMs VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateServer-Script -VMName $VM -VMSpec $deviceType
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
        $deviceType = 'Server-HyperV'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-AEBLog "Creating $Count of $NumberofHyperVVMs VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateServer-Script -VMName $VM -VMSpec $deviceType
            }
            else {
                Write-AEBLog "*** VM: $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

    # Build Domain Controller Server VM
    if ($RequireDC) {
        $Count = 1
        $deviceType = 'Server-DomainController'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $NumberofDCVMs) {
            Write-AEBLog "Creating $Count of $NumberofDCVMs VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateServer-Script -VMName $VM -VMSpec $deviceType
            }
            else {
                Write-AEBLog "*** VM: $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

    # Build SCCM Server VM
    if ($RequireSCCM) {
        $Count = 1
        $deviceType = 'Server-ConfigManager'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $NumberofSCCMVMs) {
            Write-AEBLog "Creating $Count of $NumberofSCCMVMs VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateServer-Script -VMName $VM -VMSpec $deviceType
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
        $deviceType = 'Server-Standard'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $NumberofStdSrvVMs) {
            Write-AEBLog "Configuring $Count of $NumberofStdSrvVMs VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigServer-Script -VMName $VM -VMSpec $deviceType
            $Count++
            $VMNumberStart++
        }
    }

    # Configure Hyper-V Server
    if ($RequireHyperV) {
        $Count = 1
        $deviceType = 'Server-HyperV'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-AEBLog "Configuring $Count of $NumberofHyperVVMs VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigServer-Script -VMName $VM -VMSpec $deviceType
            $Count++
            $VMNumberStart++
        }
    }

    # Configure DC Server
    if ($RequireDC) {
        $Count = 1
        $deviceType = 'Server-DomainController'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $NumberofDCVMs) {
            Write-AEBLog "Configuring $Count of $NumberofDCVMs VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigServer-Script -VMName $VM -VMSpec $deviceType
            $Count++
            $VMNumberStart++
        }
    }

    # Configure SCCM Server
    if ($RequireSCCM) {
        $Count = 1
        $deviceType = 'Server-ConfigManager'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $NumberofSCCMVMs) {
            Write-AEBLog "Configuring $Count of $NumberofSCCMVMs VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigServer-Script -VMName $VM -VMSpec $deviceType
            $Count++
            $VMNumberStart++
        }
    }
}

function CreateServer-Script {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$VMName,
        [Parameter(Position = 1, Mandatory)][String]$VMSpec
    )

    $tags = @{}
    $names = $deviceSpecs.$VMSpec.Tags | Get-Member -MemberType NoteProperty | Select-Object Name -ExpandProperty Name
    foreach ($name in $names) {
        $value = $deviceSpecs.$VMSpec.Tags.$name
        $tags.Add($name, $value)
    }

    $Vnet = Get-AzVirtualNetwork -Name $vnets.Prod.($deviceSpecs.$VMSpec.VnetRef) -ResourceGroupName $RGNamePRODVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -VirtualNetwork $Vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNamePROD -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNamePROD -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNamePROD -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.$VMSpec.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.$VMSpec.PublisherName -Offer $deviceSpecs.$VMSpec.Offer -Skus $deviceSpecs.$VMSpec.SKUS -Version $deviceSpecs.$VMSpec.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNamePROD -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function ConfigServer-Script {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$VMName,
        [Parameter(Position = 1, Mandatory)][String]$VMSpec
    )

    $VMCreate = Get-AzVM -ResourceGroupName $RGNamePROD -Name $VMName
    if ($VMCreate.ProvisioningState -eq 'Succeeded') {
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
        $diskConfig = New-AzDiskConfig -SkuName $deviceSpecs.$VMSpec.dataDiskSKU -Location $location -CreateOption Empty -DiskSizeGB $deviceSpecs.$VMSpec.dataDiskSize
        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $RGNamePROD
        Add-AzVMDataDisk -VM $VMCreate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1 -Verbose | Out-Null
        Update-AzVM -VM $VMCreate -ResourceGroupName $RGNamePROD -Verbose | Out-Null

        Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null
        Write-AEBLog "VM: $VMName - Restarting VM for 120 Seconds..."
        Start-Sleep -Seconds 120

        ConfigureVM -VMName $VMName -VMSpec $VMSpec -RG $RGNamePROD
    }
    else {
        Write-AEBLog "*** VM: $VMName - Unable to configure Virtual Machine! ***" -Level Error
    }
}