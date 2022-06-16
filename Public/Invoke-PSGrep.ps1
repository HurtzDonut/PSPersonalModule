<#
.SYNOPSIS
    Mimics Linux's grep search funciton
.EXAMPLE
    PS C:\> Invoke-PSGrep -DirectoryPath '\\Some\Path' -Filter *.config -Pattern '.+(.{20}DMDAPPDEV2.{20}).+'

    \\Some\Path\File1.config
	    [05] "WebServiceUrl" value="http://dmdappdev2.CINF.NET/Diamond/" 
    \\Some\Path\File2.config
	    [04] ointBehavior" address="http://dmdappdev2.cinf.net/Diamond/Ac
.EXAMPLE
    PS C:\> '\\Some\Path\File1.config' | grep -pat '.+(.{20}DMDAPPDEV2.{20}).+'

    \\Some\Path\File1.config
	    [05] "WebServiceUrl" value="http://dmdappdev2.CINF.NET/Diamond/" 
.INPUTS
    String
.NOTES
    Author		Jacob Allen
    Created     05/25/2022
    Modified    05/25/2022
    Additonal
        
#>
Function Invoke-PSGrep {
    [CmdLetBinding(DefaultParameterSetName = 'File')]
    [Alias('grep')]
    Param (
        [Parameter(ParameterSetName = 'Directory')]
            [String]$DirectoryPath,
        [Parameter(ParameterSetName = 'Directory')]
            [String]$Recurse = $True,
        [Parameter(ParameterSetName = 'Directory')]
            [String]$Filter,
        [Parameter(ParameterSetName = 'File',ValueFromPipeline)]
            [String]$FilePath,
        [Parameter(ParameterSetName = 'Directory')]
        [Parameter(ParameterSetName = 'File')]
        [ValidateScript({
            If (!($Null -Match $PSItem)) {
                $True
            } Else {
                Write-Warning ('Invalid RegEx pattern : {0}' -F $PSItem)
                Return
            }
        })]
            [String]$Pattern
    )
    Begin {
        $MasterPath = Switch ($PSCmdlet.ParameterSetName) {
            'Directory' {
                $DirectoryPath
            }
            'File' {
                $FilePath
            }
        }

        If (!(Test-Path -Path $MasterPath -ErrorAction SilentlyContinue)) {
            Write-Warning ('Unable to locate [{0}]' -F $MasterPath)
            Write-Warning 'Validate path and try again'
            Return
        }
    } # Begin Block
    
    Process {
        $GetChildItemSplat = Switch ($PSCmdlet.ParameterSetName) {
            'Directory' {
                @{
                    Path = $MasterPath
                    Filter = $PSBoundParameters['Filter']
                    File = $True
                    Recurse = $PSBoundParameters['Recurse']
                }
            }
            'File' {
                @{
                    Path = $MasterPath
                    File = $True
                }
            }
        }

        $Item = Get-ChildItem @GetChildItemSplat

        $Item |
            ForEach-Object {
                $Content = [IO.File]::ReadAllLines($PSItem.FullName)

                For ($i = 1;$i -lt $Content.Count;$i++) {
                    $FullFile = $PSItem.FullName
                    
                    $RegExResult = [RegEx]::Match($Content[($i - 1)],$Pattern,'IgnoreCase')

                    If ($RegExResult.Success) {
                        If ($FullFile -ne $CurrentFile) {
                            Write-Host ('{0}' -F $FullFile) -ForegroundColor Yellow
                        }
                        
                        Write-Host "`t[" -NoNewline
                        Write-Host ('{0:0#}' -F $i) -ForegroundColor Green -NoNewline
                        Write-Host '] ' -NoNewline
                        If ($RegExResult.Groups.Count -gt 1) {
                            $Display = $RegExResult.Groups[1].Value
                        } Else {
                            $RegExResult.Value
                        }
                        Write-Host ('{0}' -F $Display)

                        $CurrentFile = $FullFile
                    }
                }
            }
    } # Process Block

    End {
        $CurrentFile = $Null
    }
} # Function Invoke-PSGrep