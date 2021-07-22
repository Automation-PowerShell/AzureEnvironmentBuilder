#region Main
#=======================================================================================================================================================
if ($UseTerraform) {
    TerraformConfigure-HVVM
}
else {
    ScriptConfigure-HVVM
}
Write-Log "Hyper-V Configure Script Completed"
#endregion Main
