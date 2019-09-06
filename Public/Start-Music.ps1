<#
    .SYNOPSIS
        Uses [Console]::Beep() to play music.
    .PARAMETER Notes
        Which notes to play
        
        Uppercase letters are used to represent Quarter Notes
        Lowercase letters are used to represent Eighth Notes
    .PARAMETER PauseChar
        Specifies which of the following characters that, when found in the Notes Parameter,
            designates to add a pause:
            .   Period
            |   Pipe
            ;   Semi-Colon
            ,   Comma
            ~   Tilde
            *   Asterisk
    .EXAMPLE
        PS C:\> Start-Music -Notes 'EDCDEEE..DDD..EGG..EDCDEEEEDDEDC...'

        Plays 'Mary had a Little Lamb' as quarter notes.        
    .EXAMPLE
        PS C:\> 'edcdeee**ddd**egg**edcdeeeeddedc***' | Start-Music -PauseChar *

        Plays 'Mary had a Little Lamb' as eighth notes.
    .EXAMPLE
        PS C:\> Start-Music

        Plays a single 'C' note.
    .NOTES
        Author      Jacob C Allen (JCA)
        Created     6/12/2019
        Modified    6/13/2019
        Version     1.2
#>
Function Start-Music {
    [CmdLetBinding()]
    Param (
        [Parameter(ValueFromPipeline,Position=0)]
        [AllowNull()]
        [AllowEmptyString()]
        [ValidateScript({ $PSItem.ToCharArray() | 
                            ForEach-Object{If ([String]$PSItem -NotMatch '[a-g.|;,~*]'){Throw ('Illegal character in string:[{0}]' -F $PSItem)}}
                            $True
                        })]
        [Alias('Music')]    
            [String[]]$Notes,
        
        [Parameter(Position=1)]
        [ValidateSet('.','|',';',',','~','*')]
            [String]$PauseChar = '.'
    ) # Param
    Begin {
        $NoteVal = [System.Collections.Hashtable]::New()
        # Quarter Notes
        $NoteVal.Add('C',@{Pitch=261;Length=250})
        $NoteVal.Add('D',@{Pitch=293;Length=250})
        $NoteVal.Add('E',@{Pitch=329;Length=250})
        $NoteVal.Add('F',@{Pitch=349;Length=250})
        $NoteVal.Add('G',@{Pitch=392;Length=250})
        $NoteVal.Add('A',@{Pitch=440;Length=250})
        $NoteVal.Add('B',@{Pitch=493;Length=250})
        # Eighth Notes
        $NoteVal.Add('c',@{Pitch=261;Length=180})
        $NoteVal.Add('d',@{Pitch=293;Length=180})
        $NoteVal.Add('e',@{Pitch=329;Length=180})
        $NoteVal.Add('f',@{Pitch=349;Length=180})
        $NoteVal.Add('g',@{Pitch=392;Length=180})
        $NoteVal.Add('a',@{Pitch=440;Length=180})
        $NoteVal.Add('b',@{Pitch=493;Length=180})
    } # Begin
    Process {
        If ([String]::IsNullOrEmpty($Notes)) {
                    $Pitch  = $NoteVal["C"].Pitch
                    $Length = $NoteVal["C"].Length
                    [Console]::Beep($Pitch, $Length)
        } Else {
            ForEach ($Note in $Notes.ToCharArray()) {
                If ($Note -cEq $PauseChar) {
                    # Adds a "Pause" when playing
                    Start-Sleep -Milliseconds 350
                } Else {
                    $Pitch  = $NoteVal[[String]$Note].Pitch
                    $Length = $NoteVal[[String]$Note].Length
                    [Console]::Beep($Pitch, $Length)
                }
            } # ForEach $Notes
        } # If ::IsNullOrEmptu($Notes)
    } # Process
} # Function Start-Music