Connect-AzAccount

$RGName = "HiggCon" 
$ContainerScripts = "C:\Temp\PackagingVM\Config"   

del $ContainerScripts\MapDrv.ps1
del $ContainerScripts\RunOnce.ps1
del $ContainerScripts\AdminStudio.ps1
Remove-AzResourceGroup -Name $RGName -Force
Remove-AzAdGroup -DisplayName "Packaging-Owner-RBAC" -Force
Remove-AzAdGroup -DisplayName "Packaging-Contributor-RBAC" -Force
Remove-AzAdGroup -DisplayName "Packaging-ReadOnly-RBAC" -Force

