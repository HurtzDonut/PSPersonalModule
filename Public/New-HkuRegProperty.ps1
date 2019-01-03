Function New-HkuRegProperty {
    Param (
        [Parameter(Mandatory)]
        [ValidatePattern('[^\\@]')]
            [String]$UserAcct,

        [Parameter(Mandatory,HelpMessage="Do not include HIVE or user SID.`n`nExample: \Software\Microsoft\Office\15.0\Outlook\Security")]
            [String]$KeyPath,

        [Parameter(Mandatory)]
            [String]$PropertyName,

        [Parameter(Mandatory)]
            [String]$PropertyType,

        [Parameter(Mandatory)]
            [String]$PropertyValue,

        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
            [String[]]$ComputerName = $env:COMPUTERNAME
    )

    Begin {
        Write-Verbose ('[{0}] : Translating [{1}] to Security Identifier (SID)' -F (Get-Date).ToString('g'),$UserAcct)
        $Sid        = [System.Security.Principal.NTAccount]::New($UserAcct).Translate([System.Security.Principal.SecurityIdentifier]).Value
    }
    
    Process {
        Write-Verbose ('[{0}] : Running script block on [{1}] computer(s)' -F (Get-Date).ToString('g'),$ComputerName.Count)
        ForEach ($Computer in $ComputerName) {
            $Result = Invoke-Command -ComputerName $Computer -ScriptBlock {
                #region Remote Begin
                    Write-Verbose ('[{0}] : Creating temporary PSDrive [HKU:\] to [HKEY_USERS]' -F (Get-Date).ToString('g'))
                    $Drive          = New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS
                    $FullRegpath    = ('HKU:\{0}' -F ($Using:Sid,$Using:KeyPath -Join '\'))
                    $NewProp        = $Using:PropertyName
                    $PropType       = $Using:PropertyType
                    $PropVal        = $Using:PropertyValue

                    Try {
                        $RegKey     = Get-Item -Path $FullRegpath -ErrorAction Stop
                    } Catch {
                        $PropCreated = "Write-Warning ('[{0}] : Error on [{1}]' -F (Get-Date).ToString('g'),`"$env:COMPUTERNAME`")
                                        Write-Warning ('[{0}] : Unable to locate [{1}]' -F (Get-Date).ToString('g'),'$FullRegpath');
                                        Write-Warning ('[{0}] : {1}' -F (Get-Date).ToString('g'),`"$($PSItem.Exception.Message)`")"
                        Return $PropCreated
                    }
                #endregion Remote Begin

                #region Remote Process
                    Write-Verbose ('[{0}] : Adding location [{1}] to top of stack' -F (Get-Date).ToString('g'),$PSScriptRoot)
                    Push-Location

                    Write-Verbose ('[{0}] : Setting location to [{1}]' -F (Get-Date).ToString('g'),$RegKey.Name)
                    Set-Location $RegKey.Name

                    Write-Verbose ('[{0}] : Testing to see if property [{1}] exists' -F (Get-Date).ToString('g'),$NewProp)
                    $PropTest   = Get-ItemProperty -Path $RegKey.Name -Name $NewProp -ErrorAction SilentlyContinue

                    If ($Null -ne $PropTest) {
                        Write-Verbose ('[{0}] : Property [{1}] already exists within [{2}]' -F (Get-Date).ToString('g'),$NewProp,$RegKey.PSChildName)
                        $PropCreated = "Write-Warning ('[{0}] : Error on [{1}]' -F (Get-Date).ToString('g'),`"$env:COMPUTERNAME`");
                                        Write-Warning ('[{0}] : Property creation failed!' -F (Get-Date).ToString('g'));
                                        Write-Warning ('[{0}] : Property [{1}] already exists within [{2}]' -F (Get-Date).ToString('g'),'$NewProp',`"$($RegKey.PSChildName)`")"
                        Return $PropCreated
                    } Else {
                        Write-Verbose ('[{0}] : Property [{1}] does not exist within [{2}]' -F (Get-Date).ToString('g'),$NewProp,$RegKey.PSChildName)
                        Write-Verbose ('[{0}] : Creating property [{1}] within [{2}]' -F (Get-Date).ToString('g'),$NewProp,$RegKey.PSChildName)

                        Try {
                            $PropCreated = New-ItemProperty -Path $RegKey.Name -Name $NewProp -PropertyType $PropType -Value $PropVal
                        } Catch {
                            $PropCreated = "Write-Warning ('[{0}] : Error on [{1}]' -F (Get-Date).ToString('g'),`"$env:COMPUTERNAME`")
                                            Write-Warning ('[{0}] : Property creation failed!' -F (Get-Date).ToString('g'));
                                            Write-Warning ('[{0}] : Error was - [{1}]' -F (Get-Date).ToString('g'),`"$($PSItem.Exception.Message)`")"
                            Break
                        }
                    }
                #endregion Remote Process

                #region Remote End
                    Write-Verbose ('[{0}] : Setting location back to [{1}]' -F (Get-Date).ToString('g'),$PSScriptRoot)
                    Pop-Location
            
                    Write-Verbose ('[{0}] : Removing PSDrive [{1}]' -F (Get-Date).ToString('g'),$Drive.Name)
                    Remove-PSDrive -Name $Drive.Name

                    $PropCreated
                #endregion Remote End
            } # Invoke End
            
            
            Switch ($Result) {
                {$PSItem.GetType().Name -eq 'String'} { 
                    Write-Verbose ('[{0}] : Return results based on type' -F (Get-Date).ToString('g'))
                    Invoke-Expression $Result
                }
                {$PSItem.GetType().Name -eq 'PSCustomObject'}  { 
                    Write-Verbose ('[{0}] : Return results based on type' -F (Get-Date).ToString('g'))
                    Write-Verbose ('[{0}] : {1}' -F (Get-Date).ToString('g'),$PSItem.PSComputerName)
                    Write-Verbose ('[{0}] : Property creation successful!!' -F (Get-Date).ToString('g'))
                    $Result 
                }
                Default {}
            }
        }
    } # Process Block

    End { } # End Block
} # Function New-HkuRegProperty