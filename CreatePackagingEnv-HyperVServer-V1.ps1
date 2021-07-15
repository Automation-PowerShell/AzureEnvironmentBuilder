#region Main
#=======================================================================================================================================================
if ($UseTerraform) {
    TerraformBuild-HVVM
}
else {
    ScriptBuild-HVVM
}
Write-Log "Hyper-V Create Script Completed"
#endregion Main