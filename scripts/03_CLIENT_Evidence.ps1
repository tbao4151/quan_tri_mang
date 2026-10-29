# P07 - Run on EACH client, SIGNED IN AS its own department USER, in ordinary (not elevated) PowerShell.
# Creates evidence bundle on the client Desktop. The current user must remain sales01/acc01/hr01.
$ErrorActionPreference = 'Continue'
$name = $env:COMPUTERNAME
$user = (whoami)
$folder = Join-Path $env:USERPROFILE "Desktop\P07_Evidence_$name"
New-Item -Path $folder -ItemType Directory -Force | Out-Null

function Capture([string]$file, [scriptblock]$action) {
    try { & $action 2>&1 | Out-File -FilePath (Join-Path $folder $file) -Encoding UTF8 -Width 220 }
    catch { $_ | Out-File -FilePath (Join-Path $folder $file) -Encoding UTF8 }
}
Capture '01_Identity_Network.txt' { whoami /all; hostname; ipconfig /all; whoami /groups }
Capture '02_GPO_User.txt' { gpresult /scope user /r }
Capture '03_Lock_Registry.txt' { reg query 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v InactivityTimeoutSecs }
Capture '04_Mapped_Drives.txt' { net use }
Capture '05_SalesDocs_UNC.txt' { cmd /c 'dir \\SERVERB\SalesDocs' }
Capture '06_AccountingDocs_UNC.txt' { cmd /c 'dir \\SERVERB\AccountingDocs' }
Capture '07_Computer_Domain.txt' { nltest /dsgetdc:fittdtu.com }
# Standard users normally can export USER RSoP, but COMPUTER RSoP may require elevation.
& gpresult.exe /scope user /h (Join-Path $folder '08_GPResult_User.html') /f
Write-Host "Evidence exported to $folder (signed in as $user)."
Write-Host 'ADMINISTRATOR: separately open elevated CMD, run gpresult /scope computer /h C:\P07_Computer.html /f'
Write-Host 'MANUAL: capture Control Panel, S:/A: and actual file edit/denied error, and 5/15min timed locking.'
