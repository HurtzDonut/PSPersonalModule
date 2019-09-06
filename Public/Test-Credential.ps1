<#
.SYNOPSIS
    Tests the validity of a given credential.
.LINK
    https://github.com/RamblingCookieMonster/PowerShell/blob/master/Test-Credential.ps1
#>
Function Test-Credential {
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory)]
            [System.Management.Automation.PSCredential]$Credential,
        [Parameter()]
            [String]$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
    )
    Write-Verbose "Loading AccountManagement Assembly..."
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.DirectoryServices.AccountManagement')

    Write-Verbose "Setting the Domain to test against..."
    $DS = [System.DirectoryServices.AccountManagement.PrincipalContext]::new([System.DirectoryServices.AccountManagement.ContextType]::Domain, $Domain)

    Write-Verbose "Testing Credential..."
    $TestResult = $DS.ValidateCredentials($Credential.UserName,$Credential.GetNetworkCredential().Password)
    If ($TestResult) {
        Write-Verbose "Result: VALID"
    } Else {
        Write-Verbose "Result: INVALID"
    }

    $TestResult

    Write-Verbose "Unloading Assembly..."
    $DS.Dispose()
} # Function Test-Credential