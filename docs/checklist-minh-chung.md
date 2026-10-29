# Checklist minh chứng — Đồ án 07

Đánh dấu hoàn thành sau khi có ảnh/video hoặc kết quả xuất **thực tế**. Trạng thái ban đầu là **CHƯA KIỂM TRA**; bảng này mô tả kỳ vọng chứ không phải kết quả đã nghiệm thu.

## Preflight

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E01 | SERVERA | AD DS DNS domain va IP | 10.0.0.1 fittdtu.com | [ ] |
| E02 | SERVERB | Domain join va IP | 10.0.0.2 fittdtu.com | [ ] |

## OU

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E03 | SERVERA | Cay OU Employees Workstations Groups | 6 OU con va 3 group | [ ] |
| E04 | SERVERA | Member cua 3 security groups | sales01 acc01 hr01 dung group | [ ] |

## GPO

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E05 | SERVERA | P07_Lock_15m settings va link | 900s Workstations | [ ] |
| E06 | SERVERA | P07_Lock_5m settings va 2 links | 300s Sales Accounting | [ ] |
| E07 | PC-SAL-01 | Registry gpresult computer va lock that | 300s va 5phut | [ ] |
| E08 | PC-ACC-01 | Registry gpresult computer va lock that | 300s va 5phut | [ ] |
| E09 | PC-HR-01 | Registry gpresult computer va lock that | 900s va 15phut | [ ] |

## Starter

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E10 | SERVERA | Starter_No_ControlPanel + thiet lap | mau Administrative Templates Enabled | [ ] |
| E11 | SERVERA | GPO tu Starter va 2 links | P07_Restrict_ControlPanel Sales Accounting | [ ] |

## ControlPanel

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E12 | sales01 | Mo Control Panel | Access blocked | [ ] |
| E13 | acc01 | Mo Control Panel | Access blocked | [ ] |
| E14 | hr01 | Mo Control Panel | Allowed | [ ] |

## Share

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E15 | SERVERB | SalesDocs Share va NTFS | Only Sales RW + admin | [ ] |
| E16 | SERVERB | AccountingDocs Share va NTFS | Only Accounting RW + admin | [ ] |

## Drive

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E17 | sales01 | Net use + This PC | S: SalesDocs | [ ] |
| E18 | acc01 | Net use + This PC | A: AccountingDocs | [ ] |
| E19 | hr01 | Net use + This PC | No S: A: | [ ] |

## UNC

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E20 | sales01 | Read and write SalesDocs | Allowed | [ ] |
| E21 | sales01 | Try AccountingDocs | Access denied | [ ] |
| E22 | acc01 | Read and write AccountingDocs | Allowed | [ ] |
| E23 | acc01 | Try SalesDocs | Access denied | [ ] |
| E24 | hr01 | Try SalesDocs | Access denied | [ ] |
| E25 | hr01 | Try AccountingDocs | Access denied | [ ] |

## RSoP

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E26 | PC-SAL-01 | gpresult user + computer HTML | Correct Applied GPOs | [ ] |
| E27 | PC-ACC-01 | gpresult user + computer HTML | Correct Applied GPOs | [ ] |
| E28 | PC-HR-01 | gpresult user + computer HTML | Correct Applied GPOs | [ ] |

## Diagnostic

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E29 | PC-SAL-01 before | Sai OU + gpresult + registry | 900 seconds | [ ] |
| E30 | PC-SAL-01 after | Dung OU + gpresult + registry | 300 seconds | [ ] |

## Video

| ID | Máy/người dùng | Minh chứng cần thu | Kết quả kỳ vọng | Đã kiểm tra |
|---|---|---|---|---|
| E31 | 5 VMs | Video chung minh 5-8 phut | day du cac muc chinh | [ ] |

## Quy tắc lưu minh chứng

- Với mỗi ID, lưu ảnh/HTML/TXT hoặc video có hostname, username và thời điểm tương ứng.
- Ghi cả thử nghiệm thành công và thất bại, đặc biệt quyền chéo qua UNC.
- Không đưa mật khẩu hoặc thông tin nhạy cảm lên repo công khai.
- Bảng theo dõi có thể chỉnh sửa bằng Excel: [checklist-minh-chung.csv](checklist-minh-chung.csv).
