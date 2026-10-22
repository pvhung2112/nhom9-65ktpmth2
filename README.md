# BÀI TẬP THỰC HÀNH NHÓM 9 - 65KTPM

## Thông tin sinh viên & Nhánh làm việc
- **Họ và tên:** Phạm Văn Hưng
- **MSSV:** 2351170598
- **Tài khoản GitHub:** [pvhung2112](https://github.com/pvhung2112)
- **Nhánh thực hiện:** `hung`

## Cấu trúc thư mục
- `th2/`: Bài tập thực hành 2 (TH2) - Hệ thống Quản lý Tài liệu Đa nền tảng (Flutter Responsive + Firebase + Supabase Cloud RLS).
  - `study_document_supabase_firebase/`: Mã nguồn hoàn chỉnh của ứng dụng Flutter.
    - `lib/`: Mã nguồn chính (Models, Pages, Services, Widgets).
    - `supabase/`: Schema CSDL và chính sách bảo mật Row Level Security (RLS).
    - `test/`: Bộ kiểm thử tự động (Unit Test, Integration Test).
    - `web/`: Cấu hình nền tảng Web & Google Sign-In OAuth.
    - `BAO_CAO_TH2_HE_THONG_QUAN_LY_TAI_LIEU.md`: Báo cáo chi tiết 6 Checklist TH2.
    - `BAO_CAO_HE_THONG_FLUTTER_FIREBASE_SUPABASE.md`: Báo cáo kiến trúc hệ thống Hybrid Multi-Cloud.

## Hướng dẫn cài đặt & Khởi chạy ứng dụng (TH2)
```bash
# 1. Di chuyển vào thư mục dự án
cd th2/study_document_supabase_firebase

# 2. Tải các dependencies
flutter pub get

# 3. Chạy ứng dụng trên trình duyệt Web (Chrome)
flutter run -d chrome
```
