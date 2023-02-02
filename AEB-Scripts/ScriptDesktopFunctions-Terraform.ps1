function CreateStandardVM-Terraform($VMName) {
    mkdir -Path '.\Terraform\' -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path '.\Terraform\template-win10\variables.tf').Replace('xxxx', $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path '.\Terraform\template-win10\main.tf') | Set-Content -Path ".\Terraform\$VMName\main.tf"

    $TerraformText = '
module '+ [char]34 + $VMName + [char]34 + ' {
  source = '+ [char]34 + './' + $VMName + [char]34 + '

  myterraformgroupName = module.environment.myterraformgroup.name
  myterraformsubnetID = module.environment.myterraformsubnet.id
  myterraformnsgID = module.environment.myterraformnsg.id
}'

    $TerraformMain = Get-Content -Path '.\Terraform\main.tf'
    $TerraformText | Add-Content -Path '.\Terraform\main.tf'
}

function CreateAdminStudioVM-Terraform($VMName) {
    mkdir -Path '.\Terraform\' -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path '.\Terraform\template-win10\variables.tf').Replace('xxxx', $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path '.\Terraform\template-win10\main.tf') | Set-Content -Path ".\Terraform\$VMName\main.tf"

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

function CreateJumpboxVM-Terraform($VMName) {
    mkdir -Path '.\Terraform\' -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path '.\Terraform\template-win10\variables.tf').Replace('xxxx', $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path '.\Terraform\template-win10\main.tf') | Set-Content -Path ".\Terraform\$VMName\main.tf"

    $TerraformText = '
module '+ [char]34 + $VMName + [char]34 + ' {
  source = '+ [char]34 + './' + $VMName + [char]34 + '

  myterraformgroupName = module.environment.myterraformgroup.name
  myterraformsubnetID = module.environment.myterraformsubnet.id
  myterraformnsgID = module.environment.myterraformnsg.id
}'

    $TerraformMain = Get-Content -Path '.\Terraform\main.tf'
    $TerraformText | Add-Content -Path '.\Terraform\main.tf'
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