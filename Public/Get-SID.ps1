
Function Get-SID {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
        [Alias("SAMAccountName")]
        [string]$SAM
    )
    
    $objUser    = New-Object System.Security.Principal.NTAccount($SAM)
    $strSID     = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
    $strSID.Value
} # Function Get-SID
