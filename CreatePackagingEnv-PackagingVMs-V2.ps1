#=======================================================================================================================================================

# Main Script
if ($UseTerraform) {
    TerraformBuild-VM
}
else {
    ScriptBuild-Create-VM
}
Write-Log "Packaging VM Script Completed"