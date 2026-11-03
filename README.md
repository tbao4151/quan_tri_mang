# TDTU — Đồ án 07: Quản trị tập trung bằng GPO, Starter GPO và phân quyền tệp

Kho tài liệu triển khai kỹ thuật cho môn **Quản trị hệ thống mạng** (Tôn Đức Thắng University), tập trung vào công việc của **thành viên 2**: thiết kế và cung cấp thao tác/lệnh để thành viên 1 chạy lab, kiểm thử, thu thập bằng chứng và trình bày trước giảng viên.

> **Trạng thái:** Runbook và script tham khảo, **chưa được chạy/kiểm chứng trên 5 máy ảo thực tế**. Chỉ dùng trong lab VMware LAN Segment cô lập; không yêu cầu hardening ngoài rubric. Script 01 dùng mật khẩu demo cố định cho 3 tài khoản user thường.

## Bắt đầu từ đâu?

**DÀNH CHO THÀNH VIÊN 1: [MỞ HƯỚNG DẪN THỰC THI TỪ ĐẦU ĐẾN CUỐI](docs/ban-giao-thuc-thi-thanh-vien-1.md)** — đã đồng bộ với biên bản giao 5 VM; tập trung thao tác copy-paste và các ảnh cần chụp.

**Bộ tài khoản kiểm thử:** `user_sales`, `user_acc`, `user_hr`; mật khẩu ba user thường do script 01 tạo là `P07Lab@2026!`. NetBIOS TV1 báo là `FITTDTI` (xác nhận trên SERVERA), data path `C:\Shares`.

**[Biên bản tiếp nhận hạ tầng 30/10/2026](docs/kiem-tra-ban-giao-ha-tang-2026-10-30.md)** — mô tả thông số 5 VM và điều kiện kỹ thuật; [script 00 — kiểm tra 5 VM](scripts/00_Preflight_5VM.ps1) chỉ đọc và xuất log để làm minh chứng.

**[Đánh giá kế hoạch TV1 (bản lưu)](docs/doi-chieu-ke-hoach-thanh-vien-1.md)** — phân tích từ giai đoạn trước khi TV1 bàn giao; tên người dùng và đường dẫn chuẩn đã được chốt trong tài liệu thực thi mới.


1. **[Hướng dẫn triển khai từ A–Z](docs/huong-dan-thuc-hanh.md)** — thứ tự thao tác trên SERVERA, SERVERB, ba client; thiết lập GPO trong GPMC; kiểm thử, chẩn đoán và mở rộng lên 200 PC.
2. **[Checklist minh chứng](docs/checklist-minh-chung.md)** — các màn hình và kết quả cần chụp/quay để chuyển cho thành viên 3. Có [bản CSV](docs/checklist-minh-chung.csv) để theo dõi.
3. **[Kịch bản bảo vệ — thành viên 2](docs/kich-ban-bao-ve.md)** — lời trình bày kỹ thuật, thứ tự demo và cách giải thích kết quả.
4. **[Các script PowerShell](scripts/)** — chỉ chạy trên máy và bằng tài khoản đúng theo tiêu đề/hướng dẫn.

## Kiến trúc đề bài

| Máy | Vai trò | Địa chỉ mạng |
|---|---|---|
| SERVERA | Windows Server 2012 R2, AD DS, DNS, quản trị GPO, domain `fittdtu.com` | `10.0.0.1/24` |
| SERVERB | Domain member, file server SMB | `10.0.0.2/24` |
| PC-SAL-01 | Client Sales, user `user_sales` | IP LAN ảo |
| PC-ACC-01 | Client Accounting, user `user_acc` | IP LAN ảo |
| PC-HR-01 | Client HR, user `user_hr` | IP LAN ảo |

### Ma trận nghiệm thu

| Kiểm thử | Sales | Accounting | HR |
|---|---|---|---|
| Machine inactivity limit | 300 giây | 300 giây | 900 giây |
| Control Panel | Bị chặn | Bị chặn | Được phép |
| Drive Map | S: → SalesDocs | A: → AccountingDocs | Không có S:/A: |
| Quyền SalesDocs | Đọc/ghi | Từ chối | Từ chối |
| Quyền AccountingDocs | Từ chối | Đọc/ghi | Từ chối |

**Lưu ý:** GPO khóa phiên nằm ở **Computer Configuration** và áp qua OU `Workstations`. Control Panel và Drive Maps nằm ở **User Configuration** và áp qua OU `Employees`. Starter GPO chỉ là mẫu, phải tạo GPO hoạt động từ mẫu rồi mới liên kết OU.

## Thứ tự thực hiện

1. Trên 5 VM chạy [00 — kiểm tra preflight (read-only)](scripts/00_Preflight_5VM.ps1), xác minh DNS/domain/secure channel và lưu log; hạ tầng đã join domain nên không dựng lại.
2. Chạy [01 — SERVERA: OU/group/user/GPO khung](scripts/01_SERVERA_AD_OU_Groups_GPO.ps1).
3. Trong GPMC cấu hình `P07_Lock_15m`, `P07_Lock_5m`, `Starter_No_ControlPanel` → `P07_Restrict_ControlPanel`.
4. Chạy [02 — SERVERB: NTFS và SMB share](scripts/02_SERVERB_File_Shares.ps1).
5. Trong GPMC cấu hình `P07_Map_SalesDocs` và `P07_Map_AccountingDocs`.
6. Trên 3 client chạy [03 — Thu thập bằng chứng](scripts/03_CLIENT_Evidence.ps1) và kiểm thử thực tế.
7. Trên SERVERA chạy [04 — Xuất cấu hình](scripts/04_SERVERA_Export_Config.ps1).
8. Mô phỏng lỗi PC-SAL-01 sai OU, thu thập `gpresult` trước/sau và hoàn nguyên.
9. Đối chiếu checklist trước khi bàn giao ảnh, video và HTML/CSV cho thành viên 3.

## Phân chia công việc

- **Thành viên 1:** vận hành 5 VM, chạy lệnh, chụp màn hình, ghi hình và lưu log thật.
- **Thành viên 2:** chịu trách nhiệm logic GPO, lệnh, phân quyền, đọc `gpresult`, xử lý lỗi, trình bày.
- **Thành viên 3:** viết báo cáo PDF, tổng hợp minh chứng và làm slide.

**Nguồn yêu cầu:** PDF “Đồ án môn học số 7 — Quản trị tập trung bằng GPO, Starter GPO và phân quyền tệp” (2 trang) do giảng viên cung cấp. Tài liệu trong repo triển khai dựa trên đề và biên bản TV1; tên user và thư mục đã đồng bộ trên các script.
