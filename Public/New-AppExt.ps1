<#
    .SYNOPSIS  
        Creates a new 'Application' extension using the supplied value.
    .DESCRIPTION
        Using the user supplied extension, values are copied from the '.exe' and 'exefile' registry keys.
        Those values are then used to create the registry keys that define a new 'Application' extension.
    .INPUTS
        System.String
    .OUTPUTS
        System.Collections.ArrayList
    .EXAMPLE
        PS C:\> New-AppExt -Create -FileExt abc
    .EXAMPLE
        PS C:\> New-AppExt -Delete -FileExt abc
    .EXAMPLE
        PS C:\> New-AppExt -New -FileExt xyz -Verbose
        VERBOSE: Running in [Create] mode
        VERBOSE: Searching [Registry::HKEY_CLASSES_ROOT] for [.xyz]
        VERBOSE: Create switch identified.
        VERBOSE: No existing registry key found for [.xyz]
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\.xyz
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\.xyz\PersistentHandler
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\DefaultIcon
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shell
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shell\open
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shell\open\command
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runas
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runas\command
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runasuser
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runasuser\command
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shellex
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\ContextMenuHandlers
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\ContectMenuHandlers\Compatibility
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\DropHandler
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\PropertySheetHandlers
        VERBOSE: Creating: Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\PropertySheetHandlers\ShimLayer Property Page
        VERBOSE: Checking registry to verify keys and subkeys were created
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\.xyz
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\.xyz\PersistentHandler
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shell
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shell\open
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shell\open\command
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runas
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runas\command
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runasuser
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runasuser\command
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shellex
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\ContextMenuHandlers
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\DropHandler
        VERBOSE: Found key for Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\PropertySheetHandlers
    .EXAMPLE
        PS C:\> New-AppExt -Remove -FileExt xyz -Verbose
        VERBOSE: Running in [Delete] mode
        VERBOSE: Searching [Registry::HKEY_CLASSES_ROOT] for [.xyz]
        VERBOSE: Delete switch identified.
        VERBOSE: Existing registry key found for [.xyz]!
        VERBOSE: Continuing with removal
        VERBOSE: Removing [Registry::HKEY_CLASSES_ROOT\.xyz]
        VERBOSE: Removing [Registry::HKEY_CLASSES_ROOT\xyzfile]
        VERBOSE: Checking registry to verify keys and subkeys were Deleted
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\.xyz
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\.xyz\PersistentHandler
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shell
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shell\open
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shell\open\command
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runas
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runas\command
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runasuser
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shell\runasuser\command
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shellex
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\ContextMenuHandlers
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\DropHandler
        VERBOSE: Successfully deleted key Registry::HKEY_CLASSES_ROOT\xyzfile\shellex\PropertySheetHandlers
    .NOTES
        This was created simply because I wanted to know if I possesed the skills to do so.
#>
Function New-AppExt {
    [CmdLetBinding()]
    param(
        [Parameter(ParameterSetName = 'Create', Position = 0)]
        [Alias('C', 'New')]
        [Switch]$Create,
        [Parameter(ParameterSetName = 'Delete', Position = 0)]
        [Alias('D', 'Remove')]
        [Switch]$Delete,
        [Parameter(Mandatory = $True)]
        [ValidateScript( {
                If (($PSItem -cmatch '[a-z]') -and (($PSItem.Length -ge 2) -and ($PSItem.Length -le 3))) {
                    $True
                } else {
                    Throw "`n`n`t" + ('[{0}] is not a valid file extension.' -F $PSItem) +
                    "`n`t" + 'A valid file extension will be formatted as follows: ' +
                    "`n`t`t" + '-Will NOT contain a period (.)' +
                    "`n`t`t" + '-Consists of 2-3 lowercase letters (a-z)'
                }
            })]
        [string]$FileExt
    )
    
    Begin {
        Write-Verbose ('Running in [{0}] mode' -F $PSCmdLet.ParameterSetName)
        $HKCR = "Registry::HKEY_CLASSES_ROOT"
        $TestForExt = $Null
        Write-Verbose ('Searching [{0}] for [.{1}]' -F $HKCR, $FileExt)
        $TestForExt = Get-ChildItem -Path $HKCR | Where-Object {$PSItem.Name -cmatch "\.$FileExt"} | Select-Object Name -First 1
        Switch ($PSCmdLet.ParameterSetName) {
            'Create' {
                Write-Verbose 'Create switch identified.'
                Switch ($Null -eq $TestForExt) {
                    $False {
                        Write-Warning ('Existing registry key found for [.{0}]!' -F $FileExt)
                        Write-Warning 'Please choose a different value for a file extension!'
                        Write-Verbose 'Exiting'
                        Pop-Location
                        Exit 1
                    } # Existing key found
                    $True {
                        Write-Verbose ('No existing registry key found for [.{0}]' -F $FileExt)
                    } # No existing key found
                } # End Test for existing ext
            }
            'Delete' {
                Write-Verbose 'Delete switch identified.'
                Switch ($Null -eq $TestForExt) {
                    $False {
                        Write-Verbose ('Existing registry key found for [.{0}]!' -F $FileExt)
                        Write-Verbose 'Continuing with removal'
                    }
                    $True {
                        Write-Verbose ('No existing registry key found for [.{0}]' -F $FileExt)
                        Write-Verbose 'Exiting'
                        Pop-Location
                        Exit 2
                    }
                }
            }
        }
    } # Begin Block

    Process {
        Switch ($PSCmdLet.ParameterSetName) {
            'Delete' {
                Write-Verbose ('Removing [{0}\.{1}]' -F $HKCR, $FileExt)
                Remove-Item -Path ('{0}\.{1}' -F $HKCR, $FileExt) -Recurse

                Write-Verbose ('Removing [{0}\{1}file]' -F $HKCR, $FileExt)
                Remove-Item -Path ('{0}\{1}file' -F $HKCR, $FileExt) -Recurse
            } # Delete Parameter Set
            'Create' {
                $Def = '(Default)'
                $exe = Get-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\.exe
                $exePersistentHandler = Get-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\.exe\PersistentHandler
                $exefileKey = Get-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\exefile
                $exefileSubKeys = Get-ChildItem -Path Registry::HKEY_CLASSES_ROOT\exefile | Select -Expand Name
                $exefile = [PSCustomObject]@{
                    DefaultIcon = Get-ItemProperty -Path Registry::$($exefileSubKeys[0])
                    Shell       = Get-ChildItem -Path Registry::$($exefileSubKeys[1]) | Select -Expand Name
                    Shellex     = Get-ChildItem -Path Registry::$($exefileSubKeys[2]) | Select -Expand Name
                }
                $Shell = [PSCustomObject]@{
                    open             = Get-ItemProperty -Path Registry::$($exefile.Shell[0])
                    opencommand      = Get-ItemProperty -Path Registry::$($exefile.Shell[0])\command
                    runas            = Get-ItemProperty -Path Registry::$($exefile.Shell[1])
                    runascommand     = Get-ItemProperty -Path Registry::$($exefile.Shell[1])\command
                    runasuser        = Get-ItemProperty -Path Registry::$($exefile.Shell[2])
                    runasusercommand = Get-ItemProperty -Path Registry::$($exefile.Shell[2])\command
                }
                $Shellex = [PSCustomObject]@{
                    ContextMenuHandlers       = Get-ItemProperty -Path Registry::$($exefile.Shellex[0])
                    ContextMenuHandlersCompat = Get-ItemProperty -Path Registry::$($exefile.Shellex[0])\Compatibility
                    DropHandler               = Get-ItemProperty -Path Registry::$($exefile.Shellex[1])
                    PropertySheetHandlers     = Get-ItemProperty -Path Registry::$($exefile.Shellex[2])
                    PropertySheetHandlersShim = Get-ItemProperty -Path Registry::$($exefile.Shellex[2])\'ShimLayer Property Page'
                }

                #region HKCR:\.$FileExt
                    Write-Verbose ('Creating: {0}\.{1}' -F $HKCR, $FileExt)
                    New-Item -Path $HKCR -Name ".$FileExt" | Out-Null
                    New-ItemProperty -Path "$HKCR\.$FileExt" -Name $Def -Value "$($FileExt)file" | Out-Null
                    New-ItemProperty -Path "$HKCR\.$FileExt" -Name 'Content Type' -PropertyType STRING -Value $exe.'Content Type' | Out-Null
                    #region $FileExt\PersistentHandler
                        Write-Verbose ('Creating: {0}\.{1}\PersistentHandler' -F $HKCR, $FileExt)
                        New-Item -Path "$HKCR\.$FileExt" -Name 'PersistentHandler' | Out-Null
                        New-ItemProperty -Path "$HKCR\.$FileExt\PersistentHandler" -Name $Def -Value $exePersistentHandler.'(default)' | Out-Null
                    #endregion $FileExt\PersistentHandler
                #endregion HKCR:\.$FileExt

                #region HKCR:\$($FileExt)file
                    Write-Verbose ('Creating: {0}\{1}file' -F $HKCR, $FileExt)
                    New-Item -Path $HKCR -Name "$($FileExt)file" | Out-Null
                    New-ItemProperty -Path "$HKCR\$($FileExt)file" -Name $Def -Value $exefileKey.'(default)' | Out-Null
                    New-ItemProperty -Path "$HKCR\$($FileExt)file" -Name 'EditFlags' -PropertyType BINARY -Value $exefileKey.EditFlags | Out-Null
                    New-ItemProperty -Path "$HKCR\$($FileExt)file" -Name 'FriendlyTypeName' -PropertyType ExpandString -Value $exefileKey.FriendlyTypeName | Out-Null
                    #region DefaultIcon
                        Write-Verbose ('Creating: {0}\{1}file\DefaultIcon' -F $HKCR, $FileExt)
                        New-Item -Path "$HKCR\$($FileExt)file" -Name DefaultIcon | Out-Null
                        New-ItemProperty -Path "$HKCR\$($FileExt)file\DefaultIcon" -Name $Def -Value $exefile.DefaultIcon.'(default)' | Out-Null
                    #endregion DefaultIcon

                    #region shell
                            Write-Verbose ('Creating: {0}\{1}file\shell' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file" -Name shell | Out-Null
                        #region shell\open
                            Write-Verbose ('Creating: {0}\{1}file\shell\open' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shell" -Name open | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\open" -Name 'EditFlags' -PropertyType BINARY -Value $Shell.open.EditFlags | Out-Null
                            Write-Verbose ('Creating: {0}\{1}file\shell\open\command' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shell\open" -Name command | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\open\command" -Name $Def -Value $Shell.opencommand.'(default)' | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\open\command" -Name 'IsolatedCommand' -PropertyType STRING -Value $Shell.opencommand.IsolatedCommand | Out-Null
                        #endregion shell\open

                        #region shell\runas
                            Write-Verbose ('Creating: {0}\{1}file\shell\runas' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shell" -Name runas | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\runas" -Name 'HasLUAShield' -PropertyType STRING -Value '' | Out-Null
                            Write-Verbose ('Creating: {0}\{1}file\shell\runas\command' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shell\runas" -Name command | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\runas\command" -Name $Def -Value $Shell.runascommand.'(default)' | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\runas\command" -Name 'IsolatedCommand' -PropertyType STRING -Value $Shell.runascommand.IsolatedCommand | Out-Null
                        #endregion shell\runas

                        #region shell\runasuser    
                            Write-Verbose ('Creating: {0}\{1}file\shell\runasuser' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shell" -Name runasuser | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\runasuser" -Name $Def -Value $Shell.runasuser.'(default)' | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\runasuser" -Name 'Extended' -PropertyType STRING -Value '' | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\runasuser" -Name 'SuppressionPolicyEx' -PropertyType STRING -Value $Shell.runasuser.SuppressionPolicyEx | Out-Null
                            Write-Verbose ('Creating: {0}\{1}file\shell\runasuser\command' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shell\runasuser" -Name command | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shell\runasuser\command" -Name 'DelegateExecute' -PropertyType STRING -Value $Shell.runasusercommand.DelegateExecute | Out-Null
                        #endregion shell\runasuser
                    #endregion shell

                    #region shellex    
                        Write-Verbose ('Creating: {0}\{1}file\shellex' -F $HKCR, $FileExt)
                        New-Item -Path "$HKCR\$($FileExt)file" -Name shellex | Out-Null
                        #region shellex\ContextMenuHandlers
                            Write-Verbose ('Creating: {0}\{1}file\shellex\ContextMenuHandlers' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shellex" -Name ContextMenuHandlers | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shellex\ContextMenuHandlers" -Name $Def -Value $Shellex.ContextMenuHandlers.'(default)' | Out-Null
                            Write-Verbose ('Creating: {0}\{1}file\shellex\ContectMenuHandlers\Compatibility' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shellex\ContextMenuHandlers" -Name Compatibility | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shellex\ContextMenuHandlers\Compatibility" -Name $Def -Value $Shellex.ContextMenuHandlersCompat.'(default)' | Out-Null
                        #endregion shellex\ContextMenuHandlers

                        #region shellex\DropHandler    
                            Write-Verbose ('Creating: {0}\{1}file\shellex\DropHandler' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shellex" -Name DropHandler | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shellex\DropHandler" -Name $Def -Value $Shellex.DropHandler.'(default)' | Out-Null
                        #endregion shellex\DropHandler

                        #region PropertySheetHandlers
                            Write-Verbose ('Creating: {0}\{1}file\shellex\PropertySheetHandlers' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shellex" -Name PropertySheetHandlers | Out-Null
                            Write-Verbose ('Creating: {0}\{1}file\shellex\PropertySheetHandlers\ShimLayer Property Page' -F $HKCR, $FileExt)
                            New-Item -Path "$HKCR\$($FileExt)file\shellex\PropertySheetHandlers" -Name 'ShimLayer Property Page' | Out-Null
                            New-ItemProperty -Path "$HKCR\$($FileExt)file\shellex\PropertySheetHandlers\ShimLayer Property Page" -Name $Def -Value $Shellex.PropertySheetHandlersShim.'(default)' | Out-Null
                        #endregion PropertySheetHandlers
                    #endregion shellex
                #endregion HKCR:\$($FileExt)file
            } # Create Parameter Set
        } # Switch
    } # Process Block
    
    End {
        $KeysWithErrors = [System.Collections.ArrayList]::New()
        $NewRegKeys = @(
            "$HKCR\.$FileExt",
            "$HKCR\.$FileExt\PersistentHandler",
            "$HKCR\$($FileExt)file",
            "$HKCR\$($FileExt)file\shell", "$HKCR\$($FileExt)file\shell\open", "$HKCR\$($FileExt)file\shell\open\command",
            "$HKCR\$($FileExt)file\shell\runas", "$HKCR\$($FileExt)file\shell\runas\command",
            "$HKCR\$($FileExt)file\shell\runasuser", "$HKCR\$($FileExt)file\shell\runasuser\command",
            "$HKCR\$($FileExt)file\shellex", "$HKCR\$($FileExt)file\shellex\ContextMenuHandlers", "$HKCR\$($FileExt)file\shellex\DropHandler", "$HKCR\$($FileExt)file\shellex\PropertySheetHandlers")
        Switch ($PSCmdLet.ParameterSetName) {
            'Create' {
                Write-Verbose ('Checking registry to verify keys and subkeys were created')
                ForEach ($NewKey in $NewRegKeys) {
                    Switch (Test-Path -Path $NewKey) {
                        $True {
                            Write-Verbose ('Found key for {0}' -F $NewKey)
                        }
                        $False {
                            Write-Warning ('Unable to locate key for {0}' -F $NewKey)
                            [Void]$KeysWithErrors.Add($NewKey)
                        }
                    }
                } # RegKey test
            } # Create Set
            'Delete' {
                Write-Verbose ('Checking registry to verify keys and subkeys were Deleted')
                ForEach ($NewKey in $NewRegKeys) {
                    Switch (Test-Path -Path $NewKey) {
                        $True {
                            Write-Warning ('Found key for {0}' -F $NewKey)
                            [Void]$KeysWithErrors.Add($NewKey)
                        }
                        $False {
                            Write-Verbose ('Successfully deleted key {0}' -F $NewKey)
                        }
                    }
                } # RegKey test
            } # Delete Set
        } # Determine Param Set
        If ($KeysWithErrors.Count -gt 0) {
            Write-Output 'The following keys could not be verified:'
            $KeysWithErrors
        }
    } # End Block
} # End Function New-AppExt