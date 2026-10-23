# Hệ Thống Quản Lý Tài Liệu Đa Nền Tảng với Flutter, Firebase và Supabase

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%26%20RLS-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 👥 Danh Sách Nhóm Sinh Viên Thực Hiện

| STT | Họ và Tên | Mã Sinh Viên |
| :---: | :--- | :---: |
| 1 | Phạm Văn Hưng | 2351170598 |
| 2 | Trịnh Trung Kiên | 2251172396 |
| 3 | Đỗ Việt Tiến | 2251243452 |
| 4 | Cao Đức Đạo | 2351170581 |
| 5 | Trương Tuấn Hải | 2351170590 |

---

## 🏗️ Thiết Kế Kiến Trúc Hệ Thống (Hybrid Multi-Cloud Architecture)

Hệ thống được thiết kế theo mô hình **Kiến trúc Đám mây Kết hợp (Hybrid Multi-Cloud Architecture)**, tận dụng thế mạnh chuyên biệt của **Google Firebase** và **Supabase PostgreSQL** để tạo nên một nền tảng quản lý tài liệu học tập mạnh mẽ, bảo mật cao và thời gian thực:

```mermaid
graph TB
    subgraph ClientLayer["🖥️ TẦNG GIAO DIỆN (FLUTTER MULTI-PLATFORM)"]
        UI_Web["🌐 Flutter Web Browser"]
        UI_Mobile["📱 Flutter Mobile (Android/iOS)"]
        UI_Desktop["💻 Flutter Desktop (Windows/macOS)"]
    end

    subgraph FirebaseLayer["🔥 GOOGLE FIREBASE SERVICES"]
        FB_Auth["🔑 Firebase Authentication<br/>(Google Sign-In OAuth 2.0 / JWT)"]
        FB_Storage["📦 Firebase Cloud Storage<br/>(documents/{owner_id}/{doc_id}/{filename})"]
        FB_Msg["🔔 In-App Notifications & Messaging<br/>(Thông báo mượn/trả, phê duyệt)"]
    end

    subgraph SupabaseLayer["⚡ SUPABASE CLOUD (POSTGRESQL & ENGINE)"]
        Supa_Postgres[("🐘 Supabase PostgreSQL DB<br/>users, documents, permissions,<br/>borrow_requests, locations, tags")]
        Supa_RLS["🛡️ Row Level Security (RLS)<br/>Bảo mật cấp dòng: Owner / Editor / Viewer / Sharer"]
        Supa_FTS["🔍 Full-Text Search Engine<br/>Tìm kiếm toàn văn theo tiêu đề, mô tả, thẻ tag"]
    end

    subgraph LocalCache["💾 TẦNG LƯU TRỮ OFFLINE-FIRST"]
        SQLite_DB[("📱 SQLite / WebStorage Cache<br/>Đọc tài liệu offline tức thì & Sync nền")]
    end

    %% Tương tác luồng dữ liệu
    UI_Web & UI_Mobile & UI_Desktop -->|"1. Đăng nhập Google"| FB_Auth
    FB_Auth -->|"2. Xác thực thành công & Trả User Profile"| UI_Web & UI_Mobile & UI_Desktop
    UI_Web & UI_Mobile & UI_Desktop -->|"3. Đồng bộ User Info"| Supa_Postgres

    UI_Web & UI_Mobile & UI_Desktop -->|"4. Upload file nhị phân (PDF, Docx)"| FB_Storage
    FB_Storage -->|"5. Trả Download URL"| UI_Web & UI_Mobile & UI_Desktop
    UI_Web & UI_Mobile & UI_Desktop -->|"6. Lưu Metadata & File URL (Bảo vệ bởi RLS)"| Supa_Postgres

    UI_Web & UI_Mobile & UI_Desktop <-->|"7. Truy vấn dữ liệu có phân quyền RLS"| Supa_RLS
    Supa_RLS <--> Supa_Postgres

    UI_Web & UI_Mobile & UI_Desktop -->|"8. Gửi yêu cầu mượn & Nhận thông báo"| FB_Msg
    UI_Web & UI_Mobile & UI_Desktop <-->|"9. Cache dữ liệu cục bộ"| SQLite_DB
```

### 1. Phân định Trách nhiệm giữa các Dịch vụ Cloud (Service Responsibilities)
- **Google Firebase:**
  - **Firebase Authentication:** Đảm nhiệm toàn bộ việc xác thực danh tính người dùng qua Google Sign-In (OAuth 2.0). Cung cấp UID, Email, Display Name và mã hóa phiên làm việc an toàn.
  - **Firebase Cloud Storage:** Chuyên trách lưu trữ các tệp tin tài liệu nhị phân dung lượng lớn (PDF, Slide bài giảng, Tài liệu Word, Ảnh bài tập). Đường dẫn lưu trữ phân cấp theo cấu trúc bảo mật: `documents/{owner_id}/{doc_id}/{filename}`.
  - **In-App Messaging / Notifications:** Quản lý hàng đợi thông báo thời gian thực khi có sự kiện: Gửi yêu cầu mượn sách, Chủ tài liệu duyệt mượn, Nhắc nhở hạn trả sách.
- **Supabase Cloud (PostgreSQL Engine):**
  - **PostgreSQL Database:** Lưu trữ toàn bộ dữ liệu quan hệ có cấu trúc (Metadata tài liệu, Thẻ tag, Vị trí kho lưu trữ vật lý, Lịch sử mượn trả).
  - **Row Level Security (RLS Engine):** Kiểm soát bảo mật cấp độ dòng trực tiếp tại tầng CSDL PostgreSQL, đảm bảo chỉ chủ sở hữu hoặc người được cấp quyền hợp lệ mới được Xem, Sửa, Xóa hoặc Chia sẻ tài liệu.
  - **Full-Text Search:** Hỗ trợ tìm kiếm nhanh theo từ khóa, lọc theo thẻ Tag môn học và vị trí kho lưu trữ.
- **Offline-First Cache (SQLite / WebStorage):**
  - Lưu bản sao cục bộ giúp người dùng mở ứng dụng và đọc thông tin tài liệu ngay lập tức mà không cần mạng, tự động đồng bộ khi có kết nối trở lại.

---

## 📊 Mô Hình Dữ Liệu Thực Thể (Entity Relationship Diagram - ERD)

Cơ sở dữ liệu Supabase được xây dựng trên hệ quản trị **PostgreSQL** chuẩn hóa với các ràng buộc khóa ngoại (Foreign Keys) và chính sách bảo mật RLS:

```mermaid
erDiagram
    USERS ||--o{ DOCUMENTS : "sở hữu (owner_id)"
    USERS ||--o{ DOCUMENT_PERMISSIONS : "được cấp quyền (user_id)"
    USERS ||--o{ DOCUMENT_PERMISSIONS : "người phân quyền (granted_by)"
    DOCUMENTS ||--o{ DOCUMENT_PERMISSIONS : "được chia sẻ (document_id)"
    USERS ||--o{ BORROW_REQUESTS : "gửi yêu cầu (borrower_id)"
    USERS ||--o{ BORROW_REQUESTS : "chủ tài liệu (owner_id)"
    DOCUMENTS ||--o{ BORROW_REQUESTS : "tài liệu mượn (document_id)"
    STORAGE_LOCATIONS ||--o{ DOCUMENTS : "vị trí cất giữ vật lý"
    TAGS ||--o{ DOCUMENTS : "phân loại chủ đề"

    USERS {
        varchar(100) id PK "Firebase UID"
        varchar(255) email UK "Gmail người dùng"
        varchar(255) display_name "Họ và tên"
        text avatar_url "Ảnh đại diện"
        varchar(100) role "Vai trò (Editor/Admin)"
        timestamptz created_at "Ngày tạo"
        timestamptz last_login_at "Lần đăng nhập cuối"
    }

    DOCUMENTS {
        uuid id PK "UUID tài liệu"
        varchar(255) title "Tiêu đề tài liệu"
        text description "Mô tả chi tiết"
        varchar(50) course_code "Mã môn học"
        text file_url "Đường dẫn tải Firebase Storage"
        varchar(255) file_name "Tên tệp gốc"
        bigint file_size "Kích thước tệp (bytes)"
        varchar(100) owner_id FK "ID chủ sở hữu (users.id)"
        varchar(255) owner_email "Email chủ sở hữu"
        varchar(255) owner_name "Tên chủ sở hữu"
        varchar(255) physical_location "Kho lưu trữ vật lý"
        varchar(100) shelf_location "Tòa nhà, Phòng, Kệ"
        double_precision latitude "Tọa độ Vĩ độ GPS"
        double_precision longitude "Tọa độ Kinh độ GPS"
        text_array tags "Danh sách thẻ Tag phân loại"
        varchar(50) status "Trạng thái (inProgress/completed)"
        boolean is_pinned "Được ghim lên đầu danh sách"
        timestamptz deadline "Hạn chót học / Hạn nộp"
        timestamptz created_at "Ngày tạo"
        timestamptz updated_at "Ngày cập nhật"
    }

    DOCUMENT_PERMISSIONS {
        uuid id PK "UUID quyền hạn"
        uuid document_id FK "Tài liệu được phân quyền"
        varchar(100) user_id FK "Người được cấp quyền (users.id)"
        varchar(255) user_email "Email người nhận quyền"
        varchar(255) user_name "Tên người nhận quyền"
        varchar(100) permission_type "view, edit, delete, share"
        varchar(100) granted_by FK "Chủ sở hữu cấp quyền (users.id)"
        timestamptz created_at "Ngày cấp quyền"
    }

    BORROW_REQUESTS {
        uuid id PK "UUID yêu cầu mượn"
        uuid document_id FK "Tài liệu cần mượn"
        varchar(255) document_title "Tên tài liệu"
        varchar(100) borrower_id FK "Người xin mượn (users.id)"
        varchar(255) borrower_name "Tên người mượn"
        varchar(255) borrower_email "Email người mượn"
        varchar(100) owner_id FK "Chủ sở hữu (users.id)"
        varchar(255) owner_name "Tên chủ sở hữu"
        varchar(255) owner_email "Email chủ sở hữu"
        varchar(50) status "pending, approved, rejected, returned"
        timestamptz request_date "Ngày gửi yêu cầu"
        timestamptz due_date "Ngày hẹn trả tài liệu"
        text notes "Lời nhắn gửi chủ tài liệu"
        timestamptz created_at "Thời gian tạo yêu cầu"
    }

    STORAGE_LOCATIONS {
        uuid id PK "UUID kho lưu trữ"
        varchar(255) name UK "Tên kho / Tòa nhà"
        varchar(100) building "Tên tòa nhà"
        varchar(50) floor "Tầng"
        varchar(50) room "Phòng"
        varchar(50) cabinet "Tủ lưu trữ"
        varchar(50) shelf "Ngăn / Kệ"
        double_precision latitude "Tọa độ Vĩ độ Bản đồ"
        double_precision longitude "Tọa độ Kinh độ Bản đồ"
        text description "Ghi chú hướng dẫn vị trí"
    }

    TAGS {
        uuid id PK "UUID thẻ tag"
        varchar(100) name UK "Tên thẻ tag"
        varchar(20) color "Mã màu Hex hiển thị (#HEX)"
    }
```

---

## 🔄 Luồng Nghiệp Vụ Kết Hợp Giữa Firebase & Supabase (Data Flow)

### 1. Luồng Xác thực & Tự động Đồng bộ Người dùng (Auth Flow)
1. Người dùng bấm **"Đăng nhập bằng Google"** trên ứng dụng Flutter.
2. `FirebaseAuthService` kích hoạt Google OAuth 2.0 ➔ Google cấp Token xác thực danh tính.
3. Ứng dụng trích xuất thông tin người dùng (`uid`, `email`, `displayName`, `photoURL`).
4. Tự động gọi API `SupabaseService.upsertUserOnline()` để chèn/cập nhật bản ghi vào bảng `public.users` trên Supabase, đảm bảo tính nhất quán dữ liệu giữa 2 đám mây.

### 2. Luồng Tải lên & Lưu trữ Tài liệu (Upload Document Flow)
1. Người dùng điền thông tin tài liệu và chọn file đính kèm (PDF/Slide/Docx).
2. Tệp nhị phân được upload lên **Firebase Cloud Storage** tại thư mục:
   `documents/{owner_id}/{doc_id}/{filename}`
3. Firebase trả về URL tải tệp bảo mật (`file_url`).
4. Ứng dụng gửi toàn bộ Metadata kèm `file_url`, tọa độ vị trí kho và thẻ tags lên **Supabase PostgreSQL** (`public.documents`).
5. Dữ liệu được bảo vệ tức thì bởi **Supabase Row Level Security (RLS)**.

### 3. Luồng Yêu cầu Mượn Sách & Tự động Cấp Quyền RLS (Borrowing & Permission Flow)
1. Sinh viên A khám phá tài liệu trên trang **"Nơi mượn tài liệu"** và gửi yêu cầu mượn đến Sinh viên B (Chủ tài liệu).
2. Bản ghi được tạo trong bảng `public.borrow_requests` với trạng thái `pending`.
3. Sinh viên B nhận thông báo và truy cập tab **"Duyệt yêu cầu mượn"**.
4. Khi Sinh viên B bấm **"CHẤP NHẬN (ACCEPT)"**:
   - Trạng thái yêu cầu chuyển thành `approved`.
   - **Hệ thống tự động kích hoạt nghiệp vụ kết nối:** Tự động tạo bản ghi trong bảng `public.document_permissions` cấp quyền `view` cho Sinh viên A.
   - Nhờ đó, Sinh viên A có thể mở đọc tài liệu trực tuyến ngay lập tức với đầy đủ phân quyền RLS hợp lệ.

---

## 📌 6 Mục Checklist Yêu Cầu và Kết Quả Hoàn Thành

- [x] **Checklist 1:** Thiết lập dự án Firebase và tích hợp chức năng đăng nhập bằng tài khoản Google cho ứng dụng Flutter.
- [x] **Checklist 2:** Xây dựng cấu trúc lưu trữ file trên Firebase Storage (`documents/{owner_id}/{doc_id}/{filename}`) và kết nối với bảng quản lý thông tin tài liệu trên Supabase.
- [x] **Checklist 3:** Thiết kế cơ sở dữ liệu trên Supabase bao gồm các bảng: `users` (Người dùng), `documents` (Tài liệu), và `document_permissions` (Quyền chia sẻ).
- [x] **Checklist 4:** Triển khai chức năng tìm kiếm toàn văn, cập nhật thông tin tài liệu và tính năng chia sẻ tài liệu cho người dùng khác với 2 quyền hạn (`view`, `edit`).
- [x] **Checklist 5:** Thiết lập 6 chính sách bảo mật cấp độ hàng (Row Level Security - RLS) trên Supabase để phân quyền truy cập tài liệu.
- [x] **Checklist 6:** Tiến hành kiểm thử tự động (Automated Testing) luồng hoạt động của ứng dụng bằng ít nhất 3 tài khoản người dùng khác nhau để xác minh quyền hạn.

---

---

## 🧪 Kiểm Thử Toàn Diện Tính Năng (Comprehensive Testing)

Hệ thống đã được thiết kế bộ kiểm thử tự động (Automated Testing Suite) toàn diện tại tệp [`test/supabase_firebase_permissions_test.dart`](test/supabase_firebase_permissions_test.dart), xác minh đầy đủ các nghiệp vụ đa tài khoản và tính năng cốt lõi.

### 1. Kết quả Chạy Kiểm thử Tự động (Automated Test Execution)
```bash
flutter test test/supabase_firebase_permissions_test.dart
```
**Kết quả thực tế (Output terminal):**
```text
00:00 +0: loading test/supabase_firebase_permissions_test.dart
00:00 +0: KIỂM THỬ TOÀN DIỆN HỆ THỐNG: FIREBASE + SUPABASE RLS & LUỒNG MƯỢN TRẢ 1. Kiểm thử Cấu trúc Đường dẫn Tệp Firebase Cloud Storage (Checklist 2)
00:00 +1: KIỂM THỬ TOÀN DIỆN HỆ THỐNG: FIREBASE + SUPABASE RLS & LUỒNG MƯỢN TRẢ 2. Kiểm thử Quyền Chủ sở hữu (Owner Permissions) trên Supabase RLS (Checklist 5)
00:00 +2: KIỂM THỬ TOÀN DIỆN HỆ THỐNG: FIREBASE + SUPABASE RLS & LUỒNG MƯỢN TRẢ 3. Kiểm thử Phân quyền Chia sẻ RLS cho Người dùng B (Checklist 4 & 5)
00:00 +3: KIỂM THỬ TOÀN DIỆN HỆ THỐNG: FIREBASE + SUPABASE RLS & LUỒNG MƯỢN TRẢ 4. Kiểm thử Chặn quyền Sửa/Xóa của Người ngoài (User C) khi chưa cấp quyền
00:00 +4: KIỂM THỬ TOÀN DIỆN HỆ THỐNG: FIREBASE + SUPABASE RLS & LUỒNG MƯỢN TRẢ 5. Kiểm thử Luồng Mượn Sách & Tự động Cấp Quyền RLS khi Chấp nhận (Accept)
00:00 +5: KIỂM THỬ TOÀN DIỆN HỆ THỐNG: FIREBASE + SUPABASE RLS & LUỒNG MƯỢN TRẢ 6. Kiểm thử Thuật toán Gợi ý Thông minh AI (Recommendation Algorithm & Jaccard)
00:00 +6: All tests passed!
```
👉 **Đạt 100% (6/6 kịch bản kiểm thử PASS xanh tuyệt đối).**

### 2. Kiểm tra Phân tích Tĩnh Mã Nguồn (Static Code Analysis)
```bash
flutter analyze
```
**Kết quả:**
```text
Analyzing study_document_supabase_firebase...
No issues found! (ran in 4.8s)
```
👉 **Mã nguồn sạch, đạt chuẩn 0 cảnh báo, 0 lỗi.**

### 3. Ma Trận Kiểm Thử Phân Quyền Đa Tài Khoản (Role & Permission Matrix)

| Kịch bản Kiểm thử | Thao tác / API | User A (Owner) | User B (Editor) | User C (Viewer/Borrower) | User D (Người lạ) | Kết quả Kiểm thử |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Lưu trữ Cloud Storage** | Upload file theo định dạng chuẩn `documents/{uid}/{doc_id}/{filename}` | ✅ Cho phép | ❌ Bị chặn | ❌ Bị chặn | ❌ Bị chặn | **PASS (Checklist 2)** |
| **Xem tài liệu (SELECT)** | Đọc metadata & lấy download URL | ✅ Toàn quyền | ✅ Được cấp quyền | ✅ Được cấp sau khi mượn | ❌ Chặn xem riêng tư | **PASS (Checklist 5)** |
| **Chỉnh sửa (UPDATE)** | Cập nhật tiêu đề, tag, file đính kèm | ✅ Toàn quyền | ✅ Được sửa nội dung | ❌ Bị RLS chặn | ❌ Bị RLS chặn | **PASS (Checklist 4 & 5)** |
| **Xóa tài liệu (DELETE)** | Xóa tài liệu khỏi hệ thống | ✅ Toàn quyền | ❌ Bị chặn | ❌ Bị chặn | ❌ Bị chặn | **PASS (Checklist 5)** |
| **Chia sẻ phân quyền** | Gán quyền `view`/`edit` cho người khác | ✅ Toàn quyền | ❌ Bị chặn | ❌ Bị chặn | ❌ Bị chặn | **PASS (Checklist 4 & 5)** |
| **Quy trình Mượn/Trả** | Gửi yêu cầu mượn & tự động mở quyền RLS | ✅ Phê duyệt / Từ chối | - | ✅ Mượn thành công & mở xem | ❌ Cần gửi yêu cầu | **PASS (Checklist 4 & 6)** |
| **Gợi ý AI & Jaccard** | Tính điểm theo tags, môn học, tài liệu ghim | ✅ Gợi ý cá nhân hóa | ✅ Gợi ý cá nhân hóa | ✅ Gợi ý cá nhân hóa | - | **PASS (Thuật toán AI)** |

---

## 📦 Đóng Gói Sản Phẩm & Hướng Dẫn Triển Khai (Product Packaging & Deployment)

Hệ thống hỗ trợ đóng gói bản phát hành thương mại (Production Release) đa nền tảng tối ưu:

### 1. Đóng gói Nền tảng Web (Web Production Bundle)
Lệnh đóng gói chuẩn hóa:
```bash
flutter build web --release
```
- **Tối ưu hóa:** Tree-shaking tự động giảm dung lượng font icons tới **99.4%** (`CupertinoIcons.ttf` từ 257KB xuống 1.4KB; `MaterialIcons` từ 1.6MB xuống 21KB).
- **Thư mục đầu ra:** `build/web/`
- **Các thành phần cốt lõi:**
  - `main.dart.js`: Mã nguồn ứng dụng được biên dịch tối ưu hóa minified.
  - `flutter.js` & `flutter_bootstrap.js`: Engine khởi động ứng dụng Web.
  - `canvaskit/`: Bộ dựng hình đồ họa hiệu năng cao.
  - `assets/` & `icons/`: Tài nguyên hình ảnh, biểu tượng.
  - `index.html` & `manifest.json`: Hỗ trợ Progressive Web App (PWA).

### 2. Đóng gói Nền tảng Di động Android (Android Release Package)
- **Đóng gói file cài đặt APK:**
  ```bash
  flutter build apk --release
  ```
  *Đầu ra:* `build/app/outputs/flutter-apk/app-release.apk`
- **Đóng gói bản phát hành Google Play (App Bundle):**
  ```bash
  flutter build appbundle --release
  ```
  *Đầu ra:* `build/app/outputs/bundle/release/app-release.aab`

### 3. Đóng gói Nền tảng Máy tính Windows (Desktop Release Package)
```bash
flutter build windows --release
```
*Đầu ra:* `build/windows/x64/runner/Release/` (bao gồm tệp thực thi `.exe` và các thư viện runtime liên quan).

### 4. Hướng dẫn Triển khai Trực tiếp (Live Deployment Guide)
- **Triển khai lên Firebase Hosting:**
  ```bash
  npm install -g firebase-tools
  firebase login
  firebase init hosting   # Chọn thư mục public: build/web
  firebase deploy --only hosting
  ```
- **Triển khai lên Vercel / Netlify:**
  Chỉ cần kết nối repository GitHub và đặt thư mục xuất bản (Publish Directory) là `build/web`.


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
