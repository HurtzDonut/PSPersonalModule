<#
.DESCRIPTION
    Describe the purpose of this script
.NOTES
    Author					First (M) Last
    Created					09-16-2024
    Modified				-
    Modified By				-
    Version					v1.0
#>
Function Get-PowerPlan {
    [CmdletBinding()]
    Param ()
    $regexPattern = '^.+(?<guid>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[1-5][a-fA-F0-9]{3}-[89abAB][a-fA-F0-9]{3}-[a-fA-F0-9]{12})\s{2}\((?<plan>[a-z0-9 ]+)\)(|\s\*)$'
    $powerPlanListRaw = ((PowerCfg.exe /L ) -match 'Power Scheme GUID') -replace $regexPattern, '${plan};${guid}'

    $powerPlanTable = $powerPlanListRaw |
                        ForEach-Object {
                            $d = $_ -split ';'
                            @{$d[0]=$d[1]} 
                        }

    Return $powerPlanTable
}