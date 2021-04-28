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
    $Vnet = Get-AzVirtualNetwork -Name $VNetPROD -ResourceGroupName $RGNameVNET 
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet
    if ($RequirePublicIPs) {
        $PIP = New-AzPublicIpAddress -Name "$VMName-pip" -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic -Sku Basic -Tier Regional -IpAddressVersion IPv4
        $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
    }
    else { $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Subnet.Id }
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VmSizeHyperV -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $VMCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNamePROD -Location $Location -VM $VirtualMachine -Verbose  
}

function TerraformBuild {
        # Build Hyper-V Server VM
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VMHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-Host "Creating $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart

            CreateHyperVVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild {
        # Build Hyper-V Server VM
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VMHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-Host "Creating $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameUAT -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateHyperVVM-Script "$VM"
            }
            else {
                Write-Host "Virtual Machine $VM already exists!"
                break
            }
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
Write-Host "Hyper-V Create Script Completed"
#endregion Main