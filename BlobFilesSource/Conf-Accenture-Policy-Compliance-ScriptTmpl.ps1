$policies = [ordered]@{
    '2605'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorUser'
        'type'       = 'REG_DWORD'
        'value'      = 3
    }
    '8143'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Microsoft\Windows\CurrentVersion\Policies\System\MaxDevicePasswordFailedAttempts'
        'type'       = 'REG_DWORD'
        'value'      = 7
    }
    '1155'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Microsoft\Windows NT\CurrentVersion\Winlogon\CachedLogonsCount'
        'type'       = 'REG_SZ'
        'value'      = '2'
    }
    '10437'    = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity\MinimumPINLength'
        'type'       = 'REG_DWORD'
        'value'      = 8
    }
    '8145'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Microsoft\Windows\CurrentVersion\Policies\System\InactivityTimeoutSecs'
        'type'       = 'REG_DWORD'
        'value'      = 600
    }
    '9388'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\System\BlockDomainPicturePassword'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '1514'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows NT\Rpc\RestrictRemoteClients'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '1436'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Cryptography\ForceKeyProtection'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '3899'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\policies\Microsoft\Windows NT\Terminal Services\fAllowToGetHelp'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '3900'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\policies\Microsoft\Windows NT\Terminal Services\fAllowUnsolicited'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '3891'     = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\fPromptForPassword'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '3876'     = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\DisablePasswordSaving'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '3897'     = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI\EnumerateAdministrators'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '8425'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\CredUI\DisablePasswordReveal'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '378332.1' = @{
        'policytype' = 'reg'
        'key'        = 'Software\Microsoft\Cryptography\Wintrust\Config\EnableCertPaddingCheck'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '378332.2' = @{
        'policytype' = 'reg'
        'key'        = 'Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config\EnableCertPaddingCheck'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '2586'     = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\FilterAdministratorToken'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '10411'    = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity\Digits'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '1387'     = @{
        'policytype' = 'reg'
        'key'        = 'SYSTEM\CurrentControlSet\Control\Lsa\LmCompatibilityLevel'
        'type'       = 'REG_DWORD'
        'value'      = 5
    }
    '1149'     = @{
        'policytype' = 'reg'
        'key'        = 'SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters\RequireSecuritySignature'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '1189'     = @{
        'policytype' = 'reg'
        'key'        = 'SYSTEM\CurrentControlSet\Services\lanmanserver\Parameters\RequireSecuritySignature'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '8175'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\System\AllowDomainPINLogon'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '8176'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\System\DontEnumerateConnectedUsers'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '8177'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\System\EnumerateLocalUsers'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '8399'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\System\DisableLockScreenAppNotifications'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '10085'    = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Control Panel\International\BlockUserInputMethodsForSignIn'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '12015'    = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\MicrosoftAccount\DisableUserAuth'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '1381'     = @{
        'policytype' = 'reg'
        'key'        = 'System\CurrentControlSet\Services\LanmanServer\Parameters\EnableSecuritySignature'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '1388'     = @{
        'policytype' = 'reg'
        'key'        = 'SYSTEM\CurrentControlSet\Services\LDAP\LDAPClientIntegrity'
        'type'       = 'REG_DWORD'
        'value'      = 2
    }
    '2585'     = @{
        'policytype' = 'reg'
        'key'        = 'SYSTEM\CurrentControlSet\Control\Lsa\DisableDomainCreds'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '5265'     = @{
        'policytype' = 'reg'
        'key'        = 'SYSTEM\CurrentControlSet\Control\LSA\MSV1_0\allownullsessionfallback'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '3875'     = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\fDisableCdm'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '3908'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\SearchCompanion\DisableContentFileUpdates'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '3921'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoPublishingWizard'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '4125'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows NT\Terminal Services\fDisablePNPRedir'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '4140'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows NT\Terminal Services\DeleteTempDirsOnExit'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '10404'    = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\UserAuthentication'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '10431'    = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\SecurityLayer'
        'type'       = 'REG_DWORD'
        'value'      = 2
    }
    '14879'    = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\System\UploadUserActivities'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '17711'    = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\MinEncryptionLevel'
        'type'       = 'REG_DWORD'
        'value'      = 3
    }
    '8248'     = @{
        'policytype' = 'reg'
        'key'   = 'SOFTWARE\Policies\Microsoft\Windows\WinRM\Client\AllowDigest'
        'type'  = 'REG_DWORD'
        'value' = 0
    }
    '8251'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\WinRM\Service\DisableRunAs'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '10370'    = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation\AllowInsecureGuestAuth'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '11192'    = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows NT\DNSClient\EnableMulticast'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '8249'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\WinRM\Client\AllowBasic'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '8250'     = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\AllowBasic'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '8252'     = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\AllowUnencryptedTraffic'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '8253'     = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\Windows\WinRM\Client\AllowUnencryptedTraffic'
        'type'       = 'REG_DWORD'
        'value'      = 0
    }
    '10081'    = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\Network Connections\NC_StdDomainUserSetLocation'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '5209'     = @{
        'policytype' = 'reg'
        'key'        = 'System\CurrentControlSet\Services\LanManServer\Parameters\NullSessionPipes'
        'type'       = 'REG_MULTI_SZ'
        'value'      = ''
    }
    '5210'     = @{
        'policytype' = 'reg'
        'key'        = 'System\CurrentControlSet\Services\LanManServer\Parameters\NullSessionShares'
        'type'       = 'REG_MULTI_SZ'
        'value'      = ''
    }
    '1134'     = @{
        'policytype' = 'reg'
        'key'        = 'Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeCaption'
        'type'       = 'REG_SZ'
        'value'      = 'Accenture Security Advisory Warning'
    }
    '10383'    = @{
        'policytype' = 'reg'
        'key'        = 'SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main\FormSuggest Passwords'
        'type'       = 'REG_SZ'
        'value'      = 'no'
    }
    '10968'    = @{
        'policytype' = 'reg'
        'key'        = 'System\CurrentControlSet\Control\Lsa\RestrictRemoteSAM'
        'type'       = 'REG_SZ'
        'value'      = 'O:BAG:BAD:(A;;RC;;;BA)'
    }
    '10348'    = @{
        'policytype' = 'reg'
        'key'        = 'Software\Policies\Microsoft\Windows\DataCollection\DoNotShowFeedbackNotifications'
        'type'       = 'REG_DWORD'
        'value'      = 1
    }
    '18965'    = @{
        'policytype' = 'reg'
        'key'        = 'SYSTEM\CurrentControlSet\Services\FrameServer\Start'
        'type'       = 'REG_DWORD'
        'value'      = 4
    }
    '1979'    = @{
        'policytype' = 'reg'
        'key'        = 'SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc\Start'        # This is a guess!!!!!
        'type'       = 'REG_DWORD'
        'value'      = 4
    }
    <#'1092' = @{
        'policytype' = 'reg'
        'key'   = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Network\MinPwdLen'
        'type'  = 'REG_DWORD'
        'value' = 1
        'Hive' = 'HKEY_CURRENT_USER'
    }#>
    'xxx'      = @{
        'policytype' = 'gpo'
        'key'        = 'Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
        'property'   = 'UseWUServer'
        'type'       = 'DWord'
        'value'      = '1'
    }
    <#>'xxy'      = @{
        'policytype' = 'gpo'
        'key'        = 'Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy'
        'property'   = 'Minimum password length'
        'type'       = 'DWord'
        'value'      = '1'
    }#>
}

$typeMap = [ordered]@{
    'REG_DWORD'      = 'DWord'
    'REG_SZ'         = 'String'
    'REG_EXPAND_SZ ' = 'ExpandString'
    'REG_BINARY'     = 'Binary'
    'REG_MULTI_SZ'   = 'MultiString'
    'REG_QWORD'      = 'Qword'
}

Function CheckPolicy {
    $global:resultsCheck = foreach ($policy in $policies.GetEnumerator()) {
        if ($policy.Value.policytype -eq 'reg' -and $ActionReg) {
            Set-Location HKLM:\
            $splitLeaf = Split-Path -Path $($policy.Value.key) -Leaf
            $splitParent = Split-Path -Path $($policy.Value.key) -Parent
            try {
                $path = Test-Path -Path $splitParent
                if (!$path) {
                    New-Item -Path $splitParent -Force -ErrorAction SilentlyContinue
                }
                $value = $null
                $propertyValue = $null
                $propertyKind = $null
                $value = Get-ItemPropertyValue -Path $splitParent -Name $splitLeaf -ErrorAction SilentlyContinue
                $key = Get-Item -Path $splitParent -ErrorAction SilentlyContinue
                $propertyValue = $key.GetValue($splitLeaf)
                $propertyKind = $key.GetValueKind($splitLeaf)
            }
            catch {}

            [PSCustomObject]@{
                ID           = $policy.Name
                Property     = $splitLeaf
                MatchValue   = $value -eq $policy.Value.value
                MatchKind    = $propertyKind -eq $typeMap.$($policy.Value.type)
                CurrentValue = $value
                CurrentKind  = $propertyKind
                NewValue     = $policy.Value.value
                NewKind      = $typeMap.$($policy.Value.type)
                RegLocation  = "Computer\HKLM\$splitParent"
            }
        }
        if ($policy.Value.policytype -eq 'gpo' -and $ActionGPO) {
            #$splitLeaf = Split-Path -Path $($policy.Value.key) -Leaf
            #$splitParent = Split-Path -Path $($policy.Value.key) -Parent

            $UserDir = "$env:windir\system32\GroupPolicy\User\registry.pol"
            $SystemDir = "$env:systemroot\system32\GroupPolicy\Machine\registry.pol"

            #Set-PolicyFileEntry -Path $UserDir -Key $policy.Value.key -ValueName $policy.Value.property -Data $policy.Value.value -Type $policy.Value.type
            $global:gpopolicy = Get-PolicyFileEntry -Path $SystemDir -Key $($policy.Value.key) -ValueName $($policy.Value.property) #-Data $policy.Value.value -Type $policy.Value.type

            [PSCustomObject]@{
                ID           = $policy.Name
                Property     = $policy.Value.property
                MatchValue   = $gpopolicy.Data -eq $policy.Value.value
                MatchKind    = $gpopolicy.Type -eq $policy.Value.type
                CurrentValue = $gpopolicy.Data
                CurrentKind  = $gpopolicy.Type
                NewValue     = $policy.Value.value
                NewKind      = $policy.Value.type
                RegLocation  = $policy.Value.key
            }
        }
    }
}


Function SetPolicy {
    $global:resultsSet = foreach ($policy in $policies.GetEnumerator()) {
        if ($policy.Value.policytype -eq 'reg' -and $ActionReg) {
            Set-Location HKLM:\
            $splitLeaf = Split-Path -Path $($policy.Value.key) -Leaf
            $splitParent = Split-Path -Path $($policy.Value.key) -Parent
            try {
                New-ItemProperty -Path $splitParent -Name $splitLeaf -Value $policy.Value.value -PropertyType $typeMap.$($policy.Value.type) -ErrorAction SilentlyContinue
            }
            catch {}
            Set-ItemProperty -Path $splitParent -Name $splitLeaf -Value $policy.Value.value -ErrorAction SilentlyContinue
            $value = Get-ItemPropertyValue -Path $splitParent -Name $splitLeaf -ErrorAction SilentlyContinue
            [PSCustomObject]@{
                ID           = $policy.Name
                Property     = $splitLeaf
                CurrentValue = $value
                NewValue     = $policy.Value.value
                RegLocation  = "Computer\HKLM\$splitParent"
            }
        }
    }
}

$ActionReg = $true
$ActionGPO = $false

CheckPolicy
SetPolicy
#CheckPolicy
#$global:resultsCheck | ft