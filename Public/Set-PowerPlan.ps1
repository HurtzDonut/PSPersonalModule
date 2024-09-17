<#
.DESCRIPTION
    Describe the purpose of this script
.NOTES
    Author					Jacob C Allen
    Created					09-16-2024
    Modified				-
    Modified By				-
    Version					v1.0
#>
Function Set-PowerPlan {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({
                # param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                (Get-PowerPlan).Keys -replace '^|$',"'"
        })]
        [ValidateScript({(Get-PowerPlan).Keys.Contains($PSItem)})]
        [String]$Plan
    )
    Begin {
        $powerPlans = Get-PowerPlan
    }
    Process {
        Write-Output ('You selected plan [{0}] with GUID [{1}]' -F $Plan,$powerPlans.$Plan)
    }
}