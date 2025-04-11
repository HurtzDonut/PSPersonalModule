<#
.SYNOPSIS
    Gets all direct reports listed in AD, recursively, for a given name
.PARAMETER SamAccountName
    Parameter description
.EXAMPLE
    PS C:\> Get-ADRecursiveDirectReports -SamAccountName aduser1
.NOTES
    Author          Jacob C Allen
    Created         11/17/2022
    Modified        04-11-2025
    Modified By     Jacob C Allen
    Version         1.1
#>
Function Get-ADRecursiveDirectReports {
    [CmdletBinding(DefaultParameterSetName='Default')]
    Param(
        [Parameter(Mandatory,ParameterSetName='Default')]
        [Parameter(Mandatory,ParameterSetName='Custom')]
            [String]$SamAccountName,
        [Parameter(ParameterSetName='Custom')]
            [String]$SearchBaseForDirectReports
    )

    $DirectReports = Switch ($PSCmdlet.ParameterSetName) {
        'Default' {
            Get-ADUser -Filter "Manager -eq '$SamAccountName'" -Properties Manager
        }
        'Custom' {
            Get-ADUser -Filter "Manager -eq '$SamAccountName'" -Properties Manager -SearchBase $SearchBaseForDirectReports
        }
    }

    If(![String]::IsNullOrEmpty($DirectReports)) {
        Write-Output $DirectReports

        $DirectReports |
            ForEach-Object {
                Get-ADRecursiveDirectReports -SamAccountName $PSItem.DistinguishedName
            }    
    }
} # Function Get-ADRecursiveDirectReports