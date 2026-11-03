# RUNBOOK DEMO — BÀI 1 → BÀI 2

Sinh viên: **Nguyễn Văn Thiên Bảo — 52300179**. Ngày: **03/11/2026**.

Đây là **lệnh kiểm chứng trạng thái đã triển khai**, không phải lệnh cài lại. Không chạy lệnh format/delete, không reset VHDX, không tạo lại Domain và không ghi nội dung odj_blob.txt ra màn hình.

## 0. Thứ tự VM và lưu ý quan trọng

1. DEMO BÀI 1: chỉ mở FIT-DC-02 (192.168.1.2) và FIT-PXE-TEST.
2. Tắt FIT-PXE-TEST và **Power Off hẳn FIT-DC-02**.
3. DEMO BÀI 2: mở FIT-DC-01 (192.168.1.2), sau khi AD DS/DNS sẵn sàng mới mở FIT-WIN-01 (192.168.1.10).
4. **Không bật đồng thời FIT-DC-02 và FIT-DC-01** trên VMnet2 do trùng IP.

## 1. BÀI 1 — FIT-DC-02 — Windows PowerShell Administrator

### 1.1. Server Core, hostname, IP

    hostname
    ipconfig /all
    Get-NetIPConfiguration

Kỳ vọng theo ảnh: FIT-DC-02; IP 192.168.1.2/24; gateway danh định 192.168.1.1, DNS 127.0.0.1. RAM thực tế 4 GB thay 2 GB; đĩa hệ điều hành NVMe 60 GB thay SCSI trong đề.

### 1.2. DHCP và phạm vi PXE-Pool

    Get-WindowsFeature DHCP,FS-iSCSITarget-Server | Format-Table Name,InstallState
    Get-Service DHCPServer,WinTarget | Format-Table Name,Status
    Get-DhcpServerv4Scope | Format-Table ScopeId,Name,StartRange,EndRange,State

Kết quả đã chứng minh: DHCPServer Running; Scope PXE-Pool 192.168.1.101 tới 192.168.1.150, Active. DHCP scope đã đặt -Type Both để hỗ trợ DHCP/BOOTP.

### 1.3. iSCSI Target Server và VHDX 20 GiB

    Get-Volume -DriveLetter E | Format-Table DriveLetter,FileSystem,HealthStatus,Size
    Get-IscsiVirtualDisk | Format-List Path,Size,Status
    Get-IscsiServerTarget -TargetName 'winpe' | Format-List TargetName,TargetIqn,InitiatorIds,Status,LunMappings
    Get-NetTCPConnection -LocalPort 3260 -ErrorAction SilentlyContinue | Format-Table LocalAddress,LocalPort,RemoteAddress,State

Kết quả đã chứng minh: E:\iscsi\winpe.vhdx = 21474836480 byte (20 GiB), ánh xạ LUN 0, Target winpe, Initiator iqn.1991-05.com.microsoft:winpe, WinTarget Running, TCP 3260 Listen.

Target IQN chính xác: iqn.1991-05.com.microsoft:fit-dc-02-winpe-target

**Không diễn giải NotConnected là thành công:** khi Client đã vào WinPE, Server cho NotConnected, không có TCP established từ Client.

### 1.4. File WinPE

    Test-Path 'E:\WinPETransfer\sources\boot.wim'
    dism /Get-WimInfo /WimFile:"E:\WinPETransfer\sources\boot.wim"

Ảnh thực nghiệm cho thấy Microsoft Windows PE (x64), Index 1. startnet.cmd đang ở chế độ chẩn đoán bỏ qua wpeinit để không bị treo. Đó không phải bản cấu hình cuối.

## 2. BÀI 1 — FIT-PXE-TEST — máy chưa có hệ điều hành

### 2.1. Nếu hiện tại đã ở WinPE X:\windows\system32>

    ver
    echo WINPE_OK
    diskpart
    list disk
    exit

WinPE đã nạp được, nhưng kết quả trước đó: There are no fixed disks to show. **Chưa đạt** yêu cầu Windows PE nhìn thấy ổ iSCSI và dùng ổ để cài hệ điều hành.

### 2.2. Chỉ khởi động iPXE lại nếu giảng viên yêu cầu

Tại dấu nhắc iPXE>, nhập theo thứ tự:

    dhcp
    show net0/ip
    set initiator-iqn iqn.1991-05.com.microsoft:winpe
    sanhook iscsi:192.168.1.2::::iqn.1991-05.com.microsoft:fit-dc-02-winpe-target
    sanboot --drive 0x80

Kết quả đã từng xác minh: Registered SAN device 0x80, sau đó vào WinPE. Cẩn thận đúng chữ **fit**, không phải **fir**; đúng lệnh sanboot. Nếu máy đang ở WinPE thì ưu tiên dùng kết quả có sẵn, tránh gây treo làm mất buổi demo.

## 3. CHUYỂN SANG BÀI 2

Tắt FIT-PXE-TEST, **Power Off FIT-DC-02**, sau đó khởi động FIT-DC-01 và FIT-WIN-01. Máy Windows 10 có card mạng VMnet2 192.168.1.10/24, DNS 192.168.1.2. Nếu có thêm NAT, kiểm tra DNS của card miền.

## 4. BÀI 2 — FIT-DC-01 — Windows PowerShell Administrator

### 4.1. AD DS, Domain và DNS

    hostname
    ipconfig /all
    Get-ADDomain | Select-Object DNSRoot,NetBIOSName
    Get-Service NTDS,DNS | Format-Table Name,Status
    Resolve-DnsName labtdtu.com -Server 192.168.1.2

Đã xác nhận: Domain labtdtu.com; NetBIOS LABTDTU; NTDS/DNS Running. Server thực tế Windows Server 2019 Core; bảng mạng đề ghi 2012 R2 nhưng phần chuẩn bị cho phép 2012 R2/2019.

### 4.2. Sáu OU

    Import-Module ActiveDirectory
    Get-ADOrganizationalUnit -Filter * -SearchBase 'DC=labtdtu,DC=com' |
      Where-Object { $_.Name -in @('ChiNhanh_BaoLoc','ChiNhanh_NhaTrang','Khoa_CNTT','Qualification','Office','Leader') } |
      Select-Object Name,DistinguishedName | Format-Table -AutoSize

Đã tạo 3 OU cấp trên (ChiNhanh_BaoLoc, ChiNhanh_NhaTrang, Khoa_CNTT) và 3 OU con trong Khoa_CNTT (Qualification, Office, Leader).

### 4.3. Năm nhóm bảo mật Global/Security

    $groups = @('MangMayTinh','KHMayTinh','CNPhanMem','Officer','Leadership')
    $groups | ForEach-Object {
      Get-ADGroup -Identity $_ -Properties GroupCategory,GroupScope |
        Select-Object Name,GroupCategory,GroupScope
    } | Format-Table -AutoSize

Đã xác minh: tất cả là Security/Global.

### 4.4. 23 người dùng và số lượng thành viên nhóm

    $faculty = 'OU=Khoa_CNTT,DC=labtdtu,DC=com'
    (Get-ADUser -Filter * -SearchBase $faculty | Measure-Object).Count
    $groups | ForEach-Object {
      [pscustomobject]@{ Group=$_; Members=@(Get-ADGroupMember -Identity $_).Count }
    } | Format-Table -AutoSize
    Get-ADGroupMember -Identity 'Leadership' | Select-Object Name,SamAccountName

Số đã chứng minh: **23 tài khoản**; MangMayTinh=6, KHMayTinh=8, CNPhanMem=6, Officer=3, Leadership=2. tutu và huypv xuất hiện thêm trong Leadership nên tổng lượt thành viên nhóm là 25, không phải 25 tài khoản.

### 4.5. Provision máy Client

    Get-ADComputer -Identity 'FIT-WIN-01' | Select-Object Name,Enabled,DistinguishedName

Đã chạy thành công trên server:

    djoin.exe /provision /domain labtdtu.com /machine FIT-WIN-01 /savefile C:\odj_blob.txt

Không chạy lại provisioning để demo; chỉ dùng lệnh Get-ADComputer và hình kết quả đã ghi. **Không đọc, chụp, in nội dung C:\odj_blob.txt**.

## 5. BÀI 2 — FIT-WIN-01

Mở PowerShell, dùng Administrator nếu cần:

    hostname
    whoami
    Get-CimInstance Win32_ComputerSystem | Select-Object Name,Domain,PartOfDomain
    Test-ComputerSecureChannel -Verbose
    Resolve-DnsName labtdtu.com -Server 192.168.1.2

Bằng chứng thực tế: máy FIT-WIN-01, tài khoản labtdtu\tutu, PartOfDomain=True, Domain=labtdtu.com, Test-ComputerSecureChannel=True. ODJ trên Client đã chạy với card mạng ngắt:

    djoin.exe /requestODJ /loadfile C:\odj_blob.txt /windowspath C:\Windows /localos

Sau đó reboot, nối lại VMnet2 và đăng nhập miền. Đó là chuỗi minh chứng Offline Domain Join.

## 6. Phát biểu kết luận đúng trạng thái

- **Bài 1**: Core/DHCP/iSCSI Target hoạt động; iPXE gắn được SAN 0x80 và WinPE nạp thành công; **chưa hoàn tất** việc WinPE nhận ổ SAN 20 GiB và cài Windows qua mạng.
- **Bài 2**: Domain, DNS, OU, Groups, 23 users và Offline Domain Join đã kiểm chứng; còn cần chọn ảnh minh chứng bố cục ADUC nếu thầy yêu cầu theo mẫu.
- Nội dung checklist chi tiết nằm trong 02_CHECKLIST_TIEN_DO_BAI_1_BAI_2.md.

Nguồn: Đề Quản trị hệ thống mạng TDTU — Hệ thống 4 bài thực hành, Chương 1–2; ảnh thực nghiệm ngày 02–03/11/2026.
