import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import 'user.dart';

class TaskPermissions {
  final bool view;
  final bool updateStatus;
  final bool edit;
  final bool delete;
  final bool manage;

  const TaskPermissions({
    this.view = false,
    this.updateStatus = false,
    this.edit = false,
    this.delete = false,
    this.manage = false,
  });

  factory TaskPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TaskPermissions();
    return TaskPermissions(
      view: json['view'] == true,
      updateStatus: json['updateStatus'] == true,
      edit: json['edit'] == true,
      delete: json['delete'] == true,
      manage: json['manage'] == true,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AppUser? createdBy;
  final List<AppUser> assignees;
  final AppUser? primaryAssignee;
  final String myRole;
  final TaskPermissions permissions;
  final bool isOverdue;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.startDate,
    this.dueDate,
    this.priority = 'medium',
    this.status = 'todo',
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.assignees = const [],
    this.primaryAssignee,
    this.myRole = '',
    this.permissions = const TaskPermissions(),
    this.isOverdue = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        startDate: DateFormatter.parse(json['startDate']),
        dueDate: DateFormatter.parse(json['dueDate']),
        priority: (json['priority'] ?? 'medium').toString(),
        status: (json['status'] ?? 'todo').toString(),
        createdAt: DateFormatter.parse(json['createdAt']),
        updatedAt: DateFormatter.parse(json['updatedAt']),
        createdBy: json['createdBy'] is Map<String, dynamic>
            ? AppUser.fromJson(json['createdBy'] as Map<String, dynamic>)
            : null,
        assignees: (json['assignees'] as List? ?? [])
            .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        primaryAssignee: json['primaryAssignee'] is Map<String, dynamic>
            ? AppUser.fromJson(json['primaryAssignee'] as Map<String, dynamic>)
            : null,
        myRole: (json['myRole'] ?? '').toString(),
        permissions: TaskPermissions.fromJson(
            json['permissions'] is Map<String, dynamic> ? json['permissions'] as Map<String, dynamic> : null),
        isOverdue: json['isOverdue'] == true,
      );

  String get statusLabel => AppConstants.statusLabels[status] ?? status;
  String get priorityLabel => AppConstants.priorityLabels[priority] ?? priority;
  String get roleLabel => AppConstants.roleLabels[myRole] ?? '';
}
