class Course {
  final String id;
  final String code;
  final String name;
  final String lecturer;
  final int credits;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.code,
    required this.name,
    this.lecturer = '',
    this.credits = 3,
    this.colorValue = 0xFF1E88E5,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Course copyWith({
    String? id,
    String? code,
    String? name,
    String? lecturer,
    int? credits,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      credits: credits ?? this.credits,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'lecturer': lecturer,
      'credits': credits,
      'color_value': colorValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      lecturer: (map['lecturer'] ?? '') as String,
      credits: (map['credits'] ?? 3) as int,
      colorValue: (map['color_value'] ?? map['colorValue'] ?? 0xFF1E88E5) as int,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
    );
  }
}
