    # Client Azure Variables
$azTenant = ""                                  # Azure Tenant ID
$azSubscription = ""                            # Subscription ID
$gitlog = ""                                    # Path to GitLog location (if enabled on line 29)
$StorageAccountName = ""                        # Storage Account name to use
$keyVaultName = ""

$ServicePrincipalUser = "default"               # Service Principal name if enabled on line 25 (used for ???)
$LocalAdminUser = "default"                     # Local Admin UserName to create (will be used for VMs)
$HyperVLocalAdminUser = "default"               # Local Admin username to create for Hyper-V server
$DomainJoinUser = "domain\default"              # Domain User with Domain Join rights (needs to exist in the domain)
$DomainUserUser = "domain\default"              # ??? (needs to exist in the domain)

    # Domain Variables
$Domain = ""                                    # Name of the AD Domain
$OUPath = ""                                    # Name of the AD OU where computer objects will be created

    # Script Customisations
$VMListExclude = @()                            # Exclusion list for rebuilding Azure VMs

    # Main Control
$RequireCreate = $false                         # ???
$RequireConfigure = $false                      # ???
$UseTerraform = $false                          # Use Terraform Templates
$RequireUpdateStorage = $false                  # ???
$RequireServicePrincipal = $false               # Enable use of Service Principal

    # Required Components
$isProd = $false                                # Will this build be used for production?
$LogToGit = $false                              # Should the script log to GIT?
$LogToSA = $false                               # Should the script log to the Storage Account?
$RequireUserGroups = $true                      # Do User groups need creating?
$RequireRBAC = $true                            # Is RBAC required???
$RequireResourceGroups = $true                  # Should a Resource Group be created? (or use existing)
$RequireStorageAccount = $true                  # Should a Storage Account be created (or use existing)
$RequireVNET = $true                            # Should a VNET be created (or use existing)
$RequireNSG = $true                             # Should an NSG be created (or use existing)
$RequirePublicIPs = $true                       # Should Public IPs be used
$RequireKeyVault = $true

$RequireStandardVMs = $true                     # Should standard VMs be created?
$RequirePackagingVMs = $false                   # Should Packaging VMs be created?
$RequireAdminStudioVMs = $false                 # Should AdminStudio VMs be created?
$RequireJumpboxVMs = $false                     # Should Jumpbox VMs be created?
$RequireCoreVMs = $false                        # Should Core VMs be created???
$RequireHyperV = $false                         # Should a Hyper-V VM be created?

$VMShutdown = $false                                        # Specifies if the newly provisioned VM should be shutdown (can save costs)

$NumberofStandardVMs = 0                                    # Specify number of Standard VMs to be provisioned
$NumberofPackagingVMs = 0                                   # Specify number of Packaging VMs to be provisioned
$NumberofAdminStudioVMs = 0                                 # Specify number of AdminStudio VMs to be provisioned
$NumberofJumpboxVMs = 0                                     # Specify number of Jumpbox VMs to be provisioned
$NumberofCoreVMs = 0                                        # Specify number of Core VMs to be provisioned
$NumberofStdSrvVMs = 0                                      # Specify number of Standard Server VMs to be provisioned
$NumberofHyperVVMs = 0                                      # Specify number of HyperV Server VMs to be provisioned

    # Script Variables
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
    (Get-Credential -Message "Service Principal").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\ServicePrincipal.xml
    (Get-Credential -Message "Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\LocalAdmin.xml
    (Get-Credential -Message "Hyper-V Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\HyperVLocalAdmin.xml
    (Get-Credential -Message "Domain Join").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainJoin.xml
    (Get-Credential -Message "Domain User").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainUser.xml
}

function createNewKey {
    $KeyFile = "$ExtraFiles\my.key"
    $myKey = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($myKey)
    $myKey | Out-File $KeyFile
}
if(!(Test-Path $ExtraFiles)){
    New-Item -Path $ExtraFiles -ItemType Directory -Force
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
