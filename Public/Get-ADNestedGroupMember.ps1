<#
.SYNOPSIS
    Returns all group members of an AD group, including those from nested groups.
.DESCRIPTION
    Uses a custom LDAP filter to return all members of specified group, including due to group nesting.
.PARAMETER GroupName
    Name of the Active Directory group to search
.EXAMPLE
    PS C:\> Get-ADNestedGroupMember -GroupName ADGroup1
.NOTES
    Author      _Cabbage_Corp_
    Created     06/11/2019
    Version     1.0
#>
Function Get-ADNestedGroupMember {
    [CmdLetBinding()]
    Param(
        [Parameter()]
            [String]$GroupName
    )
    Process {
        Try {
            $ADGroup = Get-ADGroup -Identity $GroupName -ErrorAction Stop
        } Catch {
            Write-Warning ('Unable to locate AD Group [{0}]' -F $GroupName)
            Break
        }

        Get-ADUser -LDAPFilter ('(memberOf:1.2.840.113556.1.4.1941:={0})' -F $ADGroup.DistinguishedName)
    } # Process Block
} # Function Get-ADNestedGroupMember