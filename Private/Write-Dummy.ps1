<#
.SYNOPSIS
    Short Description of Function
.PARAMETER Nada
    Description for $Nada
.EXAMPLE
    PS C:\> Write-Dummy -Nada

    Short explanation for example
.NOTES
    Author		Jacob Allen
    Created		11-22-2022
    Modified	11-22-2022
    Version		1.0
#>
Function Write-Dummy {
    [CmdLetBinding()]
    Param (
        [Parameter()]
        [AllowNull()]
            [String]$Nada
    )
    Process {
        Write-Host $Nada
    } # Process
} # Function Write-Dummy