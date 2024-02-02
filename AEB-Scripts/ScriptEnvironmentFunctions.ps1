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
                $content = $content.replace('rrrrr', $clientSettings.rgs.STORE.RGName)
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

    New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName 'Owner' -ResourceGroupName $clientSettings.rgs.PROD.RGName -ErrorAction Ignore | Out-Null
    New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName 'Contributor' -ResourceGroupName $clientSettings.rgs.PROD.RGName -ErrorAction Ignore | Out-Null
    New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName 'Reader' -ResourceGroupName $clientSettings.rgs.PROD.RGName -ErrorAction Ignore | Out-Null
    if (!($clientSettings.rgs.DEV.RGName -match $clientSettings.rgs.PROD.RGName)) {
        New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName 'Owner' -ResourceGroupName $clientSettings.rgs.DEV.RGName -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName 'Contributor' -ResourceGroupName $clientSettings.rgs.DEV.RGName -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName 'Reader' -ResourceGroupName $clientSettings.rgs.DEV.RGName -ErrorAction Ignore | Out-Null
    }
    if (!($clientSettings.rgs.STORE.RGName -match $clientSettings.rgs.PROD.RGName)) {
        New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName 'Owner' -ResourceGroupName $clientSettings.rgs.STORE.RGName -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName 'Contributor' -ResourceGroupName $clientSettings.rgs.STORE.RGName -ErrorAction Ignore | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName 'Reader' -ResourceGroupName $clientSettings.rgs.STORE.RGName -ErrorAction Ignore | Out-Null
    }
    Write-AEBLog 'Role Assignments Set'
}

function ConfigureNetwork {
    if ($clientSettings.RequireNSG) {
        Write-AEBLog 'Creating Network Security Groups'
        $rule1 = New-AzNetworkSecurityRuleConfig -Name 'rdp-rule' -Description 'Allow RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix 'VirtualNetwork' -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        $rule2 = New-AzNetworkSecurityRuleConfig -Name 'dns-inbound-rule' -Description 'Allow Inbound DNS 53' -Access Allow -Protocol * -Direction Inbound -Priority 120 -SourceAddressPrefix 'VirtualNetwork' -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 53

        $rule3 = New-AzNetworkSecurityRuleConfig -Name 'smb-vnet-rule' -Description 'Allow VNET SMB' -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix 'VirtualNetwork' -DestinationPortRange 445
        $rule4 = New-AzNetworkSecurityRuleConfig -Name 'smb-storage-rule' -Description 'Allow Storage SMB' -Access Allow -Protocol Tcp -Direction Outbound -Priority 105 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix 'Storage' -DestinationPortRange 445
        $rule5 = New-AzNetworkSecurityRuleConfig -Name 'internet-allow-443--rule' -Description 'Allow Internet 443' -Access Allow -Protocol Tcp -Direction Outbound -Priority 110 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix 'Internet' -DestinationPortRange 443
        $rule6 = New-AzNetworkSecurityRuleConfig -Name 'internet-allow-80-rule' -Description 'Allow Internet 80' -Access Allow -Protocol Tcp -Direction Outbound -Priority 115 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix 'Internet' -DestinationPortRange 80
        $rule7 = New-AzNetworkSecurityRuleConfig -Name 'dns-outbound-rule' -Description 'Allow Outbound DNS 53' -Access Allow -Protocol * -Direction Outbound -Priority 120 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix 'VirtualNetwork' -DestinationPortRange 53
        $rule8 = New-AzNetworkSecurityRuleConfig -Name 'AllowVnetOutBound' -Description 'AllowVnetOutBound' -Access Allow -Protocol * -Direction Outbound -Priority 4000 -SourceAddressPrefix 'VirtualNetwork' -SourcePortRange * -DestinationAddressPrefix 'VirtualNetwork' -DestinationPortRange *
        $rule9 = New-AzNetworkSecurityRuleConfig -Name 'deny-all-rule' -Description 'Deny All' -Access Deny -Protocol * -Direction Outbound -Priority 4096 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *

        foreach ($environment in $clientSettings.vnets.GetEnumerator().Name) {
            $resourceCheck = Get-AzNetworkSecurityGroup -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name $clientSettings.nsgs.$environment.NsgName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$resourceCheck) {
                $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Location $clientSettings.location -Name $clientSettings.nsgs.$environment.NsgName -SecurityRules $rule1, $rule2, $rule3, $rule4, $rule5, $rule6, $rule7, $rule8, $rule9 -Force    # $Rule1, $Rule2 etc.
                if ($nsg.ProvisioningState -eq 'Succeeded') {
                    Write-AEBLog "$environment Network Security Group created successfully"
                    Update-AzTag -ResourceId $nsg.Id -Tag $clientSettings.tags -Operation Merge | Out-Null
                    Update-AzTag -ResourceId $nsg.Id -Tag @{ 'AEB-Environment' = $environment } -Operation Merge | Out-Null
                }
                else {
                    Write-AEBLog "*** Unable to create or configure $environment Network Security Group! ***" -Level Error
                    Write-Dump
                }
            }
            else {
                Write-AEBLog "$environment Network Security Group not required"
            }
        }
    }

    if ($clientSettings.RequireVNET -and !$clientSettings.UseTerraform) {
        Write-AEBLog 'Creating VNETs'
        foreach ($environment in $clientSettings.vnets.GetEnumerator().Name) {
            $addressSpace = 0
            foreach ($vnet in $clientSettings.vnets.$environment.Values) {
                $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name $vnet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$vnetcheck) {
                    $vnetcheck = New-AzVirtualNetwork -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Location $clientSettings.Location -Name $vnet -AddressPrefix "10.$addressSpace.0.0/22" -Tag $clientSettings.tags
                    if ($vnetcheck.ProvisioningState -eq 'Succeeded') {
                        Write-AEBLog "$environment VNET created successfully"
                        #Start-Sleep -Seconds 10
                        #Update-AzTag -ResourceId $vnetcheck.Id -Tag $clientSettings.tags -Operation Merge | Out-Null
                        #Start-Sleep -Seconds 10
                        Update-AzTag -ResourceId $vnetcheck.Id -Tag @{ 'AEB-Environment' = $environment } -Operation Merge | Out-Null
                    }
                    else {
                        Write-AEBLog "*** Unable to create $environment VNET! ***" -Level Error
                        Write-Dump
                    }
                    $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.$environment.SubnetName -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    if (!$subnetcheck) {
                        if ($clientSettings.RequireNSG) {
                            $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name $clientSettings.nsgs.$environment.NsgName
                            Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.$environment.SubnetName -AddressPrefix "10.$addressSpace.$($clientSettings.subnets.$environment.addressSpace).0/24" -VirtualNetwork $vnetcheck -NetworkSecurityGroup $nsg -ServiceEndpoint 'Microsoft.KeyVault', 'Microsoft.Storage' | Set-AzVirtualNetwork | Out-Null
                        }
                        else {
                            Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.$environment.SubnetName -AddressPrefix "10.$addressSpace.$($clientSettings.subnets.$environment.addressSpace).0/24" -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault', 'Microsoft.Storage' | Set-AzVirtualNetwork | Out-Null
                        }
                    }
                    if ($clientSettings.RequireBastion) {
                        Add-AzVirtualNetworkSubnetConfig -Name 'AzureBastionSubnet' -AddressPrefix "10.$addressSpace.0.0/24" -VirtualNetwork $vnetcheck | Set-AzVirtualNetwork | Out-Null
                    }
                }
                else {
                    Write-AEBLog "$environment VNET not required"
                    $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.$environment.SubnetName -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    if (!$subnetcheck) {
                        if ($clientSettings.RequireNSG) {
                            $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name $clientSettings.nsgs.$environment.NsgName
                            Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.$environment.SubnetName -AddressPrefix "10.$addressSpace.$($clientSettings.subnets.$environment.addressSpace).0/24" -VirtualNetwork $vnetcheck -NetworkSecurityGroup $nsg -ServiceEndpoint 'Microsoft.KeyVault', 'Microsoft.Storage' | Set-AzVirtualNetwork | Out-Null
                        }
                        else {
                            Add-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.$environment.SubnetName -AddressPrefix "10.$addressSpace.$($clientSettings.subnets.$environment.addressSpace).0/24" -VirtualNetwork $vnetcheck -ServiceEndpoint 'Microsoft.KeyVault', 'Microsoft.Storage' | Set-AzVirtualNetwork | Out-Null
                        }
                    }
                }
                $addressSpace++
            }
        }

        Write-AEBLog 'Adding VNET Peering'
        foreach ($environment in $clientSettings.vnets.GetEnumerator().Name) {
            $counter = 1
            $vnetbase = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name $clientSettings.vnets.$environment[0] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            while ($counter -lt $clientSettings.vnets.$environment.Count) {
                $vnetCounter = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name $clientSettings.vnets.$environment[$counter] -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                Add-AzVirtualNetworkPeering -Name "peer-0-to-$counter" -VirtualNetwork $vnetbase -RemoteVirtualNetworkId $vnetCounter.Id -ErrorAction SilentlyContinue | Out-Null
                Add-AzVirtualNetworkPeering -Name "peer-$counter-to-0" -VirtualNetwork $vnetCounter -RemoteVirtualNetworkId $vnetbase.Id -ErrorAction SilentlyContinue | Out-Null
                $counter++
            }
        }

        if ($clientSettings.RequireBastion) {
            Write-AEBLog 'Creating Bastions'
            foreach ($environment in $clientSettings.vnets.GetEnumerator().Name) {
                $resourceCheck = Get-AzResource -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name "$($clientSettings.bastions.$environment.BastionName)-pip" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if (!$resourceCheck) {
                    Write-AEBLog "Commisioning Bastion for $environment VNETS in RG: $($clientSettings.rgs.$environment.RGNameVNET)"
                    $publicip = New-AzPublicIpAddress -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name "$($clientSettings.bastions.$environment.BastionName)-pip" -Location $clientSettings.location -AllocationMethod Static -Sku Standard
                    Update-AzTag -ResourceId $publicip.Id -Tag $clientSettings.tags -Operation Merge | Out-Null
                    Update-AzTag -ResourceId $publicip.Id -Tag @{ 'AEB-Environment' = $environment } -Operation Merge | Out-Null
                    $resource = New-AzBastion -ResourceGroupName $clientSettings.rgs.$environment.RGNameVNET -Name $clientSettings.bastions.$environment.BastionName `
                        -PublicIpAddressRgName $clientSettings.rgs.$environment.RGNameVNET -PublicIpAddressName "$($clientSettings.bastions.$environment.BastionName)-pip" `
                        -VirtualNetworkRgName $clientSettings.rgs.$environment.RGNameVNET -VirtualNetworkName $clientSettings.vnets.$environment[0] `
                        -Sku Basic -Tag $clientSettings.tags -AsJob
                    #Update-AzTag -ResourceId $resource.Id -Tag $clientSettings.tags -Operation Merge
                    #Update-AzTag -ResourceId $resource.Id -Tag @{ 'AEB-Environment' = $environment } -Operation Merge
                }
                else {
                    Write-AEBLog "Bastion for $environment VNETs in RG: $($clientSettings.rgs.$environment.RGNameVNET) not required"
                }
            }
        }
    }
}

function CreateResourceGroups {
    if ($clientSettings.RequireResourceGroups -and !$clientSettings.UseTerraform) {
        $RG = New-AzResourceGroup -Name $clientSettings.rgs.PROD.RGName -Location $clientSettings.Location
        if ($RG.ResourceGroupName -eq $clientSettings.rgs.PROD.RGName) { Write-AEBLog 'PROD Resource Group created successfully' } else { Write-AEBLog '*** Unable to create PROD Resource Group! ***' -Level Error }
        if (!($clientSettings.rgs.DEV.RGName -match $clientSettings.rgs.PROD.RGName)) {
            $RG = New-AzResourceGroup -Name $clientSettings.rgs.DEV.RGName -Location $clientSettings.Location
            if ($RG.ResourceGroupName -eq $clientSettings.rgs.DEV.RGName) { Write-AEBLog 'DEV Resource Group created successfully' } else { Write-AEBLog '*** Unable to create DEV Resource Group! ***' -Level Error }
        }
        if (!($clientSettings.rgs.DEV.RGName -match $clientSettings.rgs.DEV.RGNameVNET)) {
            $RG = New-AzResourceGroup -Name $clientSettings.rgs.DEV.RGNameVNET -Location $clientSettings.Location
            if ($RG.ResourceGroupName -eq $clientSettings.$clientSettings.rgs.DEV.RGNameVNET) { Write-AEBLog 'DEV VNET Resource Group created successfully' } else { Write-AEBLog '*** Unable to create DEV VNET Resource Group! ***' -Level Error }
        }
        if (!($clientSettings.rgs.PROD.RGName -match $clientSettings.rgs.PROD.RGNameVNET)) {
            $RG = New-AzResourceGroup -Name $clientSettings.rgs.PROD.RGNameVNET -Location $clientSettings.Location
            if ($RG.ResourceGroupName -eq $clientSettings.rgs.PROD.RGNameVNET) { Write-AEBLog 'PROD VNET Resource Group created successfully' } else { Write-AEBLog '*** Unable to create PROD VNET Resource Group! ***' -Level Error }
        }
        if (!($clientSettings.rgs.PROD.RGName -match $clientSettings.rgs.STORE.RGName) -and $clientSettings.RequireStorageAccount) {
            $RG = Get-AzResourceGroup -Name $clientSettings.rgs.STORE.RGName -ErrorAction SilentlyContinue
            if (!$RG) {
                $RG = New-AzResourceGroup -Name $clientSettings.rgs.STORE.RGName -Location $clientSettings.Location
                if ($RG.ResourceGroupName -eq $clientSettings.rgs.STORE.RGName) { Write-AEBLog 'STORE Resource Group created successfully' } else { Write-AEBLog '*** Unable to create STORE Resource Group! ***' -Level Error }
            }
            else {
                Write-AEBLog 'STORE Resource Group already exists'
            }
        }
    }
    else {
        $RG = Get-AzResourceGroup -Name $clientSettings.rgs.PROD.RGName -ErrorAction SilentlyContinue
        if (!$RG) {
            Write-AEBLog '*** Resouce Groups are missing ***' -Level Error
            Write-Dump
        }
    }
    if ($clientSettings.UseTerraform) {
        $TerraformMainTemplate = Get-Content -Path '.\Terraform\Root Template\main.tf' | Set-Content -Path '.\Terraform\main.tf'
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
        $vnetIDs = [System.Collections.ArrayList]@()
        foreach ($vnet in $clientSettings.vnets.Prod.GetEnumerator()) {
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.rgs.PROD.RGNameVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.PROD.SubnetName -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $vnetIDs.Add($subnetcheck.Id) | Out-Null
        }
        foreach ($vnet in $clientSettings.vnets.Dev.GetEnumerator()) {
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.rgs.DEV.RGNameVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.DEV.SubnetName -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $vnetIDs.Add($subnetcheck.Id) | Out-Null
        }
        $myPublicIP = (Invoke-WebRequest ifconfig.me/ip -UseBasicParsing).Content

        $storageAccount = Get-AzStorageAccount -ResourceGroupName $clientSettings.rgs.STORE.RGName -AccountName $clientSettings.StorageAccountName -ErrorAction SilentlyContinue
        if ($storageAccount) {
            Write-AEBLog '*** Storage Account already exists ***' -Level Error
            return
        }
        $storageAccount = New-AzStorageAccount `
            -ResourceGroupName $clientSettings.rgs.STORE.RGName `
            -AccountName $clientSettings.StorageAccountName `
            -Location $clientSettings.location `
            -SkuName Standard_LRS `
            -Kind StorageV2 `
            -AccessTier Hot `
            -AllowBlobPublicAccess $false `
            -MinimumTlsVersion TLS1_2
        Update-AzTag -ResourceId $storageAccount.Id -Tag $clientSettings.tags -Operation Merge | Out-Null
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
        $script:Keys = Get-AzStorageAccountKey -ResourceGroupName $clientSettings.rgs.STORE.RGName -AccountName $clientSettings.StorageAccountName
        $script:SAS = New-AzStorageContainerSASToken -Name $clientSettings.ContainerName -Context $ctx -Permission r -StartTime $(Get-Date) -ExpiryTime $((Get-Date).AddDays(1))
        Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $clientSettings.rgs.STORE.RGName -Name $clientSettings.StorageAccountName -DefaultAction Deny | Out-Null
        foreach ($vnet in $vnetIDs) {
            Add-AzStorageAccountNetworkRule -ResourceGroupName $clientSettings.rgs.STORE.RGName -Name $clientSettings.StorageAccountName -VirtualNetworkResourceId $vnet | Out-Null
        }
        foreach ($ip in $clientSettings.StorageAccountFirewallIPs) {
            Add-AzStorageAccountNetworkRule -ResourceGroupName $clientSettings.rgs.STORE.RGName -Name $clientSettings.StorageAccountName -IPAddressOrRange $ip | Out-Null
        }
        Add-AzStorageAccountNetworkRule -ResourceGroupName $clientSettings.rgs.STORE.RGName -Name $clientSettings.StorageAccountName -IPAddressOrRange $myPublicIP | Out-Null
        Start-Sleep -Seconds 30
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
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.rgs.PROD.RGNameVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.PROD.SubnetName -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $vnetIDs.Add($subnetcheck.Id) | Out-Null
        }
        foreach ($vnet in $clientSettings.vnets.Dev.GetEnumerator()) {
            $vnetcheck = Get-AzVirtualNetwork -ResourceGroupName $clientSettings.rgs.DEV.RGNameVNET -Name $vnet.Value -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $subnetcheck = Get-AzVirtualNetworkSubnetConfig -Name $clientSettings.subnets.DEV.SubnetName -VirtualNetwork $vnetcheck -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $vnetIDs.Add($subnetcheck.Id) | Out-Null
        }
        $myPublicIP = (Invoke-WebRequest ifconfig.me/ip -UseBasicParsing).Content

        $resource = Get-AzKeyVault -VaultName $clientSettings.keyVaultName -ResourceGroupName $clientSettings.rgs.STORE.RGName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if ($clientSettings.RequireKeyVault -and !$resource) {
            $resource = New-AzKeyVault -VaultName $clientSettings.keyVaultName -ResourceGroupName $clientSettings.rgs.STORE.RGName -Location $clientSettings.Location -EnabledForDeployment -ErrorAction Stop #-EnableRbacAuthorization
            #if ($resource.ProvisioningState -eq 'Succeeded') {          # Bug with ProvisioningState
            #    Write-AEBLog 'KeyVault created successfully'
            #}
            #else {
            #    Write-AEBLog '*** Unable to create the KeyVault! ***' -Level Error
            #    Write-Dump
            #}
            Update-AzTag -ResourceId $resource.ResourceId -Tag $clientSettings.tags -Operation Merge | Out-Null
            Update-AzKeyVaultNetworkRuleSet -DefaultAction Deny -VaultName $clientSettings.keyVaultName | Out-Null
            Add-AzKeyVaultNetworkRule -VaultName $clientSettings.keyVaultName -IpAddressRange $myPublicIP | Out-Null

            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'ServicePrincipal-Id' -SecretValue $(ConvertTo-SecureString -String $clientSettings.servicePrincipalUser -AsPlainText -Force) | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'LocalAdmin-Id' -SecretValue $(ConvertTo-SecureString -String $clientSettings.LocalAdminUser -AsPlainText -Force) | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'HyperVLocalAdmin-Id' -SecretValue $(ConvertTo-SecureString -String $clientSettings.HyperVLocalAdminUser -AsPlainText -Force) | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'DomainJoin-Id' -SecretValue $(ConvertTo-SecureString -String $clientSettings.DomainJoinUser -AsPlainText -Force) | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'DomainUser-Id' -SecretValue $(ConvertTo-SecureString -String $clientSettings.DomainUserUser -AsPlainText -Force) | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'ServicePrincipal-Secret' -SecretValue $ServicePrincipalPassword | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'LocalAdmin-Secret' -SecretValue $LocalAdminPassword | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'HyperVLocalAdmin-Secret' -SecretValue $HyperVLocalAdminPassword | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'DomainJoin-Secret' -SecretValue $DomainJoinPassword | Out-Null
            Set-AzKeyVaultSecret -VaultName $clientSettings.keyVaultName -Name 'DomainUser-Secret' -SecretValue $DomainUserPassword | Out-Null
        }

        foreach ($vnet in $vnetIDs) {
            Add-AzKeyVaultNetworkRule -VaultName $clientSettings.keyVaultName -VirtualNetworkResourceId $vnet | Out-Null
        }
        Add-AzKeyVaultNetworkRule -VaultName $clientSettings.keyVaultName -IpAddressRange $myPublicIP | Out-Null
    }
}