Function ConvertFrom-LdapFilter {
	[CmdLetBinding()]
	[Alias('cfldap')]
	Param (
		[Parameter(Mandatory,Position=0)]
			[String]$ldapFilter
	)
	
	Begin {
		$Script:ldapFilter = $ldapFilter -Replace '(\(!\(name=SystemMailbox{\*.+TypeDetails=\d+\)\))'
		
		Trap {
			Write-Warning $PSItem.Exception.Message
			Continue
		} # Trap

		Function Get-StringConditions {
			$Script:ldapFilter 	= $Script:ldapFilter.Trim()
			$exitThisLevel		= $False
				
			While (!($exitThisLevel)) {				
				If ($Script:ldapFilter.StartsWith("(&(objectClass=user)(objectCategory=person)(mailNickname=*)(msExchHomeServerName=*))")) {
					# All Users
					$Script:ldapFilter = $Script:ldapFilter.Remove(0, 83).Trim()
					"RecipientType -eq 'UserMailbox'"
					Break
				}
				If ($Script:ldapFilter.StartsWith("(& (mailnickname=*) (| (objectCategory=group) ))")) {
					# All Groups
					$Script:ldapFilter = $Script:ldapFilter.Remove(0, 47).Trim()
					"(RecipientType -eq 'MailUniversalDistributionGroup' -or RecipientType -eq 'MailUniversalSecurityGroup' -or RecipientType -eq 'MailNonUniversalGroup' -or RecipientType -eq 'DynamicDistributionGroup' )"
					Break
				}
				If ($Script:ldapFilter.StartsWith("(& (mailnickname=*) (| (&(objectCategory=person)(objectClass=contact)) ))")) {
					# All Contacts
					$Script:ldapFilter = $Script:ldapFilter.Remove(0, 72).Trim()
					"RecipientType -eq 'MailContact'"
					Break
				}
				If ($Script:ldapFilter.StartsWith("(& (mailnickname=*) (| (objectCategory=publicFolder) ))")) {
					# Public Folders
					$Script:ldapFilter = $Script:ldapFilter.Remove(0, 54).Trim()
					"RecipientType -eq 'PublicFolder'"
					Break
				}
				If ($Script:ldapFilter.StartsWith("(& (mailnickname=*) (| (&(objectCategory=person)(objectClass=user)(!(homeMDB=*))(!(msExchHomeServerName=*)))(&(objectCategory=person)(objectClass=user)(|(homeMDB=*)(msExchHomeServerName=*)))(&(objectCategory=person)(objectClass=contact))(objectCategory=group)(objectCategory=publicFolder)(objectCategory=msExchDynamicDistributionList) ))")) {
					# Default Global Address List
					$Script:ldapFilter = $Script:ldapFilter.Remove(0, 336).Trim()
					"(Alias -ne `$null -and (ObjectClass -eq 'user' -or ObjectClass -eq 'contact' -or ObjectClass -eq 'msExchSystemMailbox' -or ObjectClass -eq 'msExchDynamicDistributionList' -or ObjectClass -eq 'group' -or ObjectClass -eq 'publicFolder'))"
					Break
				}
				# End of default filter cases

				If ($Script:ldapFilter.StartsWith("(")) {
					$Script:ldapFilter = $Script:ldapFilter.Remove(0, 1).Trim()
				} Else {
					Throw "Invalid filter string."
				}
				
				If ($Script:ldapFilter.StartsWith("(")) {
					Get-StringConditions
				} Else {
					$isNegative				= $Script:ldapFilter.StartsWith("!")
					$mustBeValueComparison 	= $False

					If ($isNegative) {
						$Script:ldapFilter = $Script:ldapFilter.Remove(0, 1).Trim()
						If ($Script:ldapFilter.StartsWith("(")) {
							$Script:ldapFilter = $Script:ldapFilter.Remove(0, 1).Trim()
						} Else {
							$mustBeValueComparison = $true
						}
					}
					
					$op = $Null
					If ($Script:ldapFilter.StartsWith("|(homeMDB=*)(msExchHomeServerName=*))")) {
						$Script:ldapFilter = $Script:ldapFilter.Remove(0, 36)
						$newCondition = " (recipientType -eq 'UserMailbox')"
						If ($isNegative) {
							$newCondition = " (-not(" + $newCondition + ")"
						}
						$newCondition
					} ElseIf ($Script:ldapFilter.StartsWith("&") -or $Script:ldapFilter.StartsWith("|")) {
						If ($mustBeValueComparison) {
							Throw "Invalid filter string."
						}
						If ($Script:ldapFilter.StartsWith("&")) {
							$op = "and"
						} Else {
							$op = "or"
						}
						
						$Script:ldapFilter = $Script:ldapFilter.Remove(0, 1).Trim()
						
						If ($Script:ldapFilter.StartsWith("(")) {
							[string[]]$theseConditions = Get-StringConditions
							
							$newCondition = ""
							For ([int]$x = 0; $x -lt $theseConditions.Length; $x++) {
								$newCondition = $newCondition + $theseConditions[$x]
								If (($x + 1) -lt $theseConditions.Count) {
									$newCondition = $newCondition + " -" + $op
								}
							}
							
							If ($isNegative) {
								$newCondition = " (-not(" + $newCondition + ")"
							} ElseIf ($theseConditions.Length -gt 1) {
								$newCondition = " (" + $newCondition + ")"
							}
						} Else {
							$newCondition = Get-ValueComparison -isNegative:$isNegative
						}

						$newCondition
					} Else {
						# this better be a value comparison
						Get-ValueComparison -isNegative:$isNegative
					}
					
					If ($isNegative -and -not $mustBeValueComparison) {
						If ($Script:ldapFilter.StartsWith(")")) {
							$Script:ldapFilter = $Script:ldapFilter.Remove(0, 1).Trim()
						} Else {
							Throw "Invalid filter string."
						}
					}
						
					If ($Script:ldapFilter.StartsWith(")")) {
						$Script:ldapFilter = $Script:ldapFilter.Remove(0, 1).Trim()
					} Else {
						Throw "Invalid filter string."
					}
				}
				
				If (($Script:ldapFilter.StartsWith(")")) -or ($Script:ldapFilter.Length -eq 0)) {
					$exitThisLevel = $true
				}
			}
			
			Return
		} # Function Get-StringConditions

		Function Get-ValueComparison {
			[CmdletBinding()]
			Param(
				[Switch]$isNegative
			)
			$operatorPos = $Script:ldapFilter.IndexOf("=")
			$valuePos = $operatorPos + 1
			If (($Script:ldapFilter[$operatorPos - 1] -eq '<') -or
				($Script:ldapFilter[$operatorPos - 1] -eq '>')) {
				$operatorPos--
			}
			
			If ($operatorPos -lt 1) {
				Throw "Invalid filter string."
			}
			
			$property = $Script:ldapFilter.Substring(0, $operatorPos).Trim()
			$opstring = $Script:ldapFilter.Substring($operatorPos, $valuePos - $operatorPos)
						
			$startPos = 0
			# DN-valued attribute may contain parenthesis. Need to look for the end
			# of the DN.
			If ($property.ToLower() -eq "homemdb") {
				If (!($Script:ldapFilter[$valuePos] -eq '*')) {
					$startPos = $Script:ldapFilter.IndexOf(",DC=")
				}
			}
			$endPos = $Script:ldapFilter.IndexOf(")", $startPos)
			If ($endPos -lt 0) {
				Throw "Invalid filter string."
			}
			
			$val = $Script:ldapFilter.Substring($valuePos, $endPos - $valuePos)
			$Script:ldapFilter = $Script:ldapFilter.Substring($endPos)
			
			$compType = $Null
			Switch ($opstring) {
				{$PSItem -eq '='} {
					If ($val -eq "*") {
						$compType = "exists"
					}Else {
						If ($val.IndexOf("*") -gt -1) {
							$compType = "like"
						} Else {
							$compType = "equals"
						}
					}}
				{$PSItem -eq '<='} {$compType = "lessthanorequals"}
				{$PSItem -eq '>='} {$compType = "greaterthanorequals"}
				Default {Throw "Invalid filter string."}
			}
			
			[string]$opathProp 			= ConvertTo-OPathProperty -ldapProp $property
			[string]$opathVal 			= Get-LdapValue -opathProp $opathProp  -ldapVal $val
			[string]$opathComparison 	= ConvertTo-OPathOperator -opathProp $opathProp -ldapComparison $compType -opathVal $opathVal
			
			$newCondition = " (" + $opathProp + $opathComparison + ")"
			If ($isNegative) {
				$newCondition = " (-not" + $newCondition + ")"
			}
				
			$newCondition
		} # Function Get-ValueComparison

		Function ConvertTo-OPathOperator {
			[CmdletBinding()]
			Param (
				[Parameter()]
					[string]$opathProp,
				[Parameter()]
					[string]$ldapComparison,
				[Parameter()]	
					[string]$opathVal
			)
			If ($opathProp -eq "ObjectCategory" -and $ldapComparison -eq "equals") {
				$opathComparison = " -like '" + $opathVal + "'"
			} Else {
				[string]$opathComparison = ""
				
				Switch ($ldapComparison) {
					'equals'                {$opathComparison = " -eq '"        ;Continue}
					'like'                  {$opathComparison = " -like '"      ;Continue}
					'lessthanorequals'      {$opathComparison = " -le '"        ;Continue}
					'greaterthanorequals'   {$opathComparison = " -ge '"        ;Continue}
					'exists'                {$opathComparison = " -ne `$null"   ;Continue}
					Default                 {Throw "Could not convert unknown comparison type to OPATH comparison."}
				}

				If ($ldapComparison -ne "exists") {
					$opathComparison = $opathComparison + $opathVal + "'"
				}
			}
			$opathComparison
		} # Function ConvertTo-OPathOperator

		Function Get-LdapValue {
			[CmdletBinding()]
			Param(
				[Parameter()]	
					[string]$opathProp,
				[Parameter()]
					[string]$ldapVal
			)
			If ($opathProp -like "*Enabled") {
				$newBool = [System.Convert]::ToBoolean($ldapVal)
				"$" + $newBool.ToString().ToLower()
			} Else {
				$ldapVal
			}
		} # Function Get-LdapValue

		Function ConvertTo-OPathProperty {
			[CmdletBinding()]
			Param (
				[Parameter()]
					[string]$ldapProp
			)
			$ldapProp = $ldapProp.ToLower()

			Switch ($ldapProp) {
				'altrecipient'                  				{'ForwardingAddress'                ;Continue}
				'authorig'                      				{'AcceptMessagesOnlyFrom'           ;Continue}
				'c'                             				{'CountryOrRegion'                  ;Continue}
				'canonicalname'                 				{'RawCanonicalName'                 ;Continue}
				'cn'                            				{'CommonName'                       ;Continue}
				'co'                            				{'Co'                               ;Continue}
				'company'                       				{'Company'                          ;Continue}
				'countrycode'                   				{'CountryCode'                      ;Continue}
				'deleteditemflags'              				{'DeletedItemFlags'                 ;Continue}
				'deliverandredirect'            				{'DeliverToMailboxAndForward'       ;Continue}
				'delivcontlength'               				{'MaxReceiveSize'                   ;Continue}
				'department'                    				{'Department'                       ;Continue}
				'description'                   				{'Description'                      ;Continue}
				'directreports'                 				{'DirectReports'                    ;Continue}
				'displayname'                   				{'DisplayName'                      ;Continue}
				'displaynameprintable'          				{'SimpleDisplayName'                ;Continue}
				'distinguisedname'              				{'Id'                               ;Continue}
				'dlmemrejectperms'              				{'RejectMessagesFromDLMembers'      ;Continue}
				'dlmemsubmitperms'              				{'AcceptMessagesOnlyFromDLMembers'  ;Continue}
				'extensionattribute1'           				{'customAttribute1'                 ;Continue}
				'extensionattribute2'           				{'customAttribute2'                 ;Continue}
				'extensionattribute3'           				{'customAttribute3'                 ;Continue}
				'extensionattribute4'           				{'customAttribute4'                 ;Continue}
				'extensionattribute5'           				{'customAttribute5'                 ;Continue}
				'extensionattribute6'           				{'customAttribute6'                 ;Continue}
				'extensionattribute7'           				{'customAttribute7'                 ;Continue}
				'extensionattribute8'           				{'customAttribute8'                 ;Continue}
				'extensionattribute9'           				{'customAttribute9'                 ;Continue}
				'extensionattribute10'          				{'customAttribute10'                ;Continue}
				'extensionattribute11'          				{'customAttribute11'                ;Continue}
				'extensionattribute12'          				{'customAttribute12'                ;Continue}
				'extensionattribute13'          				{'customAttribute13'                ;Continue}
				'extensionattribute14'          				{'customAttribute14'                ;Continue}
				'extensionattribute15'          				{'customAttribute15'                ;Continue}
				'facsimiletelephonenumber'      				{'fax'                              ;Continue}
				'garbagecollperiod'             				{'RetainDeletedItemsFor'            ;Continue}
				'givenname'                     				{'FirstName'                        ;Continue}
				'grouptype'                     				{'GroupType'                        ;Continue}
				'objectguid'                        			{'Guid'                             ;Continue}
				'hidedlmembership'                  			{'HiddenGroupMembershipEnabled'     ;Continue}
				'homemdb'                           			{'Database'                         ;Continue}
				'homemta'                           			{'HomeMTA'                          ;Continue}
				'homephone'                         			{'HomePhone'                        ;Continue}
				'info'                              			{'Notes'                            ;Continue}
				'initials'                          			{'Initials'                         ;Continue}
				'internetencoding'                  			{'InternetEncoding'                 ;Continue}
				'l'                                 			{'City'                             ;Continue}
				'legacyexchangedn'                  			{'LegacyExchangeDN'                 ;Continue}
				'localeid'                          			{'LocaleID'                         ;Continue}
				'mail'                              			{'WindowsEmailAddress'              ;Continue}
				'mailnickname'                      			{'Alias'                            ;Continue}
				'managedby'                         			{'ManagedBy'                        ;Continue}
				'manager'                           			{'Manager'                          ;Continue}
				'mapirecipient'                     			{'MapiRecipient'                    ;Continue}
				'mdboverhardquotalimit'             			{'ProhibitSendReceiveQuota'         ;Continue}
				'mdboverquotalimit'                 			{'ProhibitSendQuota'                ;Continue}
				'mdbstoragequota'                   			{'IssueWarningQuota'                ;Continue}
				'mdbusedefaults'                    			{'UseDatabaseQuotaDefaults'         ;Continue}
				'member'                            			{'Members'                          ;Continue}
				'memberof'                          			{'MemberOfGroup'                    ;Continue}
				'mobile'                            			{'MobilePhone'                      ;Continue}
				'msds-phoneticompanyname'           			{'PhoneticCompany'                  ;Continue}
				'msds-phoneticdepartment'           			{'PhoneticDepartment'               ;Continue}
				'msds-phoneticdsiplayname'          			{'PhoneticDisplayName'              ;Continue}
				'msds-phoneticfirstname'            			{'PhoneticFirstName'                ;Continue}
				'msds-phoneticlastname'             			{'PhoneticLastName'                 ;Continue}
				'msexchassistantname'               			{'AssistantName'                    ;Continue}
				'msexchdynamicdlbasedn'             			{'RecipientContainer'               ;Continue}
				'msexchdynamicdlfilter'             			{'LdapRecipientFilter'              ;Continue}
				'msexchelcexpirysuspensionend'      			{'ElcExpirationSuspensionEndDate'   ;Continue}
				'msexchelcexpirysuspensionstart'    			{'ElcExpirationSuspensionStartDate' ;Continue}
				'msexchelcmailboxflags' 				        {'ElcMailboxFlags'                  ;Continue}
				'msexchexpansionservername' 				    {'ExpansionServer'                  ;Continue}
				'msexchexternaloofoptions' 				        {'ExternalOofOptions'               ;Continue}
				'msexchhidefromaddresslists' 				    {'HiddenFromAddressListsEnabled'    ;Continue}
				'msexchhomeservername' 				            {'ServerLegacyDN'                   ;Continue}
				'msexchmailboxfolderset' 				        {'MailboxFolderSet'                 ;Continue}
				'msexchmailboxguid' 				            {'ExchangeGuid'                     ;Continue}
				'msexchmailboxsecuritydescriptor' 				{'ExchangeSecurityDescriptor'       ;Continue}
				'msexchmailboxtemplatelink' 				    {'ManagedFolderMailboxPolicy'       ;Continue}
				'msexchmasteraccountsid' 				        {'MasterAccountSid'                 ;Continue}
				'msexchmaxblockedsenders' 				        {'MaxBlockedSenders'                ;Continue}
				'msexchmaxsafesenders' 				            {'MaxSafeSenders'                   ;Continue}
				'msexchmdbrulesquota' 				            {'RulesQuota'                       ;Continue}
				'msexchmessagehygieneflags' 				    {'MessageHygieneFlags'              ;Continue}
				'msexchmessagehygienescldeletethreshold' 		{'SCLDeleteThresholdInt'            ;Continue}
				'msexchmessagehygienescljunkthreshold' 		    {'SCLJunkThresholdInt'              ;Continue}
				'msexchmessagehygienesclquarantinethreshold'    {'SCLQuarantineThresholdInt'        ;Continue}
				'msexchmessagehygienesclrejectthreshold' 		{'SCLRejectThresholdInt'            ;Continue}
				'msexchmobilealloweddeviceids' 				    {'ActiveSyncAllowedDeviceIDs'       ;Continue}
				'msexchmobiledebuglogging' 				        {'ActiveSyncDebugLogging'           ;Continue}
				'msexchmobilemailboxflags' 			            {'MobileMailboxFlags'               ;Continue}
				'msexchmobilemailboxpolicylink' 			    {'ActiveSyncMailboxPolicy'          ;Continue}
				'msexchomaadminextendedsettings' 			    {'MobileAdminExtendedSettings'      ;Continue}
				'msexchomaadminwirelessenable' 			        {'MobileFeaturesEnabled'            ;Continue}
				'msexchpfrooturl' 			                    {'PublicFolderRootUrl'              ;Continue}
				'msexchpftreetype' 			                    {'PublicFolderType'                 ;Continue}
				'msexchpoliciesexcluded' 			            {'PoliciesExcluded'                 ;Continue}
				'msexchpoliciesincluded' 			            {'PoliciesIncluded'                 ;Continue}
				'msexchprotocolsettings' 			            {'ProtocolSettings'                 ;Continue}
				'msexchpurportedsearchui' 			            {'PurportedSearchUI'                ;Continue}
				'msexchquerybasedn' 			                {'QueryBaseDN'                      ;Continue}
				'msexchqueryfilter' 			                {'RecipientFilter'                  ;Continue}
				'msexchqueryfiltermetadata' 			        {'RecipientFilterMetadata'          ;Continue}
				'msexchrecipientdisplaytype' 			        {'RecipientDisplayType'             ;Continue}
				'msexchrecipienttypedetails' 			        {'RecipientTypeDetailsValue'        ;Continue}
				'msexchreciplimit' 			                    {'RecipientLimits'                  ;Continue}
				'msexchrequireauthtosendto' 			        {'RequireAllSendersAreAuthenticated';Continue}
				'msexchresourcecapacity' 			            {'ResourceCapacity'                 ;Continue}
				'msexchresourcedisplay' 			            {'ResourcePropertiesDisplay'        ;Continue}
				'msexchresourcemetadata' 			            {'ResourceMetaData'                 ;Continue}
				'msexchresourcesearchproperties' 			    {'ResourceSearchProperties'         ;Continue}
				'msexchsafesendershash' 			            {'SafeSendersHash'                  ;Continue}
				'msexchsaferecipientshash' 			            {'SafeRecipientsHash'               ;Continue}
				'msexchumaudiocodec' 			                {'CallAnsweringAudioCodec'          ;Continue}
				'msexchumdtmfmap' 			                    {'UMDtmfMap'                        ;Continue}
				'msexchumenabledflags' 			                {'UMEnabledFlags'                   ;Continue}
				'msexchumlistindirectorysearch' 			    {'AllowUMCallsFromNonUsers'         ;Continue}
				'msexchumoperatornumber' 			            {'OperatorNumber'                   ;Continue}
				'msexchumpinchecksum' 			                {'UMPinChecksum'                    ;Continue}
				'msexchumrecipientdialplanlink' 			    {'UMRecipientDialPlanId'            ;Continue}
				'msexchumserverwritableflags' 			        {'UMServerWritableFlags'            ;Continue}
				'msexchumspokenname' 			                {'UMSpokenName'                     ;Continue}
				'msexchumtemplatelink' 			                {'UMMailboxPolicy'                  ;Continue}
				'msexchuseoab' 			                        {'OfflineAddressBook'               ;Continue}
				'msexchuseraccountcontrol' 			            {'ExchangeUserAccountControl'       ;Continue}
				'msexchuserculture' 			                {'LanguagesRaw'                     ;Continue}
				'msexchversion' 			                    {'ExchangeVersion'                  ;Continue}
				'name' 			                                {'Name'                             ;Continue}
				'ntsecuritydescriptor' 			                {'NTSecurityDescriptor'             ;Continue}
				'objectcategory' 			                    {'ObjectCategory'                   ;Continue}
				'objectclass' 			                        {'ObjectClass'                      ;Continue}
				'objectsid' 			                        {'Sid'                              ;Continue}
				'oofreplytooriginator' 			                {'SendOofMessageToOriginatorEnabled';Continue}
				'otherfacsimiletelephonenumber' 			    {'OtherFax'                         ;Continue}
				'otherhomephone' 			                    {'OtherHomePhone'                   ;Continue}
				'othertelephone' 			                    {'OtherTelephone'                   ;Continue}
				'pager' 			                            {'Pager'                            ;Continue}
				'pfcontacts' 			                        {'PublicFolderContacts'             ;Continue}
				'physicaldeliveryofficename' 			        {'Office'                           ;Continue}
				'postalcode' 			                        {'PostalCode'                       ;Continue}
				'postofficebox' 			                    {'PostOfficeBox'                    ;Continue}
				'primarygroupid' 			                    {'PrimaryGroupId'                   ;Continue}
				'proxyaddresses' 			                    {'EmailAddresses'                   ;Continue}
				'publicdelegates' 			                    {'GrantSendOnBehalfTo'              ;Continue}
				'pwdlastset' 			                        {'PasswordLastSetRaw'               ;Continue}
				'reporttooriginator' 			                {'ReportToOriginatorEnabled'        ;Continue}
				'reporttoowner' 			                    {'ReportToManagerEnabled'           ;Continue}
				'samaccountname' 			                    {'SamAccountName'                   ;Continue}
				'showinaddressbook' 			                {'AddressListMembership'            ;Continue}
				'sidhistory' 			                        {'SidHistory'                       ;Continue}
				'sn' 			                                {'LastName'                         ;Continue}
				'st' 			                                {'StateOrProvince'                  ;Continue}
				'submissioncontlength' 			                {'MaxSendSize'                      ;Continue}
				'streetaddress' 			                    {'StreetAddress'                    ;Continue}
				'targetaddress' 			                    {'ExternalEmailAddress'             ;Continue}
				'telephoneassistant' 			                {'TelephoneAssistant'               ;Continue}
				'telephonenumber' 			                    {'Phone'                            ;Continue}
				'textencodedoraddress' 			                {'TextEncodedORAddress'             ;Continue}
				'title' 			                            {'Title'                            ;Continue}
				'unauthorig' 			                        {'RejectMessagesFrom'               ;Continue}
				'unicodepwd' 			                        {'UnicodePassword'                  ;Continue}
				'useraccountcontrol' 			                {'UserAccountControl'               ;Continue}
				'usercertificate' 			                    {'Certificate'                      ;Continue}
				'userprincipalname' 			                {'UserPrincipalName'                ;Continue}
				'usersmimecertificate' 			                {'SMimeCertificate'                 ;Continue}
				'whenchanged' 			                        {'WhenChanged'                      ;Continue}
				'whencreated' 			                        {'WhenCreated'                      ;Continue}
				'wwwhomepage' 			                        {'WebPage'                          ;Continue}
				Default 			                            { Throw 'Could not convert LDAP attribute ' + $ldapProp + ' to Opath.'}
			} # Switch $ldapProp
		} # Function ConvertTo-OPathProperty
	} # Begin Block
	
	Process {
		$Script:ldapFilter = $Script:ldapFilter.Trim()
		
		[String[]]$conditions = Get-StringConditions
		
		If ($conditions.Length -gt 1) {
			Throw "Invalid filter string."
		}
		
		[String]$conditions -Replace '(^\s|(\()(\s))','$2' -Replace '(\-not)\s','$1'
	} # Process Block
	
	End { } # End Block
} # Function ConvertFrom-LdapFilter