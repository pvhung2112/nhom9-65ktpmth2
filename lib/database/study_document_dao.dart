import 'dart:async';
import 'database_helper.dart';
import '../struct/studyDocument.dart';

/// Data Access Object (DAO) quản lý truy xuất dữ liệu tài liệu học tập
class DocumentDao {
  final AppDatabase _db;
  DocumentDao({AppDatabase? database}) : _db = database ?? AppDatabase();

  Future<void> insert(StudyDocument doc) async {
    final newDoc = doc.copyWith(isSynced: false);
    await _db.insertDocument(newDoc);
  }

  Future<void> update(StudyDocument doc) async {
    final updatedDoc = doc.copyWith(isSynced: false, updatedAt: DateTime.now());
    await _db.updateDocument(updatedDoc);
  }

  Future<void> delete(String id) async {
    await _db.deleteDocument(id);
  }

  StudyDocument? getById(String id) => _db.getDocument(id);

  List<StudyDocument> getAll({DocumentType? type, String? courseId}) {
    if (type == null && (courseId == null || courseId.isEmpty || courseId == 'all')) {
      return _db.getAllDocuments();
    }
    return filterDocuments(type: type, courseId: courseId);
  }

  Stream<List<StudyDocument>> watchAll({DocumentType? type, String? courseId}) {
    return watchFiltered(type: type, courseId: courseId);
  }

  List<StudyDocument> filterDocuments({
    String? query,
    String? courseId,
    DocumentType? type,
    DocumentStatus? status,
    bool? isPinned,
  }) {
    var list = _db.getAllDocuments();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((d) {
        return d.title.toLowerCase().contains(q) ||
            d.description.toLowerCase().contains(q) ||
            d.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    if (courseId != null && courseId.isNotEmpty && courseId != 'all') {
      list = list.where((d) => d.courseId == courseId).toList();
    }

    if (type != null) {
      list = list.where((d) => d.type == type).toList();
    }

    if (status != null) {
      list = list.where((d) => d.status == status).toList();
    }

    if (isPinned != null) {
      list = list.where((d) => d.isPinned == isPinned).toList();
    }

    return list;
  }

  Stream<List<StudyDocument>> watchFiltered({
    String? query,
    String? courseId,
    DocumentType? type,
    DocumentStatus? status,
    bool? isPinned,
  }) {
    return _db.watchAllDocuments().map((_) {
      return filterDocuments(
        query: query,
        courseId: courseId,
        type: type,
        status: status,
        isPinned: isPinned,
      );
    });
  }

  List<StudyDocument> getUnsyncedDocuments() {
    return _db.getAllDocuments().where((d) => !d.isSynced).toList();
  }

  Future<void> saveFromCloud(StudyDocument doc) async {
    final syncedDoc = doc.copyWith(isSynced: true);
    await _db.insertDocument(syncedDoc);
  }

  Future<void> markAsSynced(List<String> ids) async {
    for (var id in ids) {
      final doc = _db.getDocument(id);
      if (doc != null) {
        await _db.updateDocument(doc.copyWith(isSynced: true));
      }
    }
  }
}
