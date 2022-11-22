<#
.SYNOPSIS
    Placeholder function for SSH alias
.DESCRIPTION
    *Nix aliasing allows aliases to include both commands AND parameters
    PwSh aliasing ONLY allows commands.

    To get around this, we can create a function that has our desired alias contents.

    Example
        *nix
            :~$ alias <alias>='<command> <param1> <param2>'
        PwSh default
            PS C:\> New-Alias -Name <alias> -Value <command>
        PwSh workaround
            PS C:\> Function Write-Something {<command> <param1> <param2>}
            PS C:\> New-Alias -Name <alias> -Value Write-Something
.PARAMETER ComputerName
    Machine name to initiate ssh with
.NOTES
    Created as a workaround to mimic *nix aliasing

    Author		Jacob C Allen
    Created		11-22-2022
    Modified	11-22-2022
    Version		1.0
#>
Function Start-SSH {
    [CmdletBinding()]
    [Alias('ssh')]
    Param (
        [Parameter(Mandatory)]
            [String]$ComputerName,
        [Parameter()]
            [String]$ConfigFile = 'H:\.ssh\config'
    )    
    . "C:\Windows\System32\OpenSSH\ssh.exe" $ComputerName -F $ConfigFile
} # Function Start-SSH