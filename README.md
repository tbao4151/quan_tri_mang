# Quản trị hệ thống mạng — Bài 1 và Bài 2

**Sinh viên:** Nguyễn Văn Thiên Bảo — 52300179  
**Đơn vị:** Trường Đại học Tôn Đức Thắng, Khoa Công nghệ Thông tin  
**Chốt bằng chứng:** 03/11/2026

Bộ tài liệu phục vụ demo trực tiếp hai nội dung của đề "Hệ thống 4 bài thực hành":

- [01_HUONG_DAN_DEMO_BAI_1_BAI_2.md](01_HUONG_DAN_DEMO_BAI_1_BAI_2.md): tuần tự các máy ảo, lệnh kiểm chứng an toàn, giải thích kết quả.
- [02_CHECKLIST_TIEN_DO_BAI_1_BAI_2.md](02_CHECKLIST_TIEN_DO_BAI_1_BAI_2.md): đã đạt/chưa đạt, căn cứ và hướng khắc phục.

**Tổng quan:** Bài 1 đã chạy Core, DHCP, iSCSI Target và boot tới WinPE nhưng WinPE chưa nhận được ổ SAN 20 GB; Bài 2 đã kiểm chứng AD DS/DNS, 6 OU, 5 nhóm, 23 tài khoản và Offline Domain Join.

**Lưu ý:** FIT-DC-02 và FIT-DC-01 dùng chung IP 192.168.1.2 nhưng là hai VM cho hai pha thực hành. Phải tắt hẳn server Bài 1 trước khi bật server Bài 2.

Tệp lời thoại cá nhân **không lưu trong repository**. Bản PDF báo cáo và lời thoại được cung cấp riêng trong cuộc trò chuyện. Nội dung cũ được lưu ở nhánh backup-pre-demo-2026-11-03.
