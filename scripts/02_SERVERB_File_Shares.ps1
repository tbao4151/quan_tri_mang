#requires -RunAsAdministrator
# P07 - Run ON SERVERB in elevated PowerShell, signed in as a domain account with local admin rights.
# Preconditions: SERVERB has joined fittdtu.com; domain groups already exist on SERVERA.
# Creates directories under C:\DeptShares (change $base if using a dedicated D: volume).
# DO NOT use on existing production file shares. First run creates share ACLs.
$ErrorActionPreference = 'Stop'
$expectedDomain = 'fittdtu.com'
if (-not ((Get-WmiObject Win32_ComputerSystem).Domain -ieq $expectedDomain)) {
    throw "SERVERB must be domain joined to $expectedDomain."
}
$netbios = $env:USERDOMAIN
if ($netbios -eq $env:COMPUTERNAME) {
    throw 'Sign in using a DOMAIN administrator, not a local administrator.'
}
$base = 'C:\DeptShares'
$specs = @(
    @{Name='SalesDocs';      Group='GG_Sales_RW';      File='KeHoach_Sales.txt';      Text='Ke hoach Sales - TDTU P07'},
    @{Name='AccountingDocs'; Group='GG_Accounting_RW'; File='BaoCao_Accounting.txt'; Text='Bao cao Accounting - TDTU P07'}
)
foreach ($spec in $specs) {
    $path = Join-Path $base $spec.Name
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    $group = "$netbios\$($spec.Group)"
    # Block inherited NTFS ACEs: keep SYSTEM + BUILTIN Administrators + relevant department only.
    # The *SID names avoid Windows display language ambiguity.
    & icacls.exe $path /inheritance:r | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "icacls inheritance failed for $path" }
    & icacls.exe $path /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' "$($group):(OI)(CI)M" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "icacls grant failed for $path; check the AD group name." }

    $sample = Join-Path $path $spec.File
    if (-not (Test-Path $sample)) { Set-Content -Path $sample -Value $spec.Text -Encoding UTF8 }

    if (-not (Get-SmbShare -Name $spec.Name -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $spec.Name -Path $path -ChangeAccess $group `
            -FullAccess 'BUILTIN\Administrators' -CachingMode None | Out-Null
        Write-Host "Created \\SERVERB\$($spec.Name)"
    } else {
        Write-Warning "Share $($spec.Name) exists. Review its existing Share ACL manually; script will not overwrite it."
    }
    Write-Host "`nNTFS for $path:"
    & icacls.exe $path
    Write-Host "Share permissions for $($spec.Name):"
    Get-SmbShareAccess -Name $spec.Name | Format-Table -AutoSize
}
Write-Host "`nREVIEW: only department group + administrators should be allowed on each share."
Write-Host 'If Everyone/Authenticated Users have excess share privileges, remove them explicitly in GUI.'
