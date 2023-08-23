Function Get-PSDefaultParamValue {
    [CmdletBinding(DefaultParameterSetName='Type')]
    [Alias('gdfpv')]
    Param ( 
        [Parameter(ParameterSetName='Type')]
        [ValidateSet('Alias','Cmdlet','Function','All')]
            [String]$CommandType = 'All',
        [Parameter(ParameterSetName='Command')]
            [String]$Command
    )
    Process {
        $Results = [System.Collections.ArrayList]::New()
        
        ForEach ($Entry in $PSDefaultParameterValues.Keys) {
            $Val = $Entry -Split '\:'
            
            [Void]$Results.Add(
                [PSCustomObject][Ordered]@{
                    CommandType         = (Get-Command $Val[0]).CommandType
                    Command             = $Val[0]
                    Parameter           = $Val[1]
                    DefaultValueWithType= ("[{0}]{1,-1}" -F $PSDefaultParameterValues.$Entry.GetType().Name,$PSDefaultParameterValues.$Entry)
                }
            )
        }

        Switch ($PSCmdlet.ParameterSetName) {
            'Type' {
                If ($CommandType -eq 'All') {
                    $Results | Sort-Object -Property CommandType,Command
                } Else {
                    $Results | Where-Object CommandType -eq $CommandType | Sort-Object -Property Command
                }
            }
            'Command' {
                $Results | Where-Object Command -Match $Command | Sort-Object -Property CommandType,Command
            }
        }
    }
} # Function Get-PSDefaultParamValue