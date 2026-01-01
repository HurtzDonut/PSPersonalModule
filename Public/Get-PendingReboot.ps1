<#
.SYNOPSIS
    Gets the pending reboot status on a local or remote computer.

.DESCRIPTION
    This function will query the registry on a local or remote computer and determine if the
    system is pending a reboot, from Microsoft updates, Configuration Manager Client SDK, Pending Computer 
    Rename, Domain Join or Pending File Rename Operations. For Windows 2008+ the function will query the 
    CBS registry key as another factor in determining pending reboot state.  "PendingFileRenameOperations" 
    and "Auto Update\RebootRequired" are observed as being consistant across Windows Server 2003 & 2008.
	
    CBServicing = Component Based Servicing (Windows 2008+)
    WindowsUpdate = Windows Update / Auto Update (Windows 2003+)
    CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value
    PendComputerRename = Detects either a computer rename or domain join operation (Windows 2003+)
    PendFileRename = PendingFileRenameOperations (Windows 2003+)
    PendFileRenVal = PendingFilerenameOperations registry value; used to filter if need be, some Anti-
                     Virus leverage this key for def/dat removal, giving a false positive PendingReboot

.PARAMETER ComputerName
    A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

.PARAMETER ErrorLog
    A single path to send error data to a log file.

.EXAMPLE
    PS C:\> Get-PendingReboot -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize
	
    Computer CBServicing WindowsUpdate CCMClientSDK PendFileRename PendFileRenVal RebootPending
    -------- ----------- ------------- ------------ -------------- -------------- -------------
    DC01           False         False                       False                        False
    DC02           False         False                       False                        False
    FS01           False         False                       False                        False

    This example will capture the contents of C:\ServerList.txt and query the pending reboot
    information from the systems contained in the file and display the output in a table. The
    null values are by design, since these systems do not have the SCCM 2012 client installed,
    nor was the PendingFileRenameOperations value populated.

.EXAMPLE
    PS C:\> Get-PendingReboot
	
    Computer           : WKS01
    CBServicing        : False
    WindowsUpdate      : True
    CCMClient          : False
    PendComputerRename : False
    PendFileRename     : False
    PendFileRenVal     : 
    RebootPending      : True
	
    This example will query the local machine for pending reboot information.
	
.EXAMPLE
    PS C:\> $Servers = Get-Content C:\Servers.txt
    PS C:\> Get-PendingReboot -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation
	
    This example will create a report that contains pending reboot information.

.LINK
    Component-Based Servicing:
    http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx
	
    PendingFileRename/Auto Update:
    http://support.microsoft.com/kb/2723674
    http://technet.microsoft.com/en-us/library/cc960241.aspx
    http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx

    SCCM 2012/CCM_ClientSDK:
    http://msdn.microsoft.com/en-us/library/jj902723.aspx

.NOTES
    Author:  Brian Wilhite
    Email:   bcwilhite (at) live.com
    Date:    29AUG2012
    PSVer:   2.0/3.0/4.0/5.0
    Updated: 27JUL2015
    UpdNote: Added Domain Join detection to PendComputerRename, does not detect Workgroup Join/Change
             Fixed Bug where a computer rename was not detected in 2008 R2 and above if a domain join occurred at the same time.
             Fixed Bug where the CBServicing wasn't detected on Windows 10 and/or Windows Server Technical Preview (2016)
             Added CCMClient property - Used with SCCM 2012 Clients only
             Added ValueFromPipelineByPropertyName=$true to the ComputerName Parameter
             Removed $Data variable from the PSObject - it is not needed
             Bug with the way CCMClientSDK returned null value if it was false
             Removed unneeded variables
             Added PendFileRenVal - Contents of the PendingFileRenameOperations Reg Entry
             Removed .Net Registry connection, replaced with WMI StdRegProv
             Added ComputerPendingRename
#>
Function Get-PendingReboot {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("CN", "Computer")]
            [String[]]$ComputerName = "$env:COMPUTERNAME",
        [Parameter()]
            [String]$ErrorLog,
        [Parameter()]
            [PSCredential]$Credential
    )

    Process {
        Foreach ($Computer in $ComputerName) {
            Try {
                #  Setting pending values to false to cut down on the number of else statements
                $compPendRen, $pendFileRename, $pending, $sccm = $false, $false, $false, $false
                        
                #  Setting CBSRebootPend to null since not all versions of Windows has this value
                $CBSRebootPend = $null
						
                #  Querying CIM for build version
                $getBuildSplat = @{
                    ClassName   = 'Win32_OperatingSystem'
                    Property    = @('BuildNumber','CSName')
                    ComputerName= $ComputerName
                }
                If ($null -ne $Credential) {
                    $cimSession = New-CimSession -Credential $Credential -ComputerName $ComputerName
                    
                    $getBuildSplat.Remove('ComputerName')
                    $getBuildSplat['CimSession'] = $cimSession
                }
                $cimOS = Get-CimInstance @getBuildSplat

                # TODO: Invoke-Command if $Credential provided
                #  Making registry connection to the local/remote computer
                $hklm   = [UInt32] "0x80000002"
                $wmiReg = [WMIClass]::New("\\$Computer\root\default:StdRegProv")
						
                #  If Vista/2008 & Above query the CBS Reg Key
                If ([Int32]$cimOS.BuildNumber -ge 6001) {
                    $regSubKeysCbs = $wmiReg.EnumKey($hklm, "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
                    $cbsRebootPend = $regSubKeysCbs.sNames -contains "RebootPending"		
                }
							
                #  Query WUAU from the registry
                $regWuauRebootReq = $wmiReg.EnumKey($hklm, "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
                $wuauRebootReq = $regWuauRebootReq.sNames -contains "RebootRequired"
						
                #  Query PendingFileRenameOperations from the registry
                $regSubKeySm = $wmiReg.GetMultiStringValue($hklm, "SYSTEM\CurrentControlSet\Control\Session Manager\", "PendingFileRenameOperations")
                $regValuePfro = $regSubKeySm.sValue

                #  Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
                $netlogon = $wmiReg.EnumKey($HKLM, "SYSTEM\CurrentControlSet\Services\Netlogon").sNames
                $pendDomJoin = ($netlogon -contains 'JoinDomain') -or ($netlogon -contains 'AvoidSpnSet')

                #  Query ComputerName and ActiveComputerName from the registry
                $actCompNm = $wmiReg.GetStringValue($HKLM, "SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\", "ComputerName")            
                $compNm = $wmiReg.GetStringValue($HKLM, "SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\", "ComputerName")

                If (($actCompNm -ne $compNm) -or $pendDomJoin) {
                    $compPendRen = $true
                }
						
                #  If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
                If ($regValuePfro) {
                    $pendFileRename = $true
                }

                #  Determine SCCM 2012 Client Reboot Pending Status
                #  To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
                $ccmClientSdk = $null
                $ccmSplat = @{
                    NameSpace    = 'ROOT\ccm\ClientSDK'
                    Class        = 'CCM_ClientUtilities'
                    Name         = 'DetermineIfRebootPending'
                    ComputerName = $computer
                    ErrorAction  = 'Stop'
                }
                #  Try CCMClientSDK
                Try {
                    $ccmClientSdk = Invoke-WmiMethod @ccmSplat
                } Catch [System.UnauthorizedAccessException] {
                    $ccmStatus = Get-Service -Name CcmExec -ComputerName $computer -ErrorAction SilentlyContinue
                    If ($ccmStatus.Status -ne 'Running') {
                        Write-Warning "$computer`: Error - CcmExec service is not running."
                        $ccmClientSdk = $null
                    }
                } Catch {
                    $ccmClientSdk = $null
                }

                If ($ccmClientSdk) {
                    If ($ccmClientSdk.ReturnValue -ne 0) {
                        Write-Warning "Error: DetermineIfRebootPending returned error code $($ccmClientSdk.ReturnValue)"          
                    }
                    If ($ccmClientSdk.IsHardRebootPending -or $ccmClientSdk.RebootPending) {
                        $SCCM = $true
                    }
                }
            
                Else {
                    $sccm = $null
                }

                #  Creating Custom PSObject and Select-Object Splat
                $selectSplat = @{
                    Property = (
                        'Computer',
                        'CBServicing',
                        'WindowsUpdate',
                        'CCMClientSDK',
                        'PendComputerRename',
                        'PendFileRename',
                        'PendFileRenVal',
                        'RebootPending'
                    )
                }
                New-Object -TypeName PSObject -Property @{
                    Computer           = $cimOS.CSName
                    CBServicing        = $cbsRebootPend
                    WindowsUpdate      = $wuauRebootReq
                    CCMClientSDK       = $sccm
                    PendComputerRename = $compPendRen
                    PendFileRename     = $pendFileRename
                    PendFileRenVal     = $regValuePfro
                    RebootPending      = ($compPendRen -or $cbsRebootPend -or $wuauRebootReq -or $sccm -or $pendFileRename)
                } | Select-Object @selectSplat

            } Catch {
                Write-Warning "$computer`: $PSItem"
                #  If $ErrorLog, log the file to a user specified location/path
                If ($errorLog) {
                    Out-File -InputObject "$computer`,$PSItem" -FilePath $ErrorLog -Append
                }				
            }			
        }#  End Foreach ($Computer in $ComputerName)			
    }#  End Process
}#  End Function Get-PendingReboot