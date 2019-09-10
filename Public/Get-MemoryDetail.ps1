<#
.SYNOPSIS
    Returns detailed information regarding the current system's memory.
.PARAMETER Format
    Specifies to format in Human-Readable numbers.
.INPUTS
    Switch
.OUTPUTS
    System.Switch
    BinaryNature.MemoryDetailed
.NOTES
    Modified By :   Jacob Allen
    Modified On :   9/10/2019

    Original Function By:   Marc Weisel
    Posted Date         :   8/13/2013
    Link                :   https://binarynature.blogspot.com/2013/08/powershell-function-windows-system-memory-statistics.html
#>
Function Get-MemoryDetail {
    [CmdletBinding()]
    Param (
        [Parameter()]    
            [switch]$Format
    )

    Begin {
$TypeDef = @'
/*
* Item: Windows PSAPI GetPerformanceInfo C# Wrapper
* Source: http://www.antoniob.com/windows-psapi-getperformanceinfo-csharp-wrapper.html 
* Author: Antonio Bakula
*/
using System;
using System.Runtime.InteropServices;

public struct PerfomanceInfoData
{
    public Int64 CommitTotalPages;
    public Int64 CommitLimitPages;
    public Int64 CommitPeakPages;
    public Int64 PhysicalTotalBytes;
    public Int64 PhysicalAvailableBytes;
    public Int64 SystemCacheBytes;
    public Int64 KernelTotalBytes;
    public Int64 KernelPagedBytes;
    public Int64 KernelNonPagedBytes;
    public Int64 PageSizeBytes;
    public int HandlesCount;
    public int ProcessCount;
    public int ThreadCount;
}

public static class PsApiWrapper
{
    [DllImport("psapi.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool 
    GetPerformanceInfo([Out] out PsApiPerformanceInformation PerformanceInformation, 
    [In] int Size);

    [StructLayout(LayoutKind.Sequential)]
    public struct PsApiPerformanceInformation
    {
        public int Size;
        public IntPtr CommitTotal;
        public IntPtr CommitLimit;
        public IntPtr CommitPeak;
        public IntPtr PhysicalTotal;
        public IntPtr PhysicalAvailable;
        public IntPtr SystemCache;
        public IntPtr KernelTotal;
        public IntPtr KernelPaged;
        public IntPtr KernelNonPaged;
        public IntPtr PageSize;
        public int HandlesCount;
        public int ProcessCount;
        public int ThreadCount;
    }

    public static PerfomanceInfoData GetPerformanceInfo()
    {
        PerfomanceInfoData data = new PerfomanceInfoData();
        PsApiPerformanceInformation perfInfo = new PsApiPerformanceInformation();
        if (GetPerformanceInfo(out perfInfo, Marshal.SizeOf(perfInfo)))
        {
            Int64 pageSize = perfInfo.PageSize.ToInt64();
            
            // data in bytes
            data.CommitTotalPages = perfInfo.CommitTotal.ToInt64() * pageSize;
            data.CommitLimitPages = perfInfo.CommitLimit.ToInt64() * pageSize;
            data.CommitPeakPages = perfInfo.CommitPeak.ToInt64() * pageSize;
            data.PhysicalTotalBytes = perfInfo.PhysicalTotal.ToInt64() * pageSize;
            data.PhysicalAvailableBytes = perfInfo.PhysicalAvailable.ToInt64() * pageSize;
            data.KernelPagedBytes = perfInfo.KernelPaged.ToInt64() * pageSize;
            data.KernelNonPagedBytes = perfInfo.KernelNonPaged.ToInt64() * pageSize;
        }
        return data;
    }
}
'@
        Add-Type -TypeDefinition $TypeDef

        Function Format-HumanReadable {
            [CmdletBinding()]
            Param (
                $Size
                )
            Switch ($Size) {
                {$PSItem -ge 1PB}   { "{0:0#.#0 'PB'}" -f ($size / 1PB) ; Continue }
                {$PSItem -ge 1TB}   { "{0:0#.#0 'TB'}" -f ($size / 1TB) ; Continue }
                {$PSItem -ge 1GB}   { "{0:0#.#0 'GB'}" -f ($size / 1GB) ; Continue }
                {$PSItem -ge 1MB}   { "{0:0#.#0 'MB'}" -f ($size / 1MB) ; Continue }
                {$PSItem -ge 1KB}   { "{0:0# 'KB'}" -f ($size / 1KB) ; Continue }
                Default             { "{0} B" -f ($size) ; Continue }
            }
        } # Function Format-HumanReadable
    } # Begin
    Process {
        # Create PerformanceInfoData object
        [PerfomanceInfoData]$W32Perf = [PsApiWrapper]::GetPerformanceInfo()

        Try {
            # Create Win32_PerfRawData_PerfOS_Memory object
            $Query = 'SELECT * FROM Win32_PerfRawData_PerfOS_Memory'
            $WmiMem = Get-CimInstance -Query $Query -ErrorAction Stop
            
            # Create "detailed" PS memory object 
            # Value in bytes for memory attributes
            $MemData = [PSObject]::New([PSCustomObject][Ordered]@{
                TotalPhysicalMem = $W32Perf.PhysicalTotalBytes
                AvailPhysicalMem = $W32Perf.PhysicalAvailableBytes
                CacheWorkingSet  = [Long]$WmiMem.CacheBytes
                KernelWorkingSet = [Long]$WmiMem.SystemCodeResidentBytes
                DriverWorkingSet = [Long]$WmiMem.SystemDriverResidentBytes
                CommitCurrent    = $W32Perf.CommitTotalPages
                CommitLimit      = $W32Perf.CommitLimitPages
                CommitPeak       = $W32Perf.CommitPeakPages
                PagedWorkingSet  = [Long]$WmiMem.PoolPagedResidentBytes
                PagedVirtual     = $W32Perf.KernelPagedBytes
                Nonpaged         = $W32Perf.KernelNonPagedBytes
                Computer         = $env:COMPUTERNAME
            })
        } Catch {
            Write-Warning ("Error: {0}" -f $PSItem.Exception.Message)
        }
    } # Process
    End {
        If ($PSBoundParameters['Format']) {
            # Format output in human-readable form
            # End of PS pipeline/format right rule option
            [PSCustomObject][Ordered]@{
                'Commit Charge' = '------'
                Current = Format-HumanReadable $MemData.CommitCurrent
                Limit   = Format-HumanReadable $MemData.CommitLimit
                Peak    = Format-HumanReadable $MemData.CommitPeak
                'Peak/Limit' = "{0:P2}" -f ($MemData.CommitPeak / $MemData.CommitLimit)
                'Curr/Limit' = "{0:P2}" -f ($MemData.CommitCurrent / $MemData.CommitLimit)
            }
            
            [PSCustomObject][Ordered]@{
                'Physical Memory' = '------'
                Total       = Format-HumanReadable $MemData.TotalPhysicalMem
                Available   = Format-HumanReadable $MemData.AvailPhysicalMem
                CacheWS     = Format-HumanReadable $MemData.CacheWorkingSet
                KernelWS    = Format-HumanReadable $MemData.KernelWorkingSet
                DriverWS    = Format-HumanReadable $MemData.DriverWorkingSet
            }

            [PSCustomObject][Ordered]@{
                'Kernel Memory' = '------'
                PagedWS     = Format-HumanReadable $MemData.PagedWorkingSet
                PagedVirt   = Format-HumanReadable $MemData.PagedVirtual
                NonPaged    = Format-HumanReadable $MemData.Nonpaged
            }
        } else {
            $MemData.PSObject.TypeNames.Insert(0, 'BinaryNature.MemoryDetailed')
            $MemData
        }
    } # End
} # Function Get-MemoryDetail