function UpdateStorage {
    if ($RequireUpdateStorage) {
        Write-AEBLog 'Syncing Files...'
        Try {
            if (!(Test-Path -Path $BlobFilesDest)) { New-Item -Path $BlobFilesDest -ItemType 'directory' | Out-Null }
            $templates = Get-ChildItem -Path $BlobFilesSource -Filter *tmpl* -File
            foreach ($template in $templates) {
                $content = Get-Content -Path "$BlobFilesSource\$(($template).Name)"
                $content = $content.replace('xxxxx', $StorageAccountName)
                $content = $content.replace('sssss', $azSubscription)
                $content = $content.replace('yyyyy', $Keys.value[0])
                $content = $content.replace('ddddd', $Domain)
                $content = $content.replace('ooooo', $OUPath)
                $content = $content.replace('rrrrr', $RGNameSTORE)
                $content = $content.replace('fffff', $FileShareName)
                $content = $content.replace('kkkkk', $keyVaultName)
                $content = $content.replace('wwwww', $HyperVVMIsoImagePath)
                $content = $content.replace('aaaaa', $HyperVLocalAdminUser)
                $content = $content.replace('jjjjj', $DomainJoinUser)
                $content = $content.replace('uuuuu', $DomainUserUser)
                $contentName = $template.Basename -replace 'Tmpl'
                $contentName = $contentName + '.ps1'
                $content | Set-Content -Path "$BlobFilesDest\$contentName" -ErrorAction stop
            }
        }
        Catch {
            Write-AEBLog '*** An error occured trying to create the customised scripts for the Storage Blob ***' -Level Error
            Write-Dump
        }
        . $AEBScripts\SyncFiles.ps1 -CallFromCreatePackaging -Recurse        # Sync Files to Storage Blob
        #. $AEBScripts\SyncFiles.ps1 -CallFromCreatePackaging                  # Sync Files to Storage Blob
        Write-AEBLog 'Storage Account has been Updated with files'
    }
}

function UpdateRBAC {
    $OwnerGroup = Get-AzADGroup -DisplayName $rbacOwner
    $ContributorGroup = Get-AzADGroup -DisplayName $rbacContributor
    $ReadOnlyGroup = Get-AzADGroup -DisplayName $rbacReadOnly

    New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName 'Owner' -ResourceGroupName $RGNamePROD -ErrorAction Ignore | Out-Null
    New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName 'Contributor' -ResourceGroupName $RGNamePROD -ErrorAction Ignore | Out-Null
    New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName 'Reader' -ResourceGroupName $RGNamePROD -ErrorAction Ignore | Out-Null
    if (!($RGNameDEV -match $RGNamePROD)) {
        New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName 'Owner' -ResourceGroupName $RGNameDEV -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName 'Contributor' -ResourceGroupName $RGNameDEV -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName 'Reader' -ResourceGroupName $RGNameDEV -ErrorAction Ignore | Out-Null
    }
    if (!($RGNameSTORE -match $RGNamePROD)) {
        New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName 'Owner' -ResourceGroupName $RGNameSTORE -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName 'Contributor' -ResourceGroupName $RGNameSTORE -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName 'Reader' -ResourceGroupName $RGNameSTORE -ErrorAction Ignore | Out-Null
    }
    Write-AEBLog 'Role Assignments Set'
}

<#function ConfigureNetwork {
    if ($RequireVNET -and !$UseTerraform) {
        $virtualNetworkPROD = New-AzVirtualNetwork -ResourceGroupName $RGNamePRODVNET -Location $Location -Name $VNetPROD -AddressPrefix 10.0.0.0/16
        $subnetConfigPROD = Add-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -AddressPrefix '10.0.1.0/24' -VirtualNetwork $virtualNetworkPROD
        if (!($RGNameDEVVNET -match $RGNamePRODVNET)) {
            $virtualNetworkDEV = New-AzVirtualNetwork -ResourceGroupName $RGNameDEVVNET -Location $Location -Name $VNetDEV -AddressPrefix 10.0.0.0/16
            $subnetConfigDEV = Add-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -AddressPrefix '10.0.1.0/24' -VirtualNetwork $virtualNetworkDEV
        }

        $rule1 = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description 'Allow RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        $rule2 = New-AzNetworkSecurityRuleConfig -Name smb-rule -Description 'Allow SMB' -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 445

        if ($RequireNSG) {
            $nsgPROD = New-AzNetworkSecurityGroup -ResourceGroupName $RGNamePRODVNET -Location $location -Name $NsgNamePROD -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc.
            if ($nsgPROD.ProvisioningState -eq 'Succeeded') { Write-AEBLog 'PROD Network Security Group created successfully' } Else { Write-AEBLog '*** Unable to create or configure PROD Network Security Group! ***' -Level Error }
            Set-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -VirtualNetwork $virtualNetworkPROD -AddressPrefix '10.0.1.0/24' -NetworkSecurityGroup $nsgPROD | Out-Null
        }
        #if ($RequireKeyVault) {
            Set-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -VirtualNetwork $virtualNetworkPROD -AddressPrefix '10.0.1.0/24' -ServiceEndpoint 'Microsoft.KeyVault' | Out-Null
            Write-AEBLog 'PROD KeyVault Service Endpoint created'
        #}
        $virtualNetworkPROD | Set-AzVirtualNetwork | Out-Null
        if ($virtualNetworkPROD.ProvisioningState -eq 'Succeeded') { Write-AEBLog 'PROD Virtual Network created and associated with the Network Security Group successfully' } Else { Write-AEBLog '*** Unable to create the PROD Virtual Network, or associate it to the Network Security Group! ***' -Level Error }
        if (!($RGNameDEVVNET -match $RGNamePRODVNET)) {
            if ($RequireNSG) {
                $nsgDEV = New-AzNetworkSecurityGroup -ResourceGroupName $RGNameDEVVNET -Location $location -Name $NsgNameDEV -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc.
                if ($nsgDEV.ProvisioningState -eq 'Succeeded') { Write-AEBLog 'DEV Network Security Group created successfully' }Else { Write-AEBLog '*** Unable to create or configure DEV Network Security Group! ***' }
                Set-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $virtualNetworkDEV -AddressPrefix '10.0.1.0/24' -NetworkSecurityGroup $nsgDEV | Out-Null
            }
            #if ($RequireKeyVault) {
                Set-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $virtualNetworkDEV -AddressPrefix '10.0.1.0/24' -ServiceEndpoint 'Microsoft.KeyVault' | Out-Null
                Write-AEBLog 'DEV KeyVault Service Endpoint created'
            #}
            $virtualNetworkDEV | Set-AzVirtualNetwork | Out-Null
            if ($virtualNetworkDEV.ProvisioningState -eq 'Succeeded') { Write-AEBLog 'DEV Virtual Network created and associated with the Network Security Group successfully' } Else { Write-AEBLog '*** Unable to create the DEV Virtual Network, or associate it to the Network Security Group! ***' -Level Error }
        }
    }
}#>

function ConfigureNetwork {
    if ($RequireNSG) {
        $rule1 = New-AzNetworkSecurityRuleConfig -Name 'smb-rule' -Description 'Allow SMB' -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 445
        #$rule2 = New-AzNetworkSecurityRuleConfig -Name 'rdp-rule' -Description 'Allow RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        $rule2 = New-AzNetworkSecurityRuleConfig -Name 'rdp-rule' -Description 'Allow RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix 'VirtualNetwork' -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        $rule3 = New-AzNetworkSecurityRuleConfig -Name 'internet-allow-rule' -Description 'Allow Internet 443' -Access Allow -Protocol Tcp -Direction Outbound -Priority 110 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443
        $rule4 = New-AzNetworkSecurityRuleConfig -Name 'internet-deny-rule' -Description 'Deny All Internet' -Access Deny -Protocol Tcp -Direction Outbound -Priority 4096 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *

        $resourceCheck = Get-AzNetworkSecurityGroup -ResourceGroupName $RGNamePRODVNET -Name $NsgNamePROD
        if (!$resourceCheck) {
            $nsgPROD = New-AzNetworkSecurityGroup -ResourceGroupName $RGNamePRODVNET -Location $location -Name $NsgNamePROD -SecurityRules $rule1, $rule2, $rule3, $rule4 -Force    # $Rule1, $Rule2 etc.
            if ($nsgPROD.ProvisioningState -eq 'Succeeded') {
                Write-AEBLog 'PROD Network Security Group created successfully'
            }
            else {
                Write-AEBLog '*** Unable to create or configure PROD Network Security Group! ***' -Level Error
                Write-Dump
            }
        }
        else {
            Write-AEBLog "PROD Network Security Group not required"
        }
        $nsgcheck = Get-AzNetworkSecurityGroup -ResourceGroupName $RGNameDEVVNET -Name $NsgNameDEV
        if (!$nsgcheck) {
            $nsgDEV = New-AzNetworkSecurityGroup -ResourceGroupName $RGNameDEVVNET -Location $location -Name $NsgNameDEV -SecurityRules $rule1, $rule2, $rule3, $rule4 -Force   # $Rule1, $Rule2 etc.
            if ($nsgDEV.ProvisioningState -eq 'Succeeded') {
                Write-AEBLog 'DEV Network Security Group created successfully'
            }
            else {
                Write-AEBLog '*** Unable to create or configure DEV Network Security Group! ***' -Level Error
                Write-Dump
            }
        }
        else {
            Write-AEBLog "DEV Network Security Group not required"
            $nsgDEV = $nsgcheck
        }
    }

    if ($RequireVNET -and !$UseTerraform) {
        foreach ($vnet in $vnets.Prod.GetEnumerator()) {
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $RGNamePRODVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$vnetcheck) {
                $vnetcheck = New-AzVirtualNetwork -ResourceGroupName $RGNamePRODVNET -Location $Location -Name $vnet.Value -AddressPrefix 10.0.0.0/16
                $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$subnetcheck) {
                    if ($RequireNSG) {
                        Add-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -AddressPrefix '10.0.1.0/24' -VirtualNetwork $vnetcheck -NetworkSecurityGroup $nsgPROD -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                    else {
                        Add-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -AddressPrefix '10.0.1.0/24' -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                }
                if ($RequireBastion) {
                    Add-AzVirtualNetworkSubnetConfig -Name 'AzureBastionSubnet' -AddressPrefix '10.0.100.0/24' -VirtualNetwork $vnetcheck | Set-AzVirtualNetwork | Out-Null
                }
            }
            else {
                $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$subnetcheck) {
                    if ($RequireNSG) {
                        Add-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -AddressPrefix '10.0.1.0/24' -VirtualNetwork $vnetcheck -NetworkSecurityGroup $nsgPROD -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                    else {
                        Add-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -AddressPrefix '10.0.1.0/24' -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                }
            }
        }
        foreach ($vnet in $vnets.Dev.GetEnumerator()) {
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $RGNameDEVVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$vnetcheck) {
                $vnetcheck = New-AzVirtualNetwork -ResourceGroupName $RGNameDEVVNET -Location $Location -Name $vnet.Value -AddressPrefix 10.0.0.0/16
                $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$subnetcheck) {
                    if ($RequireNSG) {
                        Add-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -AddressPrefix '10.0.2.0/24' -VirtualNetwork $vnetcheck -NetworkSecurityGroup $nsgDEV -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                    else {
                        Add-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -AddressPrefix '10.0.2.0/24' -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                }
                if ($RequireBastion) {
                    Add-AzVirtualNetworkSubnetConfig -Name 'AzureBastionSubnet' -AddressPrefix '10.0.100.0/24' -VirtualNetwork $vnetcheck | Set-AzVirtualNetwork | Out-Null
                }
            }
            else {
                $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$subnetcheck) {
                    if ($RequireNSG) {
                        Add-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -AddressPrefix '10.0.2.0/24' -VirtualNetwork $vnetcheck -NetworkSecurityGroup $nsgDEV -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                    else {
                        Add-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -AddressPrefix '10.0.2.0/24' -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                }
            }
        }
    }
    if ($RequireBastion) {
        foreach ($vnet in $vnets.Prod.GetEnumerator()) {
            $resourceCheck = Get-AzBastion -ResourceGroupName $RGNamePRODVNET -Name "bastion-TestClient0-$($vnet.Value)"
            if (!$resourceCheck) {
                $publicip = New-AzPublicIpAddress -ResourceGroupName $RGNamePRODVNET -Name "bastion-TestClient0-$($vnet.Value)-pip" -Location $location -AllocationMethod Static -Sku Standard
                $resource = New-AzBastion -ResourceGroupName $RGNamePRODVNET -Name "bastion-TestClient0-$($vnet.Value)" `
                    -PublicIpAddressRgName $RGNamePRODVNET -PublicIpAddressName "bastion-TestClient0-$($vnet.Value)-pip" `
                    -VirtualNetworkRgName $RGNamePRODVNET -VirtualNetworkName $vnet.Value `
                    -Sku Basic -AsJob
                if ($resource.ProvisioningState -eq 'Succeeded') {
                    Write-AEBLog "PROD Bastion for VNET $($vnet.Value) created successfully"
                }
                else {
                    Write-AEBLog "*** Unable to create PROD Bastion for VNET $($vnet.Value)! ***" -Level Error
                    Write-Dump
                }
            }
            else {
                Write-AEBLog "PROD Bastion for VNET $($vnet.Value) not required"
            }
        }
        foreach ($vnet in $vnets.Dev.GetEnumerator()) {
            $resourceCheck = Get-AzBastion -ResourceGroupName $RGNameDEVVNET -Name "bastion-TestClient0-$($vnet.Value)"
            if (!$resourceCheck) {
                $publicip = New-AzPublicIpAddress -ResourceGroupName $RGNameDEVVNET -Name "bastion-TestClient0-$($vnet.Value)-pip" -Location $location -AllocationMethod Static -Sku Standard
                $resource = New-AzBastion -ResourceGroupName $RGNameDEVVNET -Name "bastion-TestClient0-$($vnet.Value)" `
                    -PublicIpAddressRgName $RGNameDEVVNET -PublicIpAddressName "bastion-TestClient0-$($vnet.Value)-pip" `
                    -VirtualNetworkRgName $RGNameDEVVNET -VirtualNetworkName $vnet.Value `
                    -Sku Basic -AsJob
                if ($resource.ProvisioningState -eq 'Succeeded') {
                    Write-AEBLog "DEV Bastion for VNET $($vnet.Value) created successfully"
                }
                else {
                    Write-AEBLog "*** Unable to create DEV Bastion for VNET $($vnet.Value)! ***" -Level Error
                    Write-Dump
                }
            }
            else {
                Write-AEBLog "DEV Bastion for VNET $($vnet.Value) not required"
            }
        }
    }
}

function CreateRBACConfig {
    $OwnerGroup = Get-AzADGroup -DisplayName $rbacOwner
    $ContributorGroup = Get-AzADGroup -DisplayName $rbacContributor
    $ReadOnlyGroup = Get-AzADGroup -DisplayName $rbacReadOnly

    if ($RequireUserGroups -and !$UseTerraform) {
        if (!($OwnerGroup)) { New-AzADGroup -DisplayName $rbacOwner -MailNickname 'NotSet' }Else { Write-AEBLog 'Owner RBAC group already exists' -Level Error; Write-Dump }
        if (!($ContributorGroup)) { New-AzADGroup -DisplayName $rbacContributor -MailNickname 'NotSet' }Else { Write-AEBLog 'Contributor RBAC group already exists' -Level Error; Write-Dump }
        if (!($ReadOnlyGroup)) { New-AzADGroup -DisplayName $rbacReadOnly -MailNickname 'NotSet' }Else { Write-AEBLog 'ReadOnly RBAC group already exists' -Level Error; Write-Dump }
    }
}

function CreateStorageAccount {
    if ($RequireStorageAccount -and !$UseTerraform) {
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $RGNameSTORE -AccountName $StorageAccountName -ErrorAction SilentlyContinue
        if ($storageAccount) {
            Write-AEBLog '*** Storage Account already exists ***' -Level Error
            return
        }
        $storageAccount = New-AzStorageAccount -ResourceGroupName $RGNameSTORE -AccountName $StorageAccountName -Location $location -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot -AllowBlobPublicAccess $false -MinimumTlsVersion TLS1_2
        New-AzStorageAccount -ResourceGroupName $RGNameSTORE -AccountName 'testdan102asfd' -Location $location -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot -AllowBlobPublicAccess $false -MinimumTlsVersion TLS1_2
        Start-Sleep -Seconds 10
        $script:ctx = $storageAccount.Context
        $Container = New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Off
        if ($storageAccount.StorageAccountName -eq $StorageAccountName -and $Container.Name -eq $ContainerName) {
            Write-AEBLog 'Storage Account and container created successfully'
        }
        else {
            Write-AEBLog '*** Unable to create the Storage Account or container! ***' -Level Error
            Write-Dump
        }
        $Share = New-AzStorageShare -Name $FileShareName -Context $ctx
        if ($Share.Name -eq $FileShareName) {
            Write-AEBLog 'Storage Share created successfully'
        }
        else {
            Write-AEBLog '*** Unable to create the Storage Share! ***' -Level Error
            Write-Dump
        }
        $script:Keys = Get-AzStorageAccountKey -ResourceGroupName $RGNameSTORE -AccountName $StorageAccountName
        $script:SAS = New-AzStorageContainerSASToken -Name $ContainerName -Context $ctx -Permission r -StartTime $(Get-Date) -ExpiryTime $((Get-Date).AddDays(1))
    }
    else {
        Write-AEBLog 'Creation of Storage Account and Storage Container not required'
    }
}

function CreateKeyVault {
    if ($RequireKeyVault -and !$UseTerraform) {
        $vnetDEVID = (Get-AzVirtualNetwork -ResourceGroupName $RGNameDEVVNET).Subnets[0].Id
        $vnetPRODID = (Get-AzVirtualNetwork -ResourceGroupName $RGNamePRODVNET).Subnets[0].Id

        $myPublicIP = (Invoke-WebRequest ifconfig.me/ip -UseBasicParsing).Content

        $resource = New-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $RGNameSTORE -Location $Location -EnabledForDeployment #-EnableRbacAuthorization
        if (!$resource) {
            Write-AEBLog '*** Unable to create the Key Vault! ***' -Level Error
            Write-Dump
        }
        Update-AzKeyVaultNetworkRuleSet -DefaultAction Deny -VaultName $keyVaultName
        Add-AzKeyVaultNetworkRule -VaultName $keyVaultName -VirtualNetworkResourceId $vnetDEVID
        Add-AzKeyVaultNetworkRule -VaultName $keyVaultName -VirtualNetworkResourceId $vnetPRODID
        Add-AzKeyVaultNetworkRule -VaultName $keyVaultName -IpAddressRange $myPublicIP

        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'ServicePrincipal' -SecretValue $ServicePrincipalPassword | Out-Null
        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'LocalAdmin' -SecretValue $LocalAdminPassword | Out-Null
        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'HyperVLocalAdmin' -SecretValue $HyperVLocalAdminPassword | Out-Null
        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'DomainJoin' -SecretValue $DomainJoinPassword | Out-Null
        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'DomainUser' -SecretValue $DomainUserPassword | Out-Null
    }
}