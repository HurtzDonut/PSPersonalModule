<#
.SYNOPSIS
    Short Description of Function
.PARAMETER Param1
    Description for Param1
.EXAMPLE
    PS C:\> Clear-ConsoleLogFiles  -Param1

    Short explanation for example
.NOTES
    Author			Jacob C Allen
    Created			05-15-2024
    Modified		-
    Modified By		-
    Version			v1.0
#>
Function Clear-ConsoleLogFiles {
    [CmdLetBinding()]
    Param ()
    Begin {
        $LogDir         = '{0}\My Documents\PowerShell\Console_Logs' -F $env:HOMESHARE
        $Date           = Get-Date
        $PrevMonArchive = '{0}\Archive\{1}' -F $LogDir,$Date.AddMonths(-1).ToString('MMM_yyy')        
    } # Begin
    Process {
        # Check to see if we are in a new month
        If (($Date.ToString('MM') -ne $Date.AddDays(-3).ToString('MM')) -and !(Test-Path "$PrevMonArchive.zip")) {
            Write-Verbose "Entered new month and did not find archive for previous month"
            
            # Get all log files for last month
            $DateForRegEx   = $Date.AddMonths(-1).ToString('MM')
            $PrevMonLogs    = Get-ChildItem $LogDir | Where-Object BaseName -Match "^$DateForRegEx"

            $CompressSplat = @{
                DestinationPath     = $PrevMonArchive
                CompressionLevel    = 'Optimal'
                Force               = $True
                ErrorAction         = 'Stop'
            }
            Try {
                # Compress log files to folder 'MMM_yyy' (e.g. Apr_2019)
                $PrevMonLogs | Compress-Archive @CompressSplat
                
                # Remove log files after compression
                $PrevMonLogs | Remove-Item -Force -ErrorAction Stop
            } Catch {
                Write-Warning 'Error encountered when Compressing/Deleting Console Log Files:'
                Write-Warning $PSItem.Exception.Message
            }
        }
    } # Process
    End {
        # Rename Previous Day's Console Log
        $CurLog     = ('{0}\Current_Day.txt' -F $LogDir)
        $PrevDay    = $Date.AddDays(-1).ToString('MMddyy')
        $PrevDayLog = Get-ChildItem $LogDir | Where-Object BaseName -eq $PrevDay

        If ($Null -eq $PrevDayLog) {
            Rename-Item -Path $CurLog -NewName "$PrevDay.txt"
        }   
    } # End
} # Function Clear-ConsoleLogFiles