import '../utils/date_formatter.dart';
import 'user.dart';

class TaskShare {
  final String id;
  final String taskId;
  final AppUser user;
  final String permission;
  final AppUser? sharedBy;
  final DateTime? createdAt;

  const TaskShare({
    required this.id,
    required this.taskId,
    required this.user,
    required this.permission,
    this.sharedBy,
    this.createdAt,
  });

  factory TaskShare.fromJson(Map<String, dynamic> json) => TaskShare(
        id: (json['id'] ?? '').toString(),
        taskId: (json['taskId'] ?? '').toString(),
        user: AppUser.fromJson((json['user'] ?? <String, dynamic>{}) as Map<String, dynamic>),
        permission: (json['permission'] ?? 'viewer').toString(),
        sharedBy: json['sharedBy'] is Map<String, dynamic>
            ? AppUser.fromJson(json['sharedBy'] as Map<String, dynamic>)
            : null,
        createdAt: DateFormatter.parse(json['createdAt']),
      );
}
