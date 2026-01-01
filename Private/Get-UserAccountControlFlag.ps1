<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER UserName
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
Function Get-UserAccountControlFlag {
    [CmdletBinding()]
    Param(
        [String]$UserName
    )
    $UACFlags = @(
        "SCRIPT",                           # 1         | The logon script will be run.
        "ACCOUNTDISABLE",                   # 2         | The user account is disabled.
        "RESERVED",                         #           | This flag is undeclared.
        "HOMEDIR_REQUIRED",                 # 8         | The home folder is required.
        "LOCKOUT",                          # 16        |
        "PASSWD_NOTREQD",                   # 32        | No password is required.
        "PASSWD_CANT_CHANGE",               # 64        | The user cannot change the password. This is a permission on the user's object.
        "ENCRYPTED_TEXT_PWD_ALLOWED",       # 128       | This indicates whether Active Directory will store the password in the reversible encryption format.
        "TEMP_DUPLICATE_ACCOUNT",           # 256       | This is an account for users whose primary account is in another domain. This account provides user access to this domain, but not to any domain that trusts this domain.
        "NORMAL_ACCOUNT",                   # 512       | This is a default account type that represents a typical user
        "RESERVED",                         #           | This flag is undeclared.
        "INTERDOMAIN_TRUST_ACCOUNT",        # 2048      | This is a permit to trust an account for a system domain that trusts other domains.
        "WORKSTATION_TRUST_ACCOUNT",        # 4096      | This is a computer account for a computer that is running Microsoft Windows NT 4.0 Workstation, Microsoft Windows NT 4.0 Server, Microsoft Windows 2000 Professional, or Windows 2000 Server and is a member of this domain.
        "SERVER_TRUST_ACCOUNT",             # 8192      | This is a computer account for a domain controller that is a member of this domain.
        "RESERVED",                         #           | This flag is undeclared.
        "RESERVED",                         #           | This flag is undeclared.
        "DONT_EXPIRE_PASSWORD",             # 65536     | This represents the password, which should never expire on the account.
        "MNS_LOGON_ACCOUNT",                # 131072    | This is an MNS logon account
        "SMARTCARD_REQUIRED",               # 262144    | When this flag is set, it forces the user to log on by using a smart card.
        "TRUSTED_FOR_DELEGATION",           # 524288    | When this flag is set, the service account (the user or computer account) under which a service runs is trusted for Kerberos delegation. Any such service can impersonate a client requesting the service
        "NOT_DELEGATED",                    # 1048576   | When this flag is set, the security context of the user is not delegated to a service even if the service account is set as trusted for Kerberos delegation. It can be set using the "Account is sensitive and cannot be delegated" checkbox.
        "USE_DES_KEY_ONLY",                 # 2097152   | This restricts this principal to use only Data Encryption Standard (DES) encryption types for keys.
        "DONT_REQ_PREAUTH",                 # 4194304   | This account does not require Kerberos pre-authentication for logging on.
        "PASSWORD_EXPIRED",                 # 8388608   | The user's password has expired
        "TRUSTED_TO_AUTH_FOR_DELEGATION",   # 16777216  | The account is enabled for delegation. This is a security-sensitive setting. Accounts that have this option enabled should be tightly controlled. This setting lets a service that runs under the account assume a client's identity and authenticate as that user to other remote servers on the network.
        "RESERVED",                         #           | This flag is undeclared.
        "PARTIAL_SECRETS_ACCOUNT",          # 67108864  | The account is a read-only domain controller (RODC). This is a security-sensitive setting. Removing this setting from an RODC compromises security on that server.
        "RESERVED",                         #           | This flag is undeclared.
        "RESERVED",                         #           | This flag is undeclared.
        "RESERVED",                         #           | This flag is undeclared.
        "RESERVED",                         #           | This flag is undeclared.
        "RESERVED"                          #           | This flag is undeclared.
    )
    #read the attribute value of UserAccountControl
    $username = 'sqlanalyticprod'
    $UAC = Get-ADUser $userName -properties UserAccountControl | Select-Object UserAccountControl
    #convert it to a binary representation and reverse the array
    $a = ([Convert]::ToString($UAC.UserAccountControl,2)).ToCharArray()
    [array]::Reverse($a)
    #iterate though the array to see which flag is set
    0 .. $a.Length | ForEach-Object {
        if( $a[$_] -eq "1" ) { $UACFlags[$_] }
    }
}