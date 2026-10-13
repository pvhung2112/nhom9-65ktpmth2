import 'dart:convert';

class SupabaseUser {
  final String id;
  final String email;
  final String displayName;
  final String avatarUrl;
  final DateTime createdAt;

  SupabaseUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };

  factory SupabaseUser.fromMap(Map<String, dynamic> map) => SupabaseUser(
    id: map['id'] ?? '',
    email: map['email'] ?? '',
    displayName: map['display_name'] ?? '',
    avatarUrl: map['avatar_url'] ?? '',
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
  factory SupabaseUser.fromJson(String source) => SupabaseUser.fromMap(jsonDecode(source));
}
