#=======================================================================================================================================================

# Main Script
if ($UseTerraform) {
    TerraformBuild-VM
}
else {
   ScriptBuild-VM
}
Write-Log "Packaging VM Script Completed"