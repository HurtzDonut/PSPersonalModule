<#
.SYNOPSIS
    Get IIS application pool status
.DESCRIPTION
    The function would provide IIS application pool status
.EXAMPLE
   PS C:\> Get-AppPool -Server server1,server2 -Pool powershell
#>

Function Get-AppPool {
    [CmdletBinding()]
    Param(
        [Parameter()]
            [String[]]$Server,
        [Parameter()]
            [String]$Pool
    )

    Begin {
        [Void][Reflection.Assembly]::LoadWithPartialName('Microsoft.Web.Administration')
    }

    Process {
        ForEach ($S in $Server) {
            $Sm         = [Microsoft.Web.Administration.ServerManager]::OpenRemote($S)
            $AppPools   = $Sm.ApplicationPools["$Pool"]
            $Status     = $AppPools.state
            
            [PSCustomObject][Ordered]@{
                'Pool Name' = $Pool
                'Status'    = $Status
                'Server'    = $S
            }
        }
    }
} # Function Get-AppPool