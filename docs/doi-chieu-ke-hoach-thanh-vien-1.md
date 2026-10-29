# Đối chiếu kế hoạch thành viên 1 với đề Đồ án 07 và runbook thành viên 2

**Nguồn đối chiếu:** (1) đề giảng viên “Đồ án môn học số 7”, 2 trang; (2) tài liệu 6 trang do thành viên 1 chuyển (“Nhóm tôi có 3 thành viên và tôi là thành viên 1...”); (3) [runbook kỹ thuật thành viên 2](huong-dan-thuc-hanh.md).

**Kết luận:** Kế hoạch TV1 đúng hướng về số lượng VM, nhiệm vụ chụp ảnh và trình tự triển khai. Các mục dưới đây cần sửa **trước khi dựng lab**, không phải bằng chứng rằng hệ thống hiện tại đang sai. Tất cả kết quả trên VM phải được ghi nhận thật.

## I. Yêu cầu sửa trong tài liệu thành viên 1

| Ưu tiên | Trang TV1 | Vấn đề | Sửa thành |
|---|---|---|---|
| Bắt buộc | 1 | Client ghi “Win 10 / 7”, ưu tiên “Win 10 Lite” | Dùng **Windows 10 Pro/Enterprise/Education chính thức**, cùng phiên bản cho cả 3 client. Tránh Windows 7 (chính sách khóa phiên theo đề yêu cầu bắt đầu từ Windows 8) và bản Lite tùy biến. Không dùng Windows 10 Home vì không gia nhập AD domain. |
| Bắt buộc | 5 | Khẳng định GPO 5 phút sai OU sẽ ở trạng thái **Denied / Not Applied** | Khi đối tượng máy **ngoài phạm vi liên kết OU**, GPO 5 phút có thể **không xuất hiện trong RSoP**, không nên mong đợi dòng “Denied”. Chứng minh bằng vị trí OU, danh sách Applied, giá trị 900 và sau khắc phục 300. “Denied” thường có lý do lọc/quyền riêng. |
| Bắt buộc | 3, 5 | Chỉ đề cập `gpupdate /force` khi kiểm tra khóa phiên | Sau cấu hình/di chuyển OU: chạy `gpupdate /force`, **restart client**, đăng nhập lại rồi đọc registry + `gpresult /scope computer /r`. Chính sách security này yêu cầu reboot để bảo đảm hiệu lực. |
| Bắt buộc | 3–4, 6 | Tên GPO có dấu cách khác đề | Chuẩn hóa chính xác: `Starter_No_ControlPanel`, `P07_Restrict_ControlPanel`, `P07_Lock_15m`, `P07_Lock_5m`, `P07_Map_SalesDocs`, `P07_Map_AccountingDocs`. |
| Quan trọng | 1 | DNS SERVERA là `127.0.0.1` | Về mặt kỹ thuật có thể hoạt động nếu DNS service trên DC ổn định; để dễ thống nhất ảnh và kiểm thử, **nên chọn `10.0.0.1`** làm Preferred DNS của SERVERA. Toàn bộ SERVERB/client: `10.0.0.1` và không dùng DNS ngoài. |
| Quan trọng | 1–2 | RAM 1536 MB cho mỗi Windows 10; 5 VM chạy đồng thời; không ghi dung lượng disk | 1536 MB có nguy cơ giật/không ổn định trên Windows 10 đầy đủ. Ưu tiên 2 GB/client khi có thể; để SERVERA+SERVERB chạy và kiểm thử **từng client luân phiên**. Kiểm tra dung lượng SSD và snapshot trước, không chỉ tính tổng RAM. |
| Quan trọng | 2 | Giải thích clone chủ yếu do “trùng SID khiến GPO không áp dụng” | Sysprep /generalize **trước domain join** khi tạo template để loại thông tin định danh hệ thống; không quy tất cả lỗi GPO/domain join cho SID. Không clone VM đã domain-join rồi dùng đồng thời. |
| Quan trọng | 2 | “Snapshot sau Join Domain, rollback tức thì” | Snapshot để phục hồi client/lab, nhưng không rollback **SERVERA (Domain Controller)** tùy tiện khi SERVERB/client tiếp tục hoạt động; cần quản lý nhất quán trạng thái domain. |
| Quan trọng | 3–4 | Ảnh `gpresult /r` không chỉ rõ computer/user và account thực thi | Từ user phòng ban: `gpresult /scope user /r`. Từ CMD **Run as Administrator**: `gpresult /scope computer /r`. Nếu nâng quyền bằng tài khoản admin, **không dùng** kết quả user scope admin để chứng minh GPO của `sales01`. |
| Quan trọng | 4–5 | Chỉ minh chứng hiển thị ổ và thông báo “Access Denied” cố định | Chụp **hai tầng Share & NTFS** của cả hai share; xác minh bằng `whoami`, `net use`, `dir \\SERVERB\SalesDocs`, `dir \\SERVERB\AccountingDocs` và thao tác **ghi thật** bằng tài khoản đúng phòng ban. Thông báo từ chối có thể khác tùy Windows, không ép câu chữ. |
| Quan trọng | 6 | Video 5–8 phút chỉ cho thấy giá trị 300/900 | Đo khóa thực tế: 5 phút Sales/ACC, 15 phút HR; lưu bản gốc hoặc mốc thời gian đủ kiểm chứng, sau đó biên tập **minh bạch** vào video 5–8 phút. Kiểm soát screen saver/display timeout để tránh khóa sớm. |
| Bổ sung | 3–6 | Thiếu minh chứng kế hoạch mở rộng 200 PC | Thêm bảng quy tắc tên PC/user, OU đích, group đích, thao tác join domain → chuyển OU → kiểm thử; không cần tạo đủ 200 đối tượng. |
| Bổ sung | 3–6 | Chưa liệt kê rõ Group Policy Results từ SERVERA | Xuất `gpresult` HTML trên **3 client**, chạy **Group Policy Results Wizard** trên SERVERA ít nhất 1 case đại diện, ưu tiên cả 3. |
| Bổ sung | 3–6 | Chưa chứng minh Starter GPO là nguồn của GPO hoạt động | Chụp **ngay bước New GPO from Starter GPO** và trang Settings của cả Starter/GPO hoạt động; chỉ giống cấu hình không đủ chứng minh nguồn. |
| Bổ sung | 3–6 | Chưa có file log trạng thái test | Mỗi minh chứng gắn ID, máy, username, trước/sau, ảnh/HTML, kết quả thực tế PASS/FAIL; dùng [checklist Markdown](checklist-minh-chung.md). |

## II. Ma trận nghiệm thu: chốt chung cho TV1–TV2–TV3

| Client / tài khoản | Machine inactivity | Control Panel | GPP Drive Maps | SalesDocs UNC | AccountingDocs UNC |
|---|---:|---|---|---|---|
| PC-SAL-01 / sales01 | 300s | Chặn | S: | Đọc + ghi | Từ chối |
| PC-ACC-01 / acc01 | 300s | Chặn | A: | Từ chối | Đọc + ghi |
| PC-HR-01 / hr01 | 900s | Cho phép | Không có S:/A: | Từ chối | Từ chối |

**Không nhầm 2 phạm vi:** inactivity policy = **Computer Configuration** theo OU **Workstations**; Control Panel + Drive Maps = **User Configuration** theo OU **Employees**. Chuyển riêng computer object PC-SAL-01 sang Workstations/HR sẽ đổi 300 → 900, nhưng *user* sales01 vẫn bị chặn Control Panel và nhận S:.

## III. Bổ sung checklist cấu hình hạ tầng cho TV1

```text
[ ] 5 VM đúng hostname và IP, tất cả cùng LAN_DoAn07
[ ] SERVERA 10.0.0.1/24, DNS nội bộ hoạt động, domain fittdtu.com
[ ] SERVERB 10.0.0.2/24, domain member, DNS 10.0.0.1
[ ] PC-SAL-01 / PC-ACC-01 / PC-HR-01: Windows 10 Pro chính thức
[ ] Mỗi client dùng IP 10.0.0.11/.12/.13 /24 và DNS 10.0.0.1
[ ] ipconfig /all; nslookup fittdtu.com 10.0.0.1
[ ] nltest /dsgetdc:fittdtu.com; Test-ComputerSecureChannel
[ ] Đồng bộ đồng hồ; w32tm /query /status (tránh lỗi Kerberos do lệch giờ)
[ ] Snapshot an toàn, đủ dung lượng ổ; không rollback DC riêng lẻ tùy tiện
[ ] Quay/chụp thể hiện hostname + whoami + nội dung cấu hình, che thông tin nhạy cảm
```

## IV. Cập nhật đối với thành viên 2

1. **Không chạy script cấu hình GPO khung thay phần Starter GPO bằng registry:** phải tạo Starter trong GPMC và dùng “New GPO from Starter GPO”.
2. **Kiểm soát Share/NTFS:** script SERVERB không được coi là phép chứng minh quyền đã đúng nếu thư mục/share có sẵn ACL thừa. Kiểm tra kết quả `Get-SmbShareAccess` và `icacls` **thật**; nếu có `Everyone`, `Authenticated Users` hay nhóm khác được phép đọc trên đường dữ liệu phải xử lý trước nghiệm thu.
3. **Không diễn giải RSoP sai:** GPO ngoài link scope có thể không hiện trong `Denied GPOs`; so sánh **Applied + OU + registry + thực nghiệm**.
4. **Không lấy screenshot thông báo popup làm tiêu chí duy nhất:** quyền bị chặn phải thử UNC và ghi tệp thật.
5. **Thứ tự công việc:** TV1 xác nhận hạ tầng → TV2 hướng dẫn SERVERA → cấu hình GPO và Starter → SERVERB share → map drive → ba client → lỗi sai OU → quay video, thu ảnh → TV3 viết báo cáo.
6. **Review evidence:** TV2 chỉ duyệt ảnh khi biết máy, user, ngày giờ, cài đặt GPO nào đã áp, giá trị hiệu lực; không đánh dấu hoàn thành chỉ dựa trên script chạy không báo lỗi.

## V. Bố cục video 5–8 phút được khuyến nghị

- 0:00–0:45: mạng và 5 VM, domain, AD.
- 0:45–1:35: OU, group, GPO links.
- 1:35–2:45: 900/300 + registry/RSOP và **đo khóa thực tế tua minh bạch**.
- 2:45–3:35: Starter GPO → GPO hoạt động, Sales/ACC blocked và HR allowed.
- 3:35–5:15: hai share, Share/NTFS ACL, map S:/A:, sửa file, kiểm tra quyền chéo bằng UNC.
- 5:15–6:35: lỗi cố tình PC-SAL-01 sai OU → 900 → sửa → 300.
- 6:35–7:30: cách mở rộng lên 200 PC; tổng kết.

## Tài liệu Microsoft đối chiếu

- [Interactive logon: Machine inactivity limit](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/interactive-logon-machine-inactivity-limit)
- [Policy settings — Windows Server 2012 R2](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/jj966265(v=ws.11))
- [Sysprep for duplicated Windows installations](https://learn.microsoft.com/en-gb/troubleshoot/windows-server/setup-upgrade-and-drivers/windows-installations-disk-duplication)
- [Group Policy processing](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/group-policy/group-policy-processing)
- [Group Policy Preferences / Drive Maps](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/group-policy/group-policy-preferences)
