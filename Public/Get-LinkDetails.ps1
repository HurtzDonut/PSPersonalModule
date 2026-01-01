<#
.DESCRIPTION
    Gets metadata details for shortcut (link) files
.NOTES
    Author					Jacob C Allen
    Created					06-12-2025
    Modified				-
    Modified By				-
    Version					v1.0
#>
Function Get-LinkDetails {
    [CmdletBinding()]
    [Alias('Get-ShortcutDetails','glnk')]
    Param (
        [Parameter(Mandatory)]
            [String]$Path,
        [Parameter()]
            [Switch]$Recurse,
        [Parameter()]
            [Int]$Depth = 2
    )
    Begin {
        $getSplat = @{
            Path    = $Path
            File    = $True
            Filter  = '*.lnk'
            Depth   = $Depth
        }
        
        $getSplat['Recurse'] = If ($Recurse.IsPresent) {
            $True
        } Else {
            $False
        }
    } # Begin Block
    Process {
        Get-ChildItem @getSplat |
            ForEach-Object {
                $shortcutPath   = $_.Fullname
                $shell          = New-Object -ComObject WScript.Shell
                $shortcut       = $shell.CreateShortcut($shortcutPath)
                
                If ($shortcut.TargetPath -match 'TAWK16FS01') {
                    $PSItem | Select-Object FullName,
                                            Length,
                                            LastWriteTime,
                                            @{n = 'User'; e = {$_.Directory.Parent.Name}},
                                            @{n = 'Target'; e = {$shortcut.TargetPath}}
                }
            } |
                Select-Object FullName, Length, LastWriteTime, User, Target
    } # Process Block
} # Function Get-LinkDetails