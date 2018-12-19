$PublicPath     = Join-Path -Path $PSScriptRoot -ChildPath Public
# $PrivatePath    = Join-Path -Path $PSScriptRoot -ChildPath Private

$PublicFiles    = Get-ChildItem -Path $PublicPath -Include *.ps1 -Recurse
# $PrivateFiles   = Get-ChildItem -Path $PrivatePath -Include *.ps1 -Recurse


ForEach ($File in $PublicFiles) {
    Try {
        Import-Module -Path $File.FullName -ErrorAction Stop
    } Catch {
        Write-Warning ('Failed to load : {0}' -F $File.BaseName)
    }
}