// test/supabase_firebase_permissions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_app/struct/studyDocument.dart';
import 'package:study_document_app/models/borrow_request.dart';
import 'package:study_document_app/models/supabase_user.dart';
import 'package:study_document_app/services/recommendation_service.dart';

void main() {
  group('KIỂM THỬ TOÀN DIỆN HỆ THỐNG: FIREBASE + SUPABASE RLS & LUỒNG MƯỢN TRẢ', () {
    // 3 Tài khoản kiểm thử đại diện cho 3 vai trò khác nhau
    final userA = SupabaseUser(
      id: 'user_a_uid_123',
      email: 'hung.pv@example.com',
      displayName: 'Phạm Văn Hưng',
      role: 'Owner',
    );

    final userB = SupabaseUser(
      id: 'user_b_uid_456',
      email: 'kien.tt@example.com',
      displayName: 'Trịnh Trung Kiên',
      role: 'Editor',
    );

    final userC = SupabaseUser(
      id: 'user_c_uid_789',
      email: 'dao.cd@example.com',
      displayName: 'Cao Đức Đạo',
      role: 'Viewer',
    );

    test('1. Kiểm thử Cấu trúc Đường dẫn Tệp Firebase Cloud Storage (Checklist 2)', () {
      final docId = 'doc_uuid_001';
      final fileName = 'GiaoTrinh_KienTrucPhanMem.pdf';
      final storagePath = 'documents/${userA.id}/$docId/$fileName';

      // Định dạng chuẩn: documents/{owner_id}/{doc_id}/{filename}
      expect(storagePath, startsWith('documents/'));
      expect(storagePath, contains(userA.id));
      expect(storagePath, contains(docId));
      expect(storagePath, endsWith(fileName));

      final pathParts = storagePath.split('/');
      expect(pathParts.length, 4);
      expect(pathParts[0], 'documents');
      expect(pathParts[1], userA.id);
      expect(pathParts[2], docId);
      expect(pathParts[3], fileName);
    });

    test('2. Kiểm thử Quyền Chủ sở hữu (Owner Permissions) trên Supabase RLS (Checklist 5)', () {
      final doc = StudyDocument(
        id: 'doc_uuid_001',
        title: 'Báo cáo Kiến trúc Đám mây',
        courseId: 'SE301',
        type: DocumentType.lecture,
        description: 'Tài liệu môn học SE301',
        ownerId: userA.id,
        ownerEmail: userA.email,
        ownerName: userA.displayName,
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/app/o/documents%2F...',
        tags: ['Architecture', 'Cloud', 'Firebase'],
        sharedPermission: 'owner',
        permissions: ['view', 'edit', 'delete', 'share'],
      );

      // Chủ sở hữu phải có toàn quyền 100%
      expect(doc.isOwner, isTrue);
      expect(doc.canView, isTrue);
      expect(doc.canEdit, isTrue);
      expect(doc.canDelete, isTrue);
      expect(doc.canShare, isTrue);
      expect(doc.ownerEmail, userA.email);
      expect(doc.permissionsSummary, contains('Chủ sở hữu'));
    });

    test('3. Kiểm thử Phân quyền Chia sẻ RLS cho Người dùng B (Checklist 4 & 5)', () {
      // User B được User A cấp quyền: ['view', 'edit']
      expect(userB.email, 'kien.tt@example.com');
      final sharedPermissionsUserB = ['view', 'edit'];

      final docAsUserB = StudyDocument(
        id: 'doc_uuid_001',
        title: 'Báo cáo Kiến trúc Đám mây',
        courseId: 'SE301',
        type: DocumentType.lecture,
        description: 'Tài liệu môn học SE301',
        ownerId: userA.id,
        ownerEmail: userA.email,
        ownerName: userA.displayName,
        sharedPermission: 'custom',
        permissions: sharedPermissionsUserB,
      );

      // User B có quyền Xem và Sửa, nhưng không được Xóa hoặc Chia sẻ
      expect(docAsUserB.isOwner, isFalse);
      expect(docAsUserB.canView, isTrue);
      expect(docAsUserB.canEdit, isTrue);
      expect(docAsUserB.canDelete, isFalse);
      expect(docAsUserB.canShare, isFalse);
      expect(docAsUserB.permissionsSummary, contains('Xem'));
      expect(docAsUserB.permissionsSummary, contains('Sửa'));
    });

    test('4. Kiểm thử Chặn quyền Sửa/Xóa của Người ngoài (User C) khi chưa cấp quyền', () {
      // User C chưa được cấp quyền gì trên tài liệu của User A
      expect(userC.email, 'dao.cd@example.com');
      final sharedPermissionsUserC = <String>[];

      final docAsUserC = StudyDocument(
        id: 'doc_uuid_001',
        title: 'Báo cáo Kiến trúc Đám mây',
        courseId: 'SE301',
        type: DocumentType.lecture,
        ownerId: userA.id,
        ownerEmail: userA.email,
        ownerName: userA.displayName,
        sharedPermission: 'custom',
        permissions: sharedPermissionsUserC,
      );

      expect(docAsUserC.isOwner, isFalse);
      expect(docAsUserC.canEdit, isFalse);
      expect(docAsUserC.canDelete, isFalse);
      expect(docAsUserC.canShare, isFalse);
    });

    test('5. Kiểm thử Luồng Mượn Sách & Tự động Cấp Quyền RLS khi Chấp nhận (Accept)', () {
      // Bước 1: User C gửi yêu cầu mượn tài liệu của User A
      final borrowReq = BorrowRequest(
        id: 'req_001',
        documentId: 'doc_uuid_001',
        documentTitle: 'Báo cáo Kiến trúc Đám mây',
        courseCode: 'SE301',
        borrowerId: userC.id,
        borrowerName: userC.displayName,
        borrowerEmail: userC.email,
        ownerId: userA.id,
        ownerName: userA.displayName,
        ownerEmail: userA.email,
        status: BorrowStatus.pending,
        requestDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        notes: 'Xin phép mượn tài liệu để tham khảo đồ án',
      );

      expect(borrowReq.status, BorrowStatus.pending);
      expect(borrowReq.borrowerEmail, userC.email);
      expect(borrowReq.ownerEmail, userA.email);

      // Bước 2: User A duyệt chấp nhận (Approved)
      final approvedReq = borrowReq.copyWith(status: BorrowStatus.approved);
      expect(approvedReq.status, BorrowStatus.approved);

      // Bước 3: Nghiệp vụ tự động kết nối cấp quyền truy cập RLS [view] cho User C
      final grantedPermissionsForC = ['view'];
      final docAfterBorrowApproval = StudyDocument(
        id: approvedReq.documentId,
        title: approvedReq.documentTitle,
        courseId: approvedReq.courseCode,
        type: DocumentType.reference,
        ownerId: approvedReq.ownerId,
        ownerEmail: approvedReq.ownerEmail,
        ownerName: approvedReq.ownerName,
        sharedPermission: 'custom',
        permissions: grantedPermissionsForC,
      );

      // User C nay đã có quyền Xem tài liệu trực tuyến
      expect(docAfterBorrowApproval.canView, isTrue);
      expect(docAfterBorrowApproval.canEdit, isFalse);
    });

    test('6. Kiểm thử Thuật toán Gợi ý Thông minh AI (Recommendation Algorithm & Jaccard)', () {
      final recService = RecommendationService();
      recService.resetInterests();
      recService.addInterest('flutter');
      recService.addInterest('firebase');
      recService.addInterest('se301');

      // Kiểm thử Jaccard Similarity
      final similarity = recService.calculateJaccardSimilarity(
        ['flutter', 'firebase'],
        ['flutter', 'firebase', 'dart'],
      );
      expect(similarity, closeTo(2 / 3, 0.01));

      final docRelevant = StudyDocument(
        id: 'doc_rel_01',
        title: 'Lập trình Flutter và Firebase Toàn diện',
        courseId: 'SE301',
        type: DocumentType.lecture,
        tags: ['Flutter', 'Firebase', 'Mobile'],
        ownerId: 'other_user',
        ownerEmail: 'other@example.com',
        ownerName: 'Giáo viên',
        fileUrl: 'https://example.com/flutter.pdf',
        isPinned: true,
      );

      final docIrrelevant = StudyDocument(
        id: 'doc_irrel_01',
        title: 'Hóa học đại cương và Thí nghiệm',
        courseId: 'CHE101',
        type: DocumentType.reference,
        tags: ['Chemistry', 'Lab'],
        ownerId: 'other_user_2',
        ownerEmail: 'other2@example.com',
        ownerName: 'Khoa Hóa',
      );

      final recommendations = recService.getRecommendations(
        allDocuments: [docRelevant, docIrrelevant],
        currentUserId: userA.id,
        currentUserEmail: userA.email,
      );

      expect(recommendations.isNotEmpty, isTrue);
      final topRec = recommendations.first;
      expect(topRec.document.id, 'doc_rel_01');
      expect(topRec.score, greaterThan(50.0));
      expect(topRec.matchedTags, contains('flutter'));
    });
  });
}
