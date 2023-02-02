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