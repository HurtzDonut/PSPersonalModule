Function Set-ComputerLock {
    [CmdletBinding()]
    [Alias('lock')]
    Param (

    )
    rundll32.exe user32.dll,LockWorkStation
} # Function Set-ComputerLock
