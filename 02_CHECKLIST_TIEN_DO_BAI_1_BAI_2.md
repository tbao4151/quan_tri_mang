# CHECKLIST ĐÃ LÀM / CHƯA LÀM — BÀI 1 VÀ BÀI 2

**Sinh viên:** Nguyễn Văn Thiên Bảo — 52300179  
**Ngày đối chiếu:** 03/11/2026  
**Nguồn:** Đề Hệ thống 4 bài thực hành, Chương 1–2, TDTU + ảnh thực tế VMware.

Quy ước: [x] đạt theo kết quả ghi nhận; [~] đạt một phần/có khác cấu hình; [ ] chưa hoàn thành hoặc chưa đủ minh chứng. Trạng thái không phải đánh giá điểm số chính thức.

## BÀI 1 — Windows Server Core, DHCP, iSCSI, PXE

| Mức | Nội dung | Kết quả kiểm chứng |
|---|---|---|
| [x] | FIT-DC-02 chạy Windows Server 2019 Core | Hostname, môi trường Server Core hoạt động |
| [~] | Thông số VM theo đề | 2 vCPU, 4 GB RAM và đĩa OS 60 GB NVMe; khác tham chiếu 2 GB RAM/SCSI |
| [x] | Host-only VMnet2 và IP tĩnh | 192.168.1.2/24, gateway 192.168.1.1, DNS 127.0.0.1 |
| [x] | DHCP Server | DHCPServer Running |
| [x] | DHCP Scope PXE-Pool | Active, dải 192.168.1.101 đến 192.168.1.150; Type Both đã cấu hình |
| [x] | iSCSI Target Server | WinTarget Running, TCP 3260 Listen |
| [x] | VHDX 20 GiB | E:\iscsi\winpe.vhdx, 21.474.836.480 byte |
| [x] | Target, Initiator và LUN | Target winpe, đúng IQN, mapping vào LUN 0 |
| [~] | Tạo môi trường WinPE | boot.wim Windows PE x64 có thật; đang bỏ qua wpeinit trong chế độ chẩn đoán |
| [x] | Client iPXE nhận IP | FIT-PXE-TEST đã nhận 192.168.1.103 |
| [x] | Gắn SAN qua iPXE | Registered SAN device 0x80 |
| [~] | Boot mạng vào WinPE | Đã vào X:\windows\system32> từ sanboot; hệ điều hành chưa hoàn tất nhận mạng/ổ |
| [ ] | Nhận ổ iSCSI trong WinPE | diskpart/list disk: There are no fixed disks to show |
| [ ] | Duy trì iSCSI khi sang Windows PE | Server Status=NotConnected, chỉ còn TCP 3260 Listen |
| [ ] | Hoàn tất cài Windows qua SAN | Chưa có bằng chứng, không tuyên bố đã hoàn thành |
| [ ] | Khắc phục wpeinit treo | Chưa xử lý; bước 34 kiểm thử ISO độc lập đang hoãn |

**Kết luận Bài 1:** Đạt phần xây dựng dịch vụ và nạp WinPE qua SAN; **chưa đạt toàn bộ chu trình cài hệ điều hành qua mạng**.

## BÀI 2 — Active Directory, OU, Group, ODJ

| Mức | Nội dung | Kết quả kiểm chứng |
|---|---|---|
| [x] | FIT-DC-01 và IP tĩnh | 192.168.1.2/24, DNS loopback |
| [~] | Phiên bản Server | Dùng Windows Server 2019 Core; bảng mạng ghi 2012 R2, phần chuẩn bị cho phép 2012 R2/2019 |
| [x] | AD DS/DNS | Get-ADDomain: labtdtu.com, LABTDTU; NTDS và DNS Running |
| [x] | OU cấp cao | ChiNhanh_BaoLoc, ChiNhanh_NhaTrang, Khoa_CNTT |
| [x] | OU cấp con | Qualification, Office, Leader bên trong Khoa_CNTT |
| [x] | Năm Global Security Groups | MangMayTinh, KHMayTinh, CNPhanMem, Officer, Leadership |
| [x] | Đủ 23 tài khoản AD | Lệnh đếm trong OU Khoa_CNTT trả Count=23 |
| [x] | Thành viên nhóm đúng số lượng | MangMayTinh=6, KHMayTinh=8, CNPhanMem=6, Officer=3, Leadership=2 |
| [x] | Chồng nhóm Leader | tutu và huypv đồng thời thuộc nhóm chuyên môn và Leadership |
| [x] | Offline Domain Join - Server | djoin /provision thành công, FIT-WIN-01 có AD computer account |
| [x] | Offline Domain Join - Client | djoin /requestODJ thành công khi card mạng đã ngắt |
| [x] | Client thuộc miền | Domain=labtdtu.com, PartOfDomain=True |
| [x] | Xác thực miền | Đăng nhập labtdtu\tutu và Test-ComputerSecureChannel=True |
| [~] | Ảnh MC02 theo mẫu ADUC | Có chứng cứ PowerShell, chưa xác nhận ảnh giao diện ADUC đầy đủ |

**Kết luận Bài 2:** Các chức năng chính đã được kiểm chứng trực tiếp. Bổ sung ảnh minh chứng đúng mẫu nếu giáo viên yêu cầu.

## Trình bày trước với giảng viên

1. Hai máy chủ Bài 1 và Bài 2 cùng IP 192.168.1.2: demo hai pha riêng, không bật cùng lúc.
2. Thành công SAN device 0x80 ở iPXE **không đồng nghĩa** WinPE đã nhận ổ 20 GiB.
3. FIT-PXE-TEST được dùng thêm vì FIT-WIN-01 Windows 10 đã dành cho ODJ.
4. Chưa giải quyết vấn đề WinPE treo khi wpeinit, nên không nói Bài 1 hoàn thiện hoàn toàn.
5. Không đưa metadata C:\odj_blob.txt vào kho GitHub công khai hoặc ảnh chụp.

## Công việc tiếp theo

- [ ] Kiểm thử WinPE boot từ ISO độc lập để phân biệt lỗi NIC driver với lỗi iSCSI handoff.
- [ ] Bảo đảm WinPE nhận mạng và ổ SAN 20 GiB, Target còn session kết nối.
- [ ] Thực hiện cài đặt Windows qua mạng và quay lại toàn bộ.
- [ ] Chuẩn hóa ảnh minh chứng MC01/MC02 theo yêu cầu của giảng viên.

**Giới hạn chứng cứ:** Tất cả nhận định dựa trên các ảnh/lệnh đã ghi lại tới 03/11/2026, không mặc định trạng thái hiện tại của VM không thay đổi.
