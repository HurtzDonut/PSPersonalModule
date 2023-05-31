<#
.SYNOPSIS
    Retrieves the uptime of a computer/collection of computers.
.DESCRIPTION
    Retreive the uptime of the specified computer(s) using the Win32_OperatingSystem Class.
.EXAMPLE
    PS C:\> Get-CNHSAUptime DNSHostName LX085MWJ,WR2QQUSB19,SR1MGT01

    ComputerName            LastBootTime       UpTime
    ------------            ------------       ------
    LX085MWJ.hq.first.int   11/8/2021 4:40 PM  0d:18h:23m:10s
    WR2QQUSB19.hq.first.int 10/30/2021 5:48 PM 9d:17h:15m:27s
    SR1MGT01.hq.first.int   11/6/2021 9:35 PM  2d:13h:28m:10s
.EXAMPLE
    PS C:\> 'LX085MWJ','WR2QQUSB19','SR1MGT01' | ForEach-Object {Get-ADComputer $PSItem} | Get-Uptime

    ComputerName            LastBootTime       UpTime
    ------------            ------------       ------
    LX085MWJ.hq.first.int   11/8/2021 4:40 PM  0d:18h:23m:10s
    WR2QQUSB19.hq.first.int 10/30/2021 5:48 PM 9d:17h:15m:27s
    SR1MGT01.hq.first.int   11/6/2021 9:35 PM  2d:13h:28m:10s
.INPUTS
    System.String[]
.OUTPUTS
    PSCustomObject
.NOTES
    Author      Jacob C Allen
    Created     04/23/2019
    Modified    05-31-2023
    Version     1.4
#>
Function Get-CNHSAUptime {
    [CmdletBinding()]
    [Alias('uptime')]
    Param (
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Position = 0)]
        [Alias('ComputerName','Name')]
            [String[]]$DNSHostName = $env:COMPUTERNAME,
        [Parameter()]
            [PSCredential]$Credential
    )
    Process {
        #region Begin
            $Results = [System.Collections.ArrayList]::New()

            Try {
                $Null = Test-Connection -ComputerName $DNSHostName -Count 1 -ErrorAction Stop
            } Catch {
                Write-Warning ('Unable to connect to [{0}]' -F $PSItem.CategoryInfo.TargetName) 
                Write-Warning ('Please verify the name of the computer and try again')
                Break
            }
        #endregion Begin

        #region Process
            ForEach ($Computer in $DNSHostName) {
                Write-Verbose $Computer
                
                Try {
                    $getCimSplat = @{
                        ComputerName    = $computer
                        ClassName       = 'Win32_OperatingSystem'
                        ErrorAction     = 'Stop'
                    }
                    $lastBoot = If ($null -ne $Credential) {
                        Invoke-Command -ComputerName $Computer -ScriptBlock {Get-CimInstance @using:getCimSplat} -Credential $Credential
                    } Else {
                        Get-CimInstance @getCimSplat
                    }
                    
                } Catch {
                    Write-Warning ('Retrieving LastBootUpTime for [{0}] failed' -F $Computer)
                    Write-Warning ('{0}' -F $PSItem.Exception.Message)
                    Break
                }
                
                $UpTime = (Get-Date) - $LastBoot.LastBootUpTime

                [Void]$Results.Add(
                    [PSCustomObject][Ordered]@{
                        ComputerName    = $Computer
                        LastBootUpTime  = $LastBoot.LastBootUpTime
                        ElapsedTime     = ('{0:0}d:{1:0}h:{2:0}m:{3:0}s' -F $UpTime.Days,$Uptime.Hours,$UpTime.Minutes,$UpTime.Seconds)
                    }
                )
            } # ForEach
        #endregion Process

        #region End
            $Results
        #endregion End
    } # Process Block
} # Function Get-CNHSAUptime