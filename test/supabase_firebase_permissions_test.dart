import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_app/models/document_permission.dart';
import 'package:study_document_app/services/firebase_auth_service.dart';
import 'package:study_document_app/services/firebase_storage_service.dart';
import 'package:study_document_app/services/supabase_service.dart';

void main() {
  group('Hệ thống Quản lý Tài liệu với Flutter, Firebase và Supabase - Kiểm thử 6 Checklists', () {
    late FirebaseAuthService authService;
    late FirebaseStorageService storageService;
    late SupabaseService supabaseService;

    // 3 Tài khoản người dùng kiểm thử đại diện cho 3 cấp độ quyền hạn (Checklist 6)
    final user1Owner = FirebaseAuthService.predefinedAccounts[0];   // phamvanhung (Owner)
    final user2Editor = FirebaseAuthService.predefinedAccounts[1];  // trinhtrungkien (Editor)
    final user3Viewer = FirebaseAuthService.predefinedAccounts[2];  // doviettien (Viewer)
    final user4Stranger = FirebaseAuthService.predefinedAccounts[3];// unauthorized stranger

    setUp(() {
      authService = FirebaseAuthService();
      storageService = FirebaseStorageService();
      supabaseService = SupabaseService();
    });

    test('Checklist 1: Thiết lập dự án Firebase và Đăng nhập Google với ít nhất 3 tài khoản', () async {
      // 1. Đăng nhập với User 1 (Owner)
      final signedInUser1 = await authService.signInWithGoogle(user: user1Owner);
      expect(signedInUser1.id, equals('usr-owner-001'));
      expect(signedInUser1.email, equals('phamvanhung21122004@gmail.com'));
      expect(authService.isSignedIn, isTrue);

      // 2. Chuyển đổi sang User 2 (Editor)
      final signedInUser2 = await authService.switchUser('usr-editor-002');
      expect(signedInUser2.id, equals('usr-editor-002'));
      expect(signedInUser2.displayName, contains('Trịnh Trung Kiên'));

      // 3. Chuyển đổi sang User 3 (Viewer)
      final signedInUser3 = await authService.switchUser('usr-viewer-003');
      expect(signedInUser3.id, equals('usr-viewer-003'));
      expect(signedInUser3.displayName, contains('Đỗ Việt Tiến'));
    });

    test('Checklist 2: Lưu trữ File trên Firebase Storage và liên kết bảng Documents trên Supabase', () async {
      await authService.signInWithGoogle(user: user1Owner);

      // Giả lập nội dung file PDF bài giảng
      final mockPdfBytes = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52]); // '%PDF-1.4'
      final uploadRes = await storageService.uploadFile(
        ownerId: user1Owner.id,
        documentId: 'doc-cloud-001',
        fileName: 'BaoCao_KienTruc_Cloud.pdf',
        fileBytes: mockPdfBytes,
        mimeType: 'application/pdf',
      );

      expect(uploadRes.success, isTrue);
      expect(uploadRes.storagePath, equals('documents/usr-owner-001/doc-cloud-001/BaoCao_KienTruc_Cloud.pdf'));
      expect(uploadRes.fileUrl, contains('firebasestorage.googleapis.com'));

      // Tạo bản ghi trên Supabase liên kết với fileUrl của Firebase Storage
      final doc = await supabaseService.insertDocument(
        title: 'Báo cáo Kiến trúc Cloud Supabase & Firebase',
        description: 'Tài liệu phân tích mô hình Hybrid Cloud và RLS',
        courseCode: 'SE301',
        fileUrl: uploadRes.fileUrl,
        fileName: uploadRes.fileName,
        fileSize: uploadRes.fileSize,
        currentUser: user1Owner,
      );

      expect(doc.id, isNotEmpty);
      expect(doc.ownerId, equals(user1Owner.id));
      expect(doc.fileUrl, equals(uploadRes.fileUrl));
    });

    test('Checklist 3 & 4: Tìm kiếm tài liệu và Chia sẻ tài liệu cho người dùng khác', () async {
      await authService.signInWithGoogle(user: user1Owner);

      // User 1 tạo tài liệu
      final doc = await supabaseService.insertDocument(
        title: 'Giáo trình Thiết kế Hệ thống Phân tán',
        description: 'Chương 5: Cơ chế phân quyền và Row Level Security',
        courseCode: 'CS402',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/study-document-cloud.appspot.com/o/distributed_systems.pdf',
        fileName: 'distributed_systems.pdf',
        fileSize: 10240,
        currentUser: user1Owner,
      );

      // 1. Tìm kiếm tài liệu
      final searchRes = supabaseService.searchDocuments(
        query: 'Hệ thống Phân tán',
        currentUserId: user1Owner.id,
      );
      expect(searchRes.any((d) => d.id == doc.id), isTrue);

      // 2. Chia sẻ cho User 2 quyền 'edit'
      final permEditor = await supabaseService.shareDocument(
        documentId: doc.id,
        targetUserId: user2Editor.id,
        permissionType: PermissionType.edit,
        currentUser: user1Owner,
      );
      expect(permEditor.permissionType, equals(PermissionType.edit));
      expect(permEditor.userId, equals(user2Editor.id));

      // 3. Chia sẻ cho User 3 quyền 'view'
      final permViewer = await supabaseService.shareDocument(
        documentId: doc.id,
        targetUserId: user3Viewer.id,
        permissionType: PermissionType.view,
        currentUser: user1Owner,
      );
      expect(permViewer.permissionType, equals(PermissionType.view));
      expect(permViewer.userId, equals(user3Viewer.id));
    });

    test('Checklist 5 & 6: Kiểm thử Phân quyền Row Level Security (RLS) với 3 tài khoản người dùng', () async {
      // BƯỚC 1: User 1 (Owner) tạo tài liệu bảo mật
      await authService.signInWithGoogle(user: user1Owner);
      final secureDoc = await supabaseService.insertDocument(
        title: 'Đề thi Mẫu Kiến trúc Phần mềm',
        description: 'Tài liệu thi cuối kỳ có đáp án chi tiết',
        courseCode: 'SE301',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/study-document-cloud.appspot.com/o/dethi_mau.pdf',
        fileName: 'dethi_mau.pdf',
        fileSize: 20480,
        currentUser: user1Owner,
      );

      // Cấp quyền: User 2 được EDIT, User 3 được VIEW
      await supabaseService.shareDocument(
        documentId: secureDoc.id,
        targetUserId: user2Editor.id,
        permissionType: PermissionType.edit,
        currentUser: user1Owner,
      );

      await supabaseService.shareDocument(
        documentId: secureDoc.id,
        targetUserId: user3Viewer.id,
        permissionType: PermissionType.view,
        currentUser: user1Owner,
      );

      // -------------------------------------------------------------
      // BƯỚC 2: Kiểm thử User 2 (EDITOR)
      // -------------------------------------------------------------
      await authService.signInWithGoogle(user: user2Editor);
      
      // User 2 xem được tài liệu
      final user2Accessible = supabaseService.getAccessibleDocuments(user2Editor.id);
      expect(user2Accessible.any((d) => d.id == secureDoc.id), isTrue);

      // User 2 CẬP NHẬT thành công vì có quyền 'edit'
      final updateOk = await supabaseService.updateDocument(
        documentId: secureDoc.id,
        newTitle: 'Đề thi Mẫu Kiến trúc Phần mềm (Đã chỉnh sửa bởi Editor)',
        newDescription: 'Bổ sung thêm 2 câu hỏi kiến trúc microservice',
        currentUserId: user2Editor.id,
      );
      expect(updateOk, isTrue);

      // User 2 CỐ TÌNH XÓA -> Phải bị RLS chặn (Chỉ Owner mới có quyền xóa)
      expect(
        () async => await supabaseService.deleteDocument(
          documentId: secureDoc.id,
          currentUserId: user2Editor.id,
        ),
        throwsA(predicate((e) => e.toString().contains('RLS VIOLATION'))),
      );

      // -------------------------------------------------------------
      // BƯỚC 3: Kiểm thử User 3 (VIEWER)
      // -------------------------------------------------------------
      await authService.signInWithGoogle(user: user3Viewer);

      // User 3 xem được tài liệu
      final user3Accessible = supabaseService.getAccessibleDocuments(user3Viewer.id);
      expect(user3Accessible.any((d) => d.id == secureDoc.id), isTrue);

      // User 3 CỐ TÌNH CẬP NHẬT -> Phải bị RLS chặn (Chỉ có quyền view)
      expect(
        () async => await supabaseService.updateDocument(
          documentId: secureDoc.id,
          newTitle: 'User 3 cố tình phá hoại đề thi',
          newDescription: 'Hack description',
          currentUserId: user3Viewer.id,
        ),
        throwsA(predicate((e) => e.toString().contains('RLS VIOLATION'))),
      );

      // User 3 CỐ TÌNH XÓA -> Phải bị RLS chặn
      expect(
        () async => await supabaseService.deleteDocument(
          documentId: secureDoc.id,
          currentUserId: user3Viewer.id,
        ),
        throwsA(predicate((e) => e.toString().contains('RLS VIOLATION'))),
      );

      // -------------------------------------------------------------
      // BƯỚC 4: Kiểm thử User 4 (UNAUTHORIZED STRANGER - Không được cấp quyền)
      // -------------------------------------------------------------
      await authService.signInWithGoogle(user: user4Stranger);

      // User 4 hoàn toàn KHÔNG NHÌN THẤY tài liệu
      final user4Accessible = supabaseService.getAccessibleDocuments(user4Stranger.id);
      expect(user4Accessible.any((d) => d.id == secureDoc.id), isFalse);

      // User 4 cố tình cập nhật -> Bị RLS chặn
      expect(
        () async => await supabaseService.updateDocument(
          documentId: secureDoc.id,
          newTitle: 'Hacker modify',
          newDescription: 'Hacker payload',
          currentUserId: user4Stranger.id,
        ),
        throwsA(predicate((e) => e.toString().contains('RLS VIOLATION'))),
      );

      // -------------------------------------------------------------
      // BƯỚC 5: Kiểm thử Thu hồi quyền (Revoke Permission)
      // -------------------------------------------------------------
      // User 1 đăng nhập lại và thu hồi quyền của User 2
      await authService.signInWithGoogle(user: user1Owner);
      final revokeOk = await supabaseService.revokePermission(
        documentId: secureDoc.id,
        targetUserId: user2Editor.id,
        currentUserId: user1Owner.id,
      );
      expect(revokeOk, isTrue);

      // Sau khi bị thu hồi, User 2 không còn quyền xem tài liệu nữa
      await authService.signInWithGoogle(user: user2Editor);
      final user2AfterRevoke = supabaseService.getAccessibleDocuments(user2Editor.id);
      expect(user2AfterRevoke.any((d) => d.id == secureDoc.id), isFalse);
    });
  });
}
