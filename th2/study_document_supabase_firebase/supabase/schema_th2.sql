-- ========================================================
-- TH2: PHÁT TRIỂN HỆ THỐNG QUẢN LÝ TÀI LIỆU ĐA NỀN TẢNG
-- CSDL Bổ sung: Bảng borrow_requests và các trường vị trí vật lý
-- ========================================================

-- 1. Bổ sung trường Vị trí vật lý vào bảng documents
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS physical_location VARCHAR(255) DEFAULT 'Thư viện Trung tâm - Tòa H1';
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION DEFAULT 10.8700;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION DEFAULT 106.8030;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS shelf_location VARCHAR(100) DEFAULT 'Kệ A3 - Ngăn 02';
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS borrow_status VARCHAR(50) DEFAULT 'available';

-- 2. Tạo bảng Quản lý Mượn / Trả tài liệu (borrow_requests)
CREATE TABLE IF NOT EXISTS public.borrow_requests (
    id VARCHAR(100) PRIMARY KEY,
    document_id VARCHAR(100) NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    document_title VARCHAR(255) NOT NULL,
    course_code VARCHAR(50) DEFAULT 'SE301',
    owner_id VARCHAR(100) NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    owner_email VARCHAR(255) NOT NULL,
    borrower_id VARCHAR(100) NOT NULL,
    borrower_name VARCHAR(255) NOT NULL,
    borrower_email VARCHAR(255) NOT NULL,
    request_date TIMESTAMPTZ DEFAULT NOW(),
    due_date TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
    return_date TIMESTAMPTZ,
    status VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Thiết lập chính sách bảo mật RLS cho bảng borrow_requests
ALTER TABLE public.borrow_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Cho phép người mượn hoặc chủ sở hữu đọc yêu cầu mượn"
ON public.borrow_requests FOR SELECT
USING (true);

CREATE POLICY "Cho phép tạo yêu cầu mượn"
ON public.borrow_requests FOR INSERT
WITH CHECK (true);

CREATE POLICY "Cho phép cập nhật trạng thái mượn/trả"
ON public.borrow_requests FOR UPDATE
USING (true);
