function ScriptBuild-Create-Server {
    # Build Standard Server VM
    if ($clientSettings.RequireStdSrv) {
        $Count = 1
        $deviceType = 'Server-Standard'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofStdSrvVMs) {
            Write-AEBLog "Creating $Count of $($clientSettings.NumberofStdSrvVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
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
    if ($clientSettings.RequireHyperV) {
        $Count = 1
        $deviceType = 'Server-HyperV'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofHyperVVMs) {
            Write-AEBLog "Creating $Count of $($clientSettings.NumberofHyperVVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
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
    if ($clientSettings.RequireDC) {
        $Count = 1
        $deviceType = 'Server-DomainController'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofDCVMs) {
            Write-AEBLog "Creating $Count of $($clientSettings.NumberofDCVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
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
    if ($clientSettings.RequireSCCM) {
        $Count = 1
        $deviceType = 'Server-ConfigManager'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofSCCMVMs) {
            Write-AEBLog "Creating $Count of $($clientSettings.NumberofSCCMVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.RGNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
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
    if ($clientSettings.RequireStdSrv) {
        $Count = 1
        $deviceType = 'Server-Standard'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofStdSrvVMs) {
            Write-AEBLog "Configuring $Count of $($clientSettings.NumberofStdSrvVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigServer-Script -VMName $VM -VMSpec $deviceType
            $Count++
            $VMNumberStart++
        }
    }

    # Configure Hyper-V Server
    if ($clientSettings.RequireHyperV) {
        $Count = 1
        $deviceType = 'Server-HyperV'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofHyperVVMs) {
            Write-AEBLog "Configuring $Count of $($clientSettings.NumberofHyperVVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigServer-Script -VMName $VM -VMSpec $deviceType
            $Count++
            $VMNumberStart++
        }
    }

    # Configure DC Server
    if ($clientSettings.RequireDC) {
        $Count = 1
        $deviceType = 'Server-DomainController'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofDCVMs) {
            Write-AEBLog "Configuring $Count of $($clientSettings.NumberofDCVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigServer-Script -VMName $VM -VMSpec $deviceType
            $Count++
            $VMNumberStart++
        }
    }

    # Configure SCCM Server
    if ($clientSettings.RequireSCCM) {
        $Count = 1
        $deviceType = 'Server-ConfigManager'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofSCCMVMs) {
            Write-AEBLog "Configuring $Count of $($clientSettings.NumberofSCCMVMs) VMs"
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

    $Vnet = Get-AzVirtualNetwork -Name $clientSettings.vnets.PROD.($deviceSpecs.$VMSpec.VnetRef) -ResourceGroupName $clientSettings.RGNamePRODVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNamePROD -VirtualNetwork $Vnet
    if ($clientSettings.RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $clientSettings.RGNamePROD -Location $clientSettings.Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $clientSettings.RGNamePROD -Location $clientSettings.Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $clientSettings.RGNamePROD -Location $clientSettings.Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.$VMSpec.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.$VMSpec.PublisherName -Offer $deviceSpecs.$VMSpec.Offer -Skus $deviceSpecs.$VMSpec.SKUS -Version $deviceSpecs.$VMSpec.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $clientSettings.RGNamePROD -Location $clientSettings.Location -VM $VirtualMachine -Verbose | Out-Null
}

function ConfigServer-Script {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$VMName,
        [Parameter(Position = 1, Mandatory)][String]$VMSpec
    )

    $VMCreate = Get-AzVM -ResourceGroupName $clientSettings.RGNamePROD -Name $VMName
    if ($VMCreate.ProvisioningState -eq 'Succeeded') {
        Write-AEBLog "VM: $VMName created successfully"

        #$NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        $NewVm = (Get-AzADServicePrincipal -DisplayName $VMName | Where-Object { $_.AlternativeName[-1] -match $clientSettings.RGNamePROD })
        Start-Sleep -Seconds 30
        if ($clientSettings.RequireServicePrincipal) {
            Get-AzContext -Name 'StorageSP' | Select-AzContext | Out-Null
        }
        if ($clientSettings.RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $clientSettings.rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$($clientSettings.azSubscription)/resourceGroups/$($clientSettings.RGNameSTORE)/providers/Microsoft.Storage/storageAccounts/$($clientSettings.StorageAccountName)" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name 'User' | Select-AzContext | Out-Null
        Set-AzKeyVaultAccessPolicy -ObjectId $NewVm.Id -VaultName $clientSettings.keyVaultName -PermissionsToSecrets Get

        # Add Data disk to Server
        $dataDiskName = $VMName + '_datadisk1'
        $diskConfig = New-AzDiskConfig -SkuName $deviceSpecs.$VMSpec.dataDiskSKU -Location $clientSettings.location -CreateOption Empty -DiskSizeGB $deviceSpecs.$VMSpec.dataDiskSize
        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $clientSettings.RGNamePROD
        Add-AzVMDataDisk -VM $VMCreate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1 -Verbose | Out-Null
        Update-AzVM -VM $VMCreate -ResourceGroupName $clientSettings.RGNamePROD -Verbose | Out-Null

        Restart-AzVM -ResourceGroupName $clientSettings.RGNamePROD -Name $VMName | Out-Null
        Write-AEBLog "VM: $VMName - Restarting VM for 60 Seconds..."
        Start-Sleep -Seconds 60

        ConfigureVM -VMName $VMName -VMSpec $VMSpec -RG $clientSettings.RGNamePROD
    }
    else {
        Write-AEBLog "*** VM: $VMName - Unable to configure Virtual Machine! ***" -Level Error
    }
}