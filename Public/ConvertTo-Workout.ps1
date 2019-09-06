<#
    .SYNOPSIS
        Generates a workout routine based on a string.
    .PARAMETER String
        The string to base the workout routine on.
    .EXAMPLE
        PS C:\> ConvertTo-Workout -String 'Cabbage Corp'
        
        Name                           Value
        ----                           -----
        C                              25 Squats
        a                              50 Jumping Jacks
        b                              25 Crunches
        b                              25 Crunches
        a                              50 Jumping Jacks
        g                              20 Arm Circles
        e                              1 Minute Wall Sit

        REST                           == 30 Seconds ==

        C                              25 Squats
        o                              40 Jumping Jacks
        r                              15 Push Ups
        p                              25 Arm Circles

        FINISH                         !!! GREAT JOB !!!
    .EXAMPLE
        PS C:\> 'Lee Dailey' | IWTPYU
        
        Name                           Value
        ----                           -----
        L                              2 Minute Wall Sit
        e                              1 Minute Wall Sit
        e                              1 Minute Wall Sit

        REST                           == 30 Seconds ==

        D                              20 Push Ups
        a                              50 Jumping Jacks
        i                              30 Jumping Jacks
        l                              2 Minute Wall Sit
        e                              1 Minute Wall Sit
        y                              20 Crunches

        FINISH                         !!! GREAT JOB !!!
    .NOTES
        Created By  : Jacob Allen
        Created On  : 11/5/2018
        Inspiration : https://www.reddit.com/r/mildlyinteresting/comments/a35edg/local_gym_challenges_members_to_spell_their_names/
        Reasoning   : ¯\_(ツ)_/¯
        Alias 1     : IWTPYU -> I WANT TO PUMP... YOU UP (https://youtu.be/089FXiadgXY)
        Alias 2     : ctw -> ConvertTo-Workout
#>

Function ConvertTo-Workout {
    [CmdLetBinding()]
    [Alias('IWTPYU','ctw')]
    Param (
        [Parameter(Position=0,ValueFromPipeline,Mandatory)]
        [Alias('Name')]
        [ValidatePattern('^[a-z][a-z\s]{1,}$')]
        [ValidateNotNullOrEmpty()]
            [String]$String
    )
    
    Begin {
        $exList         = 'Arm Circles','Burpees','Crunches','Jumping Jacks','Push Ups','Squats','Wall Sit','Minute'
        $durList        = 1,2,3,5,10,15,20,25,30,40,50
    } # Begin Block

    Process {
        $stringArray    = $String.Split(' ')
        $Routine        = [System.Collections.ArrayList]::New()

        Switch ($stringArray.Count) {
            {($PSItem -ge 1) -and ($PSItem -le 3)} {$restTime = 30 ; $restIncrease = 15}
            {($PSItem -gt 3) -and ($PSItem -le 5)} {$restTime = 20 ; $restIncrease = 10}
            {$PSItem -gt 5} {$restTime = 15 ; $restIncrease = 5}
        }

        ForEach ($Item in $stringArray) {
            $charArray  = $Item.ToCharArray()
            
            ForEach ($Letter in $charArray) {
                Switch -Regex ($Letter) {
                    'a'     {[void]$Routine.Add(@{$PSItem=($durList[10],$exList[3] -Join ' ')})}
                    'b'     {[void]$Routine.Add(@{$PSItem=($durList[7],$exList[2] -Join ' ')})}
                    'c'     {[void]$Routine.Add(@{$PSItem=($durList[7],$exList[5] -Join ' ')})}
                    '[dmz]' {[void]$Routine.Add(@{$PSItem=($durList[6],$exList[4] -Join ' ')})}
                    'e'     {[void]$Routine.Add(@{$PSItem=($durList[0],($exList[7,6] -Join ' ') -Join ' ')})}
                    '[fs]'  {[void]$Routine.Add(@{$PSItem=($durList[4],$exList[1] -Join ' ')})}
                    'g'     {[void]$Routine.Add(@{$PSItem=($durList[6],$exList[0] -Join ' ')})}
                    'h'     {[void]$Routine.Add(@{$PSItem=($durList[6],$exList[5] -Join ' ')})}
                    'i'     {[void]$Routine.Add(@{$PSItem=($durList[8],$exList[3] -Join ' ')})}
                    'j'     {[void]$Routine.Add(@{$PSItem=($durList[5],$exList[2] -Join ' ')})}
                    'k'     {[void]$Routine.Add(@{$PSItem=($durList[4],$exList[4] -Join ' ')})}
                    'l'     {[void]$Routine.Add(@{$PSItem=($durList[1],($exList[7,6] -Join ' ') -Join ' ')})}
                    'n'     {[void]$Routine.Add(@{$PSItem=($durList[5],$exList[1] -Join ' ')})}
                    'o'     {[void]$Routine.Add(@{$PSItem=($durList[9],$exList[3] -Join ' ')})}
                    'p'     {[void]$Routine.Add(@{$PSItem=($durList[7],$exList[0] -Join ' ')})}
                    'q'     {[void]$Routine.Add(@{$PSItem=($durList[8],$exList[2] -Join ' ')})}
                    'r'     {[void]$Routine.Add(@{$PSItem=($durList[5],$exList[4] -Join ' ')})}
                    't'     {[void]$Routine.Add(@{$PSItem=($durList[5],$exList[5] -Join ' ')})}
                    'u'     {[void]$Routine.Add(@{$PSItem=($durList[8],$exList[0] -Join ' ')})}
                    'v'     {[void]$Routine.Add(@{$PSItem=($durList[2],($exList[7,6] -Join ' ') -Join ' ')})}
                    'w'     {[void]$Routine.Add(@{$PSItem=($durList[3],$exList[1] -Join ' ')})}
                    'x'     {[void]$Routine.Add(@{$PSItem=($durList[6],$exList[3] -Join ' ')})}
                    'y'     {[void]$Routine.Add(@{$PSItem=($durList[6],$exList[2] -Join ' ')})}
                }
            }
            
            If ($Item -eq $stringArray[-1]) {
                [void]$Routine.Add(@{''=$Null})
                [void]$Routine.Add(@{'FINISH'="!!! GREAT JOB !!!"})    
            } Else {
                [void]$Routine.Add(@{''=$Null})
                [void]$Routine.Add(@{'REST'="== $restTime Seconds =="})
                [void]$Routine.Add(@{''=$Null})

                $restTime = $restTime + $restIncrease
            }
        }
    } # Process Block
    
    End {
        $Routine
    } # End Block
} # Function ConvertTo-Workout