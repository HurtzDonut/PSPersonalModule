<#
.SYNOPSIS
    Converts a string(s), or individual character(s), to its corresponding ASCII byte value(s).
.DESCRIPTION
    Converts a string(s), or individual character(s), using the .NET method [System.Text.Encoding]::ASCII.GetBytes(), to 
        their corresponding ASCII byte value(s).
.PARAMETER Character
    Array of character(s) to convert.
.PARAMETER String
    Array of string(s) to convert.
.PARAMETER AsChar
    Specifies to convert the entire input as one set of characters, rather than converting by string.
.EXAMPLE
    PS C:\> ConvertTo-AsciiByte -Character a,b,c,`!,`@,`#
    
    Character ASCII_Byte
    --------- ----------
    a                 97
    b                 98
    c                 99
    !                 33
    @                 64
    #                 35
.EXAMPLE
    PS C:\> 'Jacob','Allen' | ConvertTo-AsciiByte
    ----------------------
    Original String: Jacob
    ----------------------
    74
    97
    99
    111
    98
    ----------------------
    Original String: Allen
    ----------------------
    65
    108
    108
    101
    110
.EXAMPLE
    PS C:\> 'Jacob','Allen' | ConvertTo-AsciiByte -AsChar

    Character ASCII_Byte
    --------- ----------
            J         74
            a         97
            c         99
            o        111
            b         98
            A         65
            l        108
            l        108
            e        101
            n        110
.INPUTS
    System.String[]
.OUTPUTS
    PSCustomObject
.NOTES
    Author:     Jacob C Allen (JCA)
    Created:    01/16/2019
    Modified:   01/16/2019
    Alias:      ctascii
#>
Function ConvertTo-AsciiByte {
    [CmdLetBinding(DefaultParameterSetName='String')]
    [Alias('ctascii')]
    Param ( 
        [Parameter(ParameterSetName='Character')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,1)]
            [String[]]$Character,

        [Parameter(ValueFromPipeline,ParameterSetName='String')]
        [ValidateNotNullOrEmpty()]
            [String[]]$String,

        [Parameter(ParameterSetName='String')]
            [Switch]$AsChar
    )

    Process {
        $Results = [System.Collections.ArrayList]::New()
        
        $Array = Switch ($PSCmdlet.ParameterSetName) {
            'Character' { $Character }
            'String'    { $String.ToCharArray() }
        }
        
        ForEach ($Entry in $Array) {
            [Void]$Results.Add(
                [PSCustomObject][Ordered]@{
                    Character   = If($Entry -eq ' '){'[SPACE]'}Else{$Entry}
                    ASCII_Byte  = ([System.Text.Encoding]::ASCII.GetBytes($Entry) | ForEach-Object { $PSItem })
                }
            )
        }
        
        If (($PSCmdlet.ParameterSetName -eq 'String') -and (!$AsChar)) {
            $OriginalString = $Array -Join ''
            Write-Output ('{0}{1}Original String: {2}{3}{4}' -F $('-' * (17 + $OriginalString.Length)),[Environment]::NewLine,$OriginalString,[Environment]::NewLine,$('-' * (17 + $OriginalString.Length)))
            
            $Results | Select-Object -ExpandProperty ASCII_Byte
        } Else {
            $Results
        }
    }
} # Function ConvertTo-AsciiByte