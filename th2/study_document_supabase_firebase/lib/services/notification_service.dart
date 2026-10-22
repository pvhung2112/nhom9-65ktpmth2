import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final IconData icon;
  final Color color;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    DateTime? createdAt,
    this.isRead = false,
    this.icon = Icons.notifications_rounded,
    this.color = Colors.blue,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Dịch vụ Thông báo Firebase In-App Messaging & Notification cho luồng Mượn/Trả
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif-welcome',
      title: 'Chào mừng bạn đến với Cashew TH2',
      message: 'Hệ thống đã hỗ trợ Gắn thẻ vị trí thư viện, Gợi ý tài liệu và Mượn/Trả tài liệu.',
      icon: Icons.auto_awesome_rounded,
      color: Colors.purple,
    ),
  ];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification({
    required String title,
    required String message,
    IconData icon = Icons.notifications_rounded,
    Color color = Colors.blue,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        icon: icon,
        color: color,
      ),
    );
    notifyListeners();
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      _notifications[i] = AppNotification(
        id: n.id,
        title: n.title,
        message: n.message,
        createdAt: n.createdAt,
        isRead: true,
        icon: n.icon,
        color: n.color,
      );
    }
    notifyListeners();
  }
}
