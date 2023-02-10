function CreateDesktop-Script {
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

    $Vnet = Get-AzVirtualNetwork -Name $clientSettings.vnets.DEV.($deviceSpecs.$VMSpec.VnetRef) -ResourceGroupName $clientSettings.RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNameDEV -VirtualNetwork $Vnet
    if ($clientSettings.RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $clientSettings.RGNameDEV -Location $clientSettings.Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $clientSettings.RGNameDEV -Location $clientSettings.Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $clientSettings.RGNameDEV -Location $clientSettings.Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $deviceSpecs.$VMSpec.VMSize -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $deviceSpecs.$VMSpec.PublisherName -Offer $deviceSpecs.$VMSpec.Offer -Skus $deviceSpecs.$VMSpec.SKUS -Version $deviceSpecs.$VMSpec.Version
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $clientSettings.RGNameDEV -Location $clientSettings.Location -VM $VirtualMachine -Verbose | Out-Null
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
        RunVMConfig $RG $VMName "https://$($clientSettings.StorageAccountName).blob.core.windows.net/$($clientSettings.ContainerName)/$appPS1" $appPS1
        if ($appSpec.RebootRequired) {
            Restart-AzVM -ResourceGroupName $RG -Name $VMName | Out-Null
            Write-AEBLog "VM: $VMName - Restarting VM for $($appSpec.RebootSeconds) Seconds..."
            Start-Sleep -Seconds $appSpec.RebootSeconds
        }
    }

    if ($deviceSpecs.$VMSpec.BuildShutdownOnComplete) {
        $Stopvm = Stop-AzVM -ResourceGroupName $RG -Name $VMName -Force
        if ($Stopvm.Status -eq 'Succeeded') {
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
    If ($VMCreate.ProvisioningState -eq 'Succeeded') {
        Write-AEBLog "VM: $VMName created successfully"

        #$NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        $NewVm = (Get-AzADServicePrincipal -DisplayName $VMName | Where-Object { $_.AlternativeName[-1] -match $clientSettings.RGNameDEV })
        Start-Sleep -Seconds 30
        if ($clientSettings.RequireServicePrincipal) {
            Get-AzContext -Name 'StorageSP' | Select-AzContext | Out-Null
        }
        if ($clientSettings.RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $clientSettings.rbacContributor
            $groupmember = Get-AzADGroupMember -GroupObjectId $Group.Id | Where-Object { $_.DisplayName -eq $VMName }
            if ($groupmember.DisplayName -eq $VMName) {
                Remove-AzADGroupMember -GroupObjectId $Group.Id -MemberObjectId $groupmember.Id
            }
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
            Get-AzContext -Name 'User' | Select-AzContext | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$($clientSettings.azSubscription)/resourceGroups/$($clientSettings.RGNameSTORE)/providers/Microsoft.Storage/storageAccounts/$($clientSettings.StorageAccountName)" -ErrorAction SilentlyContinue | Out-Null
            Get-AzContext -Name 'User' | Select-AzContext | Out-Null
            Start-Sleep -Seconds 30
            $confirm = Get-AzRoleAssignment -ObjectId $NewVm.Id -Scope "/subscriptions/$($clientSettings.azSubscription)/resourceGroups/$($clientSettings.RGNameSTORE)/providers/Microsoft.Storage/storageAccounts/$($clientSettings.StorageAccountName)" -ErrorAction SilentlyContinue
            if (!$confirm) {
                Write-AEBLog -String "*** VM: $VMName - Unable to set Storage Account Permission ***" -Level Error
                Write-Dump $VMCreate.Identity.PrincipalId $NewVm.Id
            }

        }
        Set-AzKeyVaultAccessPolicy -ObjectId $NewVm.Id -VaultName $clientSettings.keyVaultName -PermissionsToSecrets Get

        if ($deviceSpecs.$VMSpec.AutoShutdownRequired) {
            $ScheduledShutdownResourceId = "/subscriptions/$($clientSettings.azSubscription)/resourceGroups/$RG/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = $($deviceSpecs.$VMSpec.AutoShutdownTime) })
            $Properties.Add('TimeZoneId', 'UTC')
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15; notificationLocale = "en" })
            $Properties.Add('targetResourceId', $VMCreate.Id)
            # Bug : New-AzResource is failing
            New-AzResource -Location $clientSettings.Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-AEBLog "VM: $VMName - Auto Shutdown Enabled for $($deviceSpecs.$VMSpec.AutoShutdownTime)"
        }
    }
    else {
        Write-AEBLog "*** VM: $VMName - Unable to configure Virtual Machine! ***" -Level Error
        Write-Dump
    }
}

function ScriptRebuild-Create-VM {
    Get-AzContext -Name 'User' | Select-AzContext | Out-Null
    switch ($Spec) {
        'Desktop-Standard' {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $clientSettings.RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
            }
            CreateDesktop-Script -VMName $VM -VMSpec $Spec
        }
        'Desktop-Packaging' {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $clientSettings.RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
            }
            CreateDesktop-Script -VMName $VM -VMSpec $Spec
        }
        'Desktop-AdminStudio' {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $clientSettings.RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
            }
            CreateDesktop-Script -VMName $VM -VMSpec $Spec
        }
        'Desktop-Jumpbox' {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $clientSettings.RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
            }
            CreateDesktop-Script -VMName $VM -VMSpec $Spec
        }
        'Desktop-Core' {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $clientSettings.RGNameDEV -Force -Verbose | Out-Null
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzNetworkInterface -Force -Verbose | Out-Null
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzPublicIpAddress -Force -Verbose | Out-Null
                Get-AzDisk -Name $VMName* -ResourceGroupName $clientSettings.RGNameDEV | Remove-AzDisk -Force -Verbose | Out-Null
            }
            else {
                Write-AEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
            }
            CreateDesktop-Script -VMName $VM -VMSpec $Spec
        }
        default {
            Write-Dump
        }
    }
}

function ScriptRebuild-Config-VM {
    Get-AzContext -Name 'User' | Select-AzContext | Out-Null
    switch ($Spec) {
        'Desktop-Standard' {
            ConfigureBaseVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
        }
        'Desktop-Packaging' {
            ConfigureBaseVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
        }
        'Desktop-AdminStudio' {
            ConfigureBaseVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
        }
        'Desktop-Jumpbox' {
            ConfigureBaseVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
        }
        'Desktop-Core' {
            ConfigureBaseVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VMName" -VMSpec $Spec -RG $clientSettings.RGNameDEV
        }
        default {
            Write-Dump
        }
    }
}

function ScriptBuild-Create-VM {
    # Build Standard VMs
    if ($clientSettings.RequireStandardVMs) {
        $Count = 1
        $deviceType = 'Desktop-Standard'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofStandardVMs) {
            Write-AEBLog "Creating $Count of $($clientSettings.NumberofStandardVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateDesktop-Script -VMName $VM -VMSpec $deviceType
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
    if ($clientSettings.RequirePackagingVMs) {
        $Count = 1
        $deviceType = 'Desktop-Packaging'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofPackagingVMs) {
            Write-AEBLog "Creating $Count of $($clientSettings.NumberofPackagingVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateDesktop-Script -VMName $VM -VMSpec $deviceType
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
    if ($clientSettings.RequireAdminStudioVMs) {
        $Count = 1
        $deviceType = 'Desktop-AdminStudio'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofAdminStudioVMs) {
            Write-AEBLog "Creating $Count of $($clientSettings.NumberofAdminStudioVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateDesktop-Script -VMName $VM -VMSpec $deviceType
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
    if ($clientSettings.RequireJumpboxVMs) {
        $Count = 1
        $deviceType = 'Desktop-Jumpbox'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofJumpboxVMs) {
            Write-AEBLog "Creating $Count of $($clientSettings.NumberofJumpboxVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateDesktop-Script -VMName $VM -VMSpec $deviceType
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
    if ($clientSettings.RequireCoreVMs) {
        $Count = 1
        $deviceType = 'Desktop-Core'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofCoreVMs) {
            Write-AEBLog "Creating $Count of $($clientSettings.NumberofCoreVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $clientSettings.RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateDesktop-Script -VMName $VM -VMSpec $deviceType
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
    if ($clientSettings.RequireStandardVMs) {
        $Count = 1
        $deviceType = 'Desktop-Standard'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofStandardVMs) {
            Write-AEBLog "Configuring $Count of $($clientSettings.NumberofStandardVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            $Count++
            $VMNumberStart++
        }
    }

    # Configure Packaging VMs
    if ($clientSettings.RequirePackagingVMs) {
        $Count = 1
        $deviceType = 'Desktop-Packaging'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofPackagingVMs) {
            Write-AEBLog "Configuring $Count of $($clientSettings.NumberofPackagingVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            $Count++
            $VMNumberStart++
        }
    }

    # Configure AdminStudio VMs
    if ($clientSettings.RequireAdminStudioVMs) {
        $Count = 1
        $deviceType = 'Desktop-AdminStudio'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofAdminStudioVMs) {
            Write-AEBLog "Configuring $Count of $($clientSettings.NumberofAdminStudioVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            $Count++
            $VMNumberStart++
        }
    }

    # Configure Jumpbox VMs
    if ($clientSettings.RequireJumpboxVMs) {
        $Count = 1
        $deviceType = 'Desktop-Jumpbox'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofJumpboxVMs) {
            Write-AEBLog "Configuring $Count of $($clientSettings.NumberofJumpboxVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            $Count++
            $VMNumberStart++
        }
    }

    # Configure Core VMs
    if ($clientSettings.RequireCoreVMs) {
        $Count = 1
        $deviceType = 'Desktop-Core'
        [int]$VMNumberStart = $deviceSpecs.$deviceType.VMNumberStart
        While ($Count -le $clientSettings.NumberofCoreVMs) {
            Write-AEBLog "Configuring $Count of $($clientSettings.NumberofCoreVMs) VMs"
            $VM = $deviceSpecs.$deviceType.VMNamePrefix + $VMNumberStart
            ConfigureBaseVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            ConfigureVM -VMName "$VM" -VMSpec $deviceType -RG $clientSettings.RGNameDEV
            $Count++
            $VMNumberStart++
        }
    }
}
