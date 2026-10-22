import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_app/struct/studyDocument.dart';
import 'package:study_document_app/struct/studySyncClient.dart';
import 'package:study_document_app/database/database_helper.dart';
import 'package:study_document_app/database/study_document_dao.dart';

void main() {
  group('Checklist 4 - Kiểm thử cơ chế Sync Client Local-First (tương tự Cashew)', () {
    late AppDatabase database;
    late DocumentDao documentDao;
    late StudySyncClient syncClient;

    setUp(() {
      database = AppDatabase();
      documentDao = DocumentDao(database: database);
      syncClient = StudySyncClient(documentDao: documentDao);
    });

    test('1. Kiểm thử hàng đợi đồng bộ khi có tài liệu mới tạo offline', () async {
      final doc = StudyDocument(
        id: 'sync-test-1',
        title: 'Tài liệu tạo khi mất mạng',
        courseId: 'c1',
        type: DocumentType.exercise,
        isSynced: false,
      );
      await documentDao.insert(doc);

      final pendingCount = await syncClient.getPendingSyncCount();
      expect(pendingCount, greaterThanOrEqualTo(1));
    });

    test('2. Kiểm thử tiến trình đồng bộ 2 chiều lên Cloud Server', () async {
      final doc = StudyDocument(
        id: 'sync-test-2',
        title: 'Tài liệu cần đẩy lên đám mây',
        courseId: 'c2',
        type: DocumentType.lecture,
      );
      await documentDao.insert(doc);

      final result = await syncClient.syncWithCloud(
        uploadMock: (docs) async => true,
      );

      expect(result.success, isTrue);
      final syncedDoc = documentDao.getById('sync-test-2');
      expect(syncedDoc!.isSynced, isTrue);
    });
    test('3. Kiểm thử cơ chế Pull từ Cloud về máy khi CSDL cục bộ bị trống', () async {
      final cloudDocs = [
        StudyDocument(
          id: 'cloud-pull-1',
          title: 'Tài liệu kéo từ Firestore',
          courseId: 'c1',
          type: DocumentType.reference,
          isSynced: true,
        ),
      ];

      final pulledCount = await syncClient.pullFromCloud(
        downloadMock: () async => cloudDocs,
      );

      expect(pulledCount, equals(1));
      final pulledDoc = documentDao.getById('cloud-pull-1');
      expect(pulledDoc, isNotNull);
      expect(pulledDoc!.title, equals('Tài liệu kéo từ Firestore'));
      expect(pulledDoc.isSynced, isTrue);
    });
  });
}
