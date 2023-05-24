<#
.DESCRIPTION
    Describe the purpose of this script
.NOTES
    Author					Jacob C Allen
    Created					05-11-2023
    Modified				-
    Modified By				-
    Version					v1.0
#>
Function Test-LDAPPorts {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
            [String] $ServerName,
        [Parameter(Mandatory)]
            [Int] $Port
    )
    Try {
        $LDAP       = "LDAP://" + $ServerName + ':' + $Port
        $Connection = [ADSI]($LDAP)
        $Connection.Close()
        Return $true
    } Catch {
        If ($PSItem.Exception.ToString() -match "The server is not operational") {
            Write-Warning "Can't open $ServerName`:$Port."
        } ElseIf ($PSItem.Exception.ToString() -match "The user name or password is incorrect") {
            Write-Warning "Current user ($env:USERNAME) doesn't seem to have access to to LDAP on port $ServerName`:$Port"
        } Else {
            Write-Warning -Message $PSItem
        }
    }
    Return $false
} # Function Test-LDAPPorts