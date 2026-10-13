import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_app/struct/studyDocument.dart';
import 'package:study_document_app/database/database_helper.dart';
import 'package:study_document_app/database/study_document_dao.dart';

void main() {
  group('Checklist 3 - Kiểm thử chức năng cốt lõi (CRUD & Search/Filter)', () {
    late AppDatabase database;
    late DocumentDao documentDao;

    setUp(() {
      database = AppDatabase();
      documentDao = DocumentDao(database: database);
    });

    test('1. Thêm tài liệu học tập mới vào hệ thống', () async {
      final doc = StudyDocument(
        id: 'test-crud-1',
        title: 'Giáo trình Kiến trúc Microservices',
        courseId: 'c1',
        type: DocumentType.reference,
        status: DocumentStatus.todo,
        description: 'Tài liệu tham khảo chuyên sâu về KTPM',
        tags: ['KTPM', 'Microservices'],
      );

      await documentDao.insert(doc);
      final retrieved = documentDao.getById('test-crud-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Giáo trình Kiến trúc Microservices');
      expect(retrieved.type, DocumentType.reference);
      expect(retrieved.status, DocumentStatus.todo);
    });

    test('2. Cập nhật thông tin và trạng thái tài liệu học tập', () async {
      final doc = StudyDocument(
        id: 'test-crud-2',
        title: 'Bài tập tuần 3: Thiết kế DAO',
        courseId: 'c1',
        type: DocumentType.exercise,
        status: DocumentStatus.inProgress,
      );
      await documentDao.insert(doc);

      final updated = doc.copyWith(
        status: DocumentStatus.completed,
        description: 'Đã hoàn thành và nộp trên hệ thống',
      );
      await documentDao.update(updated);

      final retrieved = documentDao.getById('test-crud-2');
      expect(retrieved!.status, DocumentStatus.completed);
      expect(retrieved.description, 'Đã hoàn thành và nộp trên hệ thống');
    });

    test('3. Xóa tài liệu học tập khỏi hệ thống', () async {
      final doc = StudyDocument(
        id: 'test-crud-3',
        title: 'Tài liệu nháp cần xóa',
        courseId: 'c2',
        type: DocumentType.lecture,
      );
      await documentDao.insert(doc);
      expect(documentDao.getById('test-crud-3'), isNotNull);

      await documentDao.delete('test-crud-3');
      expect(documentDao.getById('test-crud-3'), isNull);
    });

    test('4. Tìm kiếm tài liệu theo từ khóa (Search)', () async {
      final docA = StudyDocument(
        id: 'search-1',
        title: 'Slide bài giảng Flutter State Management',
        courseId: 'c2',
        type: DocumentType.lecture,
        tags: ['Flutter', 'State'],
      );
      final docB = StudyDocument(
        id: 'search-2',
        title: 'Bài tập SQL Server',
        courseId: 'c3',
        type: DocumentType.exercise,
        tags: ['SQL'],
      );
      await documentDao.insert(docA);
      await documentDao.insert(docB);

      final searchResults = documentDao.filterDocuments(query: 'Flutter');
      expect(searchResults.any((d) => d.id == 'search-1'), isTrue);
      expect(searchResults.any((d) => d.id == 'search-2'), isFalse);
    });

    test('5. Lọc tài liệu đa tiêu chí (Filter theo Môn học và Loại tài liệu)', () async {
      final results = documentDao.filterDocuments(
        courseId: 'c1',
        type: DocumentType.exercise,
      );

      for (var d in results) {
        expect(d.courseId, 'c1');
        expect(d.type, DocumentType.exercise);
      }
    });
  });
}
