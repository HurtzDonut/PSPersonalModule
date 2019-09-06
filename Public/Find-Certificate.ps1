<#
.SYNOPSIS
    Finds a certificate that matches a specific thumbprint.
.PARAMETER Thumbprint
    Parameter description
.PARAMETER ComputerName
    Parameter description
.EXAMPLE
    PS C:\> $Servers = (Get-ADComputer -Filter "OperatingSystem -like '*server*'").Name
    PS C:\> Find-Certificate -Thumbprint 2AB641C43DDF59AB7A996F98E5E799D5A51132F7 -ComputerName $Servers

    1. Finds all computers in AD that have 'Server' listed as their OperatingSystem.
    2. Iterates through all the servers looking for the certificate with thumbprint:
        2AB641C43DDF59AB7A996F98E5E799D5A51132F7
.NOTES
    Author		Jacob Allen
    Created		09-06-2019
    Modified	09-06-2019
    Version		1.0
#>
Function Find-Certificate {
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory)]
        [ValidatePattern('[0-9A-F ]{40,}')]
            [String]$Thumbprint,
        [Parameter()]
            [String[]]$ComputerName = $env:COMPUTERNAME
    )
    Process {
        ForEach ($Entry in $ComputerName) {
            Invoke-Command -ComputerName $Entry.Name -ScriptBlock {
                Get-ChildItem Cert:\LocalMachine -Recurse -Force |
                    Where-Object Thumbprint -eq $Using:Thumbprint |
                        Select-Object @{Name='Folder';Expression={If($PSItem.PSIsContainer){$PSItem.PSChildName}Else{$PSItem.PSParentPath -Replace '.*::'}}},
                            @{Name='Expiration';Expression={$PSItem.NotAfter}},
                            Thumbprint
            } -AsJob
        }
    } # Process
    End {
        Get-Job | Receive-Job -Wait | Select-Object PSComputerName,Folder,Expiration,Thumbprint
    } # End
} # Function Find-Certificate