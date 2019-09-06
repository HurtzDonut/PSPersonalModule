Function Remove-ComObject {
    [CmdLetBinding()]
    Param(
        [Parameter()]
            [System.__ComObject[]]$ComObject
    )
    Process {
        ForEach ($Com in $ComObject) {
            $Null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Com)
        }
    }
    End {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}