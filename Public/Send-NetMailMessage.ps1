<#
.SYNOPSIS
    This function can be used as a 1:1 replacement/alternative for the built-in Send-MailMessage CmdLet.
.DESCRIPTION
    Can be used as a 1:1 replacement/alternative to the built-in Send-MailMessage CmdLet if, for whatever reason,
        you wish not/cannot to use the built-in CmdLet.

    However, unlike the built-in Send-MailMessage, this function allows you to specify a ReplyTo address
        if you want it to be different than the From address, and has been tested in PowerShell 5.1 and PwSh 7.

    The -ReplyTo parameter was not introduced for Send-MailMessage until PowerShell 6.
.PARAMETER From
    Email address that the message will show as sent from
.PARAMETER To
    Email address(s) that the message will be delivered to
.PARAMETER Cc
    Email address(s) that the will be Carbon Copied on the message
    Addresses entered here will show up in the CC field on the message
.PARAMETER Bcc
    Email address(s) that the will be Blind Carbon Copied on the message
    Addresses entered here will NOT show up on the message
.PARAMETER Subject
    Subject of the email message
.PARAMETER Body
    The content of the email message
.PARAMETER BodyAsHTML
    Renders the Body of the email message in HTML format
.PARAMETER Attachments
    Full paths to any file(s) that should be sent with the message
.PARAMETER Encoding
    Text encoding for the message. Default is determined by the host
.PARAMETER DeliveryNotificationOption
    Option for notifications on deliver of the email message
    Default is 'None'
.PARAMETER Priority
    Priority that the message will be sent with
    Default is 'Normal'
.PARAMETER ReplyTo
    Alternate email address(s) that will be populated it the recpient replies to the email
.PARAMETER Credential
    Credentials to connect to the SMTP server
    By default, the connection is attempted with the current user
.PARAMETER UseSsl
    Specifies whether or not to use SSL when sending the message
.PARAMETER Port
    Port to connect to the SMTP server
.PARAMETER SmtpServer
    Hostname of the SMTP server.
    By default, this is set by the value in $PSEmailServer.
.EXAMPLE
    $emailSplat = @{
        From            = 'automation@cabbage.corp'
        To              = 'user@cabbage.corp'
        Subject         = '[CRITICAL] A critical service has encountered an error'
        BodyAsHTML      = $True
        Priority        = 'High'
        WarningAction   = 'SilentlyContinue'
        ErrorAction     = 'Stop'
    }
    Send-NetMailMessage @emailSplat
.NOTES
    Author					HurtzDonut
    Created					07-20-2023
    Modified				08-23-2023
    Modified By				HurtzDonut
    Version					v1.0.1

    Tested in PowerShell 5.1 and PwSh 7.3.6
#>

Function Send-NetMailMessage {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('sdmm')]
    Param (
        [Parameter()]
            [String]$From = 'donotreply@contoso.com',
        [Parameter(Mandatory)]
            [String[]]$To,
        [Parameter()]
            [String[]]$Cc,
        [Parameter()]
            [String[]]$Bcc,
        [Parameter()]
            [String]$Subject = 'Generic Subject',
        [Parameter(Mandatory)]
            [String[]]$Body,
        [Parameter()]
            [Switch]$BodyAsHTML,
        [Parameter()]
            [String[]]$Attachments,
        [Parameter()]
        [ValidateSet('Default', 'ASCII', 'Latin1', 'Unicode', 'BigEndianUnicode', 'UTF7', 'UTF8', 'UTF32', 'BigEndianUTF32')]
            [System.Text.Encoding]$Encoding,
        [Parameter()]
        [ValidateSet('None', 'OnSuccess', 'OnFailure', 'Delay', 'Never')]
            [System.Net.Mail.DeliveryNotificationOptions]$DeliveryNotificationOption = 'None',
        [Parameter()]
        [ValidateSet('Normal', 'Low', 'High')]
            [System.Net.Mail.MailPriority]$Priority = 'Normal',
        [Parameter()]
            [String[]]$ReplyTo,
        [Parameter()]
            [PSCredential]$Credential,
        [Parameter()]
            [Switch]$UseSsl,
        [Parameter()]
            [Int]$Port = 25,
        [Parameter()]
            [String]$SmtpServer = $(
                If ($null -eq $PSEmailServer) {
                    'mail.contoso.com'
                } Else {
                    $PSEmailServer
                }
            )
    ) # Param Block
    
    Begin {
        #region Build Message
            $mailMessage                                = [System.Net.Mail.MailMessage]::New()
            $mailMessage.From                           = $From
            $mailMessage.Subject                        = $Subject
            $mailMessage.Body                           = $Body
            $mailMessage.IsBodyHtml                     = $BodyAsHTML
            $mailMessage.DeliveryNotificationOptions    = $DeliveryNotificationOption
            $mailMessage.BodyEncoding                   = $Encoding
            $mailMessage.HeadersEncoding                = $Encoding
            $mailMessage.SubjectEncoding                = $Encoding
            $mailMessage.Priority                       = $Priority
            If ($Null -ne $Attachments){
                $Attachments |
                    ForEach-Object {
                        $mailMessage.Attachments.Add([System.Net.Mail.Attachment]::New($PSItem))
                    }
            }
            
            $To |
                ForEach-Object {
                    $mailMessage.To.Add([MailAddress]::New($PSItem))
                }
            If ($Null -ne $Bcc) {
                $Bcc |
                    ForEach-Object {
                        $mailMessage.Bcc.Add([MailAddress]::New($PSItem))
                    }
            }
            If ($Null -ne $Cc) {
                $Cc |
                    ForEach-Object {
                        $mailMessage.Cc.Add([MailAddress]::New($PSItem))
                    }
            }
            If ($Null -ne $ReplyTo) {
                $ReplyTo |
                    ForEach-Object {
                        $mailMessage.ReplyToList.Add([MailAddress]::New($PSItem))
                    }
            }
        #endregion Build Message

        #region Build Message Sender
            $mailObj                = [System.Net.Mail.SmtpClient]::New()
            $mailObj.Host           = $SmtpServer
            If ($Null -ne $Credential) {
                $mailObj.Credentials    = $Credential
            }
            $mailObj.EnableSsl      = $UseSsl.IsPresent
            $mailObj.Port           = $Port
        #endregion Build Message Sender
    } # Begin Block

    Process {
        $rcptList = 'To:{0}' -F ($mailMessage.To -Join ',')
        If ($null -ne $CC) {
            $rcptList += '; CC:{0}' -F ($mailMessage.CC -Join ',')
        }
        If ($null -ne $Bcc) {
            $rcptList += '; Bcc:{0}' -F ($mailMessage.Bcc -Join ',')
        }
        
        If ($PSCmdlet.ShouldProcess("Send email to $rcptList",$mailObj.Host,"Send-MailMessage: $Subject")){
            # Send Email Message
            $mailObj.Send($mailMessage)
        }
    } # Process Block

    End {
        Write-Verbose ($mailMessage | Out-String)
        Write-Verbose ($mailObj | Out-String)

        # Clean up
        $mailMessage.Dispose()
        $mailObj.Dispose()
    } # End Block
} # Function Send-NetMailMessage