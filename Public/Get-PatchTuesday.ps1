<#
.SYNOPSIS
    Finds the date of the second Tuesday of the current month.
.OUTPUTS
    System.DateTime
.EXAMPLE
    # Get Patch Tuesday for the month
    Get-PatchTuesday
.EXAMPLE
    # Is today Patch Tuesday?
    (get-date).Day -eq (Get-PatchTuesday).day
.NOTES

#>
Function Get-PatchTuesday {
    [CmdletBinding()]
    Param (
        [Parameter()]
        [ValidateSet('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')]
            [String]$weekDay = 'Tuesday',
        
        [Parameter()]
        [ValidateRange(0, 5)]
            [Int]$findNthDay = 2
    )

    # Get the date and find the first day of the month
    # Find the first instance of the given weekday
    $today = [datetime]::NOW
    $todayM = $today.Month.ToString()
    $todayY = $today.Year.ToString()
    [datetime]$strtMonth = $todayM + '/1/' + $todayY
    
    While ($strtMonth.DayOfWeek -notmatch $weekDay ) {
        $strtMonth = $StrtMonth.AddDays(1) 
    }
    $firstWeekDay = $strtMonth
  
    # Identify and calculate the day offset
    $dayOffset = If ($findNthDay -eq 1) {
        0
    } Else {
        ($findNthDay - 1) * 7
    }
    
    # Return date of the day/instance specified
    $patchTuesday = $firstWeekDay.AddDays($dayOffset) 
    
    Return $patchTuesday
} # Function Get-PatchTuesday