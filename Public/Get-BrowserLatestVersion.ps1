<#
.SYNOPSIS
    Fetches the latest version(s) for one or more browsers
.PARAMETER Chrome
    Specifies to return the latest version for Chrome
.PARAMETER MSEdge
    Specifies to return the latest version for Microsoft Edge
.PARAMETER Firefox
    Specifies to return the latest version for Firefox
.EXAMPLE
    PS C:\> Get-BrowserLatestVersion

    MSEdge        Firefox Chrome
    ------        ------- ------
    125.0.2535.51 126.0   125.0.6422.76
.EXAMPLE
    PS C:\> Get-BrowserLatestVersion -Chrome

    Chrome
    ------
    125.0.6422.76
.EXAMPLE
    PS C:\> Get-BrowserLatestVersion -MSEdge -Firefox

    Firefox MSEdge
    ------- ------
    126.0   125.0.2535.51
.NOTES
    Author			Jacob C Allen
    Created			05-23-2024
    Modified		06-04-2024
    Modified By		Jacob C Allen
    Version			v1.1
#>
Function Get-BrowserLatestVersion {
    [CmdLetBinding(DefaultParameterSetName='All')]
    Param (
        [Parameter(ParameterSetName = 'Specific')]
            [Switch]$Chrome,
        [Parameter(ParameterSetName = 'Specific')]
            [Switch]$MSEdge,
        [Parameter(ParameterSetName = 'Specific')]
            [Switch]$Firefox,
        [Parameter(ParameterSetName = 'All')]
            [Boolean]$All = $True
    )
    Begin {
        $results    = [System.Collections.ArrayList]::New()
        $chromeURI  = 'https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions'
        $edgeURI    = 'https://edgeupdates.microsoft.com/api/products'
        $firefoxURI = 'https://product-details.mozilla.org/1.0/firefox_versions.json'

        $chromeSC = {
            $chromeWR = Invoke-WebRequest -Uri $chromeURI -Method GET
            ($chromeWR.Content |
                ConvertFrom-Json).Versions.Version |
                    Select-Object -First 1
        }
        $edgeSC = {
            $edgeWR = Invoke-Webrequest -Uri $edgeURI -Method GET
            (($edgeWR.Content |
                ConvertFrom-Json |
                    Where-Object Product -eq "Stable").Releases |
                        Where-Object {$PSItem.Architecture -eq "x64" -and $PSItem.Platform -eq "Windows"}).ProductVersion
        }
        $firefoxSC = {
            $firefoxWR = Invoke-WebRequest -Uri $firefoxURI -Method GET
            ($firefoxWR.Content |
                ConvertFrom-Json).LATEST_FIREFOX_VERSION
        }
        
    } # Begin
    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'All' {
                [Void]$results.Add((
                    [PSCustomObject][Ordered]@{
                        MSEdge  = $edgeSC.InvokeReturnAsIs()
                        Firefox = $firefoxSC.InvokeReturnAsIs()
                        Chrome  = $chromeSC.InvokeReturnAsIs()
                    }
                ))
            }
            'Specific' {
                $hash = @{}
                If ($MSEdge.IsPresent) {
                    [Void]$hash.Add('MSEdge',$edgeSC.InvokeReturnAsIs())
                }
                If ($Firefox.IsPresent) {
                    [Void]$hash.Add('Firefox',$firefoxSC.InvokeReturnAsIs())
                }
                If ($Chrome.IsPresent) {
                    [Void]$hash.Add('Chrome',$chromeSC.InvokeReturnAsIs())
                }
                
                If ($hash.Count -eq 1) {
                    [PSCustomObject]$hash
                } ElseIf ($hash.Count -eq 2) {
                    $sorted = $hash.Keys | Sort-Object -Descending
                
                    [Void]$results.Add((
                        [PSCustomObject][Ordered]@{
                            $sorted[0] = $hash[$sorted[0]]
                            $sorted[1] = $hash[$sorted[1]]
                        }
                    ))
                } ElseIf ($hash.Count -eq 3) {
                    $sorted = $hash.Keys | Sort-Object -Descending
                
                    [Void]$results.Add((
                        [PSCustomObject][Ordered]@{
                            $sorted[0] = $hash[$sorted[0]]
                            $sorted[1] = $hash[$sorted[1]]
                            $sorted[2] = $hash[$sorted[2]]
                        }
                    ))
                }
            }
        }
    } # Process
    End {
        $results
    } # End
} # Function Get-BrowserLatestVersion