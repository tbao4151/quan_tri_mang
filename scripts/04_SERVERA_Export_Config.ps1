#requires -RunAsAdministrator
# P07 - Run on SERVERA using domain admin, elevated PowerShell.
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory
Import-Module GroupPolicy
$folder = 'C:\P07_ServerA_Evidence'
New-Item -Path $folder -ItemType Directory -Force | Out-Null
$root = (Get-ADDomain).DistinguishedName

Get-ADOrganizationalUnit -Filter * -SearchBase $root |
    Select-Object Name,DistinguishedName |
    Sort-Object DistinguishedName |
    Format-Table -Wrap -AutoSize | Out-String -Width 240 |
    Set-Content "$folder\01_OU_Tree.txt"
foreach ($g in 'GG_Sales_RW','GG_Accounting_RW','GG_HR_Users') {
    Get-ADGroupMember -Identity $g | Select-Object @{Name='Group';Expression={$g}},Name,SamAccountName |
        Export-Csv "$folder\02_Group_$g.csv" -NoTypeInformation -Encoding UTF8
}
Get-ADComputer -Filter 'Name -like "PC-*"' -Properties DistinguishedName |
    Select-Object Name,DistinguishedName | Export-Csv "$folder\03_PC_OU.csv" -NoTypeInformation -Encoding UTF8
Get-ADUser -Filter 'SamAccountName -eq "sales01" -or SamAccountName -eq "acc01" -or SamAccountName -eq "hr01"' |
    Select-Object SamAccountName,DistinguishedName | Export-Csv "$folder\04_Users_OU.csv" -NoTypeInformation -Encoding UTF8
foreach ($n in 'P07_Lock_15m','P07_Lock_5m','P07_Restrict_ControlPanel','P07_Map_SalesDocs','P07_Map_AccountingDocs') {
    if (Get-GPO -Name $n -ErrorAction SilentlyContinue) {
        Get-GPOReport -Name $n -ReportType Html -Path "$folder\GPO_$n.html"
    } else { Write-Warning "Missing GPO: $n" }
}
foreach ($ou in 'OU=Workstations','OU=Sales,OU=Workstations','OU=Accounting,OU=Workstations',
                 'OU=Sales,OU=Employees','OU=Accounting,OU=Employees','OU=HR,OU=Employees') {
    Get-GPInheritance -Target "$ou,$root" | Out-File "$folder\Links_$($ou -replace '[=,]','_').txt"
}
Write-Host "SERVERA configuration exported to $folder"
Write-Host 'MANUAL: Capture GPMC Starter GPO and Group Policy Results screens as screenshots.'
