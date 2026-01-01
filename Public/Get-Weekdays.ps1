Function Get-Weekdays {
    [CmdletBinding()]
    Param (
        [DateTime]$StartDate = [DateTime]::Today,
        [DateTime]$EndDate = [DateTime]::Today.AddMonths(1)
    )
    $typeCode = @'
using System;
public class DateMath{
public static int Weekdays(DateTime dStart, DateTime dEnd){
  int startday = ((int)dStart.DayOfWeek == 0 ? 7 : (int)dStart.DayOfWeek);
  int endday = ((int)dEnd.DayOfWeek == 0 ? 7 : (int)dEnd.DayOfWeek);
  TimeSpan ts = dEnd - dStart;
  int days = 0;
  if (startday <= endday){
    days = (((ts.Days / 7) * 5) + Math.Max((Math.Min((endday + 1), 6) - startday), 0));
  } else{
    days=(((ts.Days / 7) * 5) + Math.Min((endday + 6) - Math.Min(startday, 6), 5));  
  }
  return days; 
  }
}
'@
    Add-Type -TypeDefinition $typeCode

    [PSCustomobject][Ordered]@{
        StartDate   = $StartDate.ToShortDateString()
        EndDate     = $EndDate.ToShortDateString()
        Weekdays    = ([DateMath]::Weekdays($StartDate,$EndDate))
    }
}