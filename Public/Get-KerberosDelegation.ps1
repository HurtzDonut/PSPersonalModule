<#
.SYNOPSIS
    Return the Kerberos Delegation settings.

.DESCRIPTION
    Return the Kerberos Delegation settings for the specified AD object.
    If no AD object is specified then all AD Objects with Delegation are returned.

.PARAMETER SamAccountName
    SamAccountName of the AD object. If specifying computer or managed service accounts drop the "$" from the name.

.PARAMETER DistinguishedName
    The distinguishedName of the AD object.

.PARAMETER ExcludeDomainControllers
    Exclude Domain Controllers.

.EXAMPLE
    $dn = (Get-ADServiceAccount 'MSA-TST02').distinguishedName
    Get-KerberosDelegation -DistinguishedName $dn

.EXAMPLE
    Get-KerberosDelegation -SamAccountName 'MSA-TST02$'

.EXAMPLE
    Get-ADServiceAccount 'MSA-TST02' | Get-KerberosDelegation

.EXAMPLE
    Get-ADObject -Filter "SamAccountName -eq 'MSA-TST02$'" | Get-KerberosDelegation

.NOTES
    Kerberos Delegation is a security sensitive configuration. Especially full (unconstrained) delegation has significant impact: any service
    that is configured with full delegation can take any account that authenticates to it, and impersonate that account for any other network
    service that it likes. So, if a Domain Admin were to use that service, the service in turn could read the hash of KRBRTG and immediately
    effectuate a golden ticket. Etc :)

    If a specific account isn't supplied then this script will search AD for regular forms of delegation: full, constrained,
    and resource based. It dumps the account names with relevant information (flags) and adds a comment field for special cases.
    The output is a PSObject that you can use for further analysis.

    Note regarding Resource Based Delegation: the script dumps the target services, not the actual service doing the delegation.

    Main takeaway: chase all services with unconstrained delegation. If these are Not DC accounts, reconfigure them with constrained delegation.

    Properties
    PrincipalsAllowedToRetrieveManagedPassword  - Group Managed Service Account setting. gMSA that can retrieve the managed password
    PrincipalsAllowedToDelegateToAccount        - Resource Based Constrained Delegation, list of accounts that the account will allow delegation from
    TrustedForDelegation                        - Unconstrained Delegation
    TrustedToAuthForDelegation                  - Kerberos Constrained Delegation with Protocol Transition, allows any authentication service to delegate
    msDSAllowedToDelegateTo                     - list of SPNs the account is allowed to delegate to

.LINK
    UserAccountControl flags to manipulate user account properties
    https://learn.microsoft.com/en-GB/troubleshoot/windows-server/identity/useraccountcontrol-manipulate-account-properties
    https://learn.microsoft.com/en-us/windows-server/security/group-managed-service-accounts/configure-kerberos-delegation-group-managed-service-accounts
#>
function Get-KerberosDelegation {
    [CmdletBinding(DefaultParameterSetName='sam')]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'sam', Position=0)]
        [Alias('sam')]
            [String[]]$SamAccountName,
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'dn', Position=0)]
        [Alias('dn')]
            [String[]]$DistinguishedName,
        [Parameter()]
            [Switch]$ExcludeDomainControllers
    )
 
    begin {
        $properties = @(
            'ServicePrincipalName'
            'UserAccountControl'
            'SamAccountName'
            'msDS-AllowedToDelegateTo'
            'msDS-AllowedToActOnBehalfOfOtherIdentity'
        )
 
        $domain = (Get-ADDomain).DistinguishedName
 
        $SERVER_TRUST_ACCOUNT           = 0x2000
        $TRUSTED_FOR_DELEGATION         = 0x80000
        $TRUSTED_TO_AUTH_FOR_DELEGATION = 0x1000000
        $PARTIAL_SECRETS_ACCOUNT        = 0x4000000
        $bitmask                        = $TRUSTED_FOR_DELEGATION -bor $TRUSTED_TO_AUTH_FOR_DELEGATION -bor $PARTIAL_SECRETS_ACCOUNT
 
        # LDAP filter to find all accounts having some form of delegation.
        # 1.2.840.113556.1.4.804 is an OR query.
$filter = @"
(&
    (servicePrincipalName=*)
    (|
    (msDS-AllowedToActOnBehalfOfOtherIdentity=*)
    (msDS-AllowedToDelegateTo=*)
    (UserAccountControl:1.2.840.113556.1.4.804:=$bitmask)
    )
    (|
    (objectcategory=computer)
    (objectcategory=person)
    (objectcategory=msDS-GroupManagedServiceAccount)
    (objectcategory=msDS-ManagedServiceAccount)
    )
)
"@ -replace "[\s\n]", ''
    }
 
    process {
        $object = if ($PSBoundParameters.ContainsKey('SamAccountName')) {
            Write-Verbose 'BySamAccountName'
            $samAccountName | foreach { Get-ADObject -Filter "SamAccountName -eq '$_'" -Properties $properties }
        }
        elseif ($PSBoundParameters.ContainsKey('distinguishedName')) {
            Write-Verbose 'ByDistinguishedName'
            $distinguishedName | foreach { Get-ADObject -Identity $dn -Properties $properties }
        }
        else {
            Write-Verbose 'All'
            Get-ADObject -LDAPFilter $filter -SearchBase $domain -SearchScope Subtree -Properties $properties
        }
 
        $result = $object | ForEach-Object {
            if ($_ -is [Microsoft.ActiveDirectory.Management.ADObject]) {
                $dn                                      = $_.DistinguishedName
                $isDomainController                      = ($_.UserAccountControl -band $SERVER_TRUST_ACCOUNT) -ne 0
                $isReadOnlyDC                            = ($_.UserAccountControl -band $PARTIAL_SECRETS_ACCOUNT) -ne 0
                $unconstrainedDelegation                 = ($_.UserAccountControl -band $TRUSTED_FOR_DELEGATION) -ne 0
                $constrainedDelegationProtocolTransition = ((($_.'msDS-AllowedToDelegateTo').count -gt 0) -and $adObject.TrustedToAuthForDelegation)
                $constrainedDelegation                   = ($_.'msDS-AllowedToDelegateTo').count -gt 0
                $msDSAllowedToDelegateTo                 = ($_.'msDS-AllowedToDelegateTo') -join ','
                $resourceDelegation                      = ($null -ne $_.'msDS-AllowedToActOnBehalfOfOtherIdentity')
 
                switch ($_.ObjectClass) {
                    'computer' {
                        Write-Verbose 'computer'
                        $adObject = Get-ADComputer -Filter "DistinguishedName -eq '$dn'" -Properties ServicePrincipalName, PrincipalsAllowedToDelegateToAccount, TrustedForDelegation, TrustedToAuthForDelegation, 'msDS-AllowedToActOnBehalfOfOtherIdentity'
                        break
                    }
                    'user' {
                        Write-Verbose 'user'
                        $adObject = Get-ADUser -Filter "DistinguishedName -eq '$dn'" -Properties ServicePrincipalName, PrincipalsAllowedToDelegateToAccount, TrustedForDelegation, TrustedToAuthForDelegation, 'msDS-AllowedToActOnBehalfOfOtherIdentity'
                        break
                    }
                    'msDS-ManagedServiceAccount' {
                        Write-Verbose 'msDS-ManagedServiceAccount'
                        $adObject = Get-ADServiceAccount -Filter "DistinguishedName -eq '$dn'" -Properties ServicePrincipalName, PrincipalsAllowedToDelegateToAccount, TrustedForDelegation, TrustedToAuthForDelegation, 'msDS-AllowedToActOnBehalfOfOtherIdentity'
                        break
                    }
                    'msDS-GroupManagedServiceAccount' {
                        Write-Verbose 'msDS-GroupManagedServiceAccount'
                        $adObject = Get-ADServiceAccount -Filter "DistinguishedName -eq '$dn'" -Properties ServicePrincipalName, PrincipalsAllowedToDelegateToAccount, TrustedForDelegation, TrustedToAuthForDelegation, 'msDS-AllowedToActOnBehalfOfOtherIdentity'
                        break
                    }
                    Default {
                        Write-Verbose 'Default'
                        Write-Warning "Unknown Class type"
                    }
                }
 
                [PSCustomObject] @{
                    SamAccountName                          = $adObject.SamAccountName
                    Name                                    = $adObject.Name
                    Enabled                                 = $adObject.Enabled
                    objectClass                             = $adObject.ObjectClass
                    UnconstrainedDelegation                 = $unconstrainedDelegation
                    ConstrainedDelegation                   = $constrainedDelegation
                    ConstrainedDelegationProtocolTransition = $constrainedDelegationProtocolTransition
                    ResourceBasedConstrainedDelegation      = $resourceDelegation
                    UserAccountControl                      = $_.UserAccountControl
                    UserAccountControlHex                   = ('{0:x}' -f $_.UserAccountControl)
                    UserAccountControlFlag                  = (Get-UserAccountControlFlag $_.SamAccountName)
                    TrustedForDelegation                    = $adObject.TrustedForDelegation
                    TrustedToAuthForDelegation              = $adObject.TrustedToAuthForDelegation
                    isDomainController                      = $isDomainController
                    isReadOnlyDC                            = $isReadOnlyDC
                    msDSAllowedToDelegateTo                 = $msDSAllowedToDelegateTo
                    ServicePrincipalName                    = $adObject.ServicePrincipalNames
                    PrincipalsAllowedToDelegateToAccount    = $($adObject.principalsAllowedToDelegateToAccount -join '; ')
                    # msDSAllowedToActOnBehalfOfOtherIdentity = $($adObject.'msDS-AllowedToActOnBehalfOfOtherIdentity'.Access)
                    # Comment                                 = $($comment -join '; ')
                }
            }
            else {
                Write-Warning "AD Object not found. If the account is a computer or MSA account then ensure it includes the '$'"
            }
        }
    }
 
    end {
        if ($ExcludeDomainControllers) {
            $result | Where-Object isDomainController -eq $false
        }
        else {
            $result
        }
    }
}