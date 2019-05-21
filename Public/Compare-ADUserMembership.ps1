<#
    .SYNOPSIS
        Compares the ActiveDirectory group memberships for two (2) users.
    .DESCRIPTION
        Retreives all ActiveDirectory group memberships for two (2) users, then compares them and displays the results
    .PARAMETER ReferenceUser
        Either the SamAccountName, or the ActiveDirectory User Object, for the reference user.
    .PARAMETER DifferenceUser
        Either the SamAccountName, or the ActiveDirectory User Object, for the difference user.
    .EXAMPLE
        PS C:\> Compare-ADGroupMembership -ReferenceUser 'aduser1' -DifferenceUser 'aduser2'
        
        ReferenceUserUniqueGroups   DifferenceUserUniqueGroups    CommonGroups
        -------------------------   --------------------------    ------------
        HelpDesk                    ITSystemAdmin                 IT Users
                                    PhoneAdmin                    PasswordReset
    .EXAMPLE
        PS C:\> $RUser = Get-ADUser -Identity aduser2
        PS C:\> $DUser = Get-ADUser -Identity aduser1
        PS C:\> $RUser | Compare-ADGroupMembership -DifferenceUser $DUser

        ReferenceUserUniqueGroups   DifferenceUserUniqueGroups    CommonGroups
        -------------------------   --------------------------    ------------
        ITSystemAdmin               HelpDesk                      IT Users
        PhoneAdmin                                                PasswordReset
    .INPUTS
        System.String
        Microsoft.ActiveDirectory.Management.ADUser
    .OUTPUTS
        System.Object[]
    .NOTES
        Author      Jacob C Allen (JCA)
        Created     5/21/2019
        Modified    5/21/2019
        Version     1.0

        Inspiration Post
            https://www.reddit.com/r/PowerShell/comments/bqw1lw/help_with_ad_comparison_tool/
#>
Function Compare-ADUserMembership {
    #Requires -Modules ActiveDirectory
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateScript({
            $Type = $PSitem.GetType().FullName
            If ($Type -eq 'System.String' -or $Type -eq 'Microsoft.ActiveDirectory.Management.ADUser') {
                $True
            } Else {
                Throw 'Invalid Parameter type! Must be either System.String or Microsoft.ActiveDirectory.Management.ADUser!'
            }
        })]
            $ReferenceUser,

        [Parameter(Mandatory)]
        [ValidateScript({
            $Type = $PSitem.GetType().FullName
            If ($Type -eq 'System.String' -or $Type -eq 'Microsoft.ActiveDirectory.Management.ADUser') {
                $True
            } Else {
                Throw 'Invalid Parameter type! Must be either System.String or Microsoft.ActiveDirectory.Management.ADUser!'
            }
        })]
            $DifferenceUser
    )
    
    Begin {
        $Result = [System.Collections.ArrayList]::New()
    } # Begin Block

    Process {
        Try {
            # Determine if we need to retrieve the ActiveDirectory User Object, or not
            $User1 = Switch ($ReferenceUser.GetType().FullName) {
                'System.String' {
                    Get-ADUser -Identity $ReferenceUser -ErrorAction Stop
                    Continue
                }
                'Microsoft.ActiveDirectory.Management.ADUser' {
                    $ReferenceUser
                    Continue
                }
            }

            # Determine if we need to retrieve the ActiveDirectory User Object, or not
            $User2 = Switch ($DifferenceUser.GetType().FullName) {
                'System.String' {
                    Get-ADUser -Identity $DifferenceUser -ErrorAction Stop
                    Continue
                }
                'Microsoft.ActiveDirectory.Management.ADUser' {
                    $DifferenceUser
                    Continue
                }
            }
        } Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            # Throw an error if ActiveDirectory is unable to locate a user object
            $InvalidUser = $PSitem.Exception.Message -Replace '(.+identity:\s)(.+)(under:.+)', '$2'
            
            Write-Warning ('Unable to locate user [{0}]. Verify Username and try again.' -F $InvalidUser)
            Break
        }
        
        # See 'Examples' section here: https://social.technet.microsoft.com/wiki/contents/articles/5392.active-directory-ldap-syntax-filters.aspx
        # Query:    All groups specified user belongs to, including due to group nesting
        # LDAP Filter: (member:1.2.840.113556.1.4.1941:=cn=Jim Smith,ou=West,dc=Domain,dc=com)
        $Member1            = Get-ADGroup -LDAPFilter ('(member:1.2.840.113556.1.4.1941:={0})' -F $User1.DistinguishedName)
        $Member2            = Get-ADGroup -LDAPFilter ('(member:1.2.840.113556.1.4.1941:={0})' -F $User2.DistinguishedName)

        # Compare groups, including common (shared) groups
        $Comparison         = Compare-Object -ReferenceObject $Member1 -DifferenceObject $Member2 -Property Name -IncludeEqual
    } # Process Block
    
    End {
        # Determine which groups belong where
        $ReferenceGroups    = ($Comparison | Where-Object SideIndicator -eq '<=').Name | Sort-Object
        $DifferenceGroups   = ($Comparison | Where-Object SideIndicator -eq '=>').Name | Sort-Object
        $CommonGroups       = ($Comparison | Where-Object SideIndicator -eq '==').Name | Sort-Object
        
        # Get the largest number between the group counts, so we know how many rows to add in $Result
        $ListCount = ($ReferenceGroups.Count,$DifferenceGroups.Count,$CommonGroups.Count|Sort-Object -Descending)[0]

        # Iterate through the groups and add them to $Result
        For ($i = 0;$i -lt $ListCount;$i++) {
            [Void]$Result.Add(
                [PSCustomObject][Ordered]@{
                    ReferenceUserUniqueGroups   = $ReferenceGroups[$i]
                    DifferenceUserUniqueGroups  = $DifferenceGroups[$i]
                    CommonGroups                = $CommonGroups[$i]
                }
            )
        }

        # Display the results
        $Result
    } # End Block
} # Function Compare-ADUserMembership