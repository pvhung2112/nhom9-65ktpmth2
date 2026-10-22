import 'dart:async';
import 'database_helper.dart';
import '../struct/studyCourse.dart';

class CourseDao {
  final AppDatabase _db;
  CourseDao({AppDatabase? database}) : _db = database ?? AppDatabase();

  Future<void> insert(Course course) async {
    await _db.insertCourse(course);
  }

  Future<void> update(Course course) async {
    await _db.updateCourse(course);
  }

  Future<void> delete(String id) async {
    await _db.deleteCourse(id);
  }

  Course? getById(String id) => _db.getCourse(id);

  List<Course> getAll() => _db.getAllCourses();

  Stream<List<Course>> watchAll() => _db.watchAllCourses();
}
