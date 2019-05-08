<#
.SYNOPSIS
    Retrieves the uptime of a computer/collection of computers.
.DESCRIPTION
    Retreive the uptime of the specified computer(s) using the Win32_OperatingSystem WMI Class.
.EXAMPLE
    PS C:\> Get-Uptime -ComputerName Computer1,Computer2,Computer3
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    System.String[]
.OUTPUTS
    System.Collections.ArrayList
.NOTES
    Author      Jacob C Allen
    Created     04/23/2019
    Modified    04/23/2019
    Version     1.1
#>
Function Get-Uptime {
    [CmdletBinding()]
    Param (
        [Parameter()]
        [ValidateNotNullOrEmpty()] 
            [String[]]$ComputerName = $Env:COMPUTERNAME
    )
    
    Begin {
        $Results = [System.Collections.ArrayList]::New()

        Try {
            $Null = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop
        } Catch {
            Write-Warning ('Unable to connect to [{0}]' -F $PSItem.CategoryInfo.TargetName) 
            Write-Warning ('Please verify the name of the computer and try again')
            
            Break
        }
    } # Begin Block

    Process {
        ForEach ($Computer in $ComputerName) {
            Try {
                $LastBoot = Get-CimInstance -ComputerName $Computer -ClassName Win32_OperatingSystem -ErrorAction Stop | Select-Object -ExpandProperty LastBootUpTime
            } Catch {
                Write-Warning ('Retrieving LastBootUpTime for [{0}] failed' -F $Computer)
                Write-Warning ('{0}' -F $PSItem.Exception.Message)
                Break
            }
            
            $UpTime = (Get-Date) - $LastBoot

            [Void]$Results.Add(
                [PSCustomObject][Ordered]@{
                    ComputerName    = $Computer
                    LastBootTime    = $LastBoot.ToString('g')
                    UpTime          = ('{0:0}d:{1:0}h:{2:0}m:{3:0}s' -F $UpTime.Days,$Uptime.Hours,$UpTime.Minutes,$UpTime.Seconds)
                }
            )
        } # ForEach
    } # Process Block
    
    End {
        $Results
    } # End Block
} # Function Get-Uptime