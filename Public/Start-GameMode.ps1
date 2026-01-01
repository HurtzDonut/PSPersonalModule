
Function Start-GameMode {
    Write-Host 'Starting Game Mode'
    Write-Host 'Explorer process will be killed until Game Mode is exited'
    Start-Sleep -Seconds 4

    
    While ($TRUE) {
        Get-Process explorer -ErrorAction SilentlyContinue |
            Stop-Process -Force
        $quitKey = 81 # char code for 'Q'
        
        If ($host.UI.RawUI.KeyAvailable) {
            $key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
            If ($key.VirtualKeyCode -eq $quitKey) {
                #For Key Combination: eg., press 'LeftCtrl + q' to quit.
                #Use condition: (($key.VirtualKeyCode -eq $Qkey) -and ($key.ControlKeyState -match "LeftCtrlPressed"))
                Write-Host -ForegroundColor Yellow ("[{0}] is pressed! Stopping the script now." -F ([Char][Byte]$quitKey))
                Break
            }
        }
        # Do your operations
        Clear-Host
        Write-Host ("Press [{0}] to exit Game Mode" -F ([Char][Byte]$quitKey))
        Start-Sleep -Milliseconds 500
    }
	
	Start-Process explorer
	Pause
} # Function Start-GameMode