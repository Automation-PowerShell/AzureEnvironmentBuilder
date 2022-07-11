    # Client Azure Variables
$azTenant = "b21a1566-203d-4107-9544-fa2a464073ab"                                  # Azure Tenant ID
$azSubscription = "12ffc0b7-8212-4d57-9591-3dc43c20c77c"                            # Subscription ID
$gitlog = ""                                    # Path to GitLog location (if enabled on line 29)

$ServicePrincipalUser = "default"               # Service Principal name if enabled on line 26 (used for ???)
$LocalAdminUser = "AppPackager"                     # Local Admin UserName to create (will be used for VMs)
$HyperVLocalAdminUser = "default"               # Local Admin username to create for Hyper-V server
$DomainJoinUser = "domain\default"              # Domain User with Domain Join rights (needs to exist in the domain)
$DomainUserUser = "domain\default"              # ??? (needs to exist in the domain)

$HyperVVMIsoImagePath = "SW_DVD9_Win_Pro_11_21H2_64BIT_English_Pro_Ent_EDU_N_MLF_-3_X22-89962.iso"   # This image is used to build the Hyper-V VMs

    # Domain Variables
$Domain = ""                                    # Name of the AD Domain
$OUPath = ""                                    # Name of the AD OU where computer objects will be created

    # Script Customisations
$VMListExclude = @()                            # Exclusion list for rebuilding Azure VMs

    # Main Control
$RequireCreate = $true                          # ???
$RequireConfigure = $true                       # ???
$UseTerraform = $false                          # Use Terraform Templates
$RequireUpdateStorage = $true                   # ???
$RequireServicePrincipal = $false               # Enable use of Service Principal

    # Required Components
$isProd = $true                                # Will this build be used for production?
$LogToGit = $false                              # Should the script log to GIT?
$LogToSA = $false                               # Should the script log to the Storage Account?
$RequireUserGroups = $false                     # Do User groups need creating?
$RequireRBAC = $false                           # Is RBAC required???
$RequireResourceGroups = $false                  # Should a Resource Group be created? (or use existing)
$RequireStorageAccount = $false                  # Should a Storage Account be created (or use existing)
$RequireVNET = $false                            # Should a VNET be created (or use existing)
$RequireNSG = $false                             # Should an NSG be created (or use existing)
$RequirePublicIPs = $true                       # Should Public IPs be used
$RequireKeyVault = $false

$RequireStandardVMs = $false                     # Should standard VMs be created?
$RequirePackagingVMs = $false                   # Should Packaging VMs be created?
$RequireAdminStudioVMs = $false                 # Should AdminStudio VMs be created?
$RequireJumpboxVMs = $false                     # Should Jumpbox VMs be created?
$RequireCoreVMs = $false                        # Should Core VMs be created???
$RequireStdSrv = $false
$RequireHyperV = $true                         # Should a Hyper-V VM be created?

$NumberofStandardVMs = 1                                    # Specify number of Standard VMs to be provisioned
$NumberofPackagingVMs = 1                                   # Specify number of Packaging VMs to be provisioned
$NumberofAdminStudioVMs = 1                                 # Specify number of AdminStudio VMs to be provisioned
$NumberofJumpboxVMs = 1                                     # Specify number of Jumpbox VMs to be provisioned
$NumberofCoreVMs = 1                                        # Specify number of Core VMs to be provisioned
$VMNamePrefixStandard = "vm-euc-van-"                       # Specifies the first part of the Standard VM name (15 chars max)
$VMNamePrefixPackaging = "vm-euc-pkg-"                      # Specifies the first part of the Packaging VM name (15 chars max)
$VMNamePrefixAdminStudio = "vm-euc-as-"                     # Specifies the first part of the Admin Studio VM name (15 chars max)
$VMNamePrefixJumpbox = "vm-euc-jb-"                         # Specifies the first part of the Jumpbox VM name (15 chars max)
$VMNamePrefixCore = "vm-euc-core-"                          # Specifies the first part of the Core VM name (15 chars max)
$VMNumberStartStandard = 101                                # Specifies the second part of the Standard VM name
$VMNumberStartPackaging = 201                               # Specifies the second part of the Packaging VM name
$VMNumberStartAdminStudio = 301                             # Specifies the second part of the Admin Studio VM name
$VMNumberStartJumpbox = 401                                 # Specifies the second part of the Jumpbox VM name
$VMNumberStartCore = 501                                    # Specifies the second part of the Core VM name
$VMShutdown = $true                                         # Specifies if the newly provisioned VM should be shutdown (can save costs)

$NumberofStdSrvVMs = 0                                      # Specify number of Standard Server VMs to be provisioned
$NumberofHyperVVMs = 1                                      # Specify number of HyperV Server VMs to be provisioned
$VMStdSrvVNamePrefix        # to be implemented in the code
$VmStdSrvNumberStart        # to be implemented in the code
$VMHyperVNamePrefix = "vm-euc-hyprv-0"                      # Specifies the first part of the VM name (usually alphabetic)
$VmHyperVNumberStart = 1                                    # Specifies the second part of the VM name (usually numeric)

    # General Config Variables
$location = "uksouth"                                       # Azure Region for resources to be built into
$RGNameSTORE = "rg-euc-packaging-store"                     # Storage Account & KeyVault Resource Group name
$RGNameDEV = "rg-euc-packaging-prod"                         # DEV Resource Group name
$RGNamePROD = "rg-euc-packaging-prod"                       # PROD Resource Group name
$RGNameDEVVNET = "rg-euc-packaging-prod-vnet"                # DEV VNET Resource Group name
$RGNamePRODVNET = "rg-euc-packaging-prod-vnet"              # PROD VNET Resource Group name
$VNetDEV = "vnet-euc-prod"                                   # DEV Environment Virtual Network name
$VNetPROD = "vnet-euc-prod"                                 # PROD Environment Virtual Network name
$SubnetNameDEV = "default"                                  # Environment Virtual Subnet name
$SubnetNamePROD = "default"                                 # Environment Virtual Subnet name
$NsgNameDEV = "nsg-euc-packaging-prod"                       # DEV Network Security Group name (firewall)
$NsgNamePROD = "nsg-euc-packaging-prod"                     # PROD Network Security Group name (firewall)

    # Environment Variables
$rbacOwner = "euc-rbac-owner"
$rbacContributor = "euc-rbac-contributor"
$rbacReadOnly = "euc-rbac-readonly"

    # Storage Account and Container Names
$StorageAccountName = "uolstoracc001"                       # Storage account name (if used) (24 chars maximum) (lowercase and numerical chars only). Needs to be globally unique within Azure
$ContainerName = "data"                                     # Storage container name (if used) (do not change from 'data')
$FileShareName = "pkgazfiles01"                             # Storage FileShare name (if used) (do not change from 'pkgazfiles01')
$BlobFilesSource = "$root\BlobFilesSource"                  # Source Template Folder for CustomScriptExtension
$BlobFilesDest = "$root\BlobFilesDestination"               # Destination Template Folder for CustomScriptExtension
$keyVaultName = "UoLKVAEB04"                                  # needs to be globally unique within Azure

    # Load Spec Files
Try {
    $deviceSpecs = Get-Content $root\devicespecs-template.jsonc | ConvertFrom-Json -ErrorAction Stop
    $appSpecs = Get-Content $root\appspecs-template.jsonc | ConvertFrom-Json -ErrorAction Stop
}
Catch {
    throw "Error with Device Specs"
    exit
}

    # New Client Setup and Key File Load
function setSecurePasswords {
    (Get-Credential -Message "Service Principal" -UserName $ServicePrincipalUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\ServicePrincipal.xml
    (Get-Credential -Message "Local Admin" -UserName $LocalAdminUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\LocalAdmin.xml
    (Get-Credential -Message "Hyper-V Local Admin" -UserName $HyperVLocalAdminUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\HyperVLocalAdmin.xml
    (Get-Credential -Message "Domain Join" -UserName  $DomainJoinUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainJoin.xml
    (Get-Credential -Message "Domain User" -UserName $DomainUserUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainUser.xml
}

function createNewKey {
    $KeyFile = "$ExtraFiles\my.key"
    $myKey = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($myKey)
    $myKey | Out-File $KeyFile
}

if(!(Test-Path "$ExtraFiles\my.key")){
    #New-Item -Path $ExtraFiles -ItemType Directory -Force
    createNewKey
    $KeyFile = "$ExtraFiles\my.key"
    $myKey = Get-Content $KeyFile
    setSecurePasswords
}
else {
    $KeyFile = "$ExtraFiles\my.key"
    $myKey = Get-Content $KeyFile
}

    # Passwords
if (Test-Path $ExtraFiles\ServicePrincipal.xml) {
    $ServicePrincipalPassword = Import-Clixml $ExtraFiles\ServicePrincipal.xml | ConvertTo-SecureString -Key $myKey
    $ServicePrincipalCred = New-Object System.Management.Automation.PSCredential ($ServicePrincipalUser, $ServicePrincipalPassword)
} else {(Get-Credential -Message "Service Principal").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\ServicePrincipal.xml}

if (Test-Path $ExtraFiles\LocalAdmin.xml) {
    $LocalAdminPassword = Import-Clixml $ExtraFiles\LocalAdmin.xml | ConvertTo-SecureString -Key $myKey
    $LocalAdminCred = New-Object System.Management.Automation.PSCredential ($LocalAdminUser, $LocalAdminPassword)
} else {(Get-Credential -Message "Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\LocalAdmin.xml}

if (Test-Path $ExtraFiles\HyperVLocalAdmin.xml) {
    $HyperVLocalAdminPassword = Import-Clixml $ExtraFiles\HyperVLocalAdmin.xml | ConvertTo-SecureString -Key $myKey
    $HyperVLocalAdminCred = New-Object System.Management.Automation.PSCredential ($HyperVLocalAdminUser, $HyperVLocalAdminPassword)
} else {(Get-Credential -Message "Hyper-V Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\HyperVLocalAdmin.xml}

if (Test-Path $ExtraFiles\DomainJoin.xml) {
    $DomainJoinPassword = Import-Clixml $ExtraFiles\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
    $DomainJoinCred = New-Object System.Management.Automation.PSCredential ($DomainJoinUser, $DomainJoinPassword)
} else {(Get-Credential -Message "Domain Join").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainJoin.xml}

if (Test-Path $ExtraFiles\DomainUser.xml) {
    $DomainUserPassword = Import-Clixml $ExtraFiles\DomainUser.xml | ConvertTo-SecureString -Key $myKey
    $DomainUserCred = New-Object System.Management.Automation.PSCredential ($DomainUserUser, $DomainUserPassword)
} else {(Get-Credential -Message "Domain User").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainUser.xml}
