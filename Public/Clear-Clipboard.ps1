<#
.DESCRIPTION
    Describe the purpose of this script
.NOTES
    Author					Jacob C Allen
    Created					07-21-2033
    Modified				08-23-2023
    Modified By				Jacob C Allen
    Version					v1.0.1
#>
Function Clear-Clipboard {
    [CmdletBinding()]
    [Alias('clcb')]
    Param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('DNSHostName','SystemName')]
            [String[]]$ComputerName
    )
    
    Begin {
        If ($ComputerName -ne $env:ComputerName) {
            Test-Connection -Count 1 -TimeoutSeconds 5 -tar vdifull017-w10 |
                Where-Object Status -eq 'Success' |
                    Select-Object @{n= 'ComputerName';e={$PSItem.Destination}} -OutVariable onlineComputers |
                        Out-Null
        } Else {
            $onlineComputers = $env:ComputerName
        }
    }
    
    Process {
        $onlineComputers | Get-CimInstance -Query "SELECT * FROM Win32_Service WHERE Name LIKE 'cbdhsvc%'" |
            Select-Object DisplayName, Name, State, SystemName
    }
    
    End {
        
    }
}