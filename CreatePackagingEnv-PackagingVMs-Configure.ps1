#region Main
#=======================================================================================================================================================

# Main Script
if ($UseTerraform) {
    TerraformConfigure-VM
}
else {
   ScriptConfigure-VM
}
Write-Log "Configure Packaging VM Script Completed"
#endregion Main