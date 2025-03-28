<#
.SYNOPSIS
    Short Description of Function
.PARAMETER ByteArray
    Description for ByteArray
.EXAMPLE
    PS C:\> ConvertTo-Hexadecimal -ByteArray

    Short explanation for example
.NOTES
    Author			Jacob C Allen
    Created			02-11-2025
    Modified		-
    Modified By		-
    Version			v1.0
#>
Function ConvertTo-Hexadecimal {
    [CmdLetBinding(DefaultParameterSetName='Array')]
    Param (
        [Parameter(ValueFromPipeline,ValueFromRemainingArguments,ParameterSetName='Array')]
        [Alias('Array')]
            [Byte[]]$ByteArray,
        [Parameter(ParameterSetName='Single')]
        [Alias('Value')]
            [Byte]$ByteValue,
        [Parameter(ParameterSetName='Array')]
        [ValidateSet('GUID','String')]
            [String]$As = 'GUID'
    )
    Begin {
        $strHex = [System.Collections.ArrayList]::New()
    } # Begin
    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Array' {
                $ByteArray |
                    ForEach-Object {
                        [void]$strHex.add(($PSItem | ForEach-Object ToString X2))
                    }
                
            }
            'Single' {
                $ByteValue |
                    ForEach-Object {
                        [void]$strHex.add(($PSItem | ForEach-Object ToString X2))
                    }
            }
        }
    } # Process
    End {
        Switch ($PSCmdlet.ParameterSetName) {
            'Array' {
                Switch ($As) {
                    'GUID' {
                        [Guid]::Parse(($strHex -Join '')).Guid
                    }
                    'String' {
                        $strHex -Join ''
                    }
                }
            }
            'Single' {
                $strHex
            }
        }
    } # End
} # Function ConvertTo-Hexadecimal