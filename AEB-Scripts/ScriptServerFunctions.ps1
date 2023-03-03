function ScriptBuild-Create-Server {
    # Build Standard Server VM
    if ($clientSettings.RequireStdSrv) {
        $count = 1
        $buildNumber = $clientSettings.NumberofStdSrvVMs
        $deviceType = 'Server-Standard'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Creating $count of $buildNumber VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateServer-Script -VMName $VM -VMSpec $deviceType
            }
            else {
                Write-AEBLog "*** VM: $VM already exists! ***" -Level Error
                #break
            }
            $count++
            $VMNumberStart++
        }
    }

    # Build Hyper-V Server VM
    if ($clientSettings.RequireHyperV) {
        $count = 1
        $buildNumber = $clientSettings.NumberofHyperVVMs
        $deviceType = 'Server-HyperV'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Creating $count of $buildNumber VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateServer-Script -VMName $VM -VMSpec $deviceType
            }
            else {
                Write-AEBLog "*** VM: $VM already exists! ***" -Level Error
                #break
            }
            $count++
            $VMNumberStart++
        }
    }

    # Build Domain Controller Server VM
    if ($clientSettings.RequireDC) {
        $count = 1
        $buildNumber = $clientSettings.NumberofDCVMs
        $deviceType = 'Server-DomainController'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Creating $count of $buildNumber VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateServer-Script -VMName $VM -VMSpec $deviceType
            }
            else {
                Write-AEBLog "*** VM: $VM already exists! ***" -Level Error
                #break
            }
            $count++
            $VMNumberStart++
        }
    }

    # Build SCCM Server VM
    if ($clientSettings.RequireSCCM) {
        $count = 1
        $buildNumber = $clientSettings.NumberofSCCMVMs
        $deviceType = 'Server-ConfigManager'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Creating $count of $buildNumber VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateServer-Script -VMName $VM -VMSpec $deviceType
            }
            else {
                Write-AEBLog "*** VM: $VM already exists! ***" -Level Error
                #break
            }
            $count++
            $VMNumberStart++
        }
    }

    # Build A365 Server VM
    if ($clientSettings.RequireA365) {
        $count = 1
        $buildNumber = $clientSettings.NumberofA365VMs
        $deviceType = 'Server-A365'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Creating $count of $buildNumber VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateServer-Script -VMName $VM -VMSpec $deviceType
            }
            else {
                Write-AEBLog "*** VM: $VM already exists! ***" -Level Error
                #break
            }
            $count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild-Config-Server {
    # Configure Standard Server
    if ($clientSettings.RequireStdSrv) {
        $count = 1
        $buildNumber = $clientSettings.NumberofStdSrvVMs
        $deviceType = 'Server-Standard'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Configuring $count of $buildNumber VMs"
            $vm = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $builddate = (Get-AzVM -Name $vm -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName).TimeCreated | Get-Date -Format 'yyyy-MM-dd'
            $today = Get-Date -Format 'yyyy-MM-dd'
            if ($builddate -ge $today ) {
                ConfigServer-Script -VMName $VM -VMSpec $deviceType
            }
            $count++
            $VMNumberStart++
        }
    }

    # Configure Hyper-V Server
    if ($clientSettings.RequireHyperV) {
        $count = 1
        $buildNumber = $clientSettings.NumberofHyperVVMs
        $deviceType = 'Server-HyperV'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Configuring $count of $buildNumber VMs"
            $vm = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $builddate = (Get-AzVM -Name $vm -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName).TimeCreated | Get-Date -Format 'yyyy-MM-dd'
            $today = Get-Date -Format 'yyyy-MM-dd'
            if ($builddate -ge $today ) {
                ConfigServer-Script -VMName $VM -VMSpec $deviceType
            }
            $count++
            $VMNumberStart++
        }
    }

    # Configure DC Server
    if ($clientSettings.RequireDC) {
        $count = 1
        $buildNumber = $clientSettings.NumberofDCVMs
        $deviceType = 'Server-DomainController'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Configuring $count of $buildNumber VMs"
            $vm = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $builddate = (Get-AzVM -Name $vm -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName).TimeCreated | Get-Date -Format 'yyyy-MM-dd'
            $today = Get-Date -Format 'yyyy-MM-dd'
            if ($builddate -ge $today ) {
                ConfigServer-Script -VMName $VM -VMSpec $deviceType
            }
            $count++
            $VMNumberStart++
        }
    }

    # Configure SCCM Server
    if ($clientSettings.RequireSCCM) {
        $count = 1
        $buildNumber = $clientSettings.NumberofSCCMVMs
        $deviceType = 'Server-ConfigManager'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Configuring $count of $buildNumber VMs"
            $vm = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $builddate = (Get-AzVM -Name $vm -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName).TimeCreated | Get-Date -Format 'yyyy-MM-dd'
            $today = Get-Date -Format 'yyyy-MM-dd'
            if ($builddate -ge $today ) {
                ConfigServer-Script -VMName $VM -VMSpec $deviceType
            }
            $count++
            $VMNumberStart++
        }
    }

    # Configure A365 Server
    if ($clientSettings.RequireA365) {
        $count = 1
        $buildNumber = $clientSettings.NumberofA365VMs
        $deviceType = 'Server-A365'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($count -le $buildNumber) {
            Write-AEBLog "Configuring $count of $buildNumber VMs"
            $vm = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $builddate = (Get-AzVM -Name $vm -ResourceGroup $clientSettings.rgs.($deviceSpecs.$deviceType.Environment).RGName).TimeCreated | Get-Date -Format 'yyyy-MM-dd'
            $today = Get-Date -Format 'yyyy-MM-dd'
            if ($builddate -ge $today ) {
                ConfigServer-Script -VMName $VM -VMSpec $deviceType
            }
            $count++
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

    $Vnet = Get-AzVirtualNetwork -Name $clientSettings.vnets.($deviceSpecs.$VMSpec.Environment).($deviceSpecs.$VMSpec.VnetRef) -ResourceGroupName $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGNameVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.($deviceSpecs.$VMSpec.Environment).SubnetName -VirtualNetwork $Vnet
    if ($clientSettings.RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName -Location $clientSettings.Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        Update-AzTag -ResourceId $PIP.Id -Tag $tags -Operation Merge | Out-Null
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName -Location $clientSettings.Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
        Update-AzTag -ResourceId $NIC.Id -Tag $tags -Operation Merge | Out-Null
    }
    else {
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName -Location $clientSettings.Location -SubnetId $Subnet.Id
        Update-AzTag -ResourceId $NIC.Id -Tag $tags -Operation Merge | Out-Null
    }

    $cred = New-Object System.Management.Automation.PSCredential ($deviceSpecs.$VMSpec.AdminUsername, $LocalAdminPassword)

    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.$VMSpec.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $cred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.$VMSpec.PublisherName -Offer $deviceSpecs.$VMSpec.Offer -Skus $deviceSpecs.$VMSpec.SKUS -Version $deviceSpecs.$VMSpec.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName -Location $clientSettings.Location -VM $VirtualMachine -Verbose | Out-Null
}

function ConfigServer-Script {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$VMName,
        [Parameter(Position = 1, Mandatory)][String]$VMSpec
    )

    $VMCreate = Get-AzVM -ResourceGroupName $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName -Name $VMName
    if ($VMCreate.ProvisioningState -eq 'Succeeded') {
        Write-AEBLog "VM: $VMName created successfully"

        #$NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        $NewVm = (Get-AzADServicePrincipal -DisplayName $VMName | Where-Object { $_.AlternativeName[-1] -match $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName })
        Start-Sleep -Seconds 30
        if ($clientSettings.RequireServicePrincipal) {
            Get-AzContext -Name 'StorageSP' | Select-AzContext | Out-Null
        }
        if ($clientSettings.RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $clientSettings.rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$($clientSettings.azSubscription)/resourceGroups/$($clientSettings.rgs.STORE.RGName)/providers/Microsoft.Storage/storageAccounts/$($clientSettings.StorageAccountName)" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name 'User' | Select-AzContext | Out-Null
        Set-AzKeyVaultAccessPolicy -ObjectId $NewVm.Id -VaultName $clientSettings.keyVaultName -PermissionsToSecrets Get

        # Add Data disk to Server
        $dataDiskName = $VMName + '_datadisk1'
        $diskConfig = New-AzDiskConfig -SkuName $deviceSpecs.$VMSpec.dataDiskSKU -Location $clientSettings.location -CreateOption Empty -DiskSizeGB $deviceSpecs.$VMSpec.dataDiskSize
        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName
        Add-AzVMDataDisk -VM $VMCreate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1 -Verbose | Out-Null
        Update-AzVM -VM $VMCreate -ResourceGroupName $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName -Verbose | Out-Null

        Restart-AzVM -ResourceGroupName $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName -Name $VMName | Out-Null
        Write-AEBLog "VM: $VMName - Restarting VM for 60 Seconds..."
        Start-Sleep -Seconds 60

        ConfigureVM -VMName $VMName -VMSpec $VMSpec -RG $clientSettings.rgs.($deviceSpecs.$VMSpec.Environment).RGName
    }
    else {
        Write-AEBLog "*** VM: $VMName - Unable to configure Virtual Machine! ***" -Level Error
    }
}