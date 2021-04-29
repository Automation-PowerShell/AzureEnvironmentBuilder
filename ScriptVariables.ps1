cd $PSScriptRoot

    # Main Control
$RequireCreate = $true
$RequireConfigure = $true
$UseTerraform = $false
$RequireUpdateStorage = $true
$RequireServicePrincipal = $false

    # Required Components
$RequireUserGroups = $false
$RequireRBAC = $false
$RequireResourceGroups = $false
$RequireStorageAccount = $false
$RequireVNET = $false
$RequireNSG = $false
$RequirePublicIPs = $true
$RequireHyperV = $false
$RequireStandardVMs = $false
$RequireAdminStudioVMs = $false
$RequireJumpboxVMs = $false

    # Azure Tags
$tags = @{
    "Application"         = "EUC App Packaging"
    "Envrionment"         = "Production"
}

    # General Config
$location = "uksouth"                                       # Azure Region for resources to be built into
$RGNameUAT = "rg-euc-packaging-uat"                         # UAT Resource group name
$RGNamePROD = "rg-euc-packaging-prod"                       # PROD Resource group name
$RGNameVNET = "rg-euc-packaging-vnet"                       # VNET Resource group name
$VNetUAT = "vnet-euc-uat"                                   # UAT Environment Virtual Network name
$VNetPROD = "vnet-euc-prod"                                 # PROD Environment Virtual Network name
$SubnetName = "default"                                     # Environment Virtual Subnet name
$NsgNameUAT = "nsg-euc-packaging-uat"                       # UAT Network Security Group name (firewall)
$NsgNamePROD = "nsg-euc-packaging-prod"                     # PROD Network Security Group name (firewall)

    # Environment Variables
$rbacOwner = "euc-rbac-owner"
$rbacContributor = "euc-rbac-contributor"
$rbacReadOnly = "euc-rbac-readonly"

    # Storage Account and Container Names
$StorAcc = "storage-euc-packaging01"                        # Storage account name (if used) (24 chars maximum)
$ContainerName = "container"                                # Storage container name (if used)
$FileShareName = "fileshare"                                # Storage FileShare name (if used)
$ContainerScripts = "C:\Users\d.ames\OneDrive - Avanade\Documents\GitHub\PackagingEnvironmentBuilder\PackagingFactoryConfig-main" # All files in this path will be copied up to the Storage Account Container, so available to be run on the remote VMs (includes template script for packaging share mapping

    # Windows 10 VM Count, Name, Spec, and Settings
$NumberofStandardVMs = 0                                    # Specify number of Standard VMs to be provisioned
$NumberofAdminStudioVMs = 0                                 # Specify number of AdminStudio VMs to be provisioned
$NumberofJumpboxVMs = 0                                     # Specify number of Jumpbox VMs to be provisioned
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
$NumberofHyperVVMs = 0                                      # Specify number of VMs to be provisioned
$VMHyperVNamePrefix = "vm-euc-hyprv-0"                      # Specifies the first part of the VM name (usually alphabetic)
$VmHyperVNumberStart = 1                                    # Specifies the second part of the VM name (usually numeric)
$VmSizeHyperV = "Standard_D2s_v4"                           # Specifies Azure Size to use for the VM
$dataDiskTier = "S10"
$dataDiskSKU = "Standard_LRS"
$dataDiskSize = 128

    # Domain Variables
$Domain = ""
$OUPath = ""
