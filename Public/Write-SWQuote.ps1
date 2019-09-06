<#
.SYNOPSIS
    This is a simple script designed to simply pull a random quote using Invoke-WebRequest, and display it in the Console
#>
Function Write-SWQuote {
    [CmdLetBinding()]
    Param ( )
    
    $QuoteList_Raw          = Invoke-WebRequest 'http://pastebin.com/raw/dWTSRyr9'
    $QuoteList_Formatted    = $QuoteList_Raw.Content.Split("`n").Trim()
    $SelectedQuote          = $QuoteList_Formatted | Where-Object { !$PSItem.StartsWith('#') } | Get-Random

    Write-Host $SelectedQuote -ForegroundColor Cyan
} # Function Write-SWQuote