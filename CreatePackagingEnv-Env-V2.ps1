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
        if ($nsgPROD.ProvisioningState -eq "Succeeded") { Write-Log "PROD Network Security Group created successfully"} Else { Write-Log "*** Unable to create or configure PROD Network Security Group! ***" -Level Error}
        $VnscPROD = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetworkPROD -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsgPROD
        $virtualNetworkPROD | Set-AzVirtualNetwork >> null
        if ($virtualNetworkPROD.ProvisioningState -eq "Succeeded") { Write-Log "PROD Virtual Network created and associated with the Network Security Group successfully" } Else { Write-Log "*** Unable to create the PROD Virtual Network, or associate it to the Network Security Group! ***" -Level Error }
        if (!($RGNameDEVVNET -match $RGNamePRODVNET)) {
            $nsgDEV = New-AzNetworkSecurityGroup -ResourceGroupName $RGNameDEVVNET -Location $location -Name $NsgNameDEV -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc. 
            if ($nsgDEV.ProvisioningState -eq "Succeeded") { Write-Log "DEV Network Security Group created successfully" }Else { Write-Log "*** Unable to create or configure DEV Network Security Group! ***" }
            $VnscDEV = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetworkDEV -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsgDEV
            $virtualNetworkDEV | Set-AzVirtualNetwork >> null
            if ($virtualNetworkDEV.ProvisioningState -eq "Succeeded") { Write-Log "DEV Virtual Network created and associated with the Network Security Group successfully" } Else { Write-Log "*** Unable to create the DEV Virtual Network, or associate it to the Network Security Group! ***" -Level Error }
        }

    }
}

function CreateRBACConfig {
    $OwnerGroup = Get-AzAdGroup -DisplayName $rbacOwner
    $ContributorGroup = Get-AzAdGroup -DisplayName $rbacContributor
    $ReadOnlyGroup = Get-AzAdGroup -DisplayName $rbacReadOnly

    if ($RequireUserGroups -and !$UseTerraform) {
        if ($OwnerGroup -eq $null){$Owner = New-AzADGroup -DisplayName $rbacOwner -MailNickName "NotSet"}Else{Write-Log "Owner RBAC group already exists" -Level Error;$Owner=$OwnerGroup}
        if ($ContributorGroup -eq $null){$Contributor = New-AzADGroup -DisplayName $rbacContributor -MailNickName "NotSet"}Else{Write-Log "Contributor RBAC group already exists" -Level Error;$Contributor=$ContributorGroup}
        if ($ReadOnlyGroup -eq $null){$ReadOnly = New-AzADGroup -DisplayName $rbacReadOnly -MailNickName "NotSet"}Else{Write-Log "ReadOnly RBAC group already exists" -Level Error;$ReadOnly=$ReadOnlyGroup}   
    }
}

function CreateStorageAccount {
    if ($RequireStorageAccount -and !$UseTerraform) {
        $storageAccount = New-AzStorageAccount -ResourceGroupName $RGNameSTORE -AccountName $StorageAccountName -Location $location -SkuName Standard_LRS
        Start-Sleep -Seconds 10
        $ctx = $storageAccount.Context
        $Container = New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob
        if ($storageAccount.StorageAccountName -eq $StorageAccountName -and $Container.Name -eq $ContainerName) {
            Write-Log "Storage Account and container created successfully"
        }
        else {
            Write-Log "*** Unable to create the Storage Account or container! ***" -Level Error
        }
        $Share = New-AzStorageShare -Name $FileShareName -Context $ctx
        if ($Share.Name -eq $FileShareName) {
            Write-Log "Storage Share created successfully"
        }
        else { 
            Write-Log "*** Unable to create the Storage Share! ***" -Level Error
        } 
    }
    else {
        Write-Log "Creation of Storage Account and Storage Container not required"
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
