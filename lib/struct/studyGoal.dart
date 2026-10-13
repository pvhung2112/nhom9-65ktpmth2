class StudyGoal {
  final String id;
  final String title;
  final int targetCount;
  final int completedCount;
  final DateTime deadline;
  final String? courseId;

  const StudyGoal({
    required this.id,
    required this.title,
    required this.targetCount,
    this.completedCount = 0,
    required this.deadline,
    this.courseId,
  });

  double get progressPercentage {
    if (targetCount <= 0) return 0.0;
    final progress = completedCount / targetCount;
    return progress > 1.0 ? 1.0 : progress;
  }

  bool get isAchieved => completedCount >= targetCount;

  StudyGoal copyWith({
    String? id,
    String? title,
    int? targetCount,
    int? completedCount,
    DateTime? deadline,
    String? courseId,
  }) {
    return StudyGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetCount: targetCount ?? this.targetCount,
      completedCount: completedCount ?? this.completedCount,
      deadline: deadline ?? this.deadline,
      courseId: courseId ?? this.courseId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_count': targetCount,
      'completed_count': completedCount,
      'deadline': deadline.toIso8601String(),
      'course_id': courseId,
    };
  }

  factory StudyGoal.fromMap(Map<String, dynamic> map) {
    return StudyGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      targetCount: (map['target_count'] ?? map['targetCount'] ?? 1) as int,
      completedCount: (map['completed_count'] ?? map['completedCount'] ?? 0) as int,
      deadline: DateTime.parse(map['deadline'] as String),
      courseId: map['course_id'] ?? map['courseId'],
    );
  }
}
