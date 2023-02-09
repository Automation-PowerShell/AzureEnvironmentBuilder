function UpdateStorage {
    if ($clientSettings.RequireUpdateStorage) {
        Write-AEBLog 'Syncing Files...'
        Try {
            if (!(Test-Path -Path $clientSettings.BlobFilesDest)) { New-Item -Path $clientSettings.BlobFilesDest -ItemType 'directory' | Out-Null }
            $templates = Get-ChildItem -Path $clientSettings.BlobFilesSource -Filter *tmpl* -File
            foreach ($template in $templates) {
                $content = Get-Content -Path (Join-Path -Path $clientSettings.BlobFilesSource -ChildPath $template.Name)
                $content = $content.replace('xxxxx', $clientSettings.StorageAccountName)
                $content = $content.replace('sssss', $clientSettings.azSubscription)
                $content = $content.replace('yyyyy', $Keys.value[0])
                $content = $content.replace('ddddd', $clientSettings.Domain)
                $content = $content.replace('ooooo', $clientSettings.OUPath)
                $content = $content.replace('rrrrr', $clientSettings.RGNameSTORE)
                $content = $content.replace('fffff', $clientSettings.FileShareName)
                $content = $content.replace('kkkkk', $clientSettings.keyVaultName)
                $content = $content.replace('wwwww', $clientSettings.HyperVVMIsoImagePath)
                $content = $content.replace('aaaaa', $clientSettings.HyperVLocalAdminUser)
                $content = $content.replace('jjjjj', $clientSettings.DomainJoinUser)
                $content = $content.replace('uuuuu', $clientSettings.DomainUserUser)
                $contentName = $template.Basename -replace 'Tmpl'
                $contentName = $contentName + '.ps1'
                $content | Set-Content -Path (Join-Path -Path $clientSettings.BlobFilesDest -ChildPath $contentName) -ErrorAction stop
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
    try {
        $OwnerGroup = Get-AzADGroup -DisplayName $clientSettings.rbacOwner
        $ContributorGroup = Get-AzADGroup -DisplayName $clientSettings.rbacContributor
        $ReadOnlyGroup = Get-AzADGroup -DisplayName $clientSettings.rbacReadOnly
    }
    catch {
        Write-AEBLog '*** RBAC Group Not Found! ***' -Level Error
        Write-Dump
    }

    New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName 'Owner' -ResourceGroupName $clientSettings.RGNamePROD -ErrorAction Ignore | Out-Null
    New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName 'Contributor' -ResourceGroupName $clientSettings.RGNamePROD -ErrorAction Ignore | Out-Null
    New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName 'Reader' -ResourceGroupName $clientSettings.RGNamePROD -ErrorAction Ignore | Out-Null
    if (!($clientSettings.RGNameDEV -match $clientSettings.RGNamePROD)) {
        New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName 'Owner' -ResourceGroupName $clientSettings.RGNameDEV -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName 'Contributor' -ResourceGroupName $clientSettings.RGNameDEV -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName 'Reader' -ResourceGroupName $clientSettings.RGNameDEV -ErrorAction Ignore | Out-Null
    }
    if (!($clientSettings.RGNameSTORE -match $clientSettings.RGNamePROD)) {
        New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName 'Owner' -ResourceGroupName $clientSettings.RGNameSTORE -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName 'Contributor' -ResourceGroupName $clientSettings.RGNameSTORE -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName 'Reader' -ResourceGroupName $clientSettings.RGNameSTORE -ErrorAction Ignore | Out-Null
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
    if ($clientSettings.RequireNSG) {
        Write-AEBLog 'Creating Network Security Group'
        $rule1 = New-AzNetworkSecurityRuleConfig -Name 'smb-rule' -Description 'Allow SMB' -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix 'VirtualNetwork' -DestinationPortRange 445
        $rule2 = New-AzNetworkSecurityRuleConfig -Name 'rdp-rule' -Description 'Allow RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix 'VirtualNetwork' -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        $rule3 = New-AzNetworkSecurityRuleConfig -Name 'internet-allow-rule' -Description 'Allow Internet 443' -Access Allow -Protocol Tcp -Direction Outbound -Priority 110 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix 'Internet' -DestinationPortRange 443
        $rule4 = New-AzNetworkSecurityRuleConfig -Name 'AllowVnetOutBound' -Description 'AllowVnetOutBound' -Access Allow -Protocol * -Direction Outbound -Priority 4000 -SourceAddressPrefix 'VirtualNetwork' -SourcePortRange * -DestinationAddressPrefix 'VirtualNetwork' -DestinationPortRange *
        $rule5 = New-AzNetworkSecurityRuleConfig -Name 'internet-deny-rule' -Description 'Deny All Internet' -Access Deny -Protocol * -Direction Outbound -Priority 4096 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *

        $resourceCheck = Get-AzNetworkSecurityGroup -ResourceGroupName $clientSettings.RGNamePRODVNET -Name $clientSettings.NsgNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if (!$resourceCheck) {
            $nsgPROD = New-AzNetworkSecurityGroup -ResourceGroupName $clientSettings.RGNamePRODVNET -Location $clientSettings.location -Name $clientSettings.NsgNamePROD -SecurityRules $rule1, $rule2, $rule3, $rule4, $rule5 -Force    # $Rule1, $Rule2 etc.
            if ($nsgPROD.ProvisioningState -eq 'Succeeded') {
                Write-AEBLog 'PROD Network Security Group created successfully'
            }
            else {
                Write-AEBLog '*** Unable to create or configure PROD Network Security Group! ***' -Level Error
                Write-Dump
            }
        }
        else {
            Write-AEBLog 'PROD Network Security Group not required'
        }
        $nsgcheck = Get-AzNetworkSecurityGroup -ResourceGroupName $clientSettings.RGNameDEVVNET -Name $clientSettings.NsgNameDEV
        if (!$nsgcheck) {
            $nsgDEV = New-AzNetworkSecurityGroup -ResourceGroupName $clientSettings.RGNameDEVVNET -Location $clientSettings.location -Name $clientSettings.NsgNameDEV -SecurityRules $rule1, $rule2, $rule3, $rule4 -Force   # $Rule1, $Rule2 etc.
            if ($nsgDEV.ProvisioningState -eq 'Succeeded') {
                Write-AEBLog 'DEV Network Security Group created successfully'
            }
            else {
                Write-AEBLog '*** Unable to create or configure DEV Network Security Group! ***' -Level Error
                Write-Dump
            }
        }
        else {
            Write-AEBLog 'DEV Network Security Group not required'
            $nsgDEV = $nsgcheck
        }
    }

    if ($clientSettings.RequireVNET -and !$clientSettings.UseTerraform) {
        Write-AEBLog 'Creating VNETs'
        $addressSpace = 0
        foreach ($vnet in $clientSettings.vnets.Prod.GetEnumerator()) {
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNamePRODVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$vnetcheck) {
                $vnetcheck = New-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNamePRODVNET -Location $clientSettings.Location -Name $vnet.Value -AddressPrefix 10.$addressSpace.0.0/22
                if ($vnetcheck.ProvisioningState -eq 'Succeeded') {
                    Write-AEBLog 'PROD VNET created successfully'
                }
                else {
                    Write-AEBLog '*** Unable to create PROD VNET! ***' -Level Error
                    Write-Dump
                }
                $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNamePROD -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$subnetcheck) {
                    if ($clientSettings.RequireNSG) {
                        Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNamePROD -AddressPrefix 10.$addressSpace.1.0/24 -VirtualNetwork $vnetcheck -NetworkSecurityGroup $clientSettings.nsgPROD -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                    else {
                        Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNamePROD -AddressPrefix 10.$addressSpace.1.0/24 -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                }
                if ($clientSettings.RequireBastion) {
                    Add-AzVirtualNetworkSubnetConfig -Name 'AzureBastionSubnet' -AddressPrefix 10.$addressSpace.0.0/24 -VirtualNetwork $vnetcheck | Set-AzVirtualNetwork | Out-Null
                }
            }
            else {
                $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNamePROD -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$subnetcheck) {
                    if ($clientSettings.RequireNSG) {
                        Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNamePROD -AddressPrefix 10.$addressSpace.1.0/24 -VirtualNetwork $vnetcheck -NetworkSecurityGroup $clientSettings.nsgPROD -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                    else {
                        Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNamePROD -AddressPrefix 10.$addressSpace.1.0/24 -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                }
            }
            $addressSpace++
        }

        $addressSpace = 0
        foreach ($vnet in $clientSettings.vnets.Dev.GetEnumerator()) {
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNameDEVVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$vnetcheck) {
                $vnetcheck = New-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNameDEVVNET -Location $clientSettings.Location -Name $vnet.Value -AddressPrefix 10.$addressSpace.0.0/22
                if ($vnetcheck.ProvisioningState -eq 'Succeeded') {
                    Write-AEBLog 'DEV VNET created successfully'
                }
                else {
                    Write-AEBLog '*** Unable to create DEV VNET! ***' -Level Error
                    Write-Dump
                }
                $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNameDEV -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$subnetcheck) {
                    if ($clientSettings.RequireNSG) {
                        Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNameDEV -AddressPrefix 10.$addressSpace.2.0/24 -VirtualNetwork $vnetcheck -NetworkSecurityGroup $clientSettings.nsgDEV -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                    else {
                        Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNameDEV -AddressPrefix 10.$addressSpace.2.0/24 -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                }
                if ($clientSettings.RequireBastion) {
                    Add-AzVirtualNetworkSubnetConfig -Name 'AzureBastionSubnet' -AddressPrefix 10.$addressSpace.0.0/24 -VirtualNetwork $vnetcheck | Set-AzVirtualNetwork | Out-Null
                }
            }
            else {
                Write-AEBLog 'DEV VNET not required'
                $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNameDEV -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$subnetcheck) {
                    if ($clientSettings.RequireNSG) {
                        Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNameDEV -AddressPrefix 10.$addressSpace.2.0/24 -VirtualNetwork $vnetcheck -NetworkSecurityGroup $clientSettings.nsgDEV -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                    else {
                        Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNameDEV -AddressPrefix 10.$addressSpace.2.0/24 -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault' | Set-AzVirtualNetwork | Out-Null
                    }
                }
            }
            $addressSpace++
        }

        Write-AEBLog 'Adding VNET Peering'
        foreach ($environment in $clientSettings.vnets.GetEnumerator()) {
            switch ($environment.Name) {
                'PROD' {
                    $counter = 1
                    $vnetbase = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNamePRODVNET -Name $clientSettings.vnets.$($environment.Name)[0] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    while ($counter -lt $clientSettings.vnets.$($environment.Name).Count) {
                        $vnetCounter = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNamePRODVNET -Name $clientSettings.vnets.$($environment.Name)[$counter] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                        Add-AzVirtualNetworkPeering -Name "peer-0-to-$counter" -VirtualNetwork $vnetbase -RemoteVirtualNetworkId $vnetCounter.Id -ErrorAction SilentlyContinue | Out-Null
                        Add-AzVirtualNetworkPeering -Name "peer-$counter-to-0" -VirtualNetwork $vnetCounter -RemoteVirtualNetworkId $vnetbase.Id -ErrorAction SilentlyContinue | Out-Null
                        $counter++
                    }
                }

                'DEV' {
                    $counter = 1
                    $vnetbase = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNamePRODVNET -Name $clientSettings.vnets.$($environment.Name)[0] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    while ($counter -lt $clientSettings.vnets.$($environment.Name).Count) {
                        $vnetCounter = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNamePRODVNET -Name $clientSettings.vnets.$($environment.Name)[$counter] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                        Add-AzVirtualNetworkPeering -Name "peer-0-to-$counter" -VirtualNetwork $vnetbase -RemoteVirtualNetworkId $vnetCounter.Id -ErrorAction SilentlyContinue | Out-Null
                        Add-AzVirtualNetworkPeering -Name "peer-$counter-to-0" -VirtualNetwork $vnetCounter -RemoteVirtualNetworkId $vnetbase.Id -ErrorAction SilentlyContinue | Out-Null
                        $counter++
                    }
                }
            }
        }
    }
    <#if ($RequireBastion) {
        foreach ($vnet in $vnets.Prod.GetEnumerator()) {
            $resourceCheck = Get-AzBastion -ResourceGroupName $RGNamePRODVNET -Name "bastion-TestClient0-$($vnet.Value)" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$resourceCheck) {
                $publicip = New-AzPublicIpAddress -ResourceGroupName $RGNamePRODVNET -Name "bastion-TestClient0-$($vnet.Value)-pip" -Location $location -AllocationMethod Static -Sku Standard
                $resource = New-AzBastion -ResourceGroupName $RGNamePRODVNET -Name "bastion-TestClient0-$($vnet.Value)" `
                    -PublicIpAddressRgName $RGNamePRODVNET -PublicIpAddressName "bastion-TestClient0-$($vnet.Value)-pip" `
                    -VirtualNetworkRgName $RGNamePRODVNET -VirtualNetworkName $vnet.Value `
                    -Sku Basic -AsJob
            }
            else {
                Write-AEBLog "PROD Bastion for VNET $($vnet.Value) not required"
            }
        }
        foreach ($vnet in $vnets.Dev.GetEnumerator()) {
            $resourceCheck = Get-AzBastion -ResourceGroupName $RGNameDEVVNET -Name "bastion-TestClient0-$($vnet.Value)" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$resourceCheck) {
                $publicip = New-AzPublicIpAddress -ResourceGroupName $RGNameDEVVNET -Name "bastion-TestClient0-$($vnet.Value)-pip" -Location $location -AllocationMethod Static -Sku Standard
                $resource = New-AzBastion -ResourceGroupName $RGNameDEVVNET -Name "bastion-TestClient0-$($vnet.Value)" `
                    -PublicIpAddressRgName $RGNameDEVVNET -PublicIpAddressName "bastion-TestClient0-$($vnet.Value)-pip" `
                    -VirtualNetworkRgName $RGNameDEVVNET -VirtualNetworkName $vnet.Value `
                    -Sku Basic -AsJob
            }
            else {
                Write-AEBLog "DEV Bastion for VNET $($vnet.Value) not required"
            }
        }
    }#>
    if ($clientSettings.RequireBastion) {
        Write-AEBLog 'Creating Bastions'
        foreach ($environment in $clientSettings.vnets.GetEnumerator()) {
            switch ($environment.Name) {
                'PROD' {
                    $resourceCheck = Get-AzBastion -ResourceGroupName $clientSettings.RGNamePRODVNET -Name $clientSettings.BastionNamePROD -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    if (!$resourceCheck) {
                        Write-AEBLog "Creating Bastion for VNET $($clientSettings.vnets.$($environment.Name)[0])"
                        $publicip = New-AzPublicIpAddress -ResourceGroupName $clientSettings.RGNamePRODVNET -Name "$($clientSettings.BastionNamePROD)-pip" -Location $clientSettings.location -AllocationMethod Static -Sku Standard
                        $resource = New-AzBastion -ResourceGroupName $clientSettings.RGNamePRODVNET -Name $clientSettings.BastionNamePROD `
                            -PublicIpAddressRgName $clientSettings.RGNamePRODVNET -PublicIpAddressName "$($clientSettings.BastionNamePROD)-pip" `
                            -VirtualNetworkRgName $clientSettings.RGNamePRODVNET -VirtualNetworkName $clientSettings.vnets.$($environment.Name)[0] `
                            -Sku Basic -AsJob
                    }
                    else {
                        Write-AEBLog "Bastion for VNET $($clientSettings.vnets.$($environment.Name)[0]) not required"
                    }
                }

                'DEV' {
                    $resourceCheck = Get-AzBastion -ResourceGroupName $clientSettings.RGNameDEVVNET -Name $clientSettings.BastionNameDEV -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    if (!$resourceCheck) {
                        Write-AEBLog "Creating Bastion for VNET $($clientSettings.vnets.$($environment.Name)[0])"
                        $publicip = New-AzPublicIpAddress -ResourceGroupName $clientSettings.RGNameDEVVNET -Name "$($clientSettings.BastionNameDEV)-pip" -Location $clientSettings.location -AllocationMethod Static -Sku Standard
                        $resource = New-AzBastion -ResourceGroupName $clientSettings.RGNameDEVVNET -Name $clientSettings.BastionNameDEV `
                            -PublicIpAddressRgName $clientSettings.RGNameDEVVNET -PublicIpAddressName "$($clientSettings.BastionNameDEV)-pip" `
                            -VirtualNetworkRgName $clientSettings.RGNameDEVVNET -VirtualNetworkName $clientSettings.vnets.$($environment.Name)[0] `
                            -Sku Basic -AsJob
                    }
                    else {
                        Write-AEBLog "Bastion for VNET $($clientSettings.vnets.$($environment.Name)[0]) not required"
                    }
                }
            }
        }
    }
}

function CreateRBACConfig {
    try {
        $OwnerGroup = Get-AzADGroup -DisplayName $clientSettings.rbacOwner
        $ContributorGroup = Get-AzADGroup -DisplayName $clientSettings.rbacContributor
        $ReadOnlyGroup = Get-AzADGroup -DisplayName $clientSettings.rbacReadOnly
    }
    catch {
        Write-AEBLog '*** RBAC Group Not Found! ***' -Level Error
        Write-Dump
    }

    if ($clientSettings.RequireUserGroups -and !$clientSettings.UseTerraform) {
        if (!($OwnerGroup)) {
            New-AzADGroup -DisplayName $clientSettings.rbacOwner -MailNickname 'NotSet'
        }
        else {
            Write-AEBLog 'Owner RBAC group already exists' -Level Error
            Write-Dump
        }
        if (!($ContributorGroup)) {
            New-AzADGroup -DisplayName $clientSettings.rbacContributor -MailNickname 'NotSet'
        }
        else {
            Write-AEBLog 'Contributor RBAC group already exists' -Level Error
            Write-Dump
        }
        if (!($ReadOnlyGroup)) {
            New-AzADGroup -DisplayName $clientSettings.rbacReadOnly -MailNickname 'NotSet'
        }
        else {
            Write-AEBLog 'ReadOnly RBAC group already exists' -Level Error
            Write-Dump
        }
    }
}

function CreateStorageAccount {
    if ($clientSettings.RequireStorageAccount -and !$clientSettings.UseTerraform) {
        Write-AEBLog 'Creating Storage Account'
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $clientSettings.RGNameSTORE -AccountName $clientSettings.StorageAccountName -ErrorAction SilentlyContinue
        if ($storageAccount) {
            Write-AEBLog '*** Storage Account already exists ***' -Level Error
            return
        }
        $storageAccount = New-AzStorageAccount -ResourceGroupName $clientSettings.RGNameSTORE -AccountName $clientSettings.StorageAccountName -Location $clientSettings.location -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot -AllowBlobPublicAccess $false -MinimumTlsVersion TLS1_2
        New-AzStorageAccount -ResourceGroupName $clientSettings.RGNameSTORE -AccountName 'testdan102asfd' -Location $clientSettings.location -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot -AllowBlobPublicAccess $false -MinimumTlsVersion TLS1_2
        Start-Sleep -Seconds 10
        $script:ctx = $storageAccount.Context
        $Container = New-AzStorageContainer -Name $clientSettings.ContainerName -Context $ctx -Permission Off
        if ($storageAccount.StorageAccountName -eq $clientSettings.StorageAccountName -and $Container.Name -eq $clientSettings.ContainerName) {
            Write-AEBLog 'Storage Account and container created successfully'
        }
        else {
            Write-AEBLog '*** Unable to create the Storage Account or container! ***' -Level Error
            Write-Dump
        }
        $Share = New-AzStorageShare -Name $clientSettings.FileShareName -Context $ctx
        if ($Share.Name -eq $clientSettings.FileShareName) {
            Write-AEBLog 'Storage Share created successfully'
        }
        else {
            Write-AEBLog '*** Unable to create the Storage Share! ***' -Level Error
            Write-Dump
        }
        $script:Keys = Get-AzStorageAccountKey -ResourceGroupName $clientSettings.RGNameSTORE -AccountName $clientSettings.StorageAccountName
        $script:SAS = New-AzStorageContainerSASToken -Name $clientSettings.ContainerName -Context $ctx -Permission r -StartTime $(Get-Date) -ExpiryTime $((Get-Date).AddDays(1))
    }
    else {
        Write-AEBLog 'Creation of Storage Account and Storage Container not required'
    }
}

function CreateKeyVault {
    if (!$clientSettings.UseTerraform) {
        Write-AEBLog 'Creating KeyVault'
        $vnetIDs = [System.Collections.ArrayList]@()
        foreach ($vnet in $clientSettings.vnets.Prod.GetEnumerator()) {
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNamePRODVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNamePROD -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $vnetIDs.Add($subnetcheck.Id) | Out-Null
        }
        foreach ($vnet in $clientSettings.vnets.Dev.GetEnumerator()) {
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.RGNameDEVVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.SubnetNameDEV -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $vnetIDs.Add($subnetcheck.Id) | Out-Null
        }
        $myPublicIP = (Invoke-WebRequest ifconfig.me/ip -UseBasicParsing).Content

        $resource = Get-AzKeyVault -VaultName $clientSettings.keyVaultName -ResourceGroupName $clientSettings.RGNameSTORE -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if ($clientSettings.RequireKeyVault -and !$resource) {
            $resource = New-AzKeyVault -VaultName $clientSettings.keyVaultName -ResourceGroupName $clientSettings.RGNameSTORE -Location $clientSettings.Location -EnabledForDeployment #-EnableRbacAuthorization
            #if ($resource.ProvisioningState -eq 'Succeeded') {          # Bug with ProvisioningState
            #    Write-AEBLog 'KeyVault created successfully'
            #}
            #else {
            #    Write-AEBLog '*** Unable to create the KeyVault! ***' -Level Error
            #    Write-Dump
            #}
            Update-AzKeyVaultNetworkRuleSet -DefaultAction Deny -VaultName $clientSettings.keyVaultName

            Add-AzKeyVaultNetworkRule -VaultName $clientSettings.keyVaultName -IpAddressRange $myPublicIP
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'ServicePrincipal' -SecretValue $ServicePrincipalPassword | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'LocalAdmin' -SecretValue $LocalAdminPassword | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'HyperVLocalAdmin' -SecretValue $HyperVLocalAdminPassword | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'DomainJoin' -SecretValue $DomainJoinPassword | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'DomainUser' -SecretValue $DomainUserPassword | Out-Null
        }

        foreach ($vnet in $vnetIDs) {
            Add-AzKeyVaultNetworkRule -VaultName $clientSettings.keyVaultName -VirtualNetworkResourceId $vnet
        }
        Add-AzKeyVaultNetworkRule -VaultName $clientSettings.keyVaultName -IpAddressRange $myPublicIP
    }
}