<#
.SYNOPSIS
    Sets custom NTFS permissions on a desginated folder.
.DESCRIPTION
    Resets NTFS permissions on the target folder. Then grants\removes permissions based on User selection.
.PARAMETER Folder
    Target folder to set NTFS permissions on.
.PARAMETER Owner
    Designated owner of target folder once function is complete. For domain user, must be entered as 'domain\username'.
.PARAMETER GrantACL
    Specifies additional accounts to grant access rights to.
.PARAMETER AccessLevel
    Designates what level of access the accounts specified in GrantACL are given. All accounts specified, receive this level of access.
.PARAMETER Inheritance
    Designates if inheritance should be enabled, disabled and ACEs copied, or disabled and all ACEs removed. Disabled is default.
.PARAMETER RemoveACL
    Specifies what accounts, if any, are removed from the ACL for the target folder.
.PARAMETER Log
    Defines the location of the log file.
.PARAMETER SessionLog
    Defines the location of the log file for the current session. A new file is created every run.
.EXAMPLE
    PS C:\> Set-CustomNTFSPermissions -Folder 'C:\Test' -Owner 'domain\User1' -GrantACL 'domain\User2','domain\User3' -AccessLevel M -RemoveACL 'Users','Authenticated Users' -Verbose
    
    VERBOSE: Changing owner to local Administrators group.
    VERBOSE: Resetting ACLs to default inherited.
    VERBOSE: Changing owner to "domain\User1"
    VERBOSE: Granting "SYSTEM", "FullControl" access rights.
    VERBOSE: Granting "domain\User1", "FullControl" access rights.
    VERBOSE: Additional access rights requested.
    VERBOSE: Granting "domain\User2", "Modify" access rights.
    VERBOSE: Additional access rights requested.
    VERBOSE: Granting "domain\User3", "Modify" access rights.
    VERBOSE: Setting inheritance to "d":"Disable and copy ACEs"
    VERBOSE: Request to remove access rights detected
    VERBOSE: Removing acecss rights for: "Users"
    VERBOSE: Request to remove access rights detected
    VERBOSE: Removing acecss rights for: "Authenticated Users"
.EXAMPLE
    PS C:\> Set-CustomNTFSPermissions -Folder 'C:\Test' -Owner 'domain\User1' -Inheritance e
.EXAMPLE
    PS C:\> Set CustomNTFSPermissions -Folder 'C:\Test' -Owner 'domain\User2' -Inheritance r -Grant 'domain\DocAdmins','Backup Operators' -Access F
.NOTES
    AUTHOR:     /u/_Cabbage_Corp_
    CREATED:    April 16, 2018
#>
Function Set-CustomNTFSPermissions{ 
    Param(
        [parameter(
            Mandatory=$True
        )]
        [string]$Folder,
        
        [parameter(
            HelpMessage="For a domain account, enter 'domain\username'."
        )]
        [string]$Owner,
        
        [parameter(
            HelpMessage="Owner is granted full control by default. For a domain account, enter 'domain\username'."
        )]
        [Alias("Grant")]
        [array]$GrantACL,
        
        [parameter(
            HelpMessage="FullControl is granted by default. All accounts specified will receive the same rights."
        )]
        [ValidateSet("N","F","M","RX","R","W","D")]
        [Alias("Access")]
        $AccessLevel = "F",
        
        [parameter(
            HelpMessage='Disable inheritance is selected by default.'
        )]
        [ValidateSet("e","d","r")]
        $Inheritance = "d",
        
        [parameter(
            HelpMessage="For a domain account, enter 'domain\username'."
        )]
        [Alias("Remove")]
        [array]$RemoveACL,
        
        [parameter()]
        [string]$Log = "C:\Temp\Logs\CustomNTFS_$(Get-Date -f 'yyMMddhhmm').log",
        
        [parameter()]
        [string]$SessionLog = "C:\Temp\Logs\Session.CustomNTFS.log"
    ) 
    
    Begin{
        $s = [datetime]::now
        # Display folder permissions before run
        Write-Host -Fore Yellow ('Permissions for "{0}" currently:' -F $Folder)
        (Get-Item $Folder).GetAccessControl().Access | Format-Table -Auto
        
        # Create $Log and $SessionLog
        New-Item -Path $Log -ItemType File -Force | Out-Null
        New-Item -Path $SessionLog -ItemType File -Force | Out-Null
        
        # Add Start time to $Log
        Add-Content $Log "[$s] START:`t$Folder" -Force
    } # Begin Block
    
    Process{
            # Takeown /F(FileName) <..> /A(Give ownership to Admin group) /R(Recurse) /D(Default answer to prompt) <..>
            Write-Verbose 'Changing owner to local Administrators group.'
            &takeown /F $Folder /A /R /D Y | Out-File $SessionLog -Append -Force
            
            # Icacls <..> /reset(Sets ACLs to default inherited) /T(Preform on all matching files) /C(Continue on error)
            Write-Verbose  'Resetting ACLs to default inherited.'
            &icacls $Folder /reset /T /C | Out-File $SessionLog -Append -Force
        
            # Icacls <..> /setowner(changes owner of all matching files) <..> /T(^) /C(^)
            Write-Verbose ('Changing owner to "{0}"' -f $Owner)
            &icacls $Folder /setowner $Owner /T /C | Out-File $SessionLog -Append -Force
            
            # Icacls <..> /grant(grants specified user access rights) <..> (ObjectInherit)(ContainterInherit)FullControl
            Write-Verbose 'Granting "SYSTEM", "FullControl" access rights.'
            &icacls $Folder /grant SYSTEM':(OI)(CI)F' | Out-File $SessionLog -Append -Force
            Write-Verbose ('Granting "{0}", "FullControl" access rights.' -f $Owner)
            &icacls $Folder /grant $Owner':(OI)(CI)F' | Out-File $SessionLog -Append -Force
            
            ForEach($GAccount in $GrantACL){
                # Regex '\S' matches any non-whitespace character
                # I had to do it this way, because wether I specified an account or not, the loop tried to run.
                If($GAccount -match '\S'){
                    Write-Verbose 'Additional access rights requested.'
                    Switch($AccessLevel){
                        'N'{$V = 'No'}
                        'F'{$V = 'FullControl'}
                        'M'{$V = 'Modify'}
                        'RX'{$V = 'Read and Execute'}
                        'R'{$V = 'Read-Only'}
                        'W'{$V = 'Write-Only'}
                        'D'{$V = 'Delete'}
                    }
                    Write-Verbose ('Granting "{0}", "{1}" access rights.' -f $GAccount,$V)
                    &icacls $Folder /grant $GAccount':(OI)(CI)'$AccessLevel | Out-File $SessionLog -Append -Force     
                } else {
                    Write-Verbose 'No additional access rights requested.'
                }
            }

            # Icacls <..> /inheritance:d(disable inheritance and copy the ACEs)
            Switch($Inheritance){
                'e'{$V2='Enable'}
                'd'{$V2='Disable and copy ACEs'}
                'r'{$V2='Remove all inherited ACEs'}
            }
            Write-Verbose ('Setting inheritance to "{0}":"{1}"' -f $Inheritance,$V2)
            &icacls $Folder /inheritance:$Inheritance | Out-File $SessionLog -Append -Force
            
            # Icacls <..> /remove(Removes all occurrences of the SID in the ACL) <..>
            ForEach($RAccount in $RemoveACL){
                # Regex '\S' matches any non-whitespace character
                # I had to do it this way, because wether I specified an account or not, the loop tried to run.
                If($RAccount -Match '\S'){
                    Write-Verbose 'Request to remove access rights detected'
                    Write-Verbose ('Removing acecss rights for: "{0}"' -f $RAccount)
                    &icacls $Folder /remove $RAccount | Out-File $SessionLog -Append -Force
                } else {
                    Write-Verbose 'No request to remove access rights detected.'    
                }
            }
    } # Process Block
    
    End{
        $e = [datetime]::now
        $TotalTime = $e -$s
        Add-Content $Log "[$e] END:`t$Folder" -Force
        Add-Content $Log "Processed in: $($TotalTime.Hours)h $($TotalTime.Minutes)m $($TotalTime.Seconds)s" -Force
        Add-Content $Log "--------------------" -Force
        
        # Display folder permissions after run
        Write-Host -Fore Cyan ('Permissions for "{0}" now:' -F $Folder)
        (Get-Item $Folder).GetAccessControl().Access | Format-Table -Auto
    } # End Block
} # Function Set-CustomNTFSPermissions