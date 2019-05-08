<#
    .SYNOPSIS
        Returns the site code for the specified computer.
    .DESCRIPTION
        Queries the registry of a specified computer and returns value of the 'Site-Name' property found in 'HKLM:\..\Group Policy\..\Machine'.
    .EXAMPLE
        PS C:\> $Comps = 'LX190FHN','L7040RXZ','L7520026','LX093S3B' | ForEach-Object {Get-ADComputer -Identity $PSItem}
        PS C:\> $Comps | Get-ComputerSite
        WARNING: [LX190FHN] : Unable to connect to computer. Skipping.

        ComputerName SiteName
        ------------ --------
        L7040RXZ     GOC
        L7520026     DC
        LX093S3B     OC

        Verfies the connectivity of each computer in $Comps, and if available, returns the site name for each.
    .EXAMPLE
        PS C:\> $Comps = 'LX190FHN','L7040RXZ','L7520026','LX093S3B'
        PS C:\> Get-ComputerSite -Name $Comps
        WARNING: [LX190FHN] : Unable to connect to computer. Skipping.

        ComputerName SiteName
        ------------ --------
        L7040RXZ     GOC
        L7520026     DC
        LX093S3B     OC

        Verfies the connectivity of each computer in $Comps, and if available, returns the site name for each.        
    .INPUTS
        System.String
    .OUTPUTS
        PSCustomObject
    .NOTES
        Author:         /u/nemanja_jovic
        Created On:     2/27/2019
        Original Post:  https://www.reddit.com/r/PowerShell/comments/avdc01/question_valuefrompipelinebypropertyname/
        
        Modified By:    Jacob Allen
        Modified On:    2/27/2019
#>
Function Get-ComputerSite {
    [CmdletBinding()]
    [Alias('pcsite')]
    Param (
        [Parameter(ValueFromPipelineByPropertyName, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName')]
            [String[]]$Name = $env:ComputerName
    )
    
    Process {
        ForEach ($Machine in $Name) {
            If (!(Test-Connection -ComputerName $Machine -Count 1 -Quiet)) {
                Write-Warning ('[{0}] : Unable to connect to computer. Skipping.' -F $Machine)
            } Else {
                Try {
                    $SiteSplat = @{
                        ComputerName= $Machine
                        ScriptBlock = [ScriptBlock]::Create("Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine' -Name 'Site-Name'")
                        ErrorAction = 'Stop'
                    }
                    
                    $SiteCode = Invoke-Command @SiteSplat
                } Catch {
                    Write-Error -Exception $PSItem.Exception -Message $PSItem.Exception.Message
                    Break
                }

                [PSCustomObject]@{
                    ComputerName= $Machine
                    SiteCode    = $SiteCode
                }
            } # Connectivity Check
        } # ForEach Machine in Name
    } # Process Block
} # Function Get-ComputerSite