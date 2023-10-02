$clientName = ''
$azTenant = ''                                  # AVAWS Test Client 0
$azSubscription = ''                            # AVAWS Test Client 0
$domain = ''                                                       # Name of the AD Domain
$ouPath = ''                             # Name of the AD OU where computer objects will be created
$StorageAccountName = "sa2avaws$($clientName.ToLower())"
$keyVaultName = "kv-2avaws-$($clientName)"

$clientName = $clientName.Replace('-', '')
$clientName = $clientName.Replace('_', '')
$clientName = $clientName.Replace(' ', '')
$clientName = $clientName.Replace('#', '')
$clientName = $clientName.Replace('/', '')
$clientName = $clientName.Replace('\', '')
$clientSettings = [ordered]@{
    # Client Information
    ClientName                       = $clientName

    # Client Azure Variables
    azTenant                         = $azTenant
    azSubscription                   = $azSubscription

    # Domain Variables
    Domain                           = $domain
    OUPath                           = $ouPath

    # Main Control
    RequireCreate                    = $true                                         # Switch to Create VMs
    RequireConfigure                 = $true                                         # Switch to Configure VMs
    RequireUpdateStorage             = $true                                         # Switch to update content of Storage Account
    UseTerraform                     = $false                                        # Use Terraform Templates
    RequireServicePrincipal          = $false                                        # Enable use of Service Principal

    # Required Components
    isProd                           = $false                                        # Will this build be used for production?
    LogToGit                         = $false                                        # Use - Should the script log to GIT?
    LogToSA                          = $false                                        # Use - Should the script log to the Storage Account?
    RequireUserGroups                = $false                                        # Create - User Groups?
    RequireRBAC                      = $true                                         # Use - RBAC groups model or directly add Managed Identities to Storage Account
    RequireResourceGroups            = $false                                        # Create - Should a Resource Group be created? (or use existing)
    RequireStorageAccount            = $false                                        # Create - Storage Account Resources
    RequireVNET                      = $false                                        # Create - VNET Resources
    RequireNSG                       = $false                                        # Create - NSG Resources
    RequirePublicIPs                 = $false                                        # Use - Should Public IPs be used
    RequireBastion                   = $false                                        # Create - Bastion Resources
    RequireKeyVault                  = $false                                        # Create - KeyVault Resources

    RequireStandardVMs               = $true                                       # Should Standard VMs be created?
    RequirePackagingVMs              = $true                                       # Should Packaging VMs be created?
    RequireAdminStudioVMs            = $true                                       # Should AdminStudio VMs be created?
    RequireJumpboxVMs                = $true                                       # Should Jumpbox VMs be created?
    RequireCoreVMs                   = $true                                       # Should Core VMs be created?
    RequireLiteVMs                   = $true                                       # Should Lite VMs be created?
    RequireDomainJoinedWin1020h2VMs  = $true
    RequireDomainJoinedWin1122h2VMs  = $true
    RequireStdSrv                    = $true                                       # Should Standard Server VM be created?
    RequireHyperV                    = $true                                       # Should Hyper-V Server VM be created?
    RequireDC                        = $true                                       # Should Domain Controller Server VM be created?
    RequireSCCM                      = $true                                       # Should SCCM Server VM be created?
    RequireA365                      = $true                                       # Should A365 Server VM be created?

    NumberofStandardVMs              = 0                                           # Specify number of Standard VMs to be provisioned
    NumberofPackagingVMs             = 0                                           # Specify number of Packaging VMs to be provisioned
    NumberofAdminStudioVMs           = 0                                           # Specify number of AdminStudio VMs to be provisioned
    NumberofJumpboxVMs               = 0                                           # Specify number of Jumpbox VMs to be provisioned
    NumberofCoreVMs                  = 0                                           # Specify number of Core VMs to be provisioned
    NumberofLiteVMs                  = 0                                           # Specify number of Lite VMs to be provisioned
    NumberofDomainJoinedWin1020h2VMs = 2                                           # Specify number of Domain Joined VMs to be provisioned
    NumberofDomainJoinedWin1122h2VMs = 2                                           # Specify number of Domain Joined VMs to be provisioned
    NumberofStdSrvVMs                = 0                                           # Specify number of Standard Server VMs to be provisioned
    NumberofHyperVVMs                = 0                                           # Specify number of HyperV Server VMs to be provisioned
    NumberofDCVMs                    = 0                                           # Specify number of Domain Controller Server VMs to be provisioned
    NumberofSCCMVMs                  = 0                                           # Specify number of SCCM Server VMs to be provisioned
    NumberofA365VMs                  = 0                                           # Specify number of A365 Server VMs to be provisioned

    # General Config Variables
    location                         = 'uksouth'                                     # Azure Region for resources to be built into

    # Name Collections of Resource Groups, VNETS, Subnets, NSGs, Bastions, and Tags
    rgs                              = @{
        PROD  = [ordered]@{
            RGName     = "rg-$($clientName)"
            RGNameVNET = "rg-$($clientName)"
        }
        DEV   = [ordered]@{
            RGName     = "rg-$($clientName)"
            RGNameVNET = "rg-$($clientName)"
        }
        STORE = [ordered]@{
            RGName = "rg-$($clientName)"
        }
    }

    vnets                            = @{
        PROD = [ordered]@{
            'vnet-prod-azure'  = "vnet-$($clientName)-azure"
            'vnet-prod-domain' = "vnet-$($clientName)-domain"
        }
        DEV  = [ordered]@{
            'vnet-dev-azure'  = "vnet-$($clientName)-azure"
            'vnet-dev-domain' = "vnet-$($clientName)-domain"
        }
    }

    subnets                          = @{
        PROD = [ordered]@{
            SubnetName   = 'subnet-prod'
            addressSpace = 1
        }
        DEV  = [ordered]@{
            SubnetName   = 'subnet-dev'
            addressSpace = 2
        }
    }

    nsgs                             = @{
        PROD = [ordered]@{
            NsgName = "nsg-$($clientName)"
        }
        DEV  = [ordered]@{
            NsgName = "nsg-$($clientName)"
        }
    }

    bastions                         = @{
        PROD = [ordered]@{
            BastionName = "bastion-$($clientName)"
        }
        DEV  = [ordered]@{
            BastionName = "bastion-$($clientName)"
        }
    }

    tags                             = @{
        'Application'     = 'AEB'
        'AEB-Client'      = "$($clientName)"
        'AEB-Environment' = ''
    }

    # Default Account IDs
    ServicePrincipalUser             = 'default'                                   # Service Principal name if enabled on line 26 (used for ???)
    LocalAdminUser                   = 'aebadmin'                                  # Local Admin UserName to create (will be used for VMs)
    HyperVLocalAdminUser             = 'aebadmin'                                  # Local Admin username to create for Hyper-V server
    DomainJoinUser                   = 'aebadmin'                                  # Domain User with Domain Join rights (needs to exist in the domain)
    DomainUserUser                   = 'aebadmin'                                  # ??? (needs to exist in the domain)


    # Environment Variables
    rbacOwner                        = "rbac-owner-$($clientName)"
    rbacContributor                  = "rbac-contributor-$($clientName)"
    rbacReadOnly                     = "rbac-readonly-$($clientName)"


    # Storage Account and Container Names
    StorageAccountName               = $StorageAccountName                          # Storage account name (if used) (24 chars maximum) (lowercase and numerical chars only). Needs to be globally unique within Azure
    ContainerName                    = 'data'                                       # Storage container name (if used) (do not change from 'data')
    FileShareName                    = 'share'                                      # Storage FileShare name (if used) (do not change from 'pkgazfiles01')
    BlobFilesSource                  = "$root\BlobFilesSource"                      # Source Template Folder for CustomScriptExtension
    BlobFilesDest                    = "$root\BlobFilesDestination"                 # Destination Template Folder for CustomScriptExtension
    keyVaultName                     = $keyVaultName                                # needs to be globally unique within Azure

    # Script Customisations
    gitlog                           = 'https://github.com/satsuk81/log.git'           # Path to GitLog location (if enabled on line 29)
    logFile                          = 'AEB.log'
    VMListExclude                    = @()                                             # Exclusion list for rebuilding Azure VMs
    HyperVVMIsoImagePath             = 'SW_DVD9_Win_Pro_11_21H2_64BIT_English_Pro_Ent_EDU_N_MLF_-3_X22-89962.iso'   # This image is used to build the Hyper-V VMs
    StorageAccountFirewallIPs        = @(
        '3.16.7.30'
        '13.59.164.228'
        '18.191.115.70'
        '18.218.243.39'
        '18.221.72.80'
        '18.223.141.221')

}

# Load Spec Files
Try {
    $deviceSpecs = Get-Content $AEBClientFiles\devicespecs-template.jsonc | ConvertFrom-Json -ErrorAction Stop
    $appSpecs = Get-Content $AEBClientFiles\appspecs-template.jsonc | ConvertFrom-Json -ErrorAction Stop
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
