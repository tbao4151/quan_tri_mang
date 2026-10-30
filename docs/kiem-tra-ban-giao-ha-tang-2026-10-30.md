# P07 — Kiểm tra biên bản bàn giao hạ tầng của thành viên 1 (30/10/2026)

> **Trạng thái:** **Tiếp nhận có điều kiện** để bắt đầu kiểm chứng. Biên bản mô tả hạ tầng, **không phải** log kiểm thử và không có ảnh lệnh / screenshot gốc kèm theo. Không được dùng nội dung biên bản thay cho bằng chứng thực nghiệm.
>
> **BẢO MẬT:** Biên bản nguồn có mật khẩu quản trị domain và DSRM ở dạng plaintext. **Tuyệt đối không commit bản gốc**, không đưa mật khẩu vào issue/commit/screenshot/video. Đổi cả hai mật khẩu và lưu qua kênh riêng. Tài liệu này **không** sao chép credential.

## A. Những gì được bàn giao (theo tự khai báo của TV1)

| VM | Hệ điều hành | IP / subnet | DNS | Vai trò |
|---|---|---|---|---|
| SERVERA | Windows Server 2012 R2 | 10.0.0.1/24 | 127.0.0.1 | DC, AD DS, DNS |
| SERVERB | Windows Server 2012 R2 | 10.0.0.2/24 | 10.0.0.1 | Domain member, dự kiến File Server |
| PC-SAL-01 | Windows 10 (edition chưa rõ) | 10.0.0.11/24 | 10.0.0.1 | Sales |
| PC-ACC-01 | Windows 10 (edition chưa rõ) | 10.0.0.12/24 | 10.0.0.1 | Accounting |
| PC-HR-01 | Windows 10 (edition chưa rõ) | 10.0.0.13/24 | 10.0.0.1 | HR |

- Mạng VMware: `LAN_DoAn07`; domain FQDN: `fittdtu.com`; **NetBIOS được TV1 khai báo là `FITTDTI`** (cần xác thực bằng AD thực tế).
- TV1 khai báo 4 member đã join domain, client từ Sysprep template, VMware Tools hoạt động, và 5 snapshot tên `01_Domain_Joined_OK`.
- **Chưa xác thực độc lập:** IP thực tế, Windows edition, DNS SRV/domain discovery, secure channel, AD computer objects, NetBIOSName, đồng bộ thời gian, tính nguyên vẹn snapshot.
- **Chưa có căn cứ xác nhận:** OU người dùng/máy, GG_*, GPO, Starter GPO, SMB share, NTFS, Drive Maps, RSoP, thử khóa 5/15 phút. Các phần này mới là nhiệm vụ TV2 bàn giao lại cho TV1 chạy.

## B. Vấn đề và quyết định kỹ thuật

### B1. P0 — Bảo mật credential

1. Đổi mật khẩu Domain Administrator (GUI ADUC hoặc cmdlet AD có nhập SecureString; không truyền mật khẩu dưới dạng chuỗi literal).
2. Trên SERVERA, đổi mật khẩu DSRM bằng `ntdsutil` → `set dsrm password` → `reset password on server null`; nhập mật khẩu mới theo prompt, `quit` hai lần.
3. Không dùng mật khẩu được ghi trong biên bản cũ nữa. Nếu từng đẩy credential lên repo/public, cần rà lịch sử commit và xử lý việc lộ bí mật, không chỉ xóa ở commit mới.

### B2. P1 — Default gateway sai vai trò

TV1 đang khai báo gateway `10.0.0.1` trên SERVERB và 3 client, trong khi SERVERA chỉ đảm nhiệm AD DS/DNS và không cấu hình như router. Ở cùng subnet 10.0.0.0/24, các máy vẫn liên lạc trực tiếp; gateway này không cần cho bài lab. **Khuyến nghị để trống gateway trên 5 VM** (trừ khi có nhu cầu định tuyến được thiết kế riêng). Không xem đây là lỗi làm hỏng domain join vốn đã kiểm thử.

### B3. P1 — DNS SERVERA và NetBIOS

`127.0.0.1` trên SERVERA có thể hợp lệ nếu DNS service local hoạt động; khuyến nghị đặt Preferred DNS `10.0.0.1` cho dễ kiểm tra nhất quán. Không đổi cả hai đồng thời trước khi thu bằng chứng baseline.

**Không suy đoán NetBIOS** từ tên FQDN. Trên SERVERA kiểm tra:

```powershell
Get-ADDomain | Select-Object DNSRoot,NetBIOSName,DistinguishedName
```

Tên NetBIOS khác tên FQDN **không tự nó là lỗi**; chỉ phải dùng tên thực tế khi nhập `DOMAIN\user`, tên group trong ACL.

### B4. P1 — Windows edition và mô hình clone

Trên ba client:

```powershell
(Get-WmiObject Win32_OperatingSystem).Caption
(Get-WmiObject Win32_ComputerSystem) | Select-Object Name,Domain,PartOfDomain
```

Dùng Windows 10 Pro/Enterprise/Education chính thức; không Windows Home/Lite/7. Sysprep/Linked Clone trong biên bản là **khai báo của TV1**, không thay cho việc xác minh mỗi client có hostname và AD secure channel độc lập.

### B5. P1 — Quy ước tên giữa hai thành viên

| Nội dung | TV1 đề xuất trong phần “nhiệm vụ tiếp theo” | **Chốt dùng theo repo TV2** |
|---|---|---|
| Users | `user_sales`, `user_acc`, `user_hr` | `sales01`, `acc01`, `hr01` |
| Thư mục SERVERB | `C:\Shares\...` | `C:\DeptShares\...` |
| Starter | `Starter_No_Control Panel` | `Starter_No_ControlPanel` |
| GPO chặn | `P07_Restrict_Control Panel` | `P07_Restrict_ControlPanel` |

**Chưa chạy** script 01/02 nếu OU, account, group, folder hoặc share đã tồn tại khác quy ước: kiểm kê trước và thống nhất điều chỉnh. Trong biên bản, các đối tượng trên được liệt kê là **cần thực hiện tiếp**, không phải đã tạo.

### B6. P1 — Khôi phục snapshot DC không phải thao tác “revert tức thì”

Snapshot `01_Domain_Joined_OK` rất có ích trong lab, nhưng không được xem là backup AD DS thay thế. Tránh hoàn nguyên riêng SERVERA khi các domain member/client đã cập nhật và thay đổi SID/mật khẩu quan hệ domain; nếu buộc phục hồi, lập phương án nhất quán cả lab và kiểm tra lại secure channel, DNS, OU, GPO.

### B7. P2 — Hai chỗ giải thích GPO cần sửa khi bảo vệ

- Mức **900 ở Workstations**, mức **300 ở Workstations/Sales và /Accounting**. OU con được xử lý sau trong điều kiện liên kết bình thường, **nếu GPO 900 được Enforced ở OU cha thì có thể chặn override**. **Block Inheritance ở OU con** sẽ ngăn chính sách 900 kế thừa (không có nghĩa cấp cha thắng). Không bật Enforced/Block Inheritance trong lab nếu đề không yêu cầu.
- Máy PC-SAL-01 sai OU cha nhận 900 thay vì 300: chính sách 5 phút nằm ngoài scope có thể **không xuất hiện** trong danh sách Denied; dùng OU + Applied + registry 900/300 + thử nghiệm để chứng minh.

## C. Lệnh preflight cần TV1 chạy và gửi lại TV2

**Chưa thay đổi bất cứ cấu hình nào.** Có thể dùng [script kiểm tra đọc-only 00](../scripts/00_Preflight_5VM.ps1) trên **cả 5 máy** và gửi đủ 5 file TXT. Không gửi credential.

### C1. Trên SERVERA (PowerShell chạy quyền admin)

```powershell
Get-ADDomain | Select-Object DNSRoot,NetBIOSName,DistinguishedName
Get-Service DNS,NTDS
Resolve-DnsName fittdtu.com -Server 10.0.0.1
Get-ADComputer -Filter * | Where-Object Name -in @('SERVERB','PC-SAL-01','PC-ACC-01','PC-HR-01') |
    Select-Object Name,DistinguishedName,Enabled
```

### C2. Trên SERVERB và 3 client (PowerShell)

```powershell
hostname
ipconfig /all
nltest /dsgetdc:fittdtu.com
Test-ComputerSecureChannel
w32tm /query /status
```

**Kỳ vọng:** hostname/IP/DNS khớp bảng, `nltest` tìm được SERVERA, `Test-ComputerSecureChannel` trả về **True**; đặc biệt không chạy `Test-ComputerSecureChannel` trên chính Domain Controller vì đó không phải phép thử phù hợp cho DC.

### C3. Tài liệu minh chứng tối thiểu

- 5 file `P07_Preflight_<HOSTNAME>.txt` và ảnh VMware thể hiện LAN Segment từng VM.
- SERVERA: output AD domain NetBIOS, 4 computer object đã join.
- Ba client: Windows edition cụ thể, 3 secure channels True và thời gian máy không chênh lệch đáng kể.
- Ảnh danh sách snapshot và khoảng dung lượng SSD còn trống.
- Bảng ghi nhận từng hạng mục **PASS/FAIL/chưa kiểm tra**.

## D. Điều kiện chuyển sang triển khai TV2

Chỉ tiếp tục [runbook kỹ thuật](huong-dan-thuc-hanh.md) khi xác minh được:

- [ ] Không còn phát tán mật khẩu cũ, mật khẩu admin và DSRM đã được đổi.
- [ ] AD DS + DNS SERVERA hoạt động; `Get-ADDomain` khớp `fittdtu.com`.
- [ ] NetBIOSName thực tế được xác định và TV2 biết để cấp quyền SMB.
- [ ] 4 member secure channel OK; máy đúng hostname, cùng subnet/DNS.
- [ ] Ba client có edition phù hợp; có quyền đăng nhập domain.
- [ ] Đã thống nhất tài khoản `sales01/acc01/hr01`, thư mục `C:\DeptShares`, tên GPO chính xác.

**Bước sau đó:** trên SERVERA chạy `01_SERVERA_AD_OU_Groups_GPO.ps1`, thiết lập GPO và Starter qua GPMC, trên SERVERB chạy `02_SERVERB_File_Shares.ps1`, sau đó kiểm chứng ba client theo checklist.

### Tài liệu Microsoft

- [PowerShell expandable strings: variable before `:`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_quoting_rules)
- [AD DS virtualization and snapshot safeguards](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/virtualized-domain-controller-architecture)
- [Interactive logon: Machine inactivity limit](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/interactive-logon-machine-inactivity-limit)
- [Group Policy processing](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/group-policy/group-policy-processing)
- [Reset DSRM administrator password](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/reset-directory-services-restore-mode-admin-pwd)
