cd $PSScriptRoot

    # Main Control
$RequireCreate = $true
$RequireConfigure = $true
$UseTerraform = $false
$RequireUpdateStorage = $true
$RequireServicePrincipal = $false

    # Required Components
$RequireUserGroups = $true
$RequireRBAC = $false
$RequireResourceGroups = $true
$RequireStorageAccount = $true
$RequireVNET = $true
$RequireNSG = $true
$RequirePublicIPs = $true
$RequireStandardVMs = $false
$RequireAdminStudioVMs = $false
$RequireJumpboxVMs = $true
$RequireHyperV = $false

    # Azure Tags
$tags = @{
    "Application"         = "EUC App Packaging"
    "Envrionment"         = "Production"
}

    # General Config Variables
$location = "uksouth"                                       # Azure Region for resources to be built into
$RGNameDEV = "rg-euc-packaging-dev"                         # DEV Resource group name
$RGNamePROD = "rg-euc-packaging-prod"                       # PROD Resource group name
$RGNameDEVVNET = "rg-euc-packaging-dev-vnet"                # DEV VNET Resource group name
$RGNamePRODVNET = "rg-euc-packaging-prod-vnet"              # PROD VNET Resource group name
$VNetDEV = "vnet-euc-dev"                                   # DEV Environment Virtual Network name
$VNetPROD = "vnet-euc-prod"                                 # PROD Environment Virtual Network name
$SubnetNameDEV = "default"                                  # Environment Virtual Subnet name
$SubnetNamePROD = "default"                                 # Environment Virtual Subnet name
$NsgNameDEV = "nsg-euc-packaging-dev"                       # DEV Network Security Group name (firewall)
$NsgNamePROD = "nsg-euc-packaging-prod"                     # PROD Network Security Group name (firewall)

    # Environment Variables
$rbacOwner = "euc-rbac-owner"
$rbacContributor = "euc-rbac-contributor"
$rbacReadOnly = "euc-rbac-readonly"

    # Storage Account and Container Names
$StorageAccountName = "storageeucpackaging01"                       # Storage account name (if used) (24 chars maximum)
$ContainerName = "data"                                             # Storage container name (if used) (do not change from 'data')
$FileShareName = "pkgazfiles01"                                     # Storage FileShare name (if used) (do not change from 'pkgazfiles01')
$ContainerScripts = "$PSScriptRoot\PackagingFactoryConfig-main"     # All files in this path will be copied up to the Storage Account Container, so available to be run on the remote VMs (includes template script for packaging share mapping

    # Windows 10 VM Count, Name, Spec, and Settings
$NumberofStandardVMs = 1                                    # Specify number of Standard VMs to be provisioned
$NumberofAdminStudioVMs = 1                                 # Specify number of AdminStudio VMs to be provisioned
$NumberofJumpboxVMs = 1                                     # Specify number of Jumpbox VMs to be provisioned
$VMNamePrefixStandard = "vm-euc-van-"                       # Specifies the first part of the Standard VM name (usually alphabetic) (15 chars max)
$VMNamePrefixAdminStudio = "vm-euc-as-"                     # Specifies the first part of the Admin Studio VM name (usually alphabetic) (15 chars max)
$VMNamePrefixJumpbox = "vm-euc-jb-"                         # Specifies the first part of the Jumpbox VM name (usually alphabetic) (15 chars max)
$VMNumberStartStandard = 101                                # Specifies the second part of the Standard VM name (usually numeric)
$VMNumberStartAdminStudio = 201                             # Specifies the second part of the Admin Studio VM name (usually numeric)
$VMNumberStartJumpbox = 301                                 # Specifies the second part of the Jumpbox VM name (usually numeric)
$VMSizeStandard = "Standard_B2s"                            # Specifies Azure Size to use for the Standard VM
$VMSizeAdminStudio = "Standard_B2s"                         # Specifies Azure Size to use for the Admin Studio VM
$VMSizeJumpbox = "Standard_B2s"                             # Specifies Azure Size to use for the Jumpbox VM

$VMSpecPublisherName = "MicrosoftWindowsDesktop"
$VMSpecOffer = "Windows-10"
$VMSpecSKUS = "20h2-ent"
$VMSpecVersion = "latest"
$VMShutdown = $true                                         # Specifies if the newly provisioned VM should be shutdown (can save costs)
$AutoShutdown = $true                                       # Configures Windows 10 VMs to shutdown at a specified time                                             

    # Hyper-V VM Count, Name, Spec, and Settings
$NumberofHyperVVMs = 1                                      # Specify number of VMs to be provisioned
$VMHyperVNamePrefix = "vm-euc-hyprv-0"                      # Specifies the first part of the VM name (usually alphabetic)
$VmHyperVNumberStart = 1                                    # Specifies the second part of the VM name (usually numeric)
$VmSizeHyperV = "Standard_D2s_v4"                           # Specifies Azure Size to use for the VM
$dataDiskTier = "S10"
$dataDiskSKU = "Standard_LRS"
$dataDiskSize = 128

