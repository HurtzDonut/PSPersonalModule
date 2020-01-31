<#
.SYNOPSIS
    Opens docs.microsoft.com search page for a given cmdlet
.NOTES
    Author		Jacob Allen
    Created		12-03-2019
    Modified	12-03-2019
    Version		1.0
#>
Function Get-MSDocHelp {
    [CmdLetBinding()]
    [Alias('dhelp')]
    Param (
        [Parameter(Mandatory,Position = 0)]
            [String]$CmdLetName
    )
    Process {
        $Url = ('https://docs.microsoft.com/en-us/search/?search={0}&category=Reference' -F $CmdLetName)

        Start-Process "C:\Program Files\Mozilla Firefox\firefox.exe" "$Url"
    } # Process
} # Function Get-MSDocHelp