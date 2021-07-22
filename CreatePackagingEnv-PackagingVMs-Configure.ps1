#region Main
#=======================================================================================================================================================

# Main Script
if ($UseTerraform) {
    TerraformConfigure-VM
}
else {
    ScriptBuild-Config-VM
}
Write-Log "Configure Packaging VM Script Completed"
#endregion Main
