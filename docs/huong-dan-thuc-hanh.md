# TDTU – Đồ án 07: Runbook kỹ thuật cho thành viên 2

**Nguồn yêu cầu:** `Do_an_07_GPO_Starter_GPO_File_Sharing_fittdtu.com.pdf` (2 trang).  
**Giả định:** 5 VM đã được cài đặt, cùng mạng LAN ảo, có quyền quản trị. Các lệnh chạy trong Windows PowerShell của máy được chỉ rõ, không chạy trên laptop host.  
**Trạng thái:** Đây là quy trình và mã nguồn đề xuất, **chưa được chạy/kiểm chứng trên 5 VM thực tế**.

## 0. Phân công & quy ước
- TV1: cài/duy trì 5 VM, thực thi đúng lệnh trên từng VM, chụp màn hình và quay video. Không thay đổi thiết lập/đổi tên tùy ý.
- TV2: đối chiếu yêu cầu, điều phối đúng thứ tự, cấu hình OU/GPO/NTFS, đọc `gpresult`, lập ma trận kiểm thử, chủ trì giải thích bảo vệ.
- TV3: đưa minh chứng thật của TV1 vào báo cáo và slide. Không tạo hình kết quả giả.
- Sơ đồ: `SERVERA=10.0.0.1`, `SERVERB=10.0.0.2`, `PC-SAL-01`, `PC-ACC-01`, `PC-HR-01`; DNS/AD domain là `fittdtu.com`. Client minh họa dùng IP `10.0.0.11/12/13`, gateway không bắt buộc trong host-only LAN.
- Domain NetBIOS **đề xuất** `FITTDTU`. Lấy giá trị thực bằng `(Get-ADDomain).NetBIOSName` hoặc `$env:USERDOMAIN`, **không mặc định tên NetBIOS đã là FITTDTU**.
- Tài khoản demo: `sales01`, `acc01`, `hr01`. Chỉ đăng nhập tài khoản đúng phòng ban trên PC tương ứng.
- Snapshot VM trước bước áp GPO và bước mô phỏng lỗi; **không hoàn nguyên riêng SERVERA/Domain Controller tùy tiện** khi domain member đã thay đổi trạng thái. VM Server 2012 R2 chỉ dùng LAN ảo cô lập, không đưa lên Internet (hết ESU 13/10/2026).

## 1. Preflight: 5 VM và domain

**Quy ước với TV1:** kiểm tra RAM/dung lượng SSD và dung lượng snapshot trên máy host. Với 16 GB RAM host, ưu tiên chạy SERVERA + SERVERB + từng client để kiểm thử luân phiên nếu cả 5 VM cùng bật gây thiếu RAM; phân bổ Windows 10 đầy đủ nên từ khoảng 2 GB/client nếu phần cứng cho phép. Kiểm tra đồng bộ thời gian bằng `w32tm /query /status` để tránh lỗi xác thực Kerberos do lệch giờ.


**Trên SERVERA (PowerShell quản trị):**
```powershell
hostname
ipconfig /all
Get-WindowsFeature AD-Domain-Services,GPMC
Get-ADDomain | Format-List DNSRoot,NetBIOSName,DistinguishedName
Get-ADDomainController -Discover
Resolve-DnsName serverb.fittdtu.com
```
Yêu cầu: DNSRoot=`fittdtu.com`, IPv4=`10.0.0.1/24`; vai trò AD DS, DNS chạy được.

**Trên SERVERB:**
```powershell
hostname
ipconfig /all
(Get-WmiObject Win32_ComputerSystem) | Select Name,PartOfDomain,Domain
Test-ComputerSecureChannel
nslookup servera.fittdtu.com 10.0.0.1
```
DNS của SERVERB phải trỏ **10.0.0.1**, không phải DNS công cộng. PartOfDomain=True. Địa chỉ SERVERB 10.0.0.2/24.

**Trên từng client:**
```powershell
hostname
ipconfig /all
(Get-WmiObject Win32_ComputerSystem) | Select Name,PartOfDomain,Domain
nslookup fittdtu.com 10.0.0.1
ping 10.0.0.1
ping 10.0.0.2
nltest /dsgetdc:fittdtu.com
Test-ComputerSecureChannel
```
Kết quả: DNS duy nhất/ưu tiên `10.0.0.1`, domain `fittdtu.com`, đều tìm được domain controller. ICMP có thể bị chặn bởi Windows Firewall; nếu `ping` thất bại nhưng DNS/AD chạy, xem firewall/network profile.

**Nếu domain chưa được tạo** (chỉ thực hiện 1 lần trên SERVERA, không chạy lại nếu đã có AD):
```powershell
Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools
Install-ADDSForest -DomainName 'fittdtu.com' -DomainNetbiosName 'FITTDTU' `
  -InstallDNS -SafeModeAdministratorPassword (Read-Host 'DSRM password' -AsSecureString) -Force
```
SERVERA tự khởi động lại. Trên SERVERB/client trỏ DNS về SERVERA trước khi join domain. Mỗi máy sử dụng PowerShell nâng quyền:
```powershell
Add-Computer -DomainName 'fittdtu.com' -Credential (Get-Credential) -Restart
```
Nhập tài khoản domain admin khi được hỏi. Dùng **Windows 10 Pro/Enterprise/Education chính thức và đồng nhất cho cả ba client**; tránh Windows 7 vì không hỗ trợ chính sách Machine inactivity limit theo đề và tránh bản Windows Lite tùy biến. Windows 10/11 Home không hỗ trợ domain join. Với hệ thống đã dựng đầy đủ, **bỏ qua nhánh bootstrap**.

## 2. Chạy script dựng OU, group, GPO khung trên SERVERA

Đăng nhập SERVERA bằng domain admin. Mở `Windows PowerShell` – Run as Administrator. Nếu thiếu GPMC, cài:
```powershell
Install-WindowsFeature GPMC
```
Lưu/copy `Scripts/01_SERVERA_AD_OU_Groups_GPO.ps1` sang SERVERA và chạy:
```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\01_SERVERA_AD_OU_Groups_GPO.ps1
```
Script thực hiện:
1. Tạo `OU=Employees` và ba OU con `Sales`, `Accounting`, `HR`.
2. Tạo `OU=Workstations` và ba OU con tương ứng.
3. Tạo `OU=Groups`, ba security Global Groups `GG_Sales_RW`, `GG_Accounting_RW`, `GG_HR_Users`.
4. Tạo user demo, hỏi từng mật khẩu qua SecureString, cho vào group và OU đúng.
5. Di chuyển **computer object** vào đúng OU nếu ba PC đã domain-join. Nếu chưa có, join rồi chạy lại script.
6. Tạo GPO khung `P07_Lock_15m`, `P07_Lock_5m`, `P07_Map_SalesDocs`, `P07_Map_AccountingDocs`, liên kết OU theo đề. **Chưa cấu hình settings**.

Kiểm tra trực quan: `Server Manager > Tools > Active Directory Users and Computers` (`dsa.msc`), bật `View > Advanced Features` nếu cần. Cây mẫu:
```text
fittdtu.com
├── Employees
│   ├── Sales         └── sales01
│   ├── Accounting    └── acc01
│   └── HR            └── hr01
├── Workstations
│   ├── Sales         └── PC-SAL-01
│   ├── Accounting    └── PC-ACC-01
│   └── HR            └── PC-HR-01
└── Groups
    ├── GG_Sales_RW        (sales01)
    ├── GG_Accounting_RW   (acc01)
    └── GG_HR_Users        (hr01)
```
Lệnh kiểm tra:
```powershell
Get-ADGroupMember GG_Sales_RW
Get-ADGroupMember GG_Accounting_RW
Get-ADGroupMember GG_HR_Users
Get-ADComputer PC-SAL-01 | Select Name,DistinguishedName
Get-ADComputer PC-ACC-01 | Select Name,DistinguishedName
Get-ADComputer PC-HR-01 | Select Name,DistinguishedName
```
Lưu ảnh cây OU, thuộc tính từng group và tab `Member Of` của user.

## 3. GPO khóa phiên 900 và 300 giây – Computer Configuration

**Trên SERVERA:** mở GPMC `gpmc.msc` (`Server Manager > Tools > Group Policy Management`).

**3A. P07_Lock_15m:**
1. Trong `Forest > Domains > fittdtu.com > Group Policy Objects`, click phải `P07_Lock_15m` > `Edit`.
2. `Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > Security Options`.
3. `Interactive logon: Machine inactivity limit` > tick `Define this policy setting` > nhập **900** (đơn vị giây) > OK.
4. Ở GPMC xác nhận GPO được link ở **OU=Workstations**, không phải `Employees`.

**3B. P07_Lock_5m:**
1. Edit GPO `P07_Lock_5m` theo cùng đường dẫn.
2. Nhập **300** giây.
3. Kiểm tra GPO này có **hai link riêng**: `Workstations/Sales` và `Workstations/Accounting`.
4. Không link GPO 300 giây vào `Workstations/HR`.

**Tại sao 300 ghi đè 900?** GPO áp lên các OU từ cha đến con; với cùng một security option, GPO link ở OU con (Sales, Accounting) có mức ưu tiên cao hơn so với GPO ở `Workstations` cha, nếu không bật Enforced hoặc đặt thêm cơ chế ngoại lệ. HR không có GPO 300 nên dùng 900.

**Kiểm thử (mỗi PC, sau khi chuyển đúng computer object vào OU):**
```cmd
gpupdate /force
shutdown /r /t 0
```
Sau reboot, sign in tài khoản đúng phòng ban. Chạy (cmd):
```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs
gpresult /scope computer /r
```
Lệnh `gpresult /scope computer /r` có thể cần CMD nâng quyền. Giá trị registry REG_DWORD kỳ vọng: Sales và Accounting `0x12c` (300), HR `0x384` (900). Cần **trình diễn khóa phiên thật**: bỏ tay khỏi bàn phím/chuột đủ 5/15 phút, không dùng `Win+L` để giả lập. Để không có yếu tố can thiệp, tắt tạm màn hình chờ/thiết lập nguồn gây khóa sớm hơn và dùng một đồng hồ riêng để quay; lưu thời gian bắt đầu/kết thúc. Theo Microsoft, tắt màn hình và screen saver cũng có thể làm khóa sớm; reboot cần thiết để security policy hiệu lực ổn định.

**Ảnh cần:** Setting 900, setting 300, link OU cha/con, `gpresult`/registry của ba PC, màn hình đã khóa kèm thời gian đo.

## 4. Starter GPO hạn chế Control Panel – User Configuration

**Phải làm qua GPMC, không viết registry trực tiếp**: đề yêu cầu chứng minh **Starter GPO làm mẫu** cho GPO hoạt động.

1. Trên SERVERA, mở GPMC. Chọn `Starter GPOs` dưới domain; click `Create Starter GPOs Folder` nếu hiện nút này lần đầu.
2. Click phải `Starter GPOs > New` > đặt tên **Starter_No_ControlPanel**.
3. Click phải starter vừa tạo > `Edit`.
4. Vào `User Configuration > Policies > Administrative Templates > Control Panel`.
5. `Prohibit access to Control Panel and PC settings` > `Enabled` > OK.
6. Quay lại `Starter GPOs`; click phải `Starter_No_ControlPanel > New GPO from Starter GPO`.
7. Đặt tên GPO hoạt động **P07_Restrict_ControlPanel**.
8. Tại `Employees/Sales` > `Link an Existing GPO` > chọn `P07_Restrict_ControlPanel`; làm tương tự `Employees/Accounting`.
9. **Không** liên kết với `Employees/HR`, `Employees` cha hoặc domain gốc.
10. Ở `Group Policy Objects > P07_Restrict_ControlPanel > Settings`, chụp minh chứng policy đã được sao chép từ Starter.

**Lưu ý:** Starter GPO **không liên kết trực tiếp vào OU**. Khi tạo GPO hoạt động từ Starter, các thiết lập được sao chép tại thời điểm tạo; việc chỉnh Starter về sau không tự đổi GPO đã tạo.

**Kiểm thử:** Trên từng PC đăng nhập đúng user, chạy:
```cmd
gpupdate /force
logoff
```
Đăng nhập lại. Thử `Win+R > control`, hoặc mở `Control Panel`, và `Settings` (tùy OS). Sales/Accounting phải hiện thông báo chặn; HR được mở. Xuất `gpresult /scope user /r` và `gpresult /scope user /h <duong_dan> /f`.

## 5. ServerB: hai folder, Share và NTFS

**Trên SERVERB:** đăng nhập **domain admin**, Run PowerShell as Administrator. Chép `Scripts/02_SERVERB_File_Shares.ps1` và chạy:
```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\02_SERVERB_File_Shares.ps1
```
Thư mục/tệp được tạo (ở C: trong ví dụ; có thể đổi `$base` thành D: nếu có ổ dữ liệu):
```text
C:\DeptShares\SalesDocs\KeHoach_Sales.txt
C:\DeptShares\AccountingDocs\BaoCao_Accounting.txt
```
Share UNC:
```text
\\SERVERB\SalesDocs
\\SERVERB\AccountingDocs
```

**Ma trận ACL phải đạt (không dựa vào tên tệp):**

| Tài nguyên | Share ACL | NTFS ACL |
|---|---|---|
| SalesDocs | `GG_Sales_RW: Change`; `Administrators: Full` | `GG_Sales_RW: Modify`; `Administrators: Full`; `SYSTEM: Full` |
| AccountingDocs | `GG_Accounting_RW: Change`; `Administrators: Full` | `GG_Accounting_RW: Modify`; `Administrators: Full`; `SYSTEM: Full` |

Không cấp quyền cho nhóm chéo, `Everyone` hoặc `Authenticated Users` trên thư mục bộ phận. Nếu folder/share đã tồn tại, script **dừng trước khi cấu hình** để tránh ghi đè dữ liệu/quyền NTFS tường minh có sẵn. Khi đó phải rà soát thủ công rồi chọn thư mục lab trống; mở `Computer Management > Shared Folders > Shares > Properties > Share Permissions` và kiểm tra/gỡ ACE thừa. Trên `Properties > Security > Advanced` kiểm tra NTFS, kể cả các quyền inherited. NTFS Modify cho phép tạo, chỉnh sửa và xóa tệp: phù hợp yêu cầu đọc/ghi; nếu chỉ cần đọc và cập nhật nhưng không xóa thì thiết kế riêng (ngoài phạm vi đề).

**Lệnh xem minh chứng (SERVERB):**
```powershell
Get-SmbShare -Name SalesDocs,AccountingDocs | Select Name,Path
Get-SmbShareAccess -Name SalesDocs
Get-SmbShareAccess -Name AccountingDocs
icacls C:\DeptShares\SalesDocs
icacls C:\DeptShares\AccountingDocs
```
Ảnh quan trọng: `Sharing/Permissions` và `Security` của **cả hai folder**.

## 6. GPO ánh xạ ổ đĩa – User Configuration

**Trên SERVERA, GPMC:**

**P07_Map_SalesDocs**
1. Edit `P07_Map_SalesDocs` (đã link `Employees/Sales`).
2. `User Configuration > Preferences > Windows Settings > Drive Maps`.
3. Click phải > `New > Mapped Drive`.
4. `Action: Update`.
5. `Location: \\SERVERB\SalesDocs`.
6. `Drive Letter: Use S:` (chọn letter S: cụ thể); `Label as: SalesDocs`.
7. `Reconnect: checked`, OK.

**P07_Map_AccountingDocs**
1. Edit `P07_Map_AccountingDocs` (đã link `Employees/Accounting`).
2. Cùng đường dẫn Preferences/Drive Maps.
3. `Action: Update`, `Location: \\SERVERB\AccountingDocs`, `Drive Letter: A:`, `Label as: AccountingDocs`, `Reconnect: checked`.
4. Chú ý: Windows có thể từng dùng A: làm floppy drive; kiểm tra A: đang trống trước khi áp GPO.

Không liên kết hai GPO ánh xạ vào OU cha `Employees` hoặc `Employees/HR`. Trên mỗi client login đúng user, chạy `gpupdate /force`, `logoff`, login lại, mở `This PC` và `net use` để xác minh mapping. **Ánh xạ ổ S:/A: chỉ là tiện ích hiển thị/đường dẫn, không thay thế quyền Share/NTFS.**

Nếu đổi OU/user để làm demo mà thấy ổ cũ còn tồn tại, đăng xuất/đăng nhập lại, kiểm tra GPP `Common > Remove this item when it is no longer applied` (lựa chọn này thay đổi hành vi action của item) hoặc gỡ mapping demo cũ. Không xóa mapping bất kỳ người dùng thật nào.

## 7. Ma trận 9 kiểm thử UNC độc lập với ánh xạ ổ

**Trên PC Sales, đăng nhập `sales01`:**
```cmd
whoami
net use
dir \\SERVERB\SalesDocs
dir \\SERVERB\AccountingDocs
echo Sales test > \\SERVERB\SalesDocs\KiemThu_Sales.txt
```
Kỳ vọng: `S:` có; đọc SalesDocs và ghi tệp được; `dir \\SERVERB\AccountingDocs` bị `Access is denied`.

**Trên PC Accounting, đăng nhập `acc01`:**
```cmd
whoami
net use
dir \\SERVERB\AccountingDocs
dir \\SERVERB\SalesDocs
echo Accounting test > \\SERVERB\AccountingDocs\KiemThu_Accounting.txt
```
Kỳ vọng: `A:` có; đọc/ghi AccountingDocs được; SalesDocs bị từ chối.

**Trên PC HR, đăng nhập `hr01`:**
```cmd
whoami
net use
dir \\SERVERB\SalesDocs
dir \\SERVERB\AccountingDocs
```
Kỳ vọng: không có S:/A: và cả hai lệnh truy cập UNC đều bị từ chối. Chú ý: bằng chứng "không thấy ổ S:" **không đủ**, vì user có thể tự nhập đường dẫn UNC; bắt buộc kiểm thử `dir \\SERVERB\SalesDocs`.

Tránh lỗi 1219 nhiều tài khoản SMB: đừng đăng nhập `\\SERVERB` bằng credential admin rồi kiểm thử account thường trong cùng phiên. Nếu cần, `net use` để xem session và ngắt **đúng kết nối demo** trước khi chạy; tốt nhất mỗi VM dùng riêng user đúng bộ phận.

## 8. Thu thập gpresult / Group Policy Results

**Trên từng client khi đã login `sales01`/`acc01`/`hr01`:**
```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\03_CLIENT_Evidence.ps1
```
Script xuất thư mục `Desktop\P07_Evidence_PC-...`, gồm user identity, IP/DNS, `gpresult` user, registry inactivity, `net use`, hai lệnh UNC và báo cáo HTML user.

**Để lấy báo cáo computer (cần CMD mở Run as Administrator):**
```cmd
mkdir C:\P07_Evidence_Admin
gpresult /scope computer /r > C:\P07_Evidence_Admin\Computer_RSoP.txt
gpresult /scope computer /h C:\P07_Evidence_Admin\Computer_RSoP.html /f
```
Chụp danh sách Applied và Denied nếu có. **GPO 5 phút nằm ngoài phạm vi OU có thể không xuất hiện trong mục Denied**, vì không nằm trong phạm vi xử lý; không được tự suy diễn kết quả Denied. Nếu `gpresult /h` lỗi do quyền thì tạo riêng user/computer theo scope thay vì nhầm kết quả admin là kết quả user demo.

**Trên SERVERA: Group Policy Results:**
1. GPMC > `Group Policy Results` > click phải `Group Policy Results Wizard`.
2. Select computer `PC-SAL-01`, select user `sales01` > Finish; xem `Summary/Settings`.
3. Làm tương tự `PC-ACC-01/acc01`, `PC-HR-01/hr01`.
4. Nếu wizard không truy cập từ xa, ưu tiên `gpresult /h` chạy trực tiếp trên client và kiểm tra firewall/RPC/WMI. Không dùng báo cáo cũ để giả định đã áp xong.

**Lệnh lưu cấu hình SERVERA** (độc lập với RSoP):
```powershell
.\04_SERVERA_Export_Config.ps1
```
Script xuất file văn bản/CSV/HTML vào `C:\P07_ServerA_Evidence`.

## 9. Tình huống bắt buộc: máy sai OU nhận 900 thay vì 300

Chọn `PC-SAL-01` làm máy demo. **Trước khi cố tình phá**, bảo đảm cấu hình gốc hoạt động, chụp `300` và GPO áp dụng.

**Trên SERVERA (PowerShell admin):**
```powershell
Import-Module ActiveDirectory
$dn = (Get-ADDomain).DistinguishedName
Get-ADComputer PC-SAL-01 | Select Name,DistinguishedName
Move-ADObject -Identity (Get-ADComputer PC-SAL-01).DistinguishedName `
  -TargetPath "OU=HR,OU=Workstations,$dn"
```
**Trên PC-SAL-01:** `gpupdate /force`, khởi động lại, login `sales01`, xem `gpresult /scope computer /r` và `reg query ... InactivityTimeoutSecs`. Kỳ vọng **900** do PC bị đặt trong Workstations/HR. `sales01` vẫn thuộc Employees/Sales, vì vậy Control Panel vẫn bị chặn và S: vẫn có; đây là minh chứng rõ chính sách máy/người dùng tách biệt.

**Sửa trên SERVERA:**
```powershell
Move-ADObject -Identity (Get-ADComputer PC-SAL-01).DistinguishedName `
  -TargetPath "OU=Sales,OU=Workstations,$dn"
```
**PC Sales:** `gpupdate /force`, reboot, xác minh registry về **300**, `gpresult` hiển thị `P07_Lock_5m`, chụp trước/sau. Viết báo cáo 4 vế: mong đợi 300 → thực tế sai 900 → nguyên nhân PC object ở sai OU → sửa OU và refresh/reboot → thực tế đúng 300.

Đây là lỗi có chủ đích trong VM lab, không áp vào hệ thống thật. Không di chuyển PC-HR-01 để tránh mất mẫu đối chứng.

## 10. Cách đọc kết quả / chẩn đoán nhanh

| Triệu chứng | Kiểm tra đầu tiên | Hướng xử lý |
|---|---|---|
| `gpupdate` không tìm thấy DC | `ipconfig /all`, `nslookup`, `nltest /dsgetdc:fittdtu.com` | DNS client phải trỏ 10.0.0.1; kiểm tra VMware network / AD/DNS |
| Sales nhận 900 thay vì 300 | `Get-ADComputer ... DistinguishedName`, GPMC GPO links | Đưa **computer object** vào `Workstations/Sales`, kiểm tra 300 không bị block/enforce, gpupdate và reboot |
| Sales mở được Control Panel | `gpresult /scope user /r`, OU user, Starter-derived GPO | User phải ở `Employees/Sales`, link GPO hoạt động, logout/login; Starter không thể link trực tiếp |
| HR bị chặn Control Panel | Link restriction ở domain/Employees cha? | Gỡ link sai; chỉ link `Employees/Sales` và `Employees/Accounting` |
| S:/A: không xuất hiện | `net use`, `gpresult /scope user /r`, Drive Maps item, UNC DNS | Kiểm tra User Configuration/Drive Maps, location và letter, login đúng user, gpupdate+logoff |
| Ổ có nhưng không ghi được | `Get-SmbShareAccess`, `icacls`, thử `echo > UNC` | Kiểm tra **cả Share và NTFS**; quyền hiệu lực bị giới hạn bởi tầng hạn chế hơn |
| HR vẫn đọc được SalesDocs | Share/NTFS có `Everyone`, Domain Users, Authenticated Users? | Loại bỏ ACE quá rộng ở thư mục bộ phận; bảo đảm test bằng hr01 không phải admin |
| GPMC Group Policy Results lỗi từ xa | local `gpresult /h`, RPC/WMI/firewall | Lấy HTML local trước; xử lý remote permissions / firewall sau |
| Registry đúng nhưng khóa sớm | Screen saver / display sleep | Tách nguyên nhân từ power settings/screen saver; đo thực tế, không quy chụp GPO sai |
| Access denied bất thường do SMB session | `net use`, `whoami` | Thử lại bằng đúng user, không dùng phiên mạng đã lưu credential admin |

## 11. Bảng mở rộng doanh nghiệp 200 PC

- Đặt tên nhất quán: `PC-SAL-001..N`, `PC-ACC-001..N`, `PC-HR-001..N` (môi trường mẫu theo đề có tên `PC-SAL-01` v.v.). Các số lượng phòng ban **chưa được đề ấn định**; có thể minh họa kịch bản Sales=80, Accounting=70, HR=50, tổng=200, và đánh dấu **giả định thiết kế** chứ không nói là yêu cầu đề.
- User naming: `sal.<maNV>`, `acc.<maNV>`, `hr.<maNV>` cho mở rộng, nhóm demo vẫn là `sales01`, `acc01`, `hr01`.
- Khi thêm PC: domain join → move AD computer object tới `Workstations/<phong>` → `gpupdate /force` → reboot → đọc RSoP.
- Khi thêm user: tạo trong `Employees/<phong>` → vào group bộ phận → login → kiểm tra mapping/NTFS.
- Giữ 1 GPO 300 giây dùng lại cho Sales & Accounting thay vì tạo 200 GPO. Từ OU cha có thể mở rộng chính sách chung mà không cấu hình từng PC. Nếu di chuyển phòng ban cần cập nhật **cả user và computer**, tùy trường hợp.

## 12. Minh chứng phải giao cho thành viên 3

Đính kèm `Bang_Kiem_Tra_Minh_Chung.csv`, đánh dấu `DAT/CHUA_DAT`, file ảnh, máy tạo ảnh, tài khoản đăng nhập, thời điểm. Ảnh phải thấy hostname/identity hoặc có file RSoP tương ứng, không ảnh chụp rời không truy vết.

Các ảnh quyết định điểm: (1) 5 VM và DNS/domain; (2) cây OU, 3 group; (3) hai policy 900/300 và links; (4) Starter GPO và GPO được tạo từ starter; (5) 3 kết quả Control Panel; (6) hai GPO Drive Maps; (7) Share + NTFS của 2 folder; (8) Sales/Accounting ghi được và quyền chéo từ chối; (9) HR bị từ chối cả 2 UNC; (10) 3 RSoP/registry; (11) sai OU trước/sau sửa; (12) bằng chứng lock session thực tế.

## 13. Timeline trình bày video 5–8 phút

- 00:00–00:45: mục tiêu, sơ đồ 5 VM, domain.
- 00:45–01:35: OU Employees/Workstations, 3 nhóm và phạm vi chính sách.
- 01:35–02:45: GPO 900/300, gpresult/registry 3 PC; đoạn khóa thực tế có ghi hình và tua thời gian minh bạch.
- 02:45–03:35: Starter GPO → GPO hoạt động; mở Control Panel Sales/Accounting bị chặn, HR mở được.
- 03:35–05:15: Share/NTFS, ánh xạ S:/A:, thử đọc/ghi và quyền chéo UNC.
- 05:15–06:35: sai OU → 900 → chuyển về OU Sales → 300, đọc gpresult.
- 06:35–07:30: giải thích mở rộng lên 200 PC, tổng kết đạt/không đạt.

Không cắt ghép để làm như khóa máy diễn ra ngay; có thể tua đoạn chờ, ghi rõ mốc thời gian gốc.

## 14. Bảo vệ: câu hỏi nhanh và câu trả lời đúng

**Q1. Starter GPO khác GPO hoạt động?** Starter chỉ là mẫu Administrative Templates, không liên kết trực tiếp vào OU. Tạo GPO mới từ mẫu sẽ sao chép thiết lập để liên kết và áp dụng. Sau khi tạo, hai đối tượng không tự đồng bộ.

**Q2. Sales nhận 300 dù cha Workstations có 900?** Cả hai GPO cấu hình cùng Security Option ở Computer Configuration. GPO link OU Sales con ưu tiên hơn link Workstations cha trong kế thừa thông thường (không Enforced/Block đặc biệt).

**Q3. Khóa phiên thuộc nhánh nào?** `Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > Security Options`, vì khóa gắn theo thiết bị.

**Q4. Không hiện S: đã đủ chứng minh không đọc được SalesDocs?** Chưa. Drive Map là GPP tiện dụng, đường UNC vẫn có thể truy cập nếu ACL cho phép. Phải thử `\\SERVERB\SalesDocs` bằng tài khoản không được phép.

**Q5. Share Permissions và NTFS khác nhau?** Share chỉ kiểm soát truy cập qua SMB, NTFS kiểm soát trên filesystem. Truy cập mạng phải vượt qua cả hai; quyền hiệu lực là giao của hai tầng, tầng hạn chế hơn quyết định.

**Q6. Vì sao dùng Global Security Group thay vì ACL cho từng user?** Thiết kế theo RBAC/AGDLP (mức lab dùng Global Group trực tiếp trên ACL), thay đổi thành viên nhóm thay vì sửa hàng loạt ACE trên file share; dễ mở rộng và audit.

**Q7. Vì sao HR 900 còn Sales/ACC 300?** HR chỉ chịu link 900 từ Workstations; hai OU Sales/Accounting có thêm link GPO 300 tại cấp con. `gpresult` và registry là bằng chứng kết quả thực tế.

**Q8. Vì sao `gpupdate /force` chưa đủ với khóa phiên?** Chính sách security này có thể cần restart để hiệu lực, và RSoP/registry phải được kiểm lại sau restart; `gpupdate` chỉ yêu cầu client xử lý lại chính sách.

**Q9. Nếu PC Sales bị đưa vào OU HR nhưng user sales01 vẫn ở Sales, điều gì xảy ra?** Lock computer chuyển từ 300 thành 900; restriction Control Panel và drive S: vẫn chịu cấu hình user Sales. Đây là minh họa độc lập Computer/User policy.

**Q10. Mở rộng 200 PC có phải tạo 200 GPO?** Không. Cấu hình theo OU và scope; máy/user mới thêm đúng OU và nhóm sẽ nhận chính sách. Cần quy trình kiểm chứng định kỳ bằng RSoP và kiểm soát các ngoại lệ.

## 15. Tiêu chí bàn giao TV2 cho TV1 và TV3

TV2 bàn giao: `Scripts/*.ps1`, runbook, checklist, tên OU/GPO/group/chính sách, ma trận dự kiến, lỗi cố tình và script hoàn nguyên. TV1 trả lại tất cả ảnh + HTML gpresult + TXT/CSV + video. TV2 rà soát bằng chứng thật trước khi TV3 đưa vào bài báo cáo: phát hiện mâu thuẫn (vd. Sales có S: nhưng tài khoản thực tế là admin) và yêu cầu test lại nếu cần.

**Nguồn chính:** đề giảng viên 2 trang; Microsoft Learn: `Interactive logon: Machine inactivity limit`, `Working with Starter GPOs using GPMC`, `Group Policy preferences`, `New-SmbShare`, `gpresult`.