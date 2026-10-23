import 'dart:async';
import 'dart:convert';
import '../struct/studyDocument.dart';
import '../struct/studyCourse.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  AppDatabase._internal() {
    _seedDefaultData();
  }

  final Map<String, StudyDocument> _documents = {};
  final Map<String, Course> _courses = {};

  final _docsStreamController = StreamController<List<StudyDocument>>.broadcast();
  final _coursesStreamController = StreamController<List<Course>>.broadcast();

  Stream<List<StudyDocument>> watchAllDocuments() => _docsStreamController.stream;
  Stream<List<Course>> watchAllCourses() => _coursesStreamController.stream;

  void _notifyDocuments() {
    _docsStreamController.add(getAllDocuments());
  }

  void _notifyCourses() {
    _coursesStreamController.add(getAllCourses());
  }


  void _seedDefaultData() {
    if (_courses.isEmpty) {
      final c1 = Course(id: 'c1', code: 'SE301', name: 'Kiến trúc Phần mềm', lecturer: 'TS. Nguyễn Văn A', credits: 4, colorValue: 0xFF1E88E5);
      final c2 = Course(id: 'c2', code: 'CS402', name: 'Công nghệ Web & Dịch vụ mạng', lecturer: 'ThS. Trần Thị B', credits: 3, colorValue: 0xFF43A047);
      final c3 = Course(id: 'c3', code: 'CS205', name: 'Cấu trúc Dữ liệu & Giải thuật', lecturer: 'TS. Lê Hoàng C', credits: 3, colorValue: 0xFFFB8C00);

      _courses[c1.id] = c1;
      _courses[c2.id] = c2;
      _courses[c3.id] = c3;
    }

    // Không dùng dữ liệu tài liệu tĩnh: Dữ liệu được đồng bộ trực tiếp từ Google Firebase Cloud Firestore!

  }

  // --- Document Operations ---
  Future<void> insertDocument(StudyDocument doc) async {
    _documents[doc.id] = doc;
    _notifyDocuments();
  }

  Future<void> updateDocument(StudyDocument doc) async {
    _documents[doc.id] = doc;
    _notifyDocuments();
  }

  Future<void> deleteDocument(String id) async {
    _documents.remove(id);
    _notifyDocuments();
  }

  Future<void> clearAllDocuments() async {
    _documents.clear();
    _notifyDocuments();
  }

  StudyDocument? getDocument(String id) => _documents[id];

  List<StudyDocument> getAllDocuments() {
    final list = _documents.values.toList();
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  // --- Course Operations ---
  Future<void> insertCourse(Course course) async {
    _courses[course.id] = course;
    _notifyCourses();
  }

  Future<void> updateCourse(Course course) async {
    _courses[course.id] = course;
    _notifyCourses();
  }

  Future<void> deleteCourse(String id) async {
    _courses.remove(id);
    _documents.removeWhere((_, doc) => doc.courseId == id);
    _notifyCourses();
    _notifyDocuments();
  }

  Course? getCourse(String id) => _courses[id];

  List<Course> getAllCourses() => _courses.values.toList();

  // --- Goal Operations ---




  Future<void> restoreBackupJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    _courses.clear();
    _documents.clear();

    if (data['courses'] != null) {
      for (var c in data['courses']) {
        final course = Course.fromMap(c);
        _courses[course.id] = course;
      }
    }
    if (data['documents'] != null) {
      for (var d in data['documents']) {
        final doc = StudyDocument.fromMap(d);
        _documents[doc.id] = doc;
      }
    }
    _notifyCourses();
    _notifyDocuments();
  }
}