Param(
    [switch]$CallFromCreatePackaging = $false,
    [switch]$ScriptsOnly = $false,
    [switch]$Recurse = $false
)

function SyncFiles {
    Param(
        [String]$LocalPath,
        [String]$ResourceGroupName,
        [String]$StorageAccountName,
        [String]$ContainerName
    )

    $StorageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName
    if(!$Context){$Context = $storageAccount.Context}
    #if(!$Container){$Container = Get-AzStorageContainer -Name $ContainerName -Context $Context}
    if($ScriptsOnly) {
        $files = Get-ChildItem -Path $LocalPath\* -File -Include "*.ps1" | Set-AzStorageBlobContent -Container $ContainerName -Context $Context -Force    
    }
    elseif ($Recurse) {
        $files = Get-ChildItem -Path $LocalPath\* -File -Recurse | Set-AzStorageBlobContent -Container $ContainerName -Context $Context -Force
    }
    else {
        $files = Get-ChildItem -Path $LocalPath\* -File | Set-AzStorageBlobContent -Container $ContainerName -Context $Context -Force
    }
}

Write-Host "Running SyncFiles.ps1"
Try {
    switch ($CallFromCreatePackaging) {
        $True { 
            SyncFiles -LocalPath $ContainerScripts -ResourceGroupName $RGNameDEV -ContainerName $ContainerName -StorageAccountName $StorageAccountName }
        $False {
            #SyncFiles -LocalPath $SFLocalPath -ResourceGroupName $SFResourceGroupName -StorageAccountName $SFStorageAccountName -ContainerName $SFContainerName
        }
    } 
} Catch {
    Write-Error "An error occured syncing files to the Storage Blob."
    Write-Error $_.Exception.Message
}
Write-Host "Completed SyncFiles.ps1"