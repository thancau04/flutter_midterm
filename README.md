# flutter_midterm – Quản lý người dùng (Admin) với Firebase Cloud Firestore

Bài thi Giữa kỳ môn **Lập trình đa nền tảng** – Flutter (Web + Android).

## Thông tin sinh viên
| Thông tin | Nội dung |
|---|---|
| Họ và tên | Đặng Thần Cầu |
| Mã sinh viên | 23IT025 |
| Source code | https://github.com/thancau04/flutter_midterm |
| Video demo | https://drive.google.com/file/d/1V5DMrV2_EJc9Vy96Jeypv4UCwUIbS-M6/view?usp=sharing |
| File CSDL `users.json` | https://drive.google.com/file/d/1Uff9WJr68g38CV_UMdoNVJY34jYXTwZa/view?usp=sharing |
| Báo cáo chi tiết | `[Dán link Google Drive báo cáo tại đây]` |

## Môi trường phát triển
| Thành phần | Phiên bản / Thông tin |
|---|---|
| Flutter SDK / Dart SDK | Dart v3.13.7 |
| IDE | Visual Studio Code |
| Nền tảng Web | Trình duyệt Brave |
| Nền tảng Mobile | Điện thoại Android thật (device id: `2510DRK44C`) |
| Cơ sở dữ liệu | Firebase Cloud Firestore (Project ID: `midterm-app-f2c16`) |
| Thư viện chính | `firebase_core` v5.1.0, `cloud_firestore` v7.1.0, `image_picker` v1.2.4 |

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
