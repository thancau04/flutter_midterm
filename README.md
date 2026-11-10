# flutter_midterm – Quản lý người dùng (Admin) với Firebase Cloud Firestore

Bài thi Giữa kỳ môn **Lập trình đa nền tảng** – Flutter (Web + Android).

## Chức năng
- Đăng nhập Admin (truy vấn `email` + `matkhau` trên Firestore), Đăng xuất
- Thêm / Hiển thị realtime / Sửa / Xóa người dùng
- Tìm kiếm theo họ tên hoặc email
- Chọn ảnh từ thiết bị (`image_picker`) → mã hóa Base64 lưu vào `hinhanh` (hỗ trợ cả URL ảnh)
- Xuất toàn bộ CSDL ra `users.json`

## Cơ sở dữ liệu
Collection `users`, mỗi document chỉ gồm đúng 4 trường: `email`, `matkhau`, `hoten`, `hinhanh`.

## Cấu trúc `lib/`
| File | Vai trò |
|---|---|
| `main.dart` | Khởi tạo Firebase, chạy ứng dụng |
| `firebase_options.dart` | Cấu hình sinh bởi `flutterfire configure` |
| `user_model.dart` | Model `UserModel` + widget `UserAvatar` |
| `user_service.dart` | CRUD / Login / Export JSON với Firestore |
| `login_page.dart` | Màn hình đăng nhập |
| `user_list_page.dart` | Danh sách, tìm kiếm, xóa, xuất JSON |
| `user_form_page.dart` | Form thêm / sửa + chọn ảnh |

## Chạy dự án
```bash
flutter pub get
flutter run -d chrome        # Web
flutter run -d <android-id>  # Android
```

Tài khoản mặc định khi CSDL trống: `admin@gmail.com` / `123456`.

Báo cáo chi tiết: [BAO_CAO_GIUA_KY.md](BAO_CAO_GIUA_KY.md)
