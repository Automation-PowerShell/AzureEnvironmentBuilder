function ConfigureNetwork {
    if ($RequireVNET -and !$UseTerraform) {
        $virtualNetworkPROD = New-AzVirtualNetwork -ResourceGroupName $RGNamePRODVNET -Location $Location -Name $VNetPROD -AddressPrefix 10.0.0.0/16
        $subnetConfigPROD = Add-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -AddressPrefix 10.0.0.0/24 -VirtualNetwork $virtualNetworkPROD
        if (!($RGNameDEVVNET -match $RGNamePRODVNET)) {
            $virtualNetworkDEV = New-AzVirtualNetwork -ResourceGroupName $RGNameDEVVNET -Location $Location -Name $VNetDEV -AddressPrefix 10.0.0.0/16
            $subnetConfigDEV = Add-AzVirtualNetworkSubnetConfig -Name $SubnetNameDEV -AddressPrefix 10.0.0.0/24 -VirtualNetwork $virtualNetworkDEV
        }

        $rule1 = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        $rule2 = New-AzNetworkSecurityRuleConfig -Name smb-rule -Description "Allow SMB" -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 445
    
        $nsgPROD = New-AzNetworkSecurityGroup -ResourceGroupName $RGNamePRODVNET -Location $location -Name $NsgNamePROD -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc. 
        if ($nsgPROD.ProvisioningState -eq "Succeeded") {Write-Host "PROD Network Security Group created successfully"}Else{Write-Host "*** Unable to create or configure PROD Network Security Group! ***"}
        $VnscPROD = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetworkPROD -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsgPROD
        $virtualNetworkPROD | Set-AzVirtualNetwork >> null
        if ($virtualNetworkPROD.ProvisioningState -eq "Succeeded") {Write-Host "PROD Virtual Network created and associated with the Network Security Group successfully"}Else{Write-Host "*** Unable to create the PROD Virtual Network, or associate it to the Network Security Group! ***"}
        if (!($RGNameDEVVNET -match $RGNamePRODVNET)) {
            $nsgDEV = New-AzNetworkSecurityGroup -ResourceGroupName $RGNameDEVVNET -Location $location -Name $NsgNameDEV -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc. 
            if ($nsgDEV.ProvisioningState -eq "Succeeded") { Write-Host "DEV Network Security Group created successfully" }Else { Write-Host "*** Unable to create or configure DEV Network Security Group! ***" }
            $VnscDEV = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetworkDEV -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsgDEV
            $virtualNetworkDEV | Set-AzVirtualNetwork >> null
            if ($virtualNetworkDEV.ProvisioningState -eq "Succeeded") { Write-Host "DEV Virtual Network created and associated with the Network Security Group successfully" }Else { Write-Host "*** Unable to create the DEV Virtual Network, or associate it to the Network Security Group! ***" }
        }

    }
}

function CreateRBACConfig {
    $OwnerGroup = Get-AzAdGroup -DisplayName $rbacOwner
    $ContributorGroup = Get-AzAdGroup -DisplayName $rbacContributor
    $ReadOnlyGroup = Get-AzAdGroup -DisplayName $rbacReadOnly

    if ($RequireUserGroups -and !$UseTerraform) {
        if ($OwnerGroup -eq $null){$Owner = New-AzADGroup -DisplayName $rbacOwner -MailNickName "NotSet"}Else{Write-Host "Owner RBAC group already exists";$Owner=$OwnerGroup}
        if ($ContributorGroup -eq $null){$Contributor = New-AzADGroup -DisplayName $rbacContributor -MailNickName "NotSet"}Else{Write-Host "Contributor RBAC group already exists";$Contributor=$ContributorGroup}
        if ($ReadOnlyGroup -eq $null){$ReadOnly = New-AzADGroup -DisplayName $rbacReadOnly -MailNickName "NotSet"}Else{Write-Host "ReadOnly RBAC group already exists";$ReadOnly=$ReadOnlyGroup}   
    }
}

function CreateStorageAccount {
    if ($RequireStorageAccount -and !$UseTerraform) {
        $storageAccount = New-AzStorageAccount -ResourceGroupName $RGNameDEV -AccountName $StorageAccountName -Location $location -SkuName Standard_LRS
        $ctx = $storageAccount.Context
        $Container = New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob
        If ($storageAccount.StorageAccountName -eq $StorageAccountName -and $Container.Name -eq $ContainerName) {Write-Host "Storage Account and container created successfully"}Else{Write-Host "*** Unable to create the Storage Account or container! ***"}
        $Share = New-AzStorageShare -Name $FileShareName -Context $ctx
        If ($Share.Name -eq $FileShareName) { Write-Host "Storage Share created successfully" }Else { Write-Host "*** Unable to create the Storage Share! ***"} 
    }
    else {
        Write-Host "Creation of Storage Account and Storage Container not required"
    } 
}

#=======================================================================================================================================================

# Main Script

# Create RBAC groups and assignments
CreateRBACConfig

# Create VNet, NSG and rules
ConfigureNetwork

# Create Storage Account
CreateStorageAccount
