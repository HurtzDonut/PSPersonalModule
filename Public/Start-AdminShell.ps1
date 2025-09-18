<#
.SYNOPSIS
    Short Description of Function
.PARAMETER UserName
    Description for UserName
.EXAMPLE
    PS C:\> Start-AdminShell -UserName 'adminUser' -Shell pwsh

    1. Requests password for '$ENV:USERDNSDOMAIN\adminuser'
    2. Attempts to open 'pwsh' as '$ENV:USERDNSDOMAIN\adminuser'
.EXAMPLE
    PS C:\> Start-AdminShell -UserName 'adminUser' -Shell cmd

    1. Requests password for '$ENV:USERDNSDOMAIN\adminuser'
    2. Attempts to open 'cmd' as '$ENV:USERDNSDOMAIN\adminuser'
.EXAMPLE
    PS C:\> Start-AdminShell -UserName 'adminUser' -Shell pwsh -NoProfile

    1. Requests password for '$ENV:USERDNSDOMAIN\adminuser'
    2. Attempts to open 'pwsh' as '$ENV:USERDNSDOMAIN\adminuser' with the 'NoProfile' parameter
.NOTES
    Author			Jacob C Allen
    Created			09-17-2025
    Modified		09-18-2025
    Modified By		Jacob C Allen
    Version			v1.1
#>
Function Start-AdminShell {
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory)]
            [String]$UserName,
        [Parameter()]
            [String]$Domain = $ENV:USERDNSDOMAIN,
        [Parameter(Mandatory)]
        [ValidateSet('pwsh','powershell','cmd')]
            [String]$Shell,
        [Parameter()]
        [ValidateScript({
            If ($Shell -ne 'cmd') {
                $True
            } Else {
                Throw '"-NoProfile" is only valid for PowerShell/PwSh'
            }
        })]
            [Switch]$NoProfile
            
    )
    Begin {
        $runString = If ($Shell -eq 'cmd') {
            $Shell
        } Else {
            '{0} -NoLogo' -F $Shell
        }
    } # Begin
    Process {
        If ($NoProfile.IsPresent) {
            $runString += ' -NoProfile'
        }
    } # Process
    End {
        runas /user:$Domain\$UserName $runString
    } # End
} # Function Start-AdminShell