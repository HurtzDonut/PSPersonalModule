<#
.SYNOPSIS
    Return object from Active Directory without requiring the ActiveDirectory module
.PARAMETER Identity
    Description for Identity
.EXAMPLE
    PS C:\> Get-ADSIObject -Identity

    Short explanation for example
.NOTES
    Author			Jacob C Allen
    Created			06-12-2024
    Modified		06-13-2024
    Modified By		Jacob C Allen
    Version			v1.0
#>
Function Get-ADSIObject {
    [CmdLetBinding(DefaultParameterSetName = 'SAM')]
    Param (
        [Parameter(ParameterSetName = 'SAM',Mandatory,Position = 0)]
            [String]$SamAccountName,
        [Parameter(ParameterSetName = 'Name')]
            [String]$Name,
        [Parameter(ParameterSetName = 'ID')]
            [Int]$EmployeeID,
        [Parameter(ParameterSetName = 'Filter')]
            [String]$LdapFilter
    )
    Begin {
        $results    = [System.Collections.ArrayList]::New()
        $dc         = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner.Name
        
        $filter = Switch ($PSCmdlet.ParameterSetName) {
            'SAM' {
                'samaccountname={0}' -F $SamAccountName
            }
            'Name' {
                'name={0}*"' -F $Name
            }
            'ID' {
                'employeeid={0}*' -F $EmployeeID
            }
            'Filter' {
                $LdapFilter
            }
        }

        
        If ($env:USERDOMAIN -ne 'CNHSA') {
            $cred       = Get-Credential -Message 'Credential needed for ADSI query'
            $adsi       = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$dc", $cred.UserName, $cred.GetNetworkCredential().Password)
        } Else {
            $adsi   = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$dc")
        }
    } # Begin
    Process {
        $searcher   = [DirectoryServices.DirectorySearcher]::New($adsi, $filter)
    } # Process
    End {
        $searcher.FindAll() |
            ForEach-Object {
                [Void]$results.Add($PSItem.Properties)
            }

        $results
    } # End
} # Function Get-ADSIObject