# BÀN GIAO THỰC THI CHO THÀNH VIÊN 1 — ĐỒ ÁN 07

**Đây là tệp bắt đầu thực hành.** Thành viên 1 đã dựng 5 VM và join domain theo biên bản bàn giao. **Không cài lại Windows Server, không tạo forest lần hai, không join lại domain** nếu máy đang hoạt động bình thường. Thành viên 2 cung cấp các bước và chịu trách nhiệm xử lý lỗi; thành viên 1 chạy và gửi lại ảnh/log cho thành viên 3.

**Trạng thái:** các cấu hình sau là kế hoạch thực thi, **chưa có minh chứng đã chạy trên VM**. Sau mỗi bước phải kiểm tra kết quả thật.

## 0. Sơ đồ dùng chung và quy ước cố định

| Máy | IP | Vai trò | Đăng nhập khi kiểm thử |
|---|---|---|---|
| SERVERA | 10.0.0.1 | Windows Server 2012 R2, AD DS / DNS / GPMC | Domain Administrator |
| SERVERB | 10.0.0.2 | Windows Server 2012 R2, SMB file server | Domain Administrator |
| PC-SAL-01 | 10.0.0.11 | Windows 10, Sales | \`user_sales@fittdtu.com\` |
| PC-ACC-01 | 10.0.0.12 | Windows 10, Accounting | \`user_acc@fittdtu.com\` |
| PC-HR-01 | 10.0.0.13 | Windows 10, HR | \`user_hr@fittdtu.com\` |

- Domain: \`fittdtu.com\`, mạng VMware: \`LAN_DoAn07\`.
- NetBIOS được TV1 khai báo là \`FITTDTI\` (chữ I cuối): xác nhận bằng \`(Get-ADDomain).NetBIOSName\` trên SERVERA. **Không đổi tên domain chỉ vì khác FQDN.**
- DNS \`127.0.0.1\` trên SERVERA và gateway \`10.0.0.1\` trên các VM còn lại hiện **không phải lý do để dựng lại mạng**, nếu domain/DNS đang hoạt động. Mạng LAN Segment đang cô lập.
- Tài khoản phòng ban do script 01 **sẽ tạo**: \`user_sales\`, \`user_acc\`, \`user_hr\`; mật khẩu lab chung (user thường, **không phải** Domain Administrator): **\`P07Lab@2026!\`**.
- Thư mục dữ liệu trên SERVERB: \`C:\Shares\SalesDocs\`, \`C:\Shares\AccountingDocs\`. UNC: \`\\SERVERB\SalesDocs\`, \`\\SERVERB\AccountingDocs\`.
- Tên policy **phải giống hệt đề**: \`P07_Lock_15m\`, \`P07_Lock_5m\`, \`Starter_No_ControlPanel\`, \`P07_Restrict_ControlPanel\`, \`P07_Map_SalesDocs\`, \`P07_Map_AccountingDocs\`.

### Cách chuyển script từ GitHub vào máy ảo KHÔNG có Internet

VM dùng LAN Segment nên không mặc định truy cập được GitHub. Trên **laptop host** mở file script trên GitHub, bấm **Raw** → sao chép nội dung. Trong VM đã có VMware Tools: mở Notepad → dán → Save As \`C:\P07\TEN_SCRIPT.ps1\`, **Save as type = All Files**, không được thành \`.ps1.txt\`. Hoặc dùng VMware Shared Folders nếu máy hỗ trợ.

Trên từng VM tạo thư mục lệnh:

\`\`\`powershell
New-Item -Path C:\P07 -ItemType Directory -Force
Set-Location C:\P07
Set-ExecutionPolicy -Scope Process Bypass -Force
\`\`\`

Chạy PowerShell **Run as Administrator** cho script 01, 02, 04; script 03 trên client chạy **PowerShell thường** dưới đúng tài khoản phòng ban. Không mở CMD để chạy file \`.ps1\` trực tiếp.

## 1. Kiểm tra nhanh hạ tầng — trên 5 VM

Nếu các VM đang kết nối domain và đăng nhập được, không phải dựng lại. Để có ảnh và log, chép [00_Preflight_5VM.ps1](../scripts/00_Preflight_5VM.ps1) rồi chạy trên từng máy:

\`\`\`powershell
.\00_Preflight_5VM.ps1
\`\`\`

Script chỉ đọc, xuất file \`P07_Preflight_<TENMAY>.txt\` trên Desktop. SERVERA xác nhận:

\`\`\`powershell
(Get-ADDomain).DNSRoot
(Get-ADDomain).NetBIOSName
Get-Service DNS,NTDS
\`\`\`

SERVERB và ba client xác nhận:

\`\`\`powershell
nltest /dsgetdc:fittdtu.com
Test-ComputerSecureChannel
\`\`\`

**Kỳ vọng:** \`Test-ComputerSecureChannel\` là \`True\` trên 4 domain member; không chạy kiểm tra này trên Domain Controller. Nếu sai, lưu ảnh và chuyển TV2 kiểm tra thay vì tự tạo lại domain.

## 2. SERVERA — tạo OU, 3 user, 3 group, chuyển 3 computer và GPO rỗng

Chạy [01_SERVERA_AD_OU_Groups_GPO.ps1](../scripts/01_SERVERA_AD_OU_Groups_GPO.ps1) trong PowerShell Administrator **trên SERVERA**:

\`\`\`powershell
cd C:\P07
.\01_SERVERA_AD_OU_Groups_GPO.ps1
\`\`\`

**Đầu ra cần có:**

\`\`\`text
Employees
  Sales        user_sales -> GG_Sales_RW
  Accounting   user_acc   -> GG_Accounting_RW
  HR           user_hr    -> GG_HR_Users
Workstations
  Sales        PC-SAL-01
  Accounting   PC-ACC-01
  HR           PC-HR-01
Groups
  GG_Sales_RW
  GG_Accounting_RW
  GG_HR_Users
\`\`\`

Kiểm tra trên SERVERA:

\`\`\`powershell
Get-ADGroupMember GG_Sales_RW
Get-ADGroupMember GG_Accounting_RW
Get-ADGroupMember GG_HR_Users
Get-ADComputer PC-SAL-01 | Select-Object Name,DistinguishedName
Get-ADComputer PC-ACC-01 | Select-Object Name,DistinguishedName
Get-ADComputer PC-HR-01 | Select-Object Name,DistinguishedName
\`\`\`

**Chụp:** \`dsa.msc\` cây OU + 3 computer + 3 group Members; \`gpmc.msc\` GPO links. Nếu script báo không thấy computer, kiểm tra ADUC/domain join rồi mới chạy lại.

## 3. SERVERA — cấu hình hai GPO khóa phiên trong GPMC

Mở \`gpmc.msc\` → \`Forest > Domains > fittdtu.com > Group Policy Objects\`:

**GPO \`P07_Lock_15m\`** → Edit → \`Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > Security Options\` → \`Interactive logon: Machine inactivity limit\` → Define/Enable = **900 seconds**. Link ở \`Workstations\`.

**GPO \`P07_Lock_5m\`** → cùng đường dẫn → **300 seconds**. GPO này link **cả hai OU** \`Workstations/Sales\` và \`Workstations/Accounting\`. OU HR chỉ nhận 900. Không bật Enforced hoặc Block Inheritance.

**Chụp:** mỗi setting với số giây và vị trí link tại OU.

## 4. SERVERA — tạo Starter GPO và GPO chặn Control Panel

Tại \`gpmc.msc\`:

1. \`Starter GPOs\` → tạo Starter folder nếu chưa có → \`New\`: **\`Starter_No_ControlPanel\`**.
2. Edit Starter → \`User Configuration > Policies > Administrative Templates > Control Panel\` → \`Prohibit access to Control Panel and PC settings = Enabled\`.
3. Click phải Starter vừa tạo → **New GPO from Starter GPO** → đặt tên **\`P07_Restrict_ControlPanel\`**.
4. Link **GPO hoạt động** vào \`Employees/Sales\` và \`Employees/Accounting\`; **không link HR**.
5. Chụp Starter Settings, thao tác tạo GPO từ Starter và Settings/Links của GPO hoạt động.

**Không** link Starter GPO trực tiếp với OU; không tạo \`P07_Restrict_ControlPanel\` bằng lệnh \`New-GPO\` trước bước 3.

## 5. SERVERB — tạo SMB share và phân quyền NTFS

Chạy [02_SERVERB_File_Shares.ps1](../scripts/02_SERVERB_File_Shares.ps1) bằng PowerShell Administrator, **đăng nhập Domain Administrator trên SERVERB**:

\`\`\`powershell
cd C:\P07
.\02_SERVERB_File_Shares.ps1
\`\`\`

Script tạo đúng hai thư mục, hai tệp mẫu và hai SMB share. Nó **cố ý dừng nếu thư mục/share có cùng tên đã tồn tại** để không ghi đè quyền hay dữ liệu cũ. Nếu gặp lỗi đó, gửi TV2 ảnh \`Get-SmbShare\` và \`icacls\`; **không tự xóa folder để chạy lại**.

\`\`\`powershell
Get-SmbShare -Name SalesDocs,AccountingDocs | Select-Object Name,Path
Get-SmbShareAccess -Name SalesDocs
Get-SmbShareAccess -Name AccountingDocs
icacls C:\Shares\SalesDocs
icacls C:\Shares\AccountingDocs
\`\`\`

**Quyền cần đạt:**
- SalesDocs: \`GG_Sales_RW\` Change (Share), Modify (NTFS); Accounting và HR không được phép.
- AccountingDocs: \`GG_Accounting_RW\` Change (Share), Modify (NTFS); Sales và HR không được phép.
- SYSTEM/Administrators được Full; ảnh Share Permissions và NTFS Security của **cả hai**.

## 6. SERVERA — hai GPO Drive Maps

Trong \`gpmc.msc\`, Edit từng GPO → \`User Configuration > Preferences > Windows Settings > Drive Maps\`:

| GPO | Link vào OU | New > Mapped Drive |
|---|---|---|
| \`P07_Map_SalesDocs\` | \`Employees/Sales\` | Action \`Update\`, Location \`\\SERVERB\SalesDocs\`, drive **S:** |
| \`P07_Map_AccountingDocs\` | \`Employees/Accounting\` | Action \`Update\`, Location \`\\SERVERB\AccountingDocs\`, drive **A:** |

Chọn \`Reconnect\`. Không link vào HR. Khi đổi GPO user, đăng xuất và đăng nhập lại để kiểm tra ổ đĩa.

## 7. Trên 3 client — áp GPO và đăng nhập tài khoản phòng ban

Trên mỗi client (CMD hoặc PowerShell nâng quyền) sau khi GPO được cấu hình:

\`\`\`cmd
gpupdate /force
shutdown /r /t 0
\`\`\`

Sau reboot, tại **Other user**, đăng nhập:

| Máy | Tài khoản | Mật khẩu lab |
|---|---|---|
| PC-SAL-01 | \`user_sales@fittdtu.com\` | \`P07Lab@2026!\` |
| PC-ACC-01 | \`user_acc@fittdtu.com\` | \`P07Lab@2026!\` |
| PC-HR-01 | \`user_hr@fittdtu.com\` | \`P07Lab@2026!\` |

Trong **PowerShell thường** (không Run as Administrator) của user này, chạy [03_CLIENT_Evidence.ps1](../scripts/03_CLIENT_Evidence.ps1):

\`\`\`powershell
cd C:\P07
Set-ExecutionPolicy -Scope Process Bypass -Force
.\03_CLIENT_Evidence.ps1
\`\`\`

Trên mỗi client, mở CMD **Run as Administrator** và chạy thêm:

\`\`\`cmd
gpresult /scope computer /r
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs
\`\`\`

**Giá trị:** Sales/Accounting = 300 giây (hex \`0x12c\`); HR = 900 giây (hex \`0x384\`). Kiểm tra khóa phiên **thực tế** sau thời gian không hoạt động; không thay bằng Win+L. Đăng nhập user bình thường để mở Control Panel, kiểm tra hai phòng bị chặn và HR mở được.

**Ma trận bắt buộc:**

| Kiểm thử | Sales | Accounting | HR |
|---|---|---|---|
| Lock | 300s | 300s | 900s |
| Control Panel | Bị chặn | Bị chặn | Được mở |
| Mapped drive | S: | A: | Không có S:/A: |
| \`\\SERVERB\SalesDocs\` | Đọc/ghi | Access denied | Access denied |
| \`\\SERVERB\AccountingDocs\` | Access denied | Đọc/ghi | Access denied |

Thử quyền chéo qua UNC khi đăng nhập tài khoản thường. Ví dụ trên PC Sales:

\`\`\`cmd
whoami
net use
dir \\SERVERB\SalesDocs
dir \\SERVERB\AccountingDocs
echo TDTU_P07_Sales > \\SERVERB\SalesDocs\KiemThu_Sales.txt
\`\`\`

PC Accounting thay chiều hai share và ghi tệp \`\\SERVERB\AccountingDocs\KiemThu_Accounting.txt\`. PC HR chạy \`dir\` với cả hai UNC. **Báo quyền bị từ chối khác lỗi không tìm thấy máy, lỗi DNS, hay sai đường dẫn**: cần ghi đúng kết quả.

## 8. SERVERA — xuất tài liệu minh chứng cấu hình

Trên SERVERA chạy [04_SERVERA_Export_Config.ps1](../scripts/04_SERVERA_Export_Config.ps1):

\`\`\`powershell
cd C:\P07
.\04_SERVERA_Export_Config.ps1
\`\`\`

Kết quả: \`C:\P07_ServerA_Evidence\` (OU, danh sách thành viên group, computer OU, GPO HTML, GPO link). Trên GPMC mở \`Group Policy Results Wizard\` cho PC + user đúng phòng ban. Trên client lưu \`gpresult\` HTML user/computer và ảnh màn hình.

## 9. Demo lỗi sai OU — chỉ thực hiện sau khi hệ thống đạt yêu cầu

Trên SERVERA, mở PowerShell Administrator:

\`\`\`powershell
Import-Module ActiveDirectory
$root = (Get-ADDomain).DistinguishedName
Move-ADObject -Identity (Get-ADComputer PC-SAL-01).DistinguishedName -TargetPath "OU=HR,OU=Workstations,$root"
\`\`\`

Trên PC-SAL-01: \`gpupdate /force\` → reboot → đăng nhập \`user_sales\` → registry/RSOP phải nhận **900**. Dù PC ở OU HR, user vẫn ở \`Employees/Sales\`, nên Control Panel vẫn bị chặn và S: vẫn có.

Trên SERVERA hoàn nguyên:

\`\`\`powershell
Move-ADObject -Identity (Get-ADComputer PC-SAL-01).DistinguishedName -TargetPath "OU=Sales,OU=Workstations,$root"
\`\`\`

PC-SAL-01: \`gpupdate /force\` → reboot → xác nhận **300**. GPO ngoài phạm vi OU không nhất thiết xuất hiện mục Denied: đối chiếu OU hiện tại, Applied GPOs, registry và phép thử thực tế.

## 10. Bàn giao minh chứng cho thành viên 3

Mỗi máy: hostname + \`whoami\` + screenshot + RSoP; với các phép thử quyền phải có cả **thành công lẫn bị từ chối**. Lưu bản gốc, không tự đổi kết quả. Dựa vào [checklist 31 hạng mục](checklist-minh-chung.md). Video tổng hợp 5–8 phút nên cắt hợp lý, nhưng lưu clip đo thời gian khóa thật để giải trình.

Thứ tự bàn giao: (1) 5 preflight TXT; (2) AD/GPO/ACL screenshots; (3) gpresult HTML + thử UNC; (4) ảnh lỗi 900/300 trước/sau; (5) video.
