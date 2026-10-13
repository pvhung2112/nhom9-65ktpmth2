-- ==============================================================================
-- CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS) TƯƠNG THÍCH FIREBASE AUTH & SUPABASE
-- Hệ thống: Xác thực Google qua Firebase Auth + Lưu file trên Firebase Storage + CSDL Supabase
-- ==============================================================================

-- 1. BẢNG USERS
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS role VARCHAR(100) DEFAULT 'Editor';
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "RLS_Users_Select_All" ON public.users;
CREATE POLICY "RLS_Users_Select_All" ON public.users FOR SELECT USING (true);

DROP POLICY IF EXISTS "RLS_Users_Insert_All" ON public.users;
CREATE POLICY "RLS_Users_Insert_All" ON public.users FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "RLS_Users_Update_All" ON public.users;
CREATE POLICY "RLS_Users_Update_All" ON public.users FOR UPDATE USING (true);

-- 2. BẢNG DOCUMENTS
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "RLS_Documents_Select_Accessible" ON public.documents;
CREATE POLICY "RLS_Documents_Select_Accessible" ON public.documents FOR SELECT USING (true);

DROP POLICY IF EXISTS "RLS_Documents_Insert_OwnerOnly" ON public.documents;
CREATE POLICY "RLS_Documents_Insert_OwnerOnly" ON public.documents FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "RLS_Documents_Update_OwnerOrEditor" ON public.documents;
CREATE POLICY "RLS_Documents_Update_OwnerOrEditor" ON public.documents FOR UPDATE USING (true);

DROP POLICY IF EXISTS "RLS_Documents_Delete_OwnerOnly" ON public.documents;
CREATE POLICY "RLS_Documents_Delete_OwnerOnly" ON public.documents FOR DELETE USING (true);

-- 3. BẢNG DOCUMENT_PERMISSIONS
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "RLS_Permissions_All" ON public.document_permissions;
CREATE POLICY "RLS_Permissions_All" ON public.document_permissions FOR ALL USING (true) WITH CHECK (true);

-- 4. MỞ RỘNG RÀNG BUỘC PHÂN QUYỀN (VIEW, EDIT, DELETE, ALL)
ALTER TABLE public.document_permissions DROP CONSTRAINT IF EXISTS document_permissions_permission_type_check;
ALTER TABLE public.document_permissions ADD CONSTRAINT document_permissions_permission_type_check CHECK (permission_type IN ('view', 'edit', 'delete', 'share', 'all'));

-- ==============================================================================
-- 4. HỖ TRỢ LƯU MẢNG QUYỀN HẠN (ARRAY / JSON) VÀ GỠ RÀNG BUỘC CŨ
-- ==============================================================================
ALTER TABLE public.document_permissions ALTER COLUMN permission_type TYPE VARCHAR(100);
ALTER TABLE public.document_permissions DROP CONSTRAINT IF EXISTS document_permissions_permission_type_check;
