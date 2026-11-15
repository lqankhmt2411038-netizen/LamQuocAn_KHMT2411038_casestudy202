import '../utils/date_formatter.dart';

/// Đặt tên AppNotification để không trùng với class Notification của Flutter.
class AppNotification {
  final String id;
  final String? taskId;
  final String type;
  final String title;
  final String message;
  bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    this.taskId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: (json['id'] ?? '').toString(),
        taskId: json['taskId']?.toString(),
        type: (json['type'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        isRead: json['isRead'] == true,
        createdAt: DateFormatter.parse(json['createdAt']),
      );
}
