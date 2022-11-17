<#
.SYNOPSIS
    Gets all direct reports listed in AD, recursively, for a given name
.PARAMETER SamAccountName
    Parameter description
.EXAMPLE
    PS C:\> Get-ADRecursiveDirectReports -SamAccountName aduser1
.NOTES
    Author      Jacob C Allen
    Created     11/17/2022
    Version     1.0
#>
Function Get-ADRecursiveDirectReports {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
            [String]$SamAccountName
    ) 
    $DirectReports = Get-ADUser -Filter "Manager -eq '$SamAccountName'" -Properties Manager
    
    If(![String]::IsNullOrEmpty($DirectReports)) {
        Write-Output $DirectReports
        
        $DirectReports |
            ForEach-Object {
                Get-ADRecursiveDirectReports -SamAccountName $PSItem.DistinguishedName
            }    
    }
} # Function Get-ADRecursiveDirectReports