cd $PSScriptRoot

    # Variables
$azTenant = ""
$azSubscription = ""

    # Secure Key
$KeyFile = "./my.key"
$myKey = Get-Content $KeyFile

    # Passwords
$ServicePrincipalUser = ""
$ServicePrincipalPassword = Import-Clixml .\ServicePrincipal.xml | ConvertTo-SecureString -Key $myKey
$ServicePrincipalCred = New-Object System.Management.Automation.PSCredential ($ServicePrincipalUser, $ServicePrincipalPassword)

$LocalAdminUser = ""
$LocalAdminPassword = Import-Clixml .\LocalAdmin.xml | ConvertTo-SecureString -Key $myKey
$LocalAdminCred = New-Object System.Management.Automation.PSCredential ($LocalAdminUser, $LocalAdminPassword)

$HyperVLocalAdminUser = ""
$HyperVLocalAdminPassword = Import-Clixml .\HyperVLocalAdmin.xml | ConvertTo-SecureString -Key $myKey
$HyperVLocalAdminCred = New-Object System.Management.Automation.PSCredential ($HyperVLocalAdminUser, $HyperVLocalAdminPassword)

$DomainJoinUser = ""
$DomainJoinPassword = Import-Clixml .\DomainJoin.xml | ConvertTo-SecureString -Key $myKey
$DomainJoinCred = New-Object System.Management.Automation.PSCredential ($DomainJoinUser, $DomainJoinPassword)

$DomainUserUser = ""
$DomainUserPassword = Import-Clixml .\DomainUser.xml | ConvertTo-SecureString -Key $myKey
$DomainUserCred = New-Object System.Management.Automation.PSCredential ($DomainUserUser, $DomainUserPassword)

$StorageSP = $ServicePrincipalCred
$VMCred = $LocalAdminCred

function setSecurePasswords {
    Get-Credential -Message "Service Principal" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\ServicePrincipal.xml
    Get-Credential -Message "Local Admin" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\LocalAdmin.xml
    Get-Credential -Message "Hyper-V Local Admin" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\HyperVLocalAdmin.xml
    Get-Credential -Message "Domain Join" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\DomainJoin.xml
    Get-Credential -Message "Domain User" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $myKey | Export-Clixml -Path .\DomainUser.xml
}

function createNewKey {
    $KeyFile = "./my.key"
    $myKey = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($myKey)
    $myKey | Out-File $KeyFile
}