
Function Update-EnvironmentPath {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(ParameterSetName = 'Append')]
        [Parameter(ParameterSetName = 'Overwrite')]
        [Parameter(ParameterSetName = 'Restore')]
            [String[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(ParameterSetName = 'Append')]
            [String]$AppendValue,

        [Parameter(ParameterSetName = 'Overwrite')]
            [String]$NewPath,

        [Parameter(ParameterSetName = 'Restore')]
            [Switch]$RestoreOriginal
    )

    Process {
        ForEach ($Computer in $ComputerName) {
            # Check to see if -WhatIf has been passed
            # Normally I would use a $Using: call, but PowerShell won't let you use $Using:PSCmdLet.ShouldProcess('')
            # Second option would be to use $Using:PSCmdLet.MyInvocation.BoundParameters['WhatIf'], however PowerShell doesn't like that either
            $WhatIf = $PSCmdLet.MyInvocation.BoundParameters['WhatIf']
            
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                # Get and Set Verbose Preference
                # This allows Verbose messages to be sent back from Invoke-Command
                $OrigVerbosePref    = $VerbosePreference
                $VerbosePreference  = 'Continue'
                
                Write-Verbose "[$Using:Computer] Checking for existing backup property"
                # Check if there is already a backup property
                $ExistingSplat = @{
                    Path        = 'HKLM:\System\ControlSet001\Control\Session Manager\Environment'
                    Name        = 'OriginalPath'
                    ErrorAction = 'SilentlyContinue'
                }
                $OriginalPath = Get-ItemPropertyValue @ExistingSplat

                If ([String]::IsNullOrEmpty($OriginalPath)) {
                    Write-Verbose "[$Using:Computer] No backup property found"
                    Write-Verbose "[$Using:Computer] Getting current Path value"
                    
                    # Get Original (i.e. Current) Path value
                    $OriginalPath = Get-ItemPropertyValue -Path 'HKLM:\System\ControlSet001\Control\Session Manager\Environment' -Name Path
                    $OriginalPath = ($OriginalPath -Replace 'C:\\Windows','%SystemRoot%' -Replace 'C:\\Program','%SystemDrive%\Program' -Split ';'|Sort-Object -Descending) -Join ';' -Replace '^;'

                    Write-Verbose "[$Using:Computer] Attempting to create backup property [OriginalPath]"
                        $NewPropertySplat = @{
                            Path            = 'HKLM:\System\ControlSet001\Control\Session Manager\Environment'
                            Name            = 'OriginalPath'
                            PropertyType    = 'String'
                            Value           = $OriginalPath
                            Force           = $True
                            ErrorAction     = 'Stop'
                        }
                    # Create Backup key and store Original Path
                    Try {
                        New-ItemProperty @NewPropertySplat | Out-Null
                    } Catch {
                        Throw $PSItem.Exception.Message
                    }
                } Else {
                    Write-Verbose "[$Using:Computer] Found existing backup property"
                    $OriginalPath = ($OriginalPath -Replace 'C:\\Windows','%SystemRoot%' -Replace 'C:\\Program','%SystemDrive%\Program' -Split ';'|Sort-Object -Descending) -Join ';'
                }
                
                Switch ($Using:PSCmdLet.ParameterSetName) {
                    'Append' {
                        Write-Verbose "[$Using:Computer] Setting Append values"
                        $SetPropertySplat = @{
                            Path        = 'HKLM:\System\ControlSet001\Control\Session Manager\Environment'
                            Name        = 'Path'
                            Value       = ("$OriginalPath;$($Using:AppendValue)")
                            Force       = $True
                            ErrorAction = 'Stop'
                        }
                        $Action = 'Append'
                    }
                    'Overwrite' {
                        Write-Verbose "[$Using:Computer] Setting Overwrite values"
                        $SetPropertySplat = @{
                            Path        = 'HKLM:\System\ControlSet001\Control\Session Manager\Environment'
                            Name        = 'Path'
                            Value       = $Using:NewPath
                            Force       = $True
                            ErrorAction = 'Stop'
                        }
                        $Action = 'Overwrite'
                    }
                    'Restore' {
                        Write-Verbose "[$Using:Computer] Setting Restore values"
                        $SetPropertySplat = @{
                            Path        = 'HKLM:\System\ControlSet001\Control\Session Manager\Environment'
                            Name        = 'Path'
                            Value       = $OriginalPath
                            Force       = $True
                            ErrorAction = 'Stop'
                        }
                        $Action = 'Restore'
                    }
                } # Switch ParameterSetName
                
                If ($Using:WhatIf) {
                    Write-Output ('Attempting to [{0}] property [Path] with value [{1}]' -F $Action,$SetPropertySplat['Value'])
                } Else {
                    Write-Verbose ("[$Using:Computer] {0} Path with {1} value" -F $($Action -replace '(d$)|(e$)','$1ing'),$(Switch ($Using:PSCmdLet.ParameterSetName) {'Restore' {'original'};Default {'new'}}))
                    Try {
                        Set-ItemProperty @SetPropertySplat
                    } Catch {
                        Throw $PSItem.Exception.Message
                    }
                }
                
                # Reset Verbose Preference
                $VerbosePreference = $OrigVerbosePref
            } # Invoke-Command
        } # ForEach Computer
    } # Process Block
} # Function Update-EnvironmentPath