#region Main
#=======================================================================================================================================================
if ($UseTerraform) {
    TerraformBuild-HVVM
}
else {
    ScriptBuild-HVVM
}
Write-PEBLog "Hyper-V Create Script Completed"
#endregion Main
