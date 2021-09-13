#region Main
#=======================================================================================================================================================
if ($UseTerraform) {
    TerraformConfigure-HVVM
}
else {
    ScriptConfigure-HVVM
}
Write-PEBLog "Hyper-V Configure Script Completed"
#endregion Main
