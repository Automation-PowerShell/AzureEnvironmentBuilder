function CreateStandardVM-Script($VMName) {
    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSizeStandard -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $VMSpecPublisherName -Offer $VMSpecOffer -Skus $VMSpecSKUS -Version $VMSpecVersion
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function CreatePackagingVM-Script($VMName) {
    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSizeStandard -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $VMSpecPublisherName -Offer $VMSpecOffer -Skus $VMSpecSKUS -Version $VMSpecVersion
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function CreateAdminStudioVM-Script($VMName) {
    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSizeAdminStudio -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $VMSpecPublisherName -Offer $VMSpecOffer -Skus $VMSpecSKUS -Version $VMSpecVersion
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function CreateJumpboxVM-Script($VMName) {
    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSizeStandard -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $VMSpecPublisherName -Offer $VMSpecOffer -Skus $VMSpecSKUS -Version $VMSpecVersion
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function CreateCoreVM-Script($VMName) {
    $Vnet = Get-AzVirtualNetwork -Name $VNetDEV -ResourceGroupName $RGNameDEVVNET
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $RGNameDEV -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNameDEV -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSizeStandard -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $LocalAdminCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $VMSpecPublisherName -Offer $VMSpecOffer -Skus $VMSpecSKUS -Version $VMSpecVersion
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose | Out-Null
}

function ConfigureVM {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$VMName,
        [Parameter(Position = 1, Mandatory)][String]$VMSpec
    )

    foreach ($app in $deviceSpecs.$VMSpec.Apps) {
        $appName = $($app.Name)
        $global:appSpec = $appSpecs.$appName
        $appPS1 = $appSpec.PS1
        Write-PEBLog "VM: $VMName - Installing App: $appName"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$appPS1" "$appPS1"
        if($appSpec.RebootRequired) {
            Write-PEBLog "VM: $VMName - Restarting VM for $($appSpec.RebootSeconds) Seconds..."
            Start-Sleep -Seconds $appSpec.RebootSeconds
        }
    }

    if ($VMShutdown) {
        $Stopvm = Stop-AzVM -ResourceGroupName $RGNameDEV -Name $VMName -Force
        if ($Stopvm.Status -eq "Succeeded") {
            Write-PEBLog "VM: $VMName shutdown successfully"
        }
        else {
            Write-PEBLog "*** VM: $VMName - Unable to shutdown! ***" -Level Error
        }
    }
}

function ConfigureBaseVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNameDEV -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-PEBLog "VM: $VMName created successfully"

        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
            Get-AzContext -Name "User" | Select-AzContext | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -ErrorAction SilentlyContinue | Out-Null
            Get-AzContext -Name "User" | Select-AzContext | Out-Null
            Start-Sleep -Seconds 30
            $confirm = Get-AzRoleAssignment -ObjectId $NewVm.Id -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -ErrorAction SilentlyContinue
            if(!$confirm) {
                Write-PEBLog -String "*** VM: $VMName - Unable to set Storage Account Permission ***" -Level Error
                Write-Dump $VMCreate.Identity.PrincipalId $NewVm.Id
            }

        }
        Restart-AzVM -ResourceGroupName $RGNameDEV -Name $VMName | Out-Null
        Write-PEBLog "VM: $VMName - Restarting VM for 120 Seconds..."
        Start-Sleep -Seconds 120

        if ($AutoShutdown) {
            $ScheduledShutdownResourceId = "/subscriptions/$azSubscription/resourceGroups/$RGNameDEV/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800})
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMCreate.Id)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-PEBLog "VM: $VMName - Auto Shutdown Enabled for 1800"
        }
    }
    else {
        Write-PEBLog "*** VM: $VMName - Unable to configure Virtual Machine! ***" -Level Error
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
                Write-PEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
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
                CreateStandardVM-Script "$VMName"
            }
            else {
                Write-PEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
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
                Write-PEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
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
                Write-PEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
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
                Write-PEBLog "*** Virtual Machine $VMName doesn't exist! ***" -Level Error
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
    ConfigureBaseVM "$VMName"
    switch ($Spec) {
        "Standard" {
            ConfigureVM -VMName "$VMName" -VMSpec "Standard"
        }
        "Packaging" {
            ConfigureVM -VMName "$VMName" -VMSpec "Packaging"
        }
        "AdminStudio" {
            ConfigureVM -VMName "$VMName" -VMSpec "AdminStudio"
        }
        "Jumpbox" {
            ConfigureVM -VMName "$VMName" -VMSpec "Jumpbox"
        }
        "Core" {
            ConfigureVM -VMName "$VMName" -VMSpec "Core"
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
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
           Write-PEBLog "Creating $Count of $NumberofStandardVMs VMs"
           $VM = $VMNamePrefixStandard + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateStandardVM-Script "$VM"
            }
            else {
                Write-PEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

        # Build Packaging VMs
    if ($RequirePackagingVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartPackaging
        While ($Count -le $NumberofPackagingVMs) {
            Write-PEBLog "Creating $Count of $NumberofPackagingVMs VMs"
            $VM = $VMNamePrefixPackaging + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreatePackagingVM-Script "$VM"
            }
            else {
                Write-PEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

        # Build AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartAdminStudio
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-PEBLog "Creating $Count of $NumberofAdminStudioVMs VMs"
            $VM = $VMNamePrefixAdminStudio + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateAdminStudioVM-Script "$VM"
            }
            else {
                Write-PEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

        # Build Jumpbox VMs
    if ($RequireJumpboxVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartJumpbox
        While ($Count -le $NumberofJumpboxVMs) {
            Write-PEBLog "Creating $Count of $NumberofJumpboxVMs VMs"
            $VM = $VMNamePrefixJumpbox + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateJumpboxVM-Script "$VM"
            }
            else {
                Write-PEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

        # Build Core VMs
    if ($RequireCoreVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartCore
        While ($Count -le $NumberofCoreVMs) {
            Write-PEBLog "Creating $Count of $NumberofCoreVMs VMs"
            $VM = $VMNamePrefixCore + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateAdminStudioVM-Script "$VM"
            }
            else {
                Write-PEBLog "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild-Config-VM {
        #    Configure Standard VMs
    if ($RequireStandardVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
            Write-PEBLog "Configuring $Count of $NumberofStandardVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart
            ConfigureBaseVM "$VM"
            ConfigureVM -VMName "$VM" -VMSpec "Standard"
            $Count++
            $VMNumberStart++
        }
    }

        #    Configure Packaging VMs
    if ($RequirePackagingVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartPackaging
        While ($Count -le $NumberofPackagingVMs) {
            Write-PEBLog "Configuring $Count of $NumberofPackagingVMs VMs"
            $VM = $VMNamePrefixPackaging + $VMNumberStart
            ConfigureBaseVM "$VM"
            ConfigureVM -VMName "$VM" -VMSpec "Packaging"
            $Count++
            $VMNumberStart++
            }
        }

        # Configure AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartAdminStudio
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-PEBLog "Configuring $Count of $NumberofAdminStudioVMs VMs"
            $VM = $VMNamePrefixAdminStudio + $VMNumberStart
            ConfigureBaseVM "$VM"
            ConfigureVM -VMName "$VM" -VMSpec "AdminStudio"
            $Count++
            $VMNumberStart++
        }
    }

        # Configure Jumpbox VMs
    if ($RequireJumpboxVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartJumpbox
        While ($Count -le $NumberofJumpboxVMs) {
            Write-PEBLog "Configuring $Count of $NumberofJumboxVMs VMs"
            $VM = $VMNamePrefixJumpbox + $VMNumberStart
            ConfigureBaseVM "$VM"
            ConfigureVM -VMName "$VM" -VMSpec "Jumpbox"
            $Count++
            $VMNumberStart++
        }
    }

        # Configure Core VMs
    if ($RequireCoreVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartCore
        While ($Count -le $NumberofCoreVMs) {
            Write-PEBLog "Configuring $Count of $NumberofCoreVMs VMs"
            $VM = $VMNamePrefixCore + $VMNumberStart
            ConfigureBaseVM "$VM"
            ConfigureVM -VMName "$VM" -VMSpec "Core"
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
            Write-PEBLog "Creating $Count of $NumberofStandardVMs VMs"
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
            Write-PEBLog "Creating $Count of $NumberofAdminStudioVMs VMs"
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
            Write-PEBLog "Creating $Count of $NumberofJumpboxVMs VMs"
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
            Write-PEBLog "Configuring $Count of $NumberofStandardVMs VMs"
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
            Write-PEBLog "Configuring $Count of $NumberofAdminStudioVMs VMs"
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
            Write-PEBLog "Configuring $Count of $NumberofJumpboxVMs VMs"
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
            Write-PEBLog "Configuring $Count of $NumberofCoreVMs VMs"
            $VM = $VMNamePrefixCore + $VMNumberStart
            ConfigureBaseVM "$VM"
            ConfigureCoreVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}