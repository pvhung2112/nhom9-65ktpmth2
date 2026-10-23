import '../models/tag_model.dart';
import '../models/storage_location_model.dart';
import 'web_storage.dart';
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
  final Map<String, DocumentTag> _tags = {};
  final Map<String, StorageLocationItem> _storageLocations = {};

  final _docsStreamController = StreamController<List<StudyDocument>>.broadcast();
  final _coursesStreamController = StreamController<List<Course>>.broadcast();
  final _tagsStreamController = StreamController<List<DocumentTag>>.broadcast();
  final _locationsStreamController = StreamController<List<StorageLocationItem>>.broadcast();

  Stream<List<StudyDocument>> watchAllDocuments() => _docsStreamController.stream;
  Stream<List<Course>> watchAllCourses() => _coursesStreamController.stream;
  Stream<List<DocumentTag>> watchAllTags() => _tagsStreamController.stream;
  Stream<List<StorageLocationItem>> watchAllStorageLocations() => _locationsStreamController.stream;

  void _notifyDocuments() {
    _docsStreamController.add(getAllDocuments());
  }

  void _notifyCourses() {
    _coursesStreamController.add(getAllCourses());
  }

  void _notifyTags() {
    _tagsStreamController.add(getAllTags());
  }

  void _notifyStorageLocations() {
    _locationsStreamController.add(getAllStorageLocations());
  }


  void _saveDocumentsCache() {
    try {
      final list = _documents.values.map((d) => d.toMap()).toList();
      saveLocalCache('cached_study_documents', jsonEncode(list));
    } catch (_) {}
  }

  void _loadDocumentsFromCache() {
    try {
      final cached = getLocalCache('cached_study_documents');
      if (cached != null && cached.isNotEmpty) {
        final list = jsonDecode(cached) as List<dynamic>;
        for (var item in list) {
          final doc = StudyDocument.fromMap(Map<String, dynamic>.from(item));
          _documents[doc.id] = doc;
        }
      }
    } catch (_) {}
  }

  void _saveTagsAndLocationsCache() {
    try {
      final tagList = _tags.values.map((t) => t.toMap()).toList();
      saveLocalCache('cached_tags', jsonEncode(tagList));
      final locList = _storageLocations.values.map((l) => l.toMap()).toList();
      saveLocalCache('cached_storage_locations', jsonEncode(locList));
    } catch (_) {}
  }

  void _loadTagsAndLocationsFromCache() {
    try {
      final cachedTags = getLocalCache('cached_tags');
      if (cachedTags != null && cachedTags.isNotEmpty) {
        final list = jsonDecode(cachedTags) as List<dynamic>;
        for (var item in list) {
          final t = DocumentTag.fromMap(Map<String, dynamic>.from(item));
          _tags[t.id] = t;
        }
      }
      final cachedLocs = getLocalCache('cached_storage_locations');
      if (cachedLocs != null && cachedLocs.isNotEmpty) {
        final list = jsonDecode(cachedLocs) as List<dynamic>;
        for (var item in list) {
          final l = StorageLocationItem.fromMap(Map<String, dynamic>.from(item));
          _storageLocations[l.id] = l;
        }
      }
    } catch (_) {}
  }

  void _seedDefaultData() {
    _loadDocumentsFromCache();
    _loadTagsAndLocationsFromCache();

    final isInitialized = getLocalCache('app_seed_initialized');
    if (isInitialized != 'true') {
      saveLocalCache('app_seed_initialized', 'true');
      // Khởi tạo thẻ Tag mặc định nếu chưa có
    if (_tags.isEmpty) {
      final defaultTags = [
        DocumentTag(id: 'tag_csdl', name: 'Cơ sở dữ liệu', color: '#1E88E5'),
        DocumentTag(id: 'tag_giaotrinh', name: 'Giáo trình', color: '#43A047'),
        DocumentTag(id: 'tag_laptrinh', name: 'Lập trình', color: '#FB8C00'),
        DocumentTag(id: 'tag_java', name: 'Java', color: '#E53935'),
        DocumentTag(id: 'tag_doan', name: 'Đồ án', color: '#8E24AA'),
        DocumentTag(id: 'tag_baocao', name: 'Báo cáo', color: '#00ACC1'),
        DocumentTag(id: 'tag_ktpm', name: 'KTPM', color: '#D81B60'),
      ];
      for (var t in defaultTags) {
        _tags[t.id] = t;
      }
    }

    // Khởi tạo vị trí kho mặc định nếu chưa có
    if (_storageLocations.isEmpty) {
      final defaultLocations = [
        StorageLocationItem(
          id: 'loc_toa_a',
          name: 'Tòa A - Phòng A305',
          building: 'Tòa A',
          floor: 'Tầng 3',
          room: 'Phòng A305',
          cabinet: 'Tủ số 2',
          shelf: 'Ngăn số 3',
          latitude: 10.8708,
          longitude: 106.8025,
        ),
        StorageLocationItem(
          id: 'loc_thu_vien_h1',
          name: 'Thư viện Trung tâm - Tòa H1',
          building: 'Tòa H1',
          floor: 'Tầng 2',
          room: 'Phòng Đọc SE',
          cabinet: 'Kệ A3',
          shelf: 'Ngăn số 2',
          latitude: 10.8700,
          longitude: 106.8030,
        ),
        StorageLocationItem(
          id: 'loc_lab_302',
          name: 'Tòa B - Phòng Lab 302',
          building: 'Tòa B',
          floor: 'Tầng 3',
          room: 'Lab 302',
          cabinet: 'Tủ số 1',
          shelf: 'Ngăn số 2',
          latitude: 10.8712,
          longitude: 106.8045,
        ),
        StorageLocationItem(
          id: 'loc_kho_c',
          name: 'Tòa C - Kho Lưu trữ',
          building: 'Tòa C',
          floor: 'Tầng 1',
          room: 'Kho C01',
          cabinet: 'Tủ hồ sơ 04',
          shelf: 'Ngăn số 1',
          latitude: 10.8695,
          longitude: 106.8018,
        ),
      ];
      for (var l in defaultLocations) {
        _storageLocations[l.id] = l;
      }
    }

    }

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
    _saveDocumentsCache();
    _notifyDocuments();
  }

  Future<void> updateDocument(StudyDocument doc) async {
    _documents[doc.id] = doc;
    _saveDocumentsCache();
    _notifyDocuments();
  }

  Future<void> deleteDocument(String id) async {
    _documents.remove(id);
    _saveDocumentsCache();
    _notifyDocuments();
  }

  Future<void> clearAllDocuments() async {
    _documents.clear();
    _saveDocumentsCache();
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

  // --- Tag Operations ---
  List<DocumentTag> getAllTags() => _tags.values.toList();

  Future<void> replaceTags(List<DocumentTag> list) async {
    _tags.clear();
    for (var t in list) {
      _tags[t.id] = t;
    }
    _saveTagsAndLocationsCache();
    _notifyTags();
  }

  Future<void> clearAllTags() async {
    _tags.clear();
    _saveTagsAndLocationsCache();
    _notifyTags();
  }

  Future<void> insertTag(DocumentTag tag) async {
    _tags[tag.id] = tag;
    _saveTagsAndLocationsCache();
    _notifyTags();
  }

  Future<void> deleteTag(String id) async {
    _tags.remove(id);
    _saveTagsAndLocationsCache();
    _notifyTags();
  }

  // --- Storage Location Operations ---
  List<StorageLocationItem> getAllStorageLocations() => _storageLocations.values.toList();
  StorageLocationItem? getStorageLocation(String id) => _storageLocations[id];

  Future<void> replaceStorageLocations(List<StorageLocationItem> list) async {
    _storageLocations.clear();
    for (var l in list) {
      _storageLocations[l.id] = l;
    }
    _saveTagsAndLocationsCache();
    _notifyStorageLocations();
  }

  Future<void> clearAllStorageLocations() async {
    _storageLocations.clear();
    _saveTagsAndLocationsCache();
    _notifyStorageLocations();
  }

  Future<void> insertStorageLocation(StorageLocationItem loc) async {
    _storageLocations[loc.id] = loc;
    _saveTagsAndLocationsCache();
    _notifyStorageLocations();
  }

  Future<void> deleteStorageLocation(String id) async {
    _storageLocations.remove(id);
    _saveTagsAndLocationsCache();
    _notifyStorageLocations();
  }

}
