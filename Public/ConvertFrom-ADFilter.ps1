using module ActiveDirectory
using namespace System.Reflection
<#
.SYNOPSIS
    Converts PowerShell-style filters used by the AD module into LDAP filters.

.DESCRIPTION
    Convert-ADFilter uses the QueryParser from the AD module to convert PowerShell-style filters into LDAP
    filters.

    A connection to Active Directory is required to support a number of the value conversion methods used by
    the module. This command only supports default connections at this time.

    This command can be used to test filter conversion.

.EXAMPLE
    $dn = 'CN=something,DC=domain,DC=com'
    $filter = '(name -like "something*" -or name -like "otherthing*") -and member -recursivematch $dn'
    Convert-ADFilter -Filter $filter

    Generates the LDAP filter (&(|(name=something*)(name=otherthing*))(member:1.2.840.113556.1.4.1941:=CN=something,DC=domain,DC=com))

.EXAMPLE
    $date = Get-Date
    Convert-ADFilter -Filter 'lastLogonTimeStamp -lt $date'

    When an AD connection is available, generates the date-based filter.

.EXAMPLE
    Convert-ADFilter -Filter 'LastLogonDate -lt "01/01/1601"'

    When an AD connection is available, generates the date-based filter.

.EXAMPLE
    Convert-ADFilter -Filter 'enabled -eq $true'

    Generates the LDAP filter (!(userAccountControl:1.2.840.113556.1.4.803:=2))

.EXAMPLE
    Convert-ADFilter -Filter 'objectGuid -eq "3af47167-c542-41c2-87cb-7a25032b2dec"'

    Generates the LDAP filter (objectGUID=\67\71\F4\3A\42\C5\C2\41\87\CB\7A\25\03\2B\2D\EC)
.LINK
    https://learn.microsoft.com/en-us/windows/win32/adsi/search-filter-syntax
.LINK
    https://gist.github.com/indented-automation/66e07bc76fdb6cf0be6743ed0b24575c
#>
Function ConvertFrom-ADFilter {
    [CmdletBinding()]
    [Alias('ConvertTo-LDAPFilter','ConvertTo-Win32Filter')]
    Param (
        # The filter to convert.
        [Parameter(Mandatory, Position = 1)]
        [Microsoft.ActiveDirectory.Management.Commands.TransformFilter()]
            [String]$Filter,

        # The command name affects the property mapping tables used to convert friendly attribute names into
        # AD attribute names.
        [ValidateNotNullOrEmpty()]
            [String]$CommandName = 'Get-ADUser'
    )

    Try {
        $implementingType = (Get-Command -Name $CommandName -ErrorAction Stop).ImplementingType
        $assembly = $implementingType.Assembly

        $commandInstance = $implementingType::new()
        # SessionState must be set to support variable lookups
        If ($PSEdition -eq 'Core') {
            $fieldName = '_state'
        } Else {
            $fieldName = 'state'
        }
        [PowerShell].Assembly.GetType('System.Management.Automation.Internal.InternalCommand').
        GetField($fieldName, 'Instance, NonPublic').
        SetValue($commandInstance, $executioncontext.SessionState)

        $factory = $implementingType.
        GetField('_factory', 'Instance, NonPublic').
        GetValue($commandInstance)

        Try {
            # Required to support advanced attribute value type conversions
            $cmdletSessionInfo = $implementingType.InvokeMember(
                'GetCmdletSessionInfo',
                [BindingFlags]'Instance, NonPublic, InvokeMethod',
                $null,
                $commandInstance,
                @()
            )
        } Catch {
            Write-Debug -Message $_.Exception.GetBaseException().Message

            # Limited offline support
            $cmdletSessionInfo = $assembly.GetType('Microsoft.ActiveDirectory.Management.Commands.CmdletSessionInfo').
            GetConstructor(@()).
            Invoke(@())
        }

        $factory.GetType().InvokeMember(
            'SetCmdletSessionInfo',
            [BindingFlags]'Instance, NonPublic, InvokeMethod',
            $null,
            $factory,
            @($cmdletSessionInfo)
        )

        # Create the SearchFilterConverterDelegate
        $convertSearchFilterDelegateType = $assembly.GetType('Microsoft.ActiveDirectory.Management.ConvertSearchFilterDelegate')

        $convertSearchFilterDelegate = $factory.
        GetType().
        GetMethod('BuildSearchFilter', [BindingFlags]'Instance, NonPublic').
        CreateDelegate($convertSearchFilterDelegateType, $factory)

        # Create the VariableExpressionConverter
        $evaluateVariableDelegateType = $assembly.GetType('Microsoft.ActiveDirectory.Management.EvaluateVariableDelegate')
        $evaluateVariableDelegate = $implementingType.
        GetMethod('EvaluateFilterVariable', [BindingFlags]'Instance, NonPublic').
        CreateDelegate($evaluateVariableDelegateType, $commandInstance)

        $variableExpressionConverterType = $assembly.GetType('Microsoft.ActiveDirectory.Management.VariableExpressionConverter')
        $variableExpressionConverter = $variableExpressionConverterType.
        GetConstructor('Instance, NonPublic', $null, @($evaluateVariableDelegateType), @()).
        Invoke(@($evaluateVariableDelegate))
    } Catch {
        $pscmdlet.ThrowTerminatingError($_)
    }

    Try {
        # QueryParser
        $queryParserType = $assembly.GetType('Microsoft.ActiveDirectory.Management.QueryParser')
        $queryParser = $queryParserType.GetConstructor(
            'Instance, NonPublic',
            $null,
            @([String], $variableExpressionConverterType, $ConvertSearchFilterDelegateType),
            @()
        ).Invoke(@(
                $Filter,
                $variableExpressionConverter,
                $convertSearchFilterDelegate
            ))

        $filterExpressionTree = $queryParserType.
        GetProperty('FilterExpressionTree', [BindingFlags]'Instance, NonPublic').
        GetValue($queryParser)

        # Get the LDAP filter
        $filterExpressionTree.GetType().InvokeMember(
            'Microsoft.ActiveDirectory.Management.IADOPathNode.GetLdapFilterString',
            [BindingFlags]'Instance, NonPublic, InvokeMethod',
            $null,
            $filterExpressionTree,
            @()
        )
    } Catch {
        Write-Error -ErrorRecord $_
    }
}# Function ConvertFrom-ADFilter