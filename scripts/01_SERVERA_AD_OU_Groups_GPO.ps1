#requires -RunAsAdministrator
# P07 - Run ON SERVERA, in an elevated Windows PowerShell session using a domain admin.
# Prerequisite: fittdtu.com forest and DNS already exist; clients already joined when possible.
# Safe to rerun: reuses existing OUs, users, groups, and GPOs.
# Lab user accounts: user_sales/user_acc/user_hr; shared fixed password below for DEMO only.
# This script does NOT configure Machine inactivity limit and does NOT create Starter GPO.
# Those actions MUST be done in GPMC to demonstrate the correct assignment requirement.

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory
Import-Module GroupPolicy
$domain = Get-ADDomain
if ($env:COMPUTERNAME -ine 'SERVERA') { throw 'Run this script on SERVERA only.' }
if ($domain.DNSRoot -ne 'fittdtu.com') {
    throw "Expected domain fittdtu.com; detected $($domain.DNSRoot). Stop."
}
$root = $domain.DistinguishedName
Write-Host "Domain: $($domain.DNSRoot), NetBIOS: $($domain.NetBIOSName)"
$LabUserPassword = 'P07Lab@2026!' # Demo only, three NON-ADMIN department test accounts
$LabUserPasswordSecure = ConvertTo-SecureString $LabUserPassword -AsPlainText -Force

function Ensure-OU([string]$name, [string]$parent) {
    $dn = "OU=$name,$parent"
    if (-not (Get-ADOrganizationalUnit -Identity $dn -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $name -Path $parent -ProtectedFromAccidentalDeletion $true | Out-Null
        Write-Host "Created OU: $dn"
    } else { Write-Host "OU exists: $dn" }
    return $dn
}

$employees = Ensure-OU 'Employees' $root
$workstations = Ensure-OU 'Workstations' $root
$groupsOu = Ensure-OU 'Groups' $root
foreach ($department in @('Sales','Accounting','HR')) {
    [void](Ensure-OU $department $employees)
    [void](Ensure-OU $department $workstations)
}

foreach ($groupName in @('GG_Sales_RW','GG_Accounting_RW','GG_HR_Users')) {
    if (-not (Get-ADGroup -Identity $groupName -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $groupName -SamAccountName $groupName -GroupScope Global `
            -GroupCategory Security -Path $groupsOu | Out-Null
        Write-Host "Created group: $groupName"
    }
}

$users = @(
    @{Sam='user_sales'; Name='Sales Demo'; Dept='Sales'; Group='GG_Sales_RW'},
    @{Sam='user_acc';   Name='Accounting Demo'; Dept='Accounting'; Group='GG_Accounting_RW'},
    @{Sam='user_hr';    Name='HR Demo'; Dept='HR'; Group='GG_HR_Users'}
)
foreach ($entry in $users) {
    $path = "OU=$($entry.Dept),$employees"
    $user = Get-ADUser -Identity $entry.Sam -ErrorAction SilentlyContinue
    if (-not $user) {
        New-ADUser -Name $entry.Name -SamAccountName $entry.Sam `
            -UserPrincipalName "$($entry.Sam)@fittdtu.com" -Path $path `
            -AccountPassword $LabUserPasswordSecure -Enabled $true -ChangePasswordAtLogon $false `
            -Department $entry.Dept | Out-Null
        Write-Host "Created user: $($entry.Sam)"
    } else {
        if (-not $user.DistinguishedName.EndsWith(",$path", [System.StringComparison]::OrdinalIgnoreCase)) {
            Move-ADObject -Identity $user.DistinguishedName -TargetPath $path
            Write-Host "Moved user: $($entry.Sam) to $path"
        }
    }
    $members = @(Get-ADGroupMember -Identity $entry.Group)
    if (-not ($members | Where-Object { $_.SamAccountName -eq $entry.Sam })) {
        Add-ADGroupMember -Identity $entry.Group -Members $entry.Sam
        Write-Host "Added $($entry.Sam) to $($entry.Group)"
    }
}

$pcs = @(
    @{Name='PC-SAL-01'; Dept='Sales'},
    @{Name='PC-ACC-01'; Dept='Accounting'},
    @{Name='PC-HR-01'; Dept='HR'}
)
foreach ($entry in $pcs) {
    $pc = Get-ADComputer -Identity $entry.Name -ErrorAction SilentlyContinue
    $target = "OU=$($entry.Dept),$workstations"
    if (-not $pc) {
        Write-Warning "Computer $($entry.Name) not in AD. Join it to domain, then rerun this script."
        continue
    }
    if (-not $pc.DistinguishedName.EndsWith(",$target", [System.StringComparison]::OrdinalIgnoreCase)) {
        Move-ADObject -Identity $pc.DistinguishedName -TargetPath $target
        Write-Host "Moved computer: $($entry.Name) to $target"
    }
}

# Create and link EMPTY GPOs. Configure the actual policies with GPMC afterward.
# IMPORTANT: Create P07_Restrict_ControlPanel FROM the Starter GPO through GPMC; do not create it here.
$links = @(
    @{Name='P07_Lock_15m';        Target=$workstations},
    @{Name='P07_Lock_5m';         Target="OU=Sales,$workstations"},
    @{Name='P07_Lock_5m';         Target="OU=Accounting,$workstations"},
    @{Name='P07_Map_SalesDocs';   Target="OU=Sales,$employees"},
    @{Name='P07_Map_AccountingDocs'; Target="OU=Accounting,$employees"}
)
foreach ($entry in $links) {
    if (-not (Get-GPO -Name $entry.Name -ErrorAction SilentlyContinue)) {
        New-GPO -Name $entry.Name -Comment 'TDTU P07 lab' | Out-Null
        Write-Host "Created GPO: $($entry.Name)"
    }
    $direct = @((Get-GPInheritance -Target $entry.Target).GpoLinks)
    if (-not ($direct | Where-Object { $_.DisplayName -eq $entry.Name })) {
        New-GPLink -Name $entry.Name -Target $entry.Target -LinkEnabled Yes | Out-Null
        Write-Host "Linked: $($entry.Name) -> $($entry.Target)"
    }
}
Write-Host "`nAD OU / group / user / machine placement / GPO skeleton finished."
Write-Host 'Lab test-user password (non-admin accounts): P07Lab@2026!'
Write-Host 'NEXT: In GPMC set 900s/300s; create Starter GPO -> active GPO; set Drive Maps.'
