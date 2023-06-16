
Function Get-InstalledUpdates {
    [CmdletBinding()]
    Param (
        [Parameter()]
            [String[]]$ComputerName = $env:COMPUTERNAME,
        [Parameter()]
            [String]$UpdateType,
        [Parameter()]
            [PSCredential]$Credential
    )
    Begin {
        $online = [System.Collections.ArrayList]::New()
        $ComputerName |
            ForEach-Object {
                If (Test-Connection -TargetName $PSItem -Count 1 -Quiet) {
                    [Void]$online.Add($PSItem)
                }
            }
    }
    Process {
        Invoke-Command -ComputerName $online -Credential $Credential -ScriptBlock {
            $Session        = New-Object -ComObject "Microsoft.Update.Session"
            $Searcher       = $Session.CreateUpdateSearcher()
            $historyCount   = $Searcher.GetTotalHistoryCount() 
            
            $Searcher.QueryHistory(0, $historyCount)
        } | Select-Object Title,
                            Description,
                            Date,
                            @{N="Operation"; E={
                                Switch($PSItem.operation){
                                    1 {"Installation"}
                                    2 {"Uninstallation"}
                                    3 {"Other"}
                                }
                            }},
                            @{N="Status"; E={
                                Switch($PSItem.resultcode){
                                    1 {"In Progress"}
                                    2 {"Succeeded"}
                                    3 {"Succeeded With Errors"}
                                    4 {"Failed"}
                                    5 {"Aborted"}
                                }
                            }},
                            @{N="KB"; E={($PSItem.title -split "(KB\d+)")[1]}}
    } # [Process]
} # Function Get-InstalledUpdates