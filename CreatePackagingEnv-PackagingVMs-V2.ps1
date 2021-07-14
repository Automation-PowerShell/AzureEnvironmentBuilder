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

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose
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

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose
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

    New-AzVM -ResourceGroupName $RGNameDEV -Location $Location -VM $VirtualMachine -Verbose
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

function TerraformBuild {
        # Build Standard VMs
    if ($RequireStandardVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
            Write-Log "Creating $Count of $NumberofStandardVMs VMs"
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
            Write-Log "Creating $Count of $NumberofAdminStudioVMs VMs"
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
            Write-Log "Creating $Count of $NumberofJumpboxVMs VMs"
            $VM = $VMNamePrefixJumpbox + $VMNumberStart

            CreateJumpboxVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild {
        # Build Standard VMs
    if ($RequireStandardVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
            Write-Log "Creating $Count of $NumberofStandardVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateStandardVM-Script "$VM"
            }
            else {
                Write-Log "*** Virtual Machine $VM already exists! ***" -Level Error
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
            Write-Log "Creating $Count of $NumberofAdminStudioVMs VMs"
            $VM = $VMNamePrefixAdminStudio + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateAdminStudioVM-Script "$VM"
            }
            else {
                Write-Log "*** Virtual Machine $VM already exists! ***" -Level Error
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
            Write-Log "Creating $Count of $NumberofJumpboxVMs VMs"
            $VM = $VMNamePrefixJumpbox + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateJumpboxVM-Script "$VM"
            }
            else {
                Write-Log "*** Virtual Machine $VM already exists! ***" -Level Error
                break
            }
            $Count++
            $VMNumberStart++
        }
    }
}

#=======================================================================================================================================================

# Main Script
if ($UseTerraform) {
    TerraformBuild
}
else {
   ScriptBuild
}
Write-Log "Packaging VM Script Completed"