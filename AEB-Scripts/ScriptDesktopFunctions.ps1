function CreateStandardVM-Script($VMName) {
    $tags = @{}
    $names = $deviceSpecs.'Desktop-Standard'.Tags | Get-Member -MemberType NoteProperty | Select-Object Name -ExpandProperty Name
    foreach ($name in $names) {
        $value = $deviceSpecs.'Desktop-Standard'.Tags.$name
        $tags.Add($name,$value)
    }

    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.'Desktop-Standard'.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.'Desktop-Standard'.PublisherName -Offer $deviceSpecs.'Desktop-Standard'.Offer -Skus $deviceSpecs.'Desktop-Standard'.SKUS -Version $deviceSpecs.'Desktop-Standard'.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function CreatePackagingVM-Script($VMName) {
    $tags = @{}
    $names = $deviceSpecs.'Desktop-Packaging'.Tags | Get-Member -MemberType NoteProperty | Select-Object Name -ExpandProperty Name
    foreach ($name in $names) {
        $value = $deviceSpecs.'Desktop-Packaging'.Tags.$name
        $tags.Add($name,$value)
    }

    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.'Desktop-Packaging'.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.'Desktop-Packaging'.PublisherName -Offer $deviceSpecs.'Desktop-Packaging'.Offer -Skus $deviceSpecs.'Desktop-Packaging'.SKUS -Version $deviceSpecs.'Desktop-Packaging'.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function CreateAdminStudioVM-Script($VMName) {
    $tags = @{}
    $names = $deviceSpecs.'Desktop-AdminStudio'.Tags | Get-Member -MemberType NoteProperty | Select-Object Name -ExpandProperty Name
    foreach ($name in $names) {
        $value = $deviceSpecs.'Desktop-AdminStudio'.Tags.$name
        $tags.Add($name,$value)
    }

    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.'Desktop-AdminStudio'.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.'Desktop-AdminStudio'.PublisherName -Offer $deviceSpecs.'Desktop-AdminStudio'.Offer -Skus $deviceSpecs.'Desktop-AdminStudio'.SKUS -Version $deviceSpecs.'Desktop-AdminStudio'.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function CreateJumpboxVM-Script($VMName) {
    $tags = @{}
    $names = $deviceSpecs.'Desktop-Jumpbox'.Tags | Get-Member -MemberType NoteProperty | Select-Object Name -ExpandProperty Name
    foreach ($name in $names) {
        $value = $deviceSpecs.'Desktop-Jumpbox'.Tags.$name
        $tags.Add($name,$value)
    }

    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.'Desktop-Jumpbox'.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.'Desktop-Jumpbox'.PublisherName -Offer $deviceSpecs.'Desktop-Jumpbox'.Offer -Skus $deviceSpecs.'Desktop-Jumpbox'.SKUS -Version $deviceSpecs.'Desktop-Jumpbox'.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function CreateCoreVM-Script($VMName) {
    $tags = @{}
    $names = $deviceSpecs.'Desktop-Core'.Tags | Get-Member -MemberType NoteProperty | Select-Object Name -ExpandProperty Name
    foreach ($name in $names) {
        $value = $deviceSpecs.'Desktop-Core'.Tags.$name
        $tags.Add($name,$value)
    }

    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.'Desktop-Core'.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.'Desktop-Core'.PublisherName -Offer $deviceSpecs.'Desktop-Core'.Offer -Skus $deviceSpecs.'Desktop-Core'.SKUS -Version $deviceSpecs.'Desktop-Core'.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function ConfigureVM {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$VMName,
        [Parameter(Position = 1, Mandatory)][String]$VMSpec,
        [Parameter(Position = 3, Mandatory)][String]$RG
    )

    foreach ($app in $deviceSpecs.$VMSpec.Apps) {
        $appName = $($app.Name)
        $appSpec = $appSpecs.$appName
        $appPS1 = $appSpec.PS1
        Write-AEBLog "VM: $VMName - Installing App: $appName"
        RunVMConfig $RG $VMName "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$appPS1" $appPS1
        if($appSpec.RebootRequired) {
            Restart-AzVM -ResourceGroupName $RG -Name $VMName | Out-Null
            Write-AEBLog "VM: $VMName - Restarting VM for $($appSpec.RebootSeconds) Seconds..."
            Start-Sleep -Seconds $appSpec.RebootSeconds
        }
    }

    if ($VMShutdown) {
        $Stopvm = Stop-AzVM -ResourceGroupName $RG -Name $VMName -Force
        if ($Stopvm.Status -eq "Succeeded") {
            Write-AEBLog "VM: $VMName shutdown successfully"
        }
        else {
            Write-AEBLog "*** VM: $VMName - Unable to shutdown! ***" -Level Error
        }
    }
}

function ConfigureBaseVM {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$VMName,
        [Parameter(Position = 1, Mandatory)][String]$VMSpec,
        [Parameter(Position = 3, Mandatory)][String]$RG
    )

    $VMCreate = Get-AzVM -ResourceGroupName $RG -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-AEBLog "VM: $VMName created successfully"

        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        Start-Sleep -Seconds 30
        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            $groupmember = Get-AzADGroupMember -GroupObjectId $Group.Id | Where-Object {$_.DisplayName -eq $VMName}
            if($groupmember.DisplayName -eq $VMName) {
                Remove-AzADGroupMember -GroupObjectId $Group.Id -MemberObjectId $groupmember.Id
            }
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
            Get-AzContext -Name "User" | Select-AzContext | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -ErrorAction SilentlyContinue | Out-Null
            Get-AzContext -Name "User" | Select-AzContext | Out-Null
            Start-Sleep -Seconds 30
            $confirm = Get-AzRoleAssignment -ObjectId $NewVm.Id -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -ErrorAction SilentlyContinue
            if(!$confirm) {
                Write-AEBLog -String "*** VM: $VMName - Unable to set Storage Account Permission ***" -Level Error
                Write-Dump $VMCreate.Identity.PrincipalId $NewVm.Id
            }

        }
        Set-AzKeyVaultAccessPolicy -ObjectId $NewVm.Id -VaultName $keyVaultName -PermissionsToSecrets Get

        if ($deviceSpecs.$VMSpec.AutoShutdownRequired) {
            $ScheduledShutdownResourceId = "/subscriptions/$azSubscription/resourceGroups/$RG/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = $($deviceSpecs.$VMSpec.AutoShutdownTime)})
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMCreate.Id)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-AEBLog "VM: $VMName - Auto Shutdown Enabled for $($deviceSpecs.$VMSpec.AutoShutdownTime)"
        }
    }
    else {
        Write-AEBLog "*** VM: $VMName - Unable to configure Virtual Machine! ***" -Level Error
        Write-Dump
    }
}

function ScriptRebuild-Create-VM {
    Get-AzContext -Name "User" | Select-AzContext | Out-Null
    switch ($Spec) {
        "Standard" {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
                CreateStandardVM-Script "$VMName"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
                CreateStandardVM-Script "$VMName"
            }
        }
        "Packaging" {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
                CreatePackagingVM-Script "$VMName"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
                CreatePackagingVM-Script "$VMName"
            }
        }
        "AdminStudio" {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
                CreateAdminStudioVM-Script "$VMName"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
                CreateAdminStudioVM-Script "$VMName"
            }
        }
        "Jumpbox" {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
                CreateJumpboxVM-Script "$VMName"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
                CreateJumpboxVM-Script "$VMName"
            }
        }
        "Core" {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
                CreateCoreVM-Script "$VMName"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
                CreateCoreVM-Script "$VMName"
            }
        }
        default {
            Write-Dump
        }
    }
}

function ScriptRebuild-Config-VM {
    Get-AzContext -Name "User" | Select-AzContext | Out-Null
    switch ($Spec) {
        "Standard" {
            ConfigureBaseVM -VMName "$VMName" -VMSpec "Desktop-Standard" -RG $RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec "Desktop-Standard" -RG $RGNameDEV
        }
        "Packaging" {
            ConfigureBaseVM -VMName "$VMName" -VMSpec "Desktop-Packaging" -RG $RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec "Desktop-Packaging" -RG $RGNameDEV
        }
        "AdminStudio" {
            ConfigureBaseVM -VMName "$VMName" -VMSpec "Desktop-AdminStudio" -RG $RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec "Desktop-AdminStudio" -RG $RGNameDEV
        }
        "Jumpbox" {
            ConfigureBaseVM -VMName "$VMName" -VMSpec "Desktop-Jumpbox" -RG $RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec "Desktop-Jumpbox" -RG $RGNameDEV
        }
        "Core" {
            ConfigureBaseVM -VMName "$VMName" -VMSpec "Desktop-Core" -RG $RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec "Desktop-Core" -RG $RGNameDEV
        }
        default {
            Write-Dump
        }
    }
}

function ScriptBuild-Create-VM {
        # Build Standard VMs
    if ($RequireStandardVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-Standard'.VMNumberStart
        While ($Count -le $NumberofStandardVMs) {
           Write-AEBLog "Creating $Count of $NumberofStandardVMs VMs"
           $VM = $deviceSpecs.'Desktop-Standard'.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateStandardVM-Script "$VM"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

        # Build Packaging VMs
    if ($RequirePackagingVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-Packaging'.VMNumberStart
        While ($Count -le $NumberofPackagingVMs) {
            Write-AEBLog "Creating $Count of $NumberofPackagingVMs VMs"
            $VM = $deviceSpecs.'Desktop-Packaging'.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreatePackagingVM-Script "$VM"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

        # Build AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-AdminStudio'.VMNumberStart
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-AEBLog "Creating $Count of $NumberofAdminStudioVMs VMs"
            $VM = $deviceSpecs.'Desktop-AdminStudio'.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateAdminStudioVM-Script "$VM"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

        # Build Jumpbox VMs
    if ($RequireJumpboxVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-Jumpbox'.VMNumberStart
        While ($Count -le $NumberofJumpboxVMs) {
            Write-AEBLog "Creating $Count of $NumberofJumpboxVMs VMs"
            $VM = $deviceSpecs.'Desktop-Jumpbox'.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateJumpboxVM-Script "$VM"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

        # Build Core VMs
    if ($RequireCoreVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-Core'.VMNumberStart
        While ($Count -le $NumberofCoreVMs) {
            Write-AEBLog "Creating $Count of $NumberofCoreVMs VMs"
            $VM = $deviceSpecs.'Desktop-Core'.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateCoreVM-Script "$VM"
            }
            else {
                Write-AEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild-Config-VM {
        # Configure Standard VMs
    if ($RequireStandardVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-Standard'.VMNumberStart
        While ($Count -le $NumberofStandardVMs) {
            Write-AEBLog "Configuring $Count of $NumberofStandardVMs VMs"
            $VM = $deviceSpecs.'Desktop-Standard'.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec "Desktop-Standard" -RG $RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec "Desktop-Standard" -RG $RGNameDEV
            $Count++
            $VMNumberStart++
        }
    }

        # Configure Packaging VMs
    if ($RequirePackagingVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-Packaging'.VMNumberStart
        While ($Count -le $NumberofPackagingVMs) {
            Write-AEBLog "Configuring $Count of $NumberofPackagingVMs VMs"
            $VM = $deviceSpecs.'Desktop-Packaging'.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec "Desktop-Packaging" -RG $RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec "Desktop-Packaging" -RG $RGNameDEV
            $Count++
            $VMNumberStart++
            }
        }

        # Configure AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-AdminStudio'.VMNumberStart
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-AEBLog "Configuring $Count of $NumberofAdminStudioVMs VMs"
            $VM = $deviceSpecs.'Desktop-AdminStudio'.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec "Desktop-AdminStudio" -RG $RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec "Desktop-AdminStudio" -RG $RGNameDEV
            $Count++
            $VMNumberStart++
        }
    }

        # Configure Jumpbox VMs
    if ($RequireJumpboxVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-Jumpbox'.VMNumberStart
        While ($Count -le $NumberofJumpboxVMs) {
            Write-AEBLog "Configuring $Count of $NumberofJumpboxVMs VMs"
            $VM = $deviceSpecs.'Desktop-Jumpbox'.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec "Desktop-Jumpbox" -RG $RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec "Desktop-Jumpbox" -RG $RGNameDEV
            $Count++
            $VMNumberStart++
        }
    }

        # Configure Core VMs
    if ($RequireCoreVMs) {
        $Count = 1
        [int]$VMNumberStart = $deviceSpecs.'Desktop-Core'.VMNumberStart
        While ($Count -le $NumberofCoreVMs) {
            Write-AEBLog "Configuring $Count of $NumberofCoreVMs VMs"
            $VM = $deviceSpecs.'Desktop-Core'.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec "Desktop-Core" -RG $RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec "Desktop-Core" -RG $RGNameDEV
            $Count++
            $VMNumberStart++
        }
    }
}

function CreateStandardVM-Terraform($VMName) {
    mkdir -Path ".\Terraform\" -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path ".\Terraform\template-win10\variables.tf").Replace("xxxx", $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path ".\Terraform\template-win10\main.tf") | Set-Content -Path ".\Terraform\$VMName\main.tf"

    $TerraformText = "
module "+ [char]34 + $VMName + [char]34 + " {
  source = "+ [char]34 + "./" + $VMName + [char]34 + "

  myterraformgroupName = module.environment.myterraformgroup.name
  myterraformsubnetID = module.environment.myterraformsubnet.id
  myterraformnsgID = module.environment.myterraformnsg.id
}"

    $TerraformMain = Get-Content -Path ".\Terraform\main.tf"
    $TerraformText | Add-Content -Path ".\Terraform\main.tf"
}

function CreateAdminStudioVM-Terraform($VMName) {
    mkdir -Path ".\Terraform\" -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path ".\Terraform\template-win10\variables.tf").Replace("xxxx", $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path ".\Terraform\template-win10\main.tf") | Set-Content -Path ".\Terraform\$VMName\main.tf"

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

function CreateJumpboxVM-Terraform($VMName) {
    mkdir -Path ".\Terraform\" -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path ".\Terraform\template-win10\variables.tf").Replace("xxxx", $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path ".\Terraform\template-win10\main.tf") | Set-Content -Path ".\Terraform\$VMName\main.tf"

    $TerraformText = "
module "+ [char]34 + $VMName + [char]34 + " {
  source = "+ [char]34 + "./" + $VMName + [char]34 + "

  myterraformgroupName = module.environment.myterraformgroup.name
  myterraformsubnetID = module.environment.myterraformsubnet.id
  myterraformnsgID = module.environment.myterraformnsg.id
}"

    $TerraformMain = Get-Content -Path ".\Terraform\main.tf"
    $TerraformText | Add-Content -Path ".\Terraform\main.tf"
}

function TerraformBuild-VM {
        # Build Standard VMs
    if ($RequireStandardVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
            Write-AEBLog "Creating $Count of $NumberofStandardVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart

            CreateStandardVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
        # Build AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartAdminStudio
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-AEBLog "Creating $Count of $NumberofAdminStudioVMs VMs"
            $VM = $VMNamePrefixAdminStudio + $VMNumberStart

            CreateAdminStudioVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
        # Build Jumpbox VMs
    if ($RequireJumpboxVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartJumpbox
        While ($Count -le $NumberofJumpboxVMs) {
            Write-AEBLog "Creating $Count of $NumberofJumpboxVMs VMs"
            $VM = $VMNamePrefixJumpbox + $VMNumberStart

            CreateJumpboxVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function TerraformConfigure-VM {
        # Configure Standard VMs
    if ($RequireStandardVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
            Write-AEBLog "Configuring $Count of $NumberofStandardVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart
            ConfigureStandardVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }

        # Configure AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartAdminStudio
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-AEBLog "Configuring $Count of $NumberofAdminStudioVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart
            ConfigureAdminStudioVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }

        # Configure Jumpbox VMs
    if ($RequireJumpboxVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartJumpbox
        While ($Count -le $NumberofJumpboxVMs) {
            Write-AEBLog "Configuring $Count of $NumberofJumpboxVMs VMs"
            $VM = $VMNamePrefixJumpbox + $VMNumberStart
            ConfigureJumpboxVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }

        # Configure Core VMs
    if ($RequireCoreVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartCore
        While ($Count -le $NumberofCoreVMs) {
            Write-AEBLog "Configuring $Count of $NumberofCoreVMs VMs"
            $VM = $VMNamePrefixCore + $VMNumberStart
            ConfigureBaseVM "$VM"
            ConfigureCoreVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}