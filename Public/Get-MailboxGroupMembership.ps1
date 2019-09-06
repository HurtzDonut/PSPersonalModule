Function Get-MailboxGroupMembership {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Alias('Email')]
            [string]$UserName
    )
    Process {
        Get-DistributionGroup -ResultSize Unlimited -WarningAction SilentlyContinue | ForEach-Object { 
            If ((Get-DistributionGroupMember -Identity $PSItem.Alias).SamAccountName -Contains $UserName) {
                [PSCustomObject][Ordered]@{
                    'Name'           = $PSItem.Name
                    'Alias'          = $PSItem.Alias
                    'Email'          = $PSItem.PrimarySMTPAddress
                }
            }
        }
    }
} # Function Get-MailboxGroupMembership