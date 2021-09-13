#=======================================================================================================================================================

# Main Script
if ($UseTerraform) {
    TerraformBuild-VM
}
else {
    ScriptBuild-Create-VM
}
Write-PEBLog "Packaging VM Script Completed"