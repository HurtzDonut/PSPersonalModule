<#
.SYNOPSIS
    Finds empty ActiveDirectory groups.
.EXAMPLE
    PS C:\> Find-EmptyADGroups -All -Include Total
.INPUTS
    String[]
    Switch
.NOTES
    General notes
#>
Function Find-EmptyADGroups {
    [CmdLetBinding(DefaultParameterSetName = 'Specific')]
    Param (
        [Parameter(ParameterSetName = 'Specific')]    
            [String[]]$OrgUnit,
        [Parameter(ParameterSetName = 'All')]
            [Switch]$All,
        [Parameter(ParameterSetName = 'Specific')]
        [Parameter(ParameterSetName = 'All')]
            [Switch]$IncludeTotal

    )

    Begin {
        $Results = [System.Collections.ArrayList]::New()

        $SearchCmd = Switch ($PSCmdlet.ParameterSetName) {
            'Specific' {
                # Loop through OUs
                '$OrgUnit | 
                ForEach-Object {
                    Get-ADGroup -Filter * -SearchBase $PSItem -Properties member,whenCreated,whenChanged | 
                        Where-Object { $PSItem.Member.Count -eq 0 }
                }'
            }
            'All' {
                # Look through all OUs
                'Get-ADGroup -Filter * -Properties Member,whenCreated,whenChanged | 
                        Where-Object { $PSItem.Member.Count -eq 0 }'
            }
        }
    } # Begin Block

    Process {
        Invoke-Expression $SearchCmd | 
            Sort-Object Name | 
                ForEach-Object { 
                    $DN = $PSItem.DistinguishedName -Split ','
                    $OU = $DN[1..($DN.count-4)] -Join ','
                    
                    [Void]$Results.Add(
                        [PSCustomObject][Ordered]@{
                            SamAccountName  = $PSItem.SamAccountName
                            OU              = $OU
                            MemberCount     = $PSItem.Member.Count
                            whenCreated     = $PSItem.whenCreated
                            whenChanged     = $PSItem.whenChanged
                        }
                    )
                } # Loop through Groups
    } # Process Block

    End {
        If ($PSBoundParameters['IncludeTotal']) {
            $Results.Insert(0, [PSCustomObject][Ordered]@{
                Total           = $Results.Count
                SamAccountName  = $Null
                OU              = $Null
                MemberCount     = $Null
                whenCreated     = $Null
                whenChanged     = $Null
            })
        }
        
        $Results
    } # End Block
} # Function Find-EmptyADGroups