<#
    .SYNOPSIS
        Compresses a folder on a remote computer.
    .DESCRIPTION
        Alias : CoRD

        Attempts to connect to a remote computer and compress (zip) a directory using Compress-Archive.    
    .PARAMETER ComputerName
        Alias : Server

        Remote compter name(s) to connect to.
    .PARAMETER SourceDirectory
        Aliases : Directory, Folder

        Location of the directory (folder) to compress.
    .PARAMETER CompressedFileName
        Alias : ZipName

        File name for the compressed file. Do NOT include [.zip].
        Must match the following regex pattern: ^[^\\\/:*?\"<>|]+(?<!\.zip)$

        Regex pattern explanation: 
            ^                   : Start of the string
            [^\\\/:*?\"<>|]+    : One or more characters not in - \ / : * ? " < >
            (?<!\.zip)          : Negative Lookbehind - Ensures that the pattern does NOT match [.zip] at the current position
            $ 

        e.g. 
            Original Directory Name ---- C:\Temp\ImportantLogFiles
            Compressed Directory Name -- ImportantLogFiles_010318_1022
    .PARAMETER CompressionLevel
        Specifies the amount of compression to apply.
    
        Fastest - Minimal compression. May result in larger archive. Best for large number/size of files.
        Optimal - Good compression. Time depends on number/size of files.
        NoCompression - Do not compress source file(s)
    .PARAMETER Update
        Updates the specified archive by replacing older versions of files in the archive with newer versions of files that have the same names. 
        
        You can also add this parameter to add files to an existing archive.
    .PARAMETER Force
        Specifies whether or not to overwrite an existing archive.
    .EXAMPLE
        PS C:\> Compress-RemoteDirectory -ComputerName Remote01 -SourceDirectory 'C:\ADS\Client\Logs'

        CompressResult  : SUCCESS
        TargetComputer  : Remote1
        SourceDirectory : C:\ADS\Client\Logs
        CompressedFile  : C:\ADS\Client\Logs_010319_1041.zip
        CompressionLevel: Optimal
        UpdateArchive   : False
        Error           :

        Tries to connect to Remote01 and compress the folder 'C:\ADS\Client\Logs' using the optimal compression method.
    .EXAMPLE
        PS C:\> Compress-RemoteDirectory -Server RemoteS01,RemoteS02 -SourceDirectory "C:\Temp" -CompressionLevel Fastest

        CompressResult  : SUCCESS
        TargetComputer  : RemoteS01
        SourceDirectory : C:\Temp
        CompressedFile  : C:\Temp_10319_1641.zip
        CompressionLevel: Fastest
        UpdateArchive   : False
        Error           :

        CompressResult  : SUCCESS
        TargetComputer  : RemoteS02
        SourceDirectory : C:\Temp
        CompressedFile  : C:\Temp_10319_1641.zip
        CompressionLevel: Fastest
        UpdateArchive   : False
        Error           :

        Tries to connect to both RemoteS01 and RemoteS02. 
        Then tries to compress the local 'C:\Temp' folder on each server using minimal compression.
    .EXAMPLE
        PS C:\> 'Remote3','Remote4' | CoRD -Dir C:\Temp\Logs -ZipName ClientLogs -Update | FT -Auto

        CompressResult TargetComputer SourceDirectory    CompressedFile                     CompressionLevel Error
        -------------- -------------- ---------------    --------------                     ---------------- -----
        SUCCESS        Remote3        C:\Temp\New folder C:\Temp\New folder_010319_1221.zip Optimal
        SUCCESS        Remote4        C:\Temp\New folder C:\Temp\New folder_010319_1221.zip Optimal

        Updates the archive C:\Temp\ClientLogs.zip with any new(er) files from the directory C:\Temp\Logs on both Remote3 and Remote4.
    .INPUTS
        System.String
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES
        Author:     Jacob C Allen (HurtzDonut01)
        Created:    06/29/2018
        Modified:   01/03/2019
        Version:    1.2.0
#>
Function Compress-RemoteDirectory {
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='Default')]
    [Alias('CoRD')]
    Param (
        [Parameter(Mandatory,ValueFromPipeline,ParameterSetName='Default')]
        [Parameter(Mandatory,ValueFromPipeline,ParameterSetName='Force')]
        [ValidateNotNullOrEmpty()]
        [Alias('Server')]
            [String[]]$ComputerName,

        [Parameter(Mandatory,ParameterSetName='Default')]
        [Parameter(Mandatory,ParameterSetName='Force')]
        [ValidateNotNullOrEmpty()]
        [Alias('Directory','Folder')]
            [String]$SourceDirectory,

        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Force')]
        # The below pattern verifies that the file name does contain the following characters: \ / : * ? " < > |
        # And that the entered name does not end with the file extension [.zip]
        [ValidatePattern('^[^\\\/:*?\"<>|]+(?<!\.zip)$')]
        [Alias('ZipName')]
            [String]$CompressedFileName = "$($SourceDirectory.Split('\')[-1])_$(Get-Date -f MMddyy_HHmm)",

        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Force')]
        [ValidateSet('Fastest','Optimal','NoCompression')]
            [String]$CompressionLevel = 'Optimal',

        [Parameter(ParameterSetName='Default')]
            [Switch]$Update,

        [Parameter(ParameterSetName='Force')]
            [Switch]$Force
    )

    Begin { } # Begin Block

    Process {
        $Results = [System.Collections.ArrayList]::New()

        ForEach ($Computer in $ComputerName) {
            Write-Verbose ('Testing Connection to: {0}' -F $CN)
            # Verify target computer is reachable
            If (!(Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
                Write-Warning ('{0} is offline\unreachable' -F $Computer)
                Break
            } Else {        
                # Convert 'Local' directory path (e.g. C:\Temp), to 'remote' directory path (e.g. \\Comp1\c$\Temp)
                # Only, used for the ShouldProcess message
                $WhatIfDirBase  = $SourceDirectory -Split ":\\",2,"RegexMatch"
                $WhatIfDir      = "\\$($Computer.ToUpper())\$($WhatIfDirBase[0].ToUpper())`$\$($WhatIfDirBase[1])"
                
                If ($PSCmdlet.ShouldProcess("$WhatIfDir", "Compress Directory")) {                    
                    # Remotely run 'Compress-Archive'
                    [void]$Results.Add(
                        (Invoke-Command -ComputerName $Computer -ScriptBlock {
                            $ZipErr = $Null

                            # Verify Source Directory exists
                            If (!(Test-Path $Using:SourceDirectory)) {
                                $ZipErr = ('Unable to locate source directory')
                                $ZipResult = 'FAIL'
                            } Else {
                                $CompressionPath = Get-Item -Path $Using:SourceDirectory

                                $CompressionSplat = @{
                                    Path            = ($Using:SourceDirectory,'\*' -Join '')
                                    DestinationPath = ($CompressionPath.Parent.FullName,'\',$Using:CompressedFileName,'.zip' -Join '')
                                    CompressionLevel= $Using:CompressionLevel
                                }
                                # If the [-Force] switch was specified, add [-Force] to the splat.
                                # If the [-Update] switch was specified, add [-Update] to the splat.
                                # Otherwise, don't add either.
                                If ($Using:Force) {
                                    $CompressionSplat.Add('Force',$Using:Force)
                                } ElseIf ($Using:Update) {
                                    $CompressionSplat.Add('Update',$Using:Update)
                                }
                                
                                Try {
                                    Compress-Archive @CompressionSplat
                                    $ZipResult  = 'SUCCESS'
                                } Catch {
                                    $ZipResult                          = 'FAIL'
                                    $ZipErr                             = $PSItem.Exception.Message
                                    $CompressionSplat.CompressionLevel  = $Null
                                }
                            }

                            # Results object
                            [PSCustomObject][Ordered]@{
                                CompressResult  = $ZipResult
                                TargetComputer  = $env:COMPUTERNAME
                                SourceDirectory = $Using:SourceDirectory
                                CompressedFile  = $CompressionSplat.DestinationPath
                                CompressionLevel= $CompressionSplat.CompressionLevel
                                Error           = $ZipErr
                            }
                        } -HideComputerName # Invoke-Command
                    )) # Add to $Results
                } # '-WhatIf' Check
            }
        } # ForEach
    } # Process Block

    End {
        [PSCustomObject]$Results | Select-Object CompressResult,TargetComputer,SourceDirectory,CompressedFile,CompressionLevel,Error
    } # End Block 
} # Function Compress-RemoteDirectory