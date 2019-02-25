<#
    .SYNOPSIS
        'Speaks' a given text using System.Speech.
    .DESCRIPTION
        Preforms the following, either locally or remotely:

            1. Gets the System's current Mute and Volume levels.
            2. If the System is muted, unmute it.
            3. Sets the Volume to a specified level. (Default is 25%)
            4. Changes the Speech Rate if needed.
            5. "Speaks" the supplied text.
            6. Sets Volume and Mute values back to what they originally were.
    .PARAMETER ComputerName
        Name(s) of the computer(s) to "speak" on.
    .PARAMETER Credential
        Credentials used to connect to the remote computer(s).
    .PARAMETER Text
        Text to "speak".
    .PARAMETER VolumePercentage
        How loud/quiet to set the volume when speaking.
    .PARAMETER Rate
        How fast/slow to speak the supplied text.
    .EXAMPLE
        PS C:\> Invoke-Speech -ComputerName PC1 -Text "I'm afraid I can't do that, Dave" -Volume 50 -Rate -1
        
        Verifies that PC1 is reachable, creates a PS Session, then speaks the phrase "I'm afraid I can't do that, Dave" on PC1, at 50% Volume and -1 Speech Rate
    .NOTES
        Author:     Jacob C Allen
        Created:    3/30/2018
        Modified:   2/25/2019
        Version:    2.0
#>
Function Invoke-Speech {
    [CmdletBinding(DefaultParameterSetName="Local")]
    [Alias('Speak')]
    Param (
        [Parameter(ParameterSetName="Remote",Mandatory)]
            [String]$ComputerName,
        
        [Parameter(ParameterSetName="Remote")]
            [PSCredential]$Credential,

        [Parameter(ParameterSetName="Local",Mandatory)]
        [Parameter(ParameterSetName="Remote",Mandatory)]
            [String]$Text,
        
        [Parameter(ParameterSetName="Local")]
        [Parameter(ParameterSetName="Remote")]
        [ValidateRange(20,100)]
            [Int]$VolumePercentage = 25,
        
        [Parameter(ParameterSetName="Local")]
        [Parameter(ParameterSetName="Remote")]
        [ValidateRange(-10,10)]
            [Int]$Rate = 0
    )
   
    Begin {
        # Convert Volume Percentage to Decimal Value
        $VolumeDecimal = [Decimal]::Round($VolumePercentage / 100,2)
        
        Switch ($PSCmdLet.ParameterSetName) {
            "Local" {
                Write-Verbose ('[{0}] : Speaking locally' -F $env:COMPUTERNAME)
            }
            "Remote" {
                Write-Verbose 'Speaking remotely'
                $RemoteSessionList = [System.Collections.ArrayList]::New()
                
                ForEach ($Machine in $ComputerName) {
                    Write-Verbose ('[{0}] : Verifying connectivity' -F $Machine)
                    If(!(Test-Connection -ComputerName $Machine -Count 1 -Quiet)) {
                        Write-Warning ("[{0}] : Unable to verify connectiviy" -F $Machine)
                        Break
                    }
                    
                    Write-Verbose ('[{0}] : Creating PS Session' -F $Machine)
                    $RemoteSession = If ($PSBoundParameters['Credential']) {
                        New-PSSession -ComputerName $ComputerName -Credential:$Credential    
                    } Else {
                       New-PSSession -ComputerName $ComputerName
                    }

                    Write-Verbose ('[{0}] : Adding PS Session to Remote Session List')
                    [Void]$RemoteSessionList.Add($RemoteSession)
                }      
            }
        }
        
        # Type Definition for [Audio]
        Write-Verbose 'Creating [Audio] Type Definition'
        $AudioType_Def = '
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
        }'
        
        Write-Verbose 'Creating Speech Script'
        $SpeechScript = {
            Param ($AudioType_Def,$VolumeDecimal,$Rate,$Text)
            #region Begin
                # Intialize dependencies
                Add-Type -TypeDefinition $AudioType_Def

                Add-Type -AssemblyName System.Speech
                
                # Intialize voice
                $Voice = [System.Speech.Synthesis.SpeechSynthesizer]::New()
                
                # Identify current Mute status,Volume level, Rate of speech
                $CurrentValues = @{
                    Mute    = [Audio]::Mute
                    Volume  = [Audio]::Volume
                }
            #endregion Begin

            #region Process
                # Un-mute if needed
                If ($CurrentValues.Mute) {
                    [Audio]::Mute = $False
                }
                
                # Change Volume
                [Audio]::Volume = $VolumeDecimal

                # Determine if rate of speech needs changed
                If ($Rate -ne 0) {
                    $Voice.Rate = $Rate
                }

                # Speak
                $Voice.Speak($Text)
            #endregion Process
            
            #region End
                # Set Volume,Mute values to what they were originally
                [Audio]::Volume = $CurrentValues.Volume
                [Audio]::Mute   = $CurrentValues.Mute

                # Dispose of voice
                $Voice.Dispose()
            #endregion End
        }
    } # Begin Block
    
    Process {
        Write-Verbose 'Creating initial Splat for Invoke-Command'
        $InvokeSplat = @{
            ScriptBlock     = $SpeechScript
            ArgumentList    = $AudioType_Def,$VolumeDecimal,$Rate,$Text
        }
        
        # If running against Remote Computer, add Remote PS Session to Splat
        If ($PSCmdLet.ParameterSetName -eq 'Remote') {
            Write-Verbose 'Adding Remote Sessions to Splat'
            $InvokeSplat.Add('Session',$RemoteSessionList)
        }
    } # Process Block

    End {
        $VerboseMessage = Switch ($PSCmdLet.ParameterSetName) {
            "Local" {$env:COMPUTERNAME}
            "Remote"{$ComputerName -Join ','}
        }
        Write-Verbose ('Invoking ScriptBlock on {0}' -F $VerboseMessage)
        
        Invoke-Command @InvokeSplat
    } # End Block
} # Function Invoke-RemoteSpeech