function RunVMConfig($ResourceGroup, $VMName, $BlobFilePath, $Blob) {
    $Params = @{
        ResourceGroupName = $ResourceGroup
        VMName            = $VMName
        Location          = $Location
        FileUri           = $BlobFilePath
        Run               = $Blob
        Name              = "ConfigureVM"
    }

    $VMConfigure = Set-AzVMCustomScriptExtension @Params
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format hh:mm
    if ($VMConfigure.IsSuccessStatusCode -eq $True) {
        Write-Host "$Date - $Time -- Virtual Machine $VMName configured with $Blob successfully"
    }
    else {
        Write-Host "$Date - $Time -- *** Unable to configure Virtual Machine $VMName with $Blob ***"
    }
}
