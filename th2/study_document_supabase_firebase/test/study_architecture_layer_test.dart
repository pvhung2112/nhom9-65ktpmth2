import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_app/struct/studyDocument.dart';
import 'package:study_document_app/struct/studyCourse.dart';
import 'package:study_document_app/database/database_helper.dart';
import 'package:study_document_app/database/study_document_dao.dart';
import 'package:study_document_app/database/study_course_dao.dart';

void main() {
  group('Checklist 4 - Kiểm thử tính đúng đắn của việc phân tách logic kiến trúc', () {
    late AppDatabase database;
    late DocumentDao documentDao;
    late CourseDao courseDao;

    setUp(() {
      database = AppDatabase();
      documentDao = DocumentDao(database: database);
      courseDao = CourseDao(database: database);
    });

    test('1. Kiểm thử tính tách biệt của tầng Data Access (DAO Layer)', () async {
      final course = Course(
        id: 'arch-c1',
        code: 'TEST101',
        name: 'Kiến trúc thử nghiệm',
      );
      await courseDao.insert(course);

      final doc = StudyDocument(
        id: 'arch-doc-1',
        title: 'Tài liệu kiến trúc',
        courseId: 'arch-c1',
        type: DocumentType.lecture,
      );
      await documentDao.insert(doc);

      expect(courseDao.getById('arch-c1')!.code, 'TEST101');
      expect(documentDao.getById('arch-doc-1')!.title, 'Tài liệu kiến trúc');
    });

    test('2. Kiểm thử cơ chế Reactive Streams (tương tự Drift .watch() trong Cashew)', () async {
      final stream = documentDao.watchAll();
      final streamExpectation = expectLater(
        stream,
        emitsThrough(predicate<List<StudyDocument>>((list) {
          return list.any((d) => d.id == 'reactive-doc-1');
        })),
      );

      await documentDao.insert(StudyDocument(
        id: 'reactive-doc-1',
        title: 'Tài liệu kiểm thử Reactive Stream',
        courseId: 'c1',
        type: DocumentType.lecture,
      ));

      await streamExpectation;
    });

    test('3. Kiểm thử tính toàn vẹn dữ liệu quan hệ (Cascade Delete)', () async {
      final tempCourse = Course(
        id: 'cascade-c1',
        code: 'TEMP999',
        name: 'Môn tạm',
      );
      await courseDao.insert(tempCourse);

      final tempDoc = StudyDocument(
        id: 'cascade-doc-1',
        title: 'Tài liệu của môn tạm',
        courseId: 'cascade-c1',
        type: DocumentType.lecture,
      );
      await documentDao.insert(tempDoc);

      expect(documentDao.getById('cascade-doc-1'), isNotNull);

      await courseDao.delete('cascade-c1');
      expect(documentDao.getById('cascade-doc-1'), isNull);
    });

    test('4. Kiểm thử chiến lược Sao lưu và Phục hồi (Backup & Restore Strategy)', () async {
      final doc = StudyDocument(id: 'backup-doc-1', title: 'Test Backup Document', courseId: 'c1', type: DocumentType.lecture);
      await documentDao.insert(doc);
      final backupJson = database.exportBackupJson();
      expect(backupJson.isNotEmpty, isTrue);
      expect(backupJson.contains('SE301'), isTrue);

      await database.restoreBackupJson(backupJson);
      expect(documentDao.getAll().isNotEmpty, isTrue);
    });
  });
}
