# Hệ Thống Quản Lý Tài Liệu Đa Nền Tảng với Flutter, Firebase và Supabase

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%26%20RLS-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 👥 Danh Sách Nhóm Sinh Viên Thực Hiện

| STT | Họ và Tên | Mã Sinh Viên | Vai Trò | Nhiệm Vụ Phụ Trách |
| :---: | :--- | :---: | :--- | :--- |
| 1 | **Phạm Văn Hưng** | 2351170598 | **Trưởng nhóm / Cloud Architect** | Kiến trúc Hybrid Cloud, Supabase Schema, RLS & Firebase Auth |
| 2 | **Trịnh Trung Kiên** | 2251172396 | **Frontend Developer** | Giao diện Flutter, Đăng nhập Google và Quản lý Tài liệu |
| 3 | **Đỗ Việt Tiến** | 2251243452 | **Frontend Developer** | Chia sẻ tài liệu (Permissions) & Bộ lọc Tìm kiếm |
| 4 | **Cao Đức Đạo** | 2351170581 | **Backend & Database Engineer** | Thiết kế CSDL Supabase, Viết RLS Policies & Tích hợp Storage |
| 5 | **Trương Tuấn Hải** | 2351170590 | **QA / Test Engineer** | Bộ kiểm thử tự động Đa tài khoản & Viết Báo cáo |

---

## 📌 6 Mục Checklist Yêu Cầu và Kết Quả Hoàn Thành

- [x] **Checklist 1:** Thiết lập dự án Firebase và tích hợp chức năng đăng nhập bằng tài khoản Google cho ứng dụng Flutter.
- [x] **Checklist 2:** Xây dựng cấu trúc lưu trữ file trên Firebase Storage (`documents/{owner_id}/{doc_id}/{filename}`) và kết nối với bảng quản lý thông tin tài liệu trên Supabase.
- [x] **Checklist 3:** Thiết kế cơ sở dữ liệu trên Supabase bao gồm các bảng: `users` (Người dùng), `documents` (Tài liệu), và `document_permissions` (Quyền chia sẻ).
- [x] **Checklist 4:** Triển khai chức năng tìm kiếm toàn văn, cập nhật thông tin tài liệu và tính năng chia sẻ tài liệu cho người dùng khác với 2 quyền hạn (`view`, `edit`).
- [x] **Checklist 5:** Thiết lập 6 chính sách bảo mật cấp độ hàng (Row Level Security - RLS) trên Supabase để phân quyền truy cập tài liệu.
- [x] **Checklist 6:** Tiến hành kiểm thử tự động (Automated Testing) luồng hoạt động của ứng dụng bằng ít nhất 3 tài khoản người dùng khác nhau để xác minh quyền hạn.

---

## 🚀 Hướng Dẫn Chạy và Kiểm Thử

### 1. Kiểm tra tính toàn vẹn mã nguồn
```bash
flutter analyze
```

### 2. Chạy toàn bộ các kịch bản kiểm thử 6 Checklist (Multi-Accounts Permission Testing)
```bash
flutter test test/supabase_firebase_permissions_test.dart
```

### 3. Khởi chạy Ứng dụng trên Trình duyệt Web
```bash
flutter run -d chrome
```

---

## 📄 Thư Mục và Tệp Tin Quan Trọng
- **Báo cáo Chi tiết Nộp bài:** [`BAO_CAO_HE_THONG_FLUTTER_FIREBASE_SUPABASE.md`](BAO_CAO_HE_THONG_FLUTTER_FIREBASE_SUPABASE.md)
- **Cơ sở dữ liệu Supabase DDL:** [`supabase/schema.sql`](supabase/schema.sql)
- **Chính sách Bảo mật RLS:** [`supabase/rls_policies.sql`](supabase/rls_policies.sql)
- **Dịch vụ Xác thực Firebase Google:** [`lib/services/firebase_auth_service.dart`](lib/services/firebase_auth_service.dart)
- **Dịch vụ Lưu trữ File Firebase:** [`lib/services/firebase_storage_service.dart`](lib/services/firebase_storage_service.dart)
- **Dịch vụ Supabase & RLS Engine:** [`lib/services/supabase_service.dart`](lib/services/supabase_service.dart)
- **Bộ Kiểm thử Đa người dùng:** [`test/supabase_firebase_permissions_test.dart`](test/supabase_firebase_permissions_test.dart)
