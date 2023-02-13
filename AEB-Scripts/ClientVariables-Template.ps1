$clientSettings = [ordered]@{
    # Client Azure Variables
    azTenant = ''           # Azure Tenant ID
    azSubscription = ''     # Subscription ID
    gitlog = ''              # Path to GitLog location (if enabled on line 29)

    ServicePrincipalUser = 'default'                    # Service Principal name if enabled on line 26 (used for ???)
    LocalAdminUser = 'AppPackager'                      # Local Admin UserName to create (will be used for VMs)
    HyperVLocalAdminUser = 'default'                    # Local Admin username to create for Hyper-V server
    DomainJoinUser = 'domain\default'                   # Domain User with Domain Join rights (needs to exist in the domain)
    DomainUserUser = 'domain\default'                   # ??? (needs to exist in the domain)

    HyperVVMIsoImagePath = 'SW_DVD9_Win_Pro_11_21H2_64BIT_English_Pro_Ent_EDU_N_MLF_-3_X22-89962.iso'   # This image is used to build the Hyper-V VMs

    # Domain Variables
    Domain = 'test.local'                               # Name of the AD Domain
    OUPath = 'OU=Computers,OU=EUC,DC=test,DC=local'     # Name of the AD OU where computer objects will be created

    # Script Customisations
    VMListExclude = @()                                 # Exclusion list for rebuilding Azure VMs

    # Main Control
    RequireCreate = $true                               # Switch to Create VMs
    RequireConfigure = $true                            # Switch to Configure VMs
    UseTerraform = $false                               # Use Terraform Templates
    RequireUpdateStorage = $true                        # Switch to update content of Storage Account
    RequireServicePrincipal = $false                    # Enable use of Service Principal

    # Required Components
    isProd = $false                                     # Will this build be used for production?
    LogToGit = $true                                    # Should the script log to GIT?
    LogToSA = $false                                    # Should the script log to the Storage Account?
    RequireUserGroups = $false                          # Do User Groups need creating?
    RequireRBAC = $true                                 # Use RBAC groups model or directly add Managed Identities to Storage Account
    RequireResourceGroups = $false                      # Should a Resource Group be created? (or use existing)
    RequireStorageAccount = $true                       # Should a Storage Account be created (or use existing)
    RequireVNET = $true                                 # Should a VNET be created (or use existing)
    RequireNSG = $true                                  # Should an NSG be created (or use existing)
    RequirePublicIPs = $false                           # Should Public IPs be used
    RequireBastion = $true                              # Should Bastion be used
    RequireKeyVault = $true                             # Create KeyVault (used for storing passwords)

    RequireStandardVMs = $true                          # Should Standard VMs be created?
    RequirePackagingVMs = $false                        # Should Packaging VMs be created?
    RequireAdminStudioVMs = $false                      # Should AdminStudio VMs be created?
    RequireJumpboxVMs = $false                          # Should Jumpbox VMs be created?
    RequireCoreVMs = $false                             # Should Core VMs be created???
    RequireStdSrv = $true                               # Should a Standard Server VM be created?
    RequireHyperV = $false                              # Should a Hyper-V Server VM be created?
    RequireDC = $true                                   # Should a Domain Controller Server VM be created?
    RequireSCCM = $true                                 # Should a SCCM Server VM be created?

    NumberofStandardVMs = 0                             # Specify number of Standard VMs to be provisioned
    NumberofPackagingVMs = 0                            # Specify number of Packaging VMs to be provisioned
    NumberofAdminStudioVMs = 0                          # Specify number of AdminStudio VMs to be provisioned
    NumberofJumpboxVMs = 0                              # Specify number of Jumpbox VMs to be provisioned
    NumberofCoreVMs = 0                                 # Specify number of Core VMs to be provisioned
    NumberofStdSrvVMs = 1                               # Specify number of Standard Server VMs to be provisioned
    NumberofHyperVVMs = 0                               # Specify number of HyperV Server VMs to be provisioned
    NumberofDCVMs = 0                                   # Specify number of Domain Controller Server VMs to be provisioned
    NumberofSCCMVMs = 0                                 # Specify number of SCCM Server VMs to be provisioned

    # General Config Variables
    location = 'uksouth'                                # Azure Region for resources to be built into
    #RGNameSTORE = 'rg-TestClient1'                      # Storage Account & KeyVault Resource Group name
    #RGNameDEV = 'rg-TestClient1'                        # DEV Resource Group name
    #RGNamePROD = 'rg-TestClient1'                       # PROD Resource Group name
    #RGNameDEVVNET = 'rg-TestClient1'                    # DEV VNET Resource Group name
    #RGNamePRODVNET = 'rg-TestClient1'                   # PROD VNET Resource Group name
    #SubnetNameDEV = 'subnet-dev'                        # Environment Virtual Subnet name
    #SubnetNamePROD = 'subnet-prod'                      # Environment Virtual Subnet name
    NsgNameDEV = 'nsg-TestClient1'                      # DEV Network Security Group name (firewall)
    NsgNamePROD = 'nsg-TestClient1'                     # PROD Network Security Group name (firewall)
    #BastionNameDEV = 'bastion-TestClient1'              # DEV Bastion name
    #BastionNamePROD = 'bastion-TestClient1'             # PROD Bastion name

    rgs = @{
        PROD = [ordered]@{
            RGName = 'rg-TestClient1'
            RGNameVNET = 'rg-TestClient1'
        }
        DEV = [ordered]@{
            RGName = 'rg-TestClient1'
            RGNameVNET = 'rg-TestClient1'
        }
        STORE = [ordered]@{
            RGName = 'rg-TestClient1'
        }
    }

    vnets = @{
        PROD = [ordered]@{
            'vnet-prod-azure'  = 'vnet-TestClient1-azure'
            'vnet-prod-domain' = 'vnet-TestClient1-domain'
        }
        DEV = [ordered]@{
            'vnet-dev-azure' = 'vnet-TestClient1-azure'
            'vnet-dev-domain' = 'vnet-TestClient1-domain'
        }
    }

    subnets = @{
        PROD = [ordered]@{
            SubnetName = 'subnet-prod'
        }
        DEV = [ordered]@{
            SubnetName = 'subnet-dev'
        }
    }

    bastions = @{
        PROD = [ordered]@{
            BastionName = 'bastion-TestClient1'
        }
        DEV = [ordered]@{
            BastionName = 'bastion-TestClient1'
        }
    }

    # Environment Variables
    rbacOwner = 'rbac-owner-TestClient1'
    rbacContributor = 'rbac-contributor-TestClient1'
    rbacReadOnly = 'rbac-readonly-TestClient1'


    # Storage Account and Container Names
    StorageAccountName = 'satestclient1'                # Storage account name (if used) (24 chars maximum) (lowercase and numerical chars only). Needs to be globally unique within Azure
    ContainerName = 'data'                              # Storage container name (if used) (do not change from 'data')
    FileShareName = 'share'                             # Storage FileShare name (if used) (do not change from 'pkgazfiles01')
    BlobFilesSource = "$root\BlobFilesSource"           # Source Template Folder for CustomScriptExtension
    BlobFilesDest = "$root\BlobFilesDestination"        # Destination Template Folder for CustomScriptExtension
    keyVaultName = 'kv-avaws-TestClient1'               # needs to be globally unique within Azure
}

# Load Spec Files
Try {
    $deviceSpecs = Get-Content $root\devicespecs-template.jsonc | ConvertFrom-Json -ErrorAction Stop
    $appSpecs = Get-Content $root\appspecs-template.jsonc | ConvertFrom-Json -ErrorAction Stop
}
Catch {
    throw 'Error with Device Specs'
    exit
}

# New Client Setup and Key File Load
function setSecurePasswords {
    (Get-Credential -Message 'Service Principal' -UserName $clientSettings.ServicePrincipalUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\ServicePrincipal.xml
    (Get-Credential -Message 'Local Admin' -UserName $clientSettings.LocalAdminUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\LocalAdmin.xml
    (Get-Credential -Message 'Hyper-V Local Admin' -UserName $clientSettings.HyperVLocalAdminUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\HyperVLocalAdmin.xml
    (Get-Credential -Message 'Domain Join' -UserName $clientSettings.DomainJoinUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainJoin.xml
    (Get-Credential -Message 'Domain User' -UserName $clientSettings.DomainUserUser).Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainUser.xml
}

function createNewKey {
    $KeyFile = "$ExtraFiles\my.key"
    $myKey = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($myKey)
    $myKey | Out-File $KeyFile
}

if (!(Test-Path "$ExtraFiles\my.key")) {
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

    if ($ServicePrincipalPassword) {
        $ServicePrincipalCred = New-Object System.Management.Automation.PSCredential ($clientSettings.ServicePrincipalUser, $ServicePrincipalPassword)
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServicePrincipalPassword))
    }
}
else { (Get-Credential -Message 'Service Principal').Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\ServicePrincipal.xml }

if (Test-Path $ExtraFiles\LocalAdmin.xml) {
    $LocalAdminPassword = Import-Clixml $ExtraFiles\LocalAdmin.xml | ConvertTo-SecureString -Key $myKey
    if ($LocalAdminPassword) {
        $LocalAdminCred = New-Object System.Management.Automation.PSCredential ($clientSettings.LocalAdminUser, $LocalAdminPassword)
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($LocalAdminPassword))
    }
}
else { (Get-Credential -Message 'Local Admin').Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\LocalAdmin.xml }

if (Test-Path $ExtraFiles\HyperVLocalAdmin.xml) {
    $HyperVLocalAdminPassword = Import-Clixml $ExtraFiles\HyperVLocalAdmin.xml | ConvertTo-SecureString -Key $myKey
    if ($HyperVLocalAdminPassword) {
        $HyperVLocalAdminCred = New-Object System.Management.Automation.PSCredential ($clientSettings.HyperVLocalAdminUser, $HyperVLocalAdminPassword)
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($HyperVLocalAdminPassword))
    }
}
else { (Get-Credential -Message 'Hyper-V Local Admin').Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\HyperVLocalAdmin.xml }

if (Test-Path $ExtraFiles\DomainJoin.xml) {
    $DomainJoinPassword = Import-Clixml $ExtraFiles\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
    if ($DomainJoinPassword) {
        $DomainJoinCred = New-Object System.Management.Automation.PSCredential ($clientSettings.DomainJoinUser, $DomainJoinPassword)
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DomainJoinPassword))
    }
}
else { (Get-Credential -Message 'Domain Join').Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainJoin.xml }

if (Test-Path $ExtraFiles\DomainUser.xml) {
    $DomainUserPassword = Import-Clixml $ExtraFiles\DomainUser.xml | ConvertTo-SecureString -Key $myKey
    if ($DomainUserPassword) {
        $DomainUserCred = New-Object System.Management.Automation.PSCredential ($clientSettings.DomainUserUser, $DomainUserPassword)
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DomainUserPassword))
    }
}
else { (Get-Credential -Message 'Domain User').Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainUser.xml }
