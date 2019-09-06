Function Set-PowerState {
    [CmdletBinding()]
    [Alias('Sleep-Computer','slpc')]
    Param (
        [Parameter()]
            $PowerState = 'Suspend',
        [Parameter()]   
            [Switch]$DisableWake,
        [Parameter()]
            [Switch]$Force
    )

    Begin {
        [Void][Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        $PowerChoice = [System.Windows.Forms.PowerState]::$PowerState

        If (!$DisableWake)  { $DisableWake  = $False }
        If (!$Force)        { $Force        = $False }
    }

    Process {
        [System.Windows.Forms.Application]::SetSuspendState($PowerChoice, $Force, $DisableWake)
    }
} # Function Set-PowerState
