Function New-CustomDistributionGroup {
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
            [String]$Name,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $validCharSet = "[a-z0-9!#$%&'*+\-\/=?_^``{|}~]"

            If ((($PSItem -match $validCharSet) -and ($PSItem -notmatch '\.|\s')) -or (($PSItem -match "$validCharSet\.$validCharSet") -and ($PSItem -notmatch '\s'))) {
                $True
            } Else {
                Write-Host -ForegroundColor Yellow "An Alias can only contain the following characters:"
                Write-Host -ForegroundColor Yellow "  a-z A-Z 0-9 ! # $ % ' * + - / = ? _ ^ `` { | } ."
                Write-Host -ForegroundColor Yellow "Any periods (.) must be surrounded by other valid characters"
                Write-Host -ForegroundColor Yellow "  e.g. Help.Desk"
                $False
            }
        })]
            [String]$Alias = $Name.Replace(' ',$Null),
        [Parameter()]
        [ValidateSet('Open', 'Closed')]
            [String]$MemberJoinRestriction = 'Closed',
        [Parameter()]
        [ValidateSet('Open', 'Closed')]
            [String]$MemberDepartRestriction = 'Open',
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
            [String]$Description,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
            [String[]]$Members,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
            [String]$ManagedBy,
        [Parameter()]
            [Switch]$AllowExternalMail,
        [Parameter()]
            [String]$Notes
    )

    Process {
        $dlSplat = @{
            Name                    = $Name
            Alias                   = $Alias
            Type                    = 'Distribution'
            MemberJoinRestriction   = $MemberJoinRestriction
            MemberDepartRestriction = $MemberDepartRestriction
            OrganizationalUnit      = "OU=Distribution Lists,OU=Mail,OU=Departments,DC=hq,DC=first,DC=int"
            ManagedBy               = $ManagedBy
            Notes                   = $Notes
            ErrorAction             = 'Stop'
        }

        If ($Null -ne $Members) {
            # Add members to group if specified
            [Void]$dlSplat.Add('Members', $Members)
        }

        If ($AllowExternalMail) {
            # Sets the Distribution Group to receive both Internal and External emails
            [Void]$dlSplat.Add('RequireSenderAuthenticationEnabled', $False)
        } Else {
            # Sets the Distribution Group to only receive Internal emails
            [Void]$dlSplat.Add('RequireSenderAuthenticationEnabled', $True)
        }

        Try {
            New-DistributionGroup @dlSplat
        } Catch {
            Write-Warning "!! Distribution Group Creation Failed !!"
            $Error[0]
        }
    } # Process Block
} # Function New-CustomDistributionGroup