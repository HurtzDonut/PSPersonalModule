<#
    .SYNOPSIS
        Uses CIM to find/stop a remote process.
    .DESCRIPTION
        Uses CIM to find a remote process, then calls the CIM Method, Terminate, to stop the process.
    .EXAMPLE
        PS C:\> Stop-RemoteProcess -ComputerName Computer1 -ProcessName Notepad
        
        ComputerName : Computer1
        ProcessName  : notepad.exe
        ProcessId    : 11228
        ExitCode     : 0
        Termination  : SUCCESS

        Locates any process on 'Computer1' that matches 'Notepad', then terminates it.
    .INPUTS
        System.String
    .OUTPUTS
        System.Management.Automation.PSCustomObject
        System.String
    .NOTES
        Created:    2/8/2019
        Author:     Jacob C Allen (JCA)
        Modified:   5/14/2019
        Version:    1.2
#>
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