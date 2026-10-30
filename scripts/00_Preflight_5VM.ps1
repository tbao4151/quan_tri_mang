#requires -Version 3.0
# P07 read-only audit. Run on each of the five VMs in Windows PowerShell.
# Does NOT modify IP/DNS/domain/GPO/ACLs and does not read passwords.
$ErrorActionPreference = 'Continue'
$computer = $env:COMPUTERNAME
$desktop = [Environment]::GetFolderPath('Desktop')
if (-not (Test-Path -LiteralPath $desktop)) { $desktop = $env:USERPROFILE }
$output = Join-Path $desktop ("P07_Preflight_{0}.txt" -f $computer)

function Check([string]$heading, [scriptblock]$body) {
    [Environment]::NewLine + "==== $heading ===="
    try {
        & $body 2>&1 | Out-String -Width 220
    } catch {
        "ERROR: $($_.Exception.Message)"
    }
}
$report = @()
$report += 'TDTU P07 READ-ONLY PREFLIGHT'
$report += "Computer: $computer"
$report += "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
$report += "User: $(whoami)"
$report += Check 'Hostname / Operating System' {
    hostname
    Get-WmiObject Win32_OperatingSystem | Select-Object Caption,Version,OSArchitecture | Format-List
}
$report += Check 'Domain membership' {
    Get-WmiObject Win32_ComputerSystem | Select-Object Name,Domain,PartOfDomain | Format-List
}
$report += Check 'IP, gateway and DNS' {
    Get-NetIPConfiguration | Format-List InterfaceAlias,IPv4Address,IPv4DefaultGateway,DNSServer
    Get-DnsClientServerAddress -AddressFamily IPv4 |
        Select-Object InterfaceAlias,ServerAddresses | Format-List
}
$report += Check 'DNS lookup to SERVERA' { Resolve-DnsName fittdtu.com -Server 10.0.0.1 }
$report += Check 'Domain Controller discovery' { nltest /dsgetdc:fittdtu.com }
$report += Check 'Clock / Kerberos' { w32tm /query /status }
$report += Check 'VMware Tools' { Get-Service VMTools -ErrorAction SilentlyContinue | Select-Object Name,Status }
if ($computer -ieq 'SERVERA') {
    $report += Check 'AD DS / DNS status on SERVERA' {
        Get-Service -Name DNS,NTDS | Select-Object Name,Status
        Import-Module ActiveDirectory -ErrorAction Stop
        Get-ADDomain | Select-Object DNSRoot,NetBIOSName,DistinguishedName | Format-List
        Get-ADComputer -Filter * |
            Where-Object { $_.Name -in @('SERVERB','PC-SAL-01','PC-ACC-01','PC-HR-01') } |
            Select-Object Name,Enabled,DistinguishedName | Format-Table -Wrap
    }
} else {
    $report += Check 'Domain secure channel on member' { Test-ComputerSecureChannel -Verbose }
}
$report -join [Environment]::NewLine | Set-Content -Path $output -Encoding UTF8
Write-Host "Saved preflight report: $output"
Write-Host "Review the report before sharing. Never send password, cookies, or tokens."
