Function Start-Timer {
    [CmdletBinding()]
    [Alias('lunch','timer')]
    Param (
        [Parameter()]
            [Int]$Length = 45
    ) 
    
    $Start      = Get-Date
    Write-Host -Object "Start:`t$($Start.ToString('HH:mm'))"
    
    $EndTarget  = $Start.AddMinutes($Length)
    Write-Host -Object "End:`t$($EndTarget.ToString('HH:mm'))"
    
    Write-Host -Object ([Environment]::NewLine)
    Write-Host -Object ("Minutes remaining {0}" -F ($EndTarget - $Start).Minutes)

    $i = 0
    Do {
        If ($i % 60) {
            $Run            = Get-Date
            $TimeRemaining  = ($EndTarget - $Run).Minutes
            
            If ($TimeRemaining -gt 10) {
                Write-Host -Object "Minutes remaining $TimeRemaining"
            } ElseIf ($TimeRemaining -gt 2 -and $TimeRemaining -le 10) {
                Write-Host -ForegroundColor Yellow -Object "Minutes remaining !!! " -NoNewline
                Write-Host -ForegroundColor Cyan -Object $TimeRemaining -NoNewline
                Write-Host -ForegroundColor Yellow -Object " !!!"
                
                [Console]::Beep(350,150)
            } ElseIf ($TimeRemaining -ge 1 -and $TimeRemaining -le 2) {
                Write-Host -ForegroundColor Yellow -Object "Minutes remaining !!! " -NoNewline
                Write-Host -ForegroundColor Red -Object $TimeRemaining -NoNewline
                Write-Host -ForegroundColor Yellow -Object " !!!"

            } Else {
                For ($j=0;$j -lt 3;$j++) {
                    Write-Host -ForegroundColor Yellow -Object "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                    Write-Host -ForegroundColor Yellow -Object "!!!!!!!!! " -NoNewline
                    Write-Host -ForegroundColor Red -Object "TIME'S UP" -NoNewline
                    Write-Host -ForegroundColor Yellow -Object " !!!!!!!!!"
                    Write-Host -ForegroundColor Yellow -Object "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                }
                
                For ($j=0;$j -lt 2;$j++) {
                    [Console]::Beep(700,150)
                    [Console]::Beep(650,150)
                    [Console]::Beep(800,150)
                    [Console]::Beep(750,150)
                }
                Return
            }
        }
        Start-Sleep -Seconds 60
        
        $i++
    } Until ((Get-Date -f "HH:mm") -eq $Start.AddMinutes($Length).ToString("HH:mm"))
} # Function Start-Timer