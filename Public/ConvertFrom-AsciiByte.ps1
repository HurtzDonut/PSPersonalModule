<#
.SYNOPSIS
    Converts an array of bytes to the corresponding ASCII character.
.DESCRIPTION
    Converts bytes ([Int[]]), using the .NET method [System.Text.Encoding]::ASCII.GetString(), to 
        their corresponding ASCII characters.
.PARAMETER Byte
    Byte(s) ([Int[]]), to convert to ASCII character(s).
.EXAMPLE
    PS C:\> ConvertFrom-AsciiByte -Byte (95..100)
    
    ASCII Byte Character
    ---------- ---------
            95 _
            96 `
            97 a
            98 b
            99 c
           100 d
.EXAMPLE
    PS C:\> 95..100 | ConvertFrom-AsciiByte

    ASCII Byte Character
    ---------- ---------
            95 _
            96 `
            97 a
            98 b
            99 c
           100 d
.INPUTS
    System.Int[]
.OUTPUTS
    PSCustomObject
.NOTES
    Author:     Jacob C Allen (JCA)
    Created:    01/16/2019
    Modified:   01/16/2019
    Alias:      cfascii
#>
Function ConvertFrom-AsciiByte {
    [CmdLetBinding()]
    [Alias('cfascii')]
    Param ( 
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
            [Int[]]$Byte
    )

    Process {
        ForEach ($Num in $Byte) {
            [PSCustomObject]@{
                'ASCII Byte'    = $Num
                Character       = [System.Text.Encoding]::ASCII.GetString($Num) | ForEach-Object { $PSItem }
            }
        }
    }
} # Function ConvertFrom-AsciiByte