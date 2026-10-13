-- ==============================================================================
-- CHECKLIST 3: THIẾT KẾ CƠ SỞ DỮ LIỆU TRÊN SUPABASE (POSTGRESQL)
-- Hệ thống Quản lý Tài liệu Đa nền tảng với Flutter, Firebase và Supabase
-- Bao gồm 3 bảng cốt lõi: users, documents, và document_permissions
-- ==============================================================================

-- 1. Bật extension UUID tự động sinh khóa chính
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- BẢNG 1: users (Quản lý Thông tin Người dùng đã Xác thực qua Firebase Google)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.users (
    id VARCHAR(100) PRIMARY KEY, -- Khớp với Firebase Auth UID (hoặc UUID)
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chỉ mục tối ưu hóa tìm kiếm người dùng theo Email
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- ==============================================================================
-- BẢNG 2: documents (Quản lý Thông tin Tài liệu & Liên kết Firebase Storage)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    course_code VARCHAR(50) DEFAULT 'SE301',
    file_url TEXT NOT NULL,       -- URL tải tệp vật lý lưu trên Firebase Cloud Storage
    file_name VARCHAR(255) NOT NULL,
    file_size BIGINT DEFAULT 0,  -- Kích thước tệp (bytes)
    owner_id VARCHAR(100) NOT NULL,
    owner_email VARCHAR(255) NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ràng buộc toàn vẹn dữ liệu: owner_id tham chiếu tới users(id)
    CONSTRAINT fk_documents_owner
        FOREIGN KEY (owner_id) 
        REFERENCES public.users(id) 
        ON DELETE CASCADE
);

-- Chỉ mục tối ưu hóa truy vấn tài liệu theo Chủ sở hữu và Mã môn học
CREATE INDEX IF NOT EXISTS idx_documents_owner ON public.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_course ON public.documents(course_code);

-- ==============================================================================
-- BẢNG 3: document_permissions (Quản lý Quyền Chia sẻ & Phân quyền Truy cập)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.document_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL,
    user_id VARCHAR(100) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    permission_type VARCHAR(20) NOT NULL CHECK (permission_type IN ('view', 'edit')),
    granted_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ràng buộc khóa ngoại
    CONSTRAINT fk_perm_document
        FOREIGN KEY (document_id) 
        REFERENCES public.documents(id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_perm_user
        FOREIGN KEY (user_id) 
        REFERENCES public.users(id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_perm_granter
        FOREIGN KEY (granted_by) 
        REFERENCES public.users(id),

    -- Ràng buộc một tài liệu chỉ gán 1 quyền duy nhất cho 1 người dùng
    CONSTRAINT uq_document_user_permission 
        UNIQUE (document_id, user_id)
);

-- Chỉ mục tối ưu hóa kiểm tra quyền hạn khi truy vấn RLS
CREATE INDEX IF NOT EXISTS idx_permissions_lookup 
    ON public.document_permissions(document_id, user_id, permission_type);
