function ConfigureStandardVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNameDEV -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Log "Virtual Machine $VMName created successfully"
        
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name "User" | Select-AzContext | Out-Null

        Restart-AzVM -ResourceGroupName $RGNameDEV -Name $VMName | Out-Null
        Write-Log "Restarting VM..."
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Prevision.ps1" "Prevision.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/VMConfig.ps1" "VMConfig.ps1"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/ORCA.ps1" "ORCA.ps1"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/7-Zip.ps1" "7-Zip.ps1"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/InstEd.ps1" "InstEd.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/DesktopApps.ps1" "DesktopApps.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/GlassWire.ps1" "GlassWire.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/IntuneWinUtility.ps1" "IntuneWinUtility.ps1"
        
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$azSubscription/resourceGroups/$RGNameDEV/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Log "Auto Shutdown Enabled for 1800"
        }
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RGNameDEV -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Log "VM $VMName shutdown successfully" }Else { Write-Log "*** Unable to shutdown VM $VMName! ***" -Level Error }
        }
    }
    Else {
        Write-Log "*** Unable to configure Virtual Machine $VMName! ***" -Level Error
    }
}

function ConfigureAdminStudioVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNameDEV -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Log "Virtual Machine $VMName created successfully"
        
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name "User" | Select-AzContext | Out-Null
        
        Restart-AzVM -ResourceGroupName $RGNameDEV -Name $VMName | Out-Null
        Write-Log "Restarting VM..."
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Prevision.ps1" "Prevision.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/VMConfig.ps1" "VMConfig.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/RunOnce.ps1" "RunOnce.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/AdminStudio.ps1" "AdminStudio.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/ORCA.ps1" "ORCA.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/GlassWire.ps1" "GlassWire.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/7-Zip.ps1" "7-Zip.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/InstEd.ps1" "InstEd.ps1"
        
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$azSubscription/resourceGroups/$RGNameDEV/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Log "Auto Shutdown Enabled for 1800"
        }
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RGNameDEV -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Log "VM $VMName shutdown successfully" }Else { Write-Log "*** Unable to shutdown VM $VMName! ***" -Level Error }
        }
    }
    Else {
        Write-Log "*** Unable to configure Virtual Machine $VMName! ***" -Level Error
    }
}

function ConfigureJumpboxVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNameDEV -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Log "Virtual Machine $VMName created successfully"
        
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name "User" | Select-AzContext | Out-Null
        
        Restart-AzVM -ResourceGroupName $RGNameDEV -Name $VMName | Out-Null
        Write-Log "Restarting VM..."
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Prevision.ps1" "Prevision.ps1"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Jumpbox.ps1" "Jumpbox.ps1"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/MECMConsole.ps1" "MECMConsole.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/DomainJoin.ps1" "DomainJoin.ps1"
        
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$azSubscription/resourceGroups/$RGNameDEV/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Log "Auto Shutdown Enabled for 1800"
        }
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RGNameDEV -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Log "VM $VMName shutdown successfully" }Else { Write-Log "*** Unable to shutdown VM $VMName! ***" -Level Error }
        }
    }
    Else {
        Write-Log "*** Unable to configure Virtual Machine $VMName! ***" -Level Error
    }
}

function ConfigureCoreVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNameDEV -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Log "Virtual Machine $VMName created successfully"
        
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue | Out-Null
        }
        Get-AzContext -Name "User" | Select-AzContext | Out-Null

        Restart-AzVM -ResourceGroupName $RGNameDEV -Name $VMName | Out-Null
        Write-Log "Restarting VM..."
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Prevision.ps1" "Prevision.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/VMConfig.ps1" "VMConfig.ps1"
        #RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/VCPP.ps1" "VCPP.ps1"
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/Office365.ps1" "Office365.ps1"
        
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$azSubscription/resourceGroups/$RGNameDEV/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Log "Auto Shutdown Enabled for 1800"
        }
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RGNameDEV -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Log "VM $VMName shutdown successfully" }Else { Write-Log "*** Unable to shutdown VM $VMName! ***" -Level Error }
        }
    }
    Else {
        Write-Log "*** Unable to configure Virtual Machine $VMName! ***" -Level Error
    }
}
