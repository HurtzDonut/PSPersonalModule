<#
.SYNOPSIS
    Vaidates the current user's Local Admin Status
#>

Function Test-LocalAdminStatus {
    [CmdLetBinding()]
    Param()

    Write-Verbose "Verifying Administrator Status for the current user"
    If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Verbose "Current user is NOT an Administrator."
        $False
    } Else {
        Write-Verbose "Current user IS an Administrator."
        $True
    }
} # Function Test-LocalAdminStatus