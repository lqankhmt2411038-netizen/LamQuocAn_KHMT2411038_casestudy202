import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import 'user.dart';

class TaskActivity {
  final String id;
  final AppUser? user;
  final String action;
  final Map<String, dynamic> details;
  final DateTime? createdAt;

  const TaskActivity({
    required this.id,
    this.user,
    required this.action,
    this.details = const {},
    this.createdAt,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> json) => TaskActivity(
        id: (json['id'] ?? '').toString(),
        user: json['user'] is Map<String, dynamic> ? AppUser.fromJson(json['user'] as Map<String, dynamic>) : null,
        action: (json['action'] ?? '').toString(),
        details: json['details'] is Map<String, dynamic> ? json['details'] as Map<String, dynamic> : {},
        createdAt: DateFormatter.parse(json['createdAt']),
      );

  String describe() {
    final who = user?.fullName ?? 'Ai đó';
    switch (action) {
      case 'created':
        return '$who đã tạo công việc';
      case 'updated':
        final changes = (details['changes'] as List? ?? [])
            .map((c) => (c as Map)['label']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .join(', ');
        return '$who đã cập nhật${changes.isEmpty ? '' : ' ($changes)'}';
      case 'status_changed':
        final to = AppConstants.statusLabels[details['to']] ?? '${details['to']}';
        return '$who đổi trạng thái thành "$to"';
      case 'assigned':
        return '$who đã giao việc cho ${details['email'] ?? 'một người'}';
      case 'unassigned':
        return '$who đã hủy giao việc cho một người';
      case 'primary_changed':
        return '$who đã đổi người phụ trách chính';
      case 'shared':
        final p = AppConstants.permissionLabels[details['permission']] ?? '';
        return '$who đã chia sẻ cho ${details['email'] ?? 'một người'} ($p)';
      case 'share_permission_changed':
        return '$who đã đổi quyền chia sẻ';
      case 'share_revoked':
        return '$who đã thu hồi quyền chia sẻ';
      default:
        return '$who: $action';
    }
  }
}
