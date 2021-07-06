cd $PSScriptRoot

    # Client Azure Variables
$azTenant = ""
$azSubscription = ""

    # Domain Variables
$Domain = ""
$OUPath = ""
    
    # Script Customisations
$VMListExclude = @()                    # Exclusion list for rebuilding Azure VMs

    # Secure Key
$KeyFile = "./my.key"
$myKey = Get-Content $KeyFile

    # Passwords
if (Test-Path .\ServicePrincipal.xml) {
    $ServicePrincipalUser = ""
    $ServicePrincipalPassword = Import-Clixml .\ServicePrincipal.xml | ConvertTo-SecureString -Key $myKey
    $ServicePrincipalCred = New-Object System.Management.Automation.PSCredential ($ServicePrincipalUser, $ServicePrincipalPassword)
} else {(Get-Credential -Message "Service Principal").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\ServicePrincipal.xml}

if (Test-Path .\LocalAdmin.xml) {
    $LocalAdminUser = ""
    $LocalAdminPassword = Import-Clixml .\LocalAdmin.xml | ConvertTo-SecureString -Key $myKey
    $LocalAdminCred = New-Object System.Management.Automation.PSCredential ($LocalAdminUser, $LocalAdminPassword)
} else {(Get-Credential -Message "Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\LocalAdmin.xml}

if (Test-Path .\HyperVLocalAdmin.xml) {
    $HyperVLocalAdminUser = ""
    $HyperVLocalAdminPassword = Import-Clixml .\HyperVLocalAdmin.xml | ConvertTo-SecureString -Key $myKey
    $HyperVLocalAdminCred = New-Object System.Management.Automation.PSCredential ($HyperVLocalAdminUser, $HyperVLocalAdminPassword)
} else {(Get-Credential -Message "Hyper-V Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\HyperVLocalAdmin.xml}

if (Test-Path .\DomainJoin.xml) {
    $DomainJoinUser = ""
    $DomainJoinPassword = Import-Clixml .\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
    $DomainJoinCred = New-Object System.Management.Automation.PSCredential ($DomainJoinUser, $DomainJoinPassword)
} else {(Get-Credential -Message "Domain Join").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\DomainJoin.xml}

if (Test-Path .\DomainUser.xml) {
    $DomainUserUser = ""
    $DomainUserPassword = Import-Clixml .\DomainUser.xml | ConvertTo-SecureString -Key $myKey
    $DomainUserCred = New-Object System.Management.Automation.PSCredential ($DomainUserUser, $DomainUserPassword)
} else {(Get-Credential -Message "Domain User").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\DomainUser.xml}

function setSecurePasswords {
    (Get-Credential -Message "Service Principal").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\ServicePrincipal.xml
    (Get-Credential -Message "Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\LocalAdmin.xml
    (Get-Credential -Message "Hyper-V Local Admin").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\HyperVLocalAdmin.xml
    (Get-Credential -Message "Domain Join").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\DomainJoin.xml
    (Get-Credential -Message "Domain User").Password | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\DomainUser.xml
}

function createNewKey {
    $KeyFile = "./my.key"
    $myKey = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($myKey)
    $myKey | Out-File $KeyFile
}