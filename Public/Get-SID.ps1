<#
.SYNOPSIS
    Returns the SID for a specified SamAccountName
.PARAMETER SAM
    SamAccountName to use
.EXAMPLE
    PS C:\> Get-SID -SAM jallen

    Returns the SID for the account belonging to jallen
#>
Function Get-SID {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [Alias("SAMAccountName")]
        [string]$SAM
    )
    
    $objUser    = [System.Security.Principal.NTAccount]::New($SAM)
    $strSID     = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
    $strSID.Value
} # Function Get-SID
