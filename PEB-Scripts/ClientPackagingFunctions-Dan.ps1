function ConfigureVM {
    Param(
        [Parameter(Position = 0, Mandatory)][String]$VMName,
        [Parameter(Position = 1, Mandatory)][String]$VMSpec
    )

    foreach ($app in $deviceSpecs.$VMSpec.Apps) {
        RunVMConfig "$RGNameDEV" "$VMName" "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$($app.Name)" "$($app.Name)"
    }

    if ($VMShutdown) {
        $Stopvm = Stop-AzVM -ResourceGroupName $RGNameDEV -Name $VMName -Force
        if ($Stopvm.Status -eq "Succeeded") {
            Write-PEBLog "VM: $VMName shutdown successfully"
        }
        else {
            Write-PEBLog "*** VM: $VMName - Unable to shutdown! ***" -Level Error
        }
    }
}

function ConfigureStandardVM($VMName) {
    ConfigureVM -VMName $VMName -VMSpec "Standard"
}

function ConfigureAdminStudioVM($VMName) {
    ConfigureVM -VMName $VMName -VMSpec "AdminStudio"
}

function ConfigureJumpboxVM($VMName) {
    ConfigureVM -VMName $VMName -VMSpec "Jumpbox"
}

function ConfigureCoreVM($VMName) {
    ConfigureVM -VMName $VMName -VMSpec "Core"
}

function ConfigureBaseVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNameDEV -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-PEBLog "VM: $VMName created successfully"

        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        if ($RequireServicePrincipal) {
            Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        }
        if ($RequireRBAC) {
            $Group = Get-AzADGroup -searchstring $rbacContributor
            Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose | Out-Null
            Get-AzContext -Name "User" | Select-AzContext | Out-Null
        }
        else {
            New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -ErrorAction SilentlyContinue | Out-Null
            Get-AzContext -Name "User" | Select-AzContext | Out-Null
            Start-Sleep -Seconds 30
            $confirm = Get-AzRoleAssignment -ObjectId $NewVm.Id -Scope "/subscriptions/$azSubscription/resourceGroups/$RGNameSTORE/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -ErrorAction SilentlyContinue
            if(!$confirm) {
                Write-PEBLog -String "*** VM: $VMName - Unable to set Storage Account Permission ***" -Level Error
                Write-Dump $VMCreate.Identity.PrincipalId $NewVm.Id
            }

        }
        Restart-AzVM -ResourceGroupName $RGNameDEV -Name $VMName | Out-Null
        Write-PEBLog "VM: $VMName - Restarting VM..."
        Start-Sleep -Seconds 120

        if ($AutoShutdown) {
            $ScheduledShutdownResourceId = "/subscriptions/$azSubscription/resourceGroups/$RGNameDEV/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800})
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMCreate.Id)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-PEBLog "VM: $VMName - Auto Shutdown Enabled for 1800"
        }
    }
    else {
        Write-PEBLog "*** VM: $VMName - Unable to configure Virtual Machine! ***" -Level Error
        Write-Dump
    }
}
