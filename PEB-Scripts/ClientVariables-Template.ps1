    # Client Azure Variables
$azTenant = ""
$azSubscription = ""
$gitlog = ""

    # Domain Variables
$Domain = ""
$OUPath = ""

    # Script Customisations
$VMListExclude = @()                    # Exclusion list for rebuilding Azure VMs

    # Main Control
$RequireCreate = $false
$RequireConfigure = $false
$UseTerraform = $false
$RequireUpdateStorage = $false
$RequireServicePrincipal = $false

    # Required Components
$RequireUserGroups = $true
$RequireRBAC = $true
$RequireResourceGroups = $true
$RequireStorageAccount = $true
$RequireVNET = $true
$RequireNSG = $true
$RequirePublicIPs = $true
$RequireStandardVMs = $true
$RequirePackagingVMs = $true
$RequireAdminStudioVMs = $true
$RequireJumpboxVMs = $true
$RequireCoreVMs = $true
$RequireHyperV = $true

    # Script Variables
$ExtraFiles = "$root\ExtraFiles"
Try {
    $deviceSpecs = Get-Content $root\devicespecs-template.jsonc | ConvertFrom-Json -ErrorAction Stop
    $appSpecs = Get-Content $root\appspecs-template.jsonc | ConvertFrom-Json -ErrorAction Stop
}
Catch {
    throw "Error with Device Specs"
    exit
}

    # Azure Tags
$tags = @{
    "Application"         = "EUC App Packaging"
    "Envrionment"         = "Production"
}

    # Secure Key
$KeyFile = "$ExtraFiles\my.key"
$myKey = Get-Content $KeyFile

    # Passwords
if (Test-Path $ExtraFiles\ServicePrincipal.xml) {
    $ServicePrincipalUser = ""
    $ServicePrincipalPassword = Import-Clixml $ExtraFiles\ServicePrincipal.xml | ConvertTo-SecureString -Key $myKey
    $ServicePrincipalCred = New-Object System.Management.Automation.PSCredential ($ServicePrincipalUser, $ServicePrincipalPassword)
} else {(Get-Credential -Message "Service Principal").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\ServicePrincipal.xml}

if (Test-Path $ExtraFiles\LocalAdmin.xml) {
    $LocalAdminUser = ""
    $LocalAdminPassword = Import-Clixml $ExtraFiles\LocalAdmin.xml | ConvertTo-SecureString -Key $myKey
    $LocalAdminCred = New-Object System.Management.Automation.PSCredential ($LocalAdminUser, $LocalAdminPassword)
} else {(Get-Credential -Message "Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\LocalAdmin.xml}

if (Test-Path $ExtraFiles\HyperVLocalAdmin.xml) {
    $HyperVLocalAdminUser = ""
    $HyperVLocalAdminPassword = Import-Clixml $ExtraFiles\HyperVLocalAdmin.xml | ConvertTo-SecureString -Key $myKey
    $HyperVLocalAdminCred = New-Object System.Management.Automation.PSCredential ($HyperVLocalAdminUser, $HyperVLocalAdminPassword)
} else {(Get-Credential -Message "Hyper-V Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\HyperVLocalAdmin.xml}

if (Test-Path $ExtraFiles\DomainJoin.xml) {
    $DomainJoinUser = ""
    $DomainJoinPassword = Import-Clixml $ExtraFiles\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
    $DomainJoinCred = New-Object System.Management.Automation.PSCredential ($DomainJoinUser, $DomainJoinPassword)
} else {(Get-Credential -Message "Domain Join").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainJoin.xml}

if (Test-Path $ExtraFiles\DomainUser.xml) {
    $DomainUserUser = ""
    $DomainUserPassword = Import-Clixml $ExtraFiles\DomainUser.xml | ConvertTo-SecureString -Key $myKey
    $DomainUserCred = New-Object System.Management.Automation.PSCredential ($DomainUserUser, $DomainUserPassword)
} else {(Get-Credential -Message "Domain User").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path $ExtraFiles\DomainUser.xml}

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