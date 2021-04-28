cd $PSScriptRoot

    # Main Control
$RequireCreate = $false
$RequireConfigure = $false
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
$RequireStandardVMs = $true
$RequireAdminStudioVMs = $false
$RequireJumpboxVMs = $false

    # Azure Tags
$tags = @{
    "Application"         = "App Packaging"
    "Compliance"          = "General"
    "CostCentre"          = "5400200015"
    "Criticality"         = "Mission Critical"
    "Data Classification" = "General Business"
    "Disaster Recovery"   = "None"
    "Envrionment"         = "Prod"
}

    # General Config
$location = "eastus"                                        # Azure Region for resources to be built into
$RGNameUAT = "rg-wl-prod-packaging"                         # UAT Resource group name
$RGNamePROD = "rg-wl-prod-packaging"                        # PROD Resource group name
$ResourceGroupName = $RGNamePROD
#$RGNameVNET = "rg-wl-prod-vnet"                            # VNET Resource group name
$RGNameVNET = "rg-wl-prod-packaging"                        # VNET Resource group name
$VNetUAT = "vnet-wl-eus-prod"                               # UAT Environment Virtual Network name
$VNetPROD = "vnet-wl-eus-prod"                              # PROD Environment Virtual Network name
#$SubnetName = "snet-wl-eus-prod-packaging"                 # Environment Virtual Subnet name
$SubnetName = "default"                                     # Environment Virtual Subnet name
$NsgNameUAT = "nsg-wl-eus-prod-packaging"                   # UAT Network Security Group name (firewall)
$NsgNamePROD = "nsg-wl-eus-prod-packaging"                  # PROD Network Security Group name (firewall)

    # Environment Variables
$rbacOwner = "euc-rbac-owner"
$rbacContributor = "euc-rbac-contributor"
$rbacReadOnly = "euc-rbac-readonly"

    # Storage Account and Container Names
$StorAccRequired = $RequireStorageAccount                   # Specifies if a Storage Account and Container should be created
#$StorAcc = "wlprodeusprodpkgstr01"                         # Storage account name (if used) (24 chars maximum)
$StorAcc = "wlprodeusprodpkgstr02"                          # Storage account name (if used) (24 chars maximum)
$StorageAccountName = $StorAcc
$ContainerName = "data"                                     # Storage container name (if used)
$FileShareName = "pkgazfiles01"                             # Storage FileShare name (if used)
$ContainerScripts = "C:\Users\d.ames\OneDrive - Avanade\Documents\GitHub\PackagingEnvironmentBuilder\PackagingFactoryConfig-main" # All files in this path will be copied up to the Storage Account Container, so available to be run on the remote VMs (includes template script for packaging share mapping

    # Windows 10 VM Count, Name, Spec, and Settings
$NumberofStandardVMs = 1                                    # Specify number of Standard VMs to be provisioned
$NumberofAdminStudioVMs = 0                                 # Specify number of AdminStudio VMs to be provisioned
$NumberofJumpboxVMs = 0                                     # Specify number of Jumpbox VMs to be provisioned
$VMNamePrefixStandard = "vmwleusvan"                        # Specifies the first part of the Standard VM name (usually alphabetic) (15 chars max)
$VMNamePrefixAdminStudio = "vmwleusas"                      # Specifies the first part of the Admin Studio VM name (usually alphabetic) (15 chars max)
$VMNamePrefixJumpbox = "vmwleusjb"                          # Specifies the first part of the Jumpbox VM name (usually alphabetic) (15 chars max)
$VMNumberStartStandard = 103                                # Specifies the second part of the Standard VM name (usually numeric)
$VMNumberStartAdminStudio = 201                             # Specifies the second part of the Admin Studio VM name (usually numeric)
$VMNumberStartJumpbox = 301                                 # Specifies the second part of the Jumpbox VM name (usually numeric)
$VMSizeStandard = "Standard_B2s"                            # Specifies Azure Size to use for the Standard VM
$VMSizeAdminStudio = "Standard_B2s"                         # Specifies Azure Size to use for the Admin Studio VM
$VMSizeJumpbox = "Standard_B2s"                             # Specifies Azure Size to use for the Jumpbox VM
# Specifies the Publisher, Offer, SKU and Version of the image to be used
$VMSpecPublisherName = "MicrosoftWindowsDesktop"
$VMSpecOffer = "Windows-10"
$VMSpecSKUS = "20h2-ent"
$VMSpecVersion = "latest"
$VMShutdown = $true                                         # Specifies if the newly provisioned VM should be shutdown (can save costs)
$AutoShutdown = $true                                       # Configures Windows 10 VMs to shutdown at a specified time                                             

    # Hyper-V VM Count, Name, Spec, and Settings
$NumberofHyperVVMs = 1                                      # Specify number of VMs to be provisioned
$VMHyperVNamePrefix = "wlprodeushypv0"                      # Specifies the first part of the VM name (usually alphabetic)
$VmHyperVNumberStart = 1                                    # Specifies the second part of the VM name (usually numeric)
#$VmSizeHyperV = "Standard_D16s_v4"                         # Specifies Azure Size to use for the VM
$VmSizeHyperV = "Standard_D2s_v4"                           # Specifies Azure Size to use for the VM
#$dataDiskTier = "P50"
#$dataDiskSKU = "Premium_LRS"
#$dataDiskSize = 4096
$dataDiskTier = "S10"
$dataDiskSKU = "Standard_LRS"
$dataDiskSize = 128

    # Domain Variables
$Domain = "wella.team"
$OUPath = "OU=Packaging,OU=Servers,DC=wella,DC=team"
