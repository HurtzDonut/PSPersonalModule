<#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> $Hashtable = [Ordered]@{First="Hello";Second="World";"Th ird"="I'm Dave"}
        PS C:\> $Hashtable

        Name   Value
        ----   -----
        First  Hello
        Second World
        Th ird I'm Dave

        PS C:\> ConvertTo-HashString $Hashtable

        @{First="Hello";Second="World";"Th ird"="I'm Dave";}

        
        Outputs a hashtable/ordereddictionary as a string in the hash literal format.
    .INPUTS
        System.Collections.Hashtable
        System.Collections.Specialized.OrderedDictionary
    .OUTPUTS
        System.String
    .NOTES
        Created:    5/14/2019
        Author:     Jacob C Allen (JCA)
        Modified:   5/14/2019
        Version:    1.1
        Link:       https://www.reddit.com/r/PowerShell/comments/boc96v/visibly_show_hashtable/
#>
Function ConvertTo-HashString {
    Param (
        [Parameter(Mandatory,Position=0)]
            $Hash
    )
    
    Begin {
        $Result = [System.Collections.ArrayList]::New()
        $Type   = $Hash.GetType()
            
        If ($Type -NotIn ([System.Collections.Hashtable],[System.Collections.Specialized.OrderedDictionary])) {
            $Message    = 'Parameter is of an invalid type. Valid types: [System.Collections.Hashtable]|[System.Collections.Specialized.OrderedDictionary]'
            Write-Error -Message $Message -Category 'InvalidArgument' -ErrorId (0xD1C14).ToString('X8') -TargetObject $Type
            Break
        }
    } # Begin Block

    Process {
        $StringStart = Switch ($Type.FullName) {
            'System.Collections.Hashtable'                      { "@{" }
            'System.Collections.Specialized.OrderedDictionary'  { "[Ordered]@{" }
        }

        $Hash.GetEnumerator() | ForEach-Object {
            [Void]$Result.Add($(
                If ($PSItem.Name -match '\s') {
                    ('"{0}"="{1}"' -F $PSItem.Name,$PSItem.Value)
                } Else {
                    ('{0}="{1}"' -F $PSItem.Name,$PSItem.Value)
                }
            ))
        }
    } # Process Block
    
    End {
        $StringStart,($Result -Join ';'),'}' -Join ''
    } # End Block
} # Function ConvertTo-HashString