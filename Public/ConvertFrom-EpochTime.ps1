<#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
#>
Function ConvertFrom-EpochTime {
    [CmdLetBinding()]
    [Alias('FromUnix','ConvertFrom-UnixTime')]
    Param (
        [Parameter()]
            [String]$EpochTime
    ) 
    
    Process {
        [TimeZone]::CurrentTimeZone.ToLocalTime(([DateTime]'1/1/1970').AddSeconds($EpochTime)).ToString('dddd, MMMM dd, yyy')
    }
} # Function ConvertFrom-EpochTime