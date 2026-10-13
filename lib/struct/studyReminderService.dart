import 'studyDocument.dart';

class StudyReminderService {
  static List<StudyDocument> getOverdueDocuments(List<StudyDocument> documents) {
    final now = DateTime.now();
    return documents.where((doc) {
      return doc.deadline != null &&
          doc.deadline!.isBefore(now) &&
          doc.status != DocumentStatus.completed;
    }).toList();
  }

  static List<StudyDocument> getUpcomingDeadlines(
    List<StudyDocument> documents, {
    int withinDays = 7,
  }) {
    final now = DateTime.now();
    final threshold = now.add(Duration(days: withinDays));
    return documents.where((doc) {
      return doc.deadline != null &&
          doc.deadline!.isAfter(now) &&
          doc.deadline!.isBefore(threshold) &&
          doc.status != DocumentStatus.completed;
    }).toList();
  }
}
