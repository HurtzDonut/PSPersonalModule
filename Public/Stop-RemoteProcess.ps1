Function Stop-RemoteProcess {
    [CmdLetBinding()]
    Param (
    [Parameter()]
        [String]$ComputerName = $env:COMPUTERNAME,
    
    [Parameter(Mandatory)]
        [String]$ProcessName
    )
    
    $Result = [System.Collections.ArrayList]::New()

    # Use Cim to filter through the list of Processes from $ComputerName and find $ProcessName
    $ProcessList = Get-CimInstance -ClassName Win32_Process -ComputerName $ComputerName | Where-Object Name -match $ProcessName
    
    If ($ProcessList.Name.Count -gt 0) {
        ForEach ($Process in $ProcessList) {
            $ExitCode = Invoke-CimMethod -InputObject $Process -MethodName Terminate -ComputerName $ComputerName
            
            [Void]$Result.Add((
                [PSCustomObject][Ordered]@{
                    ComputerName= $Process.PSComputerName
                    ProcessName = $Process.Name
                    ProcessId   = $Process.Handle
                    ExitCode    = $ExitCode.ReturnValue
                    Termination = Switch ($ExitCode.ReturnValue) {
                        0       {'SUCCESS'}
                        Default {'FAIL'}
                    }
                }
            ))
        }

        $Result
    } Else {
        Write-Output ('[{0}] : No instances of ({1}) found' -F $ComputerName,$ProcessName)
    }
} # Function Stop-RemoteProcess