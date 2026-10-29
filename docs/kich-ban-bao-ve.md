# Kịch bản trình bày kỹ thuật – TV2 (khoảng 6–8 phút)

**Mở đầu:** “Đồ án 07 tập trung vào quản trị chính sách theo tổ chức thông qua Active Directory và GPO, đồng thời kiểm soát tài nguyên file server. Hệ thống minh họa gồm một Domain Controller, một File Server và ba client Sales, Accounting, HR. Các chính sách được triển khai trên OU thay vì từng máy, vì vậy có thể nhân rộng lên 200 PC.”

**OU/nhóm:** “Chúng em tách OU Employees chứa user và Workstations chứa computer. Tách biệt này quan trọng vì chính sách khóa phiên áp lên Computer Configuration, còn hạn chế Control Panel và drive mapping là User Configuration. Các quyền file được cấp theo security group để không phải sửa ACL trên từng tài khoản.”

**Khóa phiên:** “Workstations có GPO nền đặt 900 giây. Hai OU con Sales/Accounting có thêm cùng một GPO đặt 300 giây. Theo thứ tự thừa kế GPO thông thường, setting cùng loại ở OU con được ưu tiên, nên hai client tương ứng nhận 300 giây; HR giữ 900 giây. Chúng em kiểm chứng bằng gpresult, registry InactivityTimeoutSecs và thử khóa phiên thực tế.”

**Starter:** “Starter_No_ControlPanel là mẫu chỉ chứa Administrative Templates. Từ mẫu này, chúng em tạo GPO hoạt động P07_Restrict_ControlPanel, rồi link vào hai OU user Sales/Accounting. Điểm cần phân biệt là Starter không được link trực tiếp và không tác động lên người dùng nếu chưa tạo/link GPO thực.”

**File Server:** “SERVERB có hai thư mục chia sẻ SalesDocs và AccountingDocs. Ở Share Permissions, nhóm đúng phòng ban được Change; ở NTFS nhóm đó được Modify. Quyền hành chính và SYSTEM được giữ để vận hành. Phép thử được tiến hành cả trên ổ đã map và đường UNC, bởi không hiện ổ không đồng nghĩa với không có quyền truy cập SMB.”

**Drive mapping:** “Hai GPO loại User Preferences/Drive Maps tự tạo S: và A: cho đúng user OU. HR không được map ổ nào. Trên mỗi máy chúng em dùng net use và This PC đối chiếu, sau đó thử đọc/ghi và thử Access Denied ở thư mục chéo.”

**Chẩn đoán:** “Chúng em mô phỏng một sai sót quản trị: chuyển computer object PC-SAL-01 khỏi Workstations/Sales sang Workstations/HR. Khi áp lại chính sách và khởi động, PC Sales chỉ còn nhận GPO 900 giây; chính sách user Sales vẫn không đổi. Chuyển đúng OU và refresh thì registry/RSoP trở về 300 giây. Tình huống này chứng minh cơ chế link GPO và phân biệt chính sách máy-người dùng.”

**Mở rộng:** “Mở rộng lên 200 máy không có nghĩa tạo 200 GPO. Nhóm xây dựng naming convention và quy trình join domain, move đúng OU, cấp group và kiểm tra gpresult. Số lượng nhân viên thực tế có thể thay đổi mà không phải thiết lập thủ công chính sách trên từng client.”

**Kết luận:** “Bài chỉ được kết luận đạt sau khi đối chiếu ma trận 5–5–15 phút, chặn Control Panel theo user, drive mapping chính xác và thử quyền UNC ở cả ba phòng ban. Mỗi kết luận đều có ảnh và RSoP đi kèm.”

**Lưu ý khi trình bày:** Chỉ đọc câu “đã kiểm chứng” sau khi có kết quả thật; không đọc kết quả kỳ vọng như kết quả đo thực tế. Nếu thiếu test hoặc màn hình không khớp, nói rõ chưa hoàn tất và chạy demo trực tiếp.