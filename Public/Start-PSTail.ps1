<#
.SYNOPSIS
    Short Description of Function
.PARAMETER Path
    Description for $FilePath
.PARAMETER LinesToView
    Number of lines to tail. (Default = 20)
.EXAMPLE
    PS C:\> Start-PSTail -FilePath "C:\Path\To\File.txt"

    Opens new PwSh window and tails "C:\Path\To\File.txt" showing the last 20 lines
.INPUTS
    String
    Int
.NOTES
    Author		Jacob C Allen
    Created		11-02-2022
    Modified	11-02-2022
    Version		1.0
#>
Function Start-PSTail {
    [CmdLetBinding()]
    [Alias('tail')]
    Param (
        [Parameter(Position = 0, Mandatory)]
        [ValidateScript({
            Get-ChildItem -Path $PSItem
        })]
            [String]$FilePath,
        [Parameter(Position = 1)]
        [ValidateRange(1,500)]
            [Int]$LinesToView = 20
    )
    Begin {
        $FileItem       = Get-ChildItem -Path $FilePath
        $ConsoleTitle   = ("[tail] {0}" -F ($FileItem.Directory.Name,$FileItem.Name -Join '\'))
        $ArgCatCmd      = ("[Console]::Title='{0}';Get-Content -Path {1} -Tail {2} -Wait" -F $ConsoleTitle,$PSBoundParameters['FilePath'],$LinesToView)

        $ArgumentList   = '-NoProfile',"-NoLogo"
        $ArgumentList   += ('-Command "Remove-Module PSReadline -ErrorAction SilentlyContinue;{0}"' -F $ArgCatCmd )
    } # Begin
    Process {
        $PSVers = If ($env:Path -match 'PowerShell\\7') {
            'PwSh'
        } Else {
            'PowerShell'
        }

        Start-Process $PSVers -ArgumentList $ArgumentList
    } # Process
} # Function Start-PSTail