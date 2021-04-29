function ConfigureNetwork {
    if ($RequireVNET -and !$UseTerraform) {
        $virtualNetworkPROD = New-AzVirtualNetwork -ResourceGroupName $RGNamePROD -Location $Location -Name $VNetPROD -AddressPrefix 10.0.0.0/16
        $subnetConfigPROD = Add-AzVirtualNetworkSubnetConfig -Name $SubnetNamePROD -AddressPrefix 10.0.0.0/24 -VirtualNetwork $virtualNetworkPROD
        if (!($RGNameUAT -match $RGNamePROD)) {
            $virtualNetworkUAT = New-AzVirtualNetwork -ResourceGroupName $RGNameUAT -Location $Location -Name $VNetUAT -AddressPrefix 10.0.0.0/16
            $subnetConfigUAT = Add-AzVirtualNetworkSubnetConfig -Name $SubnetNameUAT -AddressPrefix 10.0.0.0/24 -VirtualNetwork $virtualNetworkUAT
        }

        $rule1 = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        $rule2 = New-AzNetworkSecurityRuleConfig -Name smb-rule -Description "Allow SMB" -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 445
    
        $nsgPROD = New-AzNetworkSecurityGroup -ResourceGroupName $RGNamePROD -Location $location -Name $NsgNamePROD -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc. 
        if ($nsgPROD.ProvisioningState -eq "Succeeded") {Write-Host "PROD Network Security Group created successfully"}Else{Write-Host "*** Unable to create or configure PROD Network Security Group! ***"}
        $VnscPROD = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetworkPROD -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsgPROD
        $virtualNetworkPROD | Set-AzVirtualNetwork >> null
        if ($virtualNetworkPROD.ProvisioningState -eq "Succeeded") {Write-Host "PROD Virtual Network created and associated with the Network Security Group successfully"}Else{Write-Host "*** Unable to create the PROD Virtual Network, or associate it to the Network Security Group! ***"}
        if (!($RGNameUAT -match $RGNamePROD)) {
            $nsgUAT = New-AzNetworkSecurityGroup -ResourceGroupName $RGNameUAT -Location $location -Name $NsgNameUAT -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc. 
            if ($nsgUAT.ProvisioningState -eq "Succeeded") { Write-Host "UAT Network Security Group created successfully" }Else { Write-Host "*** Unable to create or configure UAT Network Security Group! ***" }
            $VnscUAT = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetworkUAT -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsgUAT
            $virtualNetworkUAT | Set-AzVirtualNetwork >> null
            if ($virtualNetworkUAT.ProvisioningState -eq "Succeeded") { Write-Host "UAT Virtual Network created and associated with the Network Security Group successfully" }Else { Write-Host "*** Unable to create the UAT Virtual Network, or associate it to the Network Security Group! ***" }
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
        $storageAccount = New-AzStorageAccount -ResourceGroupName $RGNameUAT -AccountName $StorAcc -Location $location -SkuName Standard_LRS
        $ctx = $storageAccount.Context
        $Container = New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob
        If ($storageAccount.StorageAccountName -eq $StorAcc -and $Container.Name -eq $ContainerName) {Write-Host "Storage Account and container created successfully"}Else{Write-Host "*** Unable to create the Storage Account or container! ***"}
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
