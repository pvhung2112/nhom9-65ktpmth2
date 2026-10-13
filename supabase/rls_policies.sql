-- ==============================================================================
-- CHECKLIST 5: THIẾT LẬP CHÍNH SÁCH BẢO MẬT (ROW LEVEL SECURITY - RLS) TRÊN SUPABASE
-- Phân quyền truy cập tài liệu: Chủ sở hữu (Owner), Người xem (View), Người sửa (Edit)
-- ==============================================================================

-- 1. KÍCH HOẠT ROW LEVEL SECURITY (RLS) TRÊN CÁC BẢNG
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- CHÍNH SÁCH RLS CHO BẢNG: documents
-- ==============================================================================

-- Policy 1 [SELECT]: Người dùng chỉ được xem tài liệu nếu là Owner HOẶC được cấp quyền View/Edit
CREATE POLICY "RLS_Documents_Select_Accessible"
ON public.documents
FOR SELECT
USING (
    -- Trường hợp 1: Người dùng là Chủ sở hữu
    owner_id = auth.uid()::text
    OR
    -- Trường hợp 2: Người dùng có trong danh sách phân quyền (View hoặc Edit)
    EXISTS (
        SELECT 1 FROM public.document_permissions dp
        WHERE dp.document_id = documents.id
          AND dp.user_id = auth.uid()::text
          AND dp.permission_type IN ('view', 'edit')
    )
);

-- Policy 2 [INSERT]: Chỉ cho phép thêm tài liệu mới nếu auth.uid() trùng với owner_id
CREATE POLICY "RLS_Documents_Insert_OwnerOnly"
ON public.documents
FOR INSERT
WITH CHECK (
    owner_id = auth.uid()::text
);

-- Policy 3 [UPDATE]: Chỉ Owner HOẶC người dùng có quyền 'edit' mới được cập nhật thông tin
CREATE POLICY "RLS_Documents_Update_OwnerOrEditor"
ON public.documents
FOR UPDATE
USING (
    -- Owner có toàn quyền sửa
    owner_id = auth.uid()::text
    OR
    -- Editor được cấp quyền 'edit'
    EXISTS (
        SELECT 1 FROM public.document_permissions dp
        WHERE dp.document_id = documents.id
          AND dp.user_id = auth.uid()::text
          AND dp.permission_type = 'edit'
    )
)
WITH CHECK (
    -- Không cho phép thay đổi chủ sở hữu ban đầu
    owner_id = documents.owner_id
);

-- Policy 4 [DELETE]: CHỈ DUY NHẤT Owner mới có quyền xóa tài liệu
CREATE POLICY "RLS_Documents_Delete_OwnerOnly"
ON public.documents
FOR DELETE
USING (
    owner_id = auth.uid()::text
);

-- ==============================================================================
-- CHÍNH SÁCH RLS CHO BẢNG: document_permissions
-- ==============================================================================

-- Policy 5 [SELECT]: Người dùng có thể xem danh sách quyền nếu là Owner tài liệu hoặc chính họ
CREATE POLICY "RLS_Permissions_Select"
ON public.document_permissions
FOR SELECT
USING (
    user_id = auth.uid()::text
    OR
    EXISTS (
        SELECT 1 FROM public.documents d
        WHERE d.id = document_permissions.document_id
          AND d.owner_id = auth.uid()::text
    )
);

-- Policy 6 [INSERT/UPDATE/DELETE]: CHỈ CÓ OWNER CỦA TÀI LIỆU MỚI ĐƯỢC QUẢN TRỊ QUYỀN
CREATE POLICY "RLS_Permissions_Manage_OwnerOnly"
ON public.document_permissions
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.documents d
        WHERE d.id = document_permissions.document_id
          AND d.owner_id = auth.uid()::text
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.documents d
        WHERE d.id = document_permissions.document_id
          AND d.owner_id = auth.uid()::text
    )
);

-- ==============================================================================
-- CHÍNH SÁCH RLS CHO BẢNG: users
-- ==============================================================================
CREATE POLICY "RLS_Users_Select_All"
ON public.users
FOR SELECT
USING (true); -- Mọi người dùng đã xác thực đều có thể xem danh sách thành viên để chia sẻ

CREATE POLICY "RLS_Users_Update_Self"
ON public.users
FOR UPDATE
USING (id = auth.uid()::text);
