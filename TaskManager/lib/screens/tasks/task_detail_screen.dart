import 'package:flutter/material.dart';

import '../../models/email_log.dart';
import '../../models/task.dart';
import '../../models/task_activity.dart';
import '../../models/task_share.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../services/task_share_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import '../assignment/assign_task_screen.dart';
import '../sharing/task_sharing_screen.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _service = TaskService();
  final _shareService = TaskShareService();

  Task? _task;
  List<TaskShare> _shares = [];
  List<TaskActivity> _activities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      final task = await _service.get(widget.taskId);
      List<TaskShare> shares = [];
      List<TaskActivity> activities = [];
      try {
        shares = await _shareService.list(widget.taskId);
      } on ApiException {
        // không bắt buộc
      }
      try {
        activities = await _service.activities(widget.taskId);
      } on ApiException {
        // không bắt buộc
      }
      if (!mounted) return;
      setState(() {
        _task = task;
        _shares = shares;
        _activities = activities;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _changeStatus(String status) async {
    try {
      await _service.updateStatus(widget.taskId, status);
      _toast('Đã cập nhật trạng thái');
      _load(showSpinner: false);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: const Text('Công việc cùng lịch sử, chia sẻ và thông báo liên quan sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(widget.taskId);
      if (!mounted) return;
      _toast('Đã xóa công việc');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _go(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load(showSpinner: false);
  }

  void _showEmailLogs() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EmailLogSheet(taskId: widget.taskId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          if (task != null && task.permissions.edit)
            IconButton(
              tooltip: 'Chỉnh sửa',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _go(TaskEditScreen(task: task)),
            ),
          if (task != null && task.permissions.delete)
            IconButton(
              tooltip: 'Xóa',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildContent(task!),
    );
  }

  Widget _buildContent(Task task) {
    return RefreshIndicator(
      onRefresh: () => _load(showSpinner: false),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(task.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusBadge(status: task.status),
              PriorityBadge(priority: task.priority),
              if (task.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text('Quá hạn',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (task.permissions.updateStatus) ...[
            const SizedBox(height: 16),
            const Text('Cập nhật trạng thái', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: AppConstants.statusLabels.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: task.status == e.key,
                        onSelected: task.status == e.key ? null : (_) => _changeStatus(e.key),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          _section('Thông tin', [
            _infoRow(Icons.notes, 'Mô tả', task.description.isEmpty ? 'Không có mô tả' : task.description),
            _infoRow(Icons.play_arrow_outlined, 'Bắt đầu', DateFormatter.dateTime(task.startDate)),
            _infoRow(Icons.event, 'Hạn hoàn thành', DateFormatter.dateTime(task.dueDate)),
            _infoRow(Icons.person_outline, 'Người tạo', task.createdBy?.fullName ?? '—'),
            _infoRow(Icons.badge_outlined, 'Vai trò của tôi', task.roleLabel.isEmpty ? '—' : task.roleLabel),
          ]),
          const SizedBox(height: 12),
          _section(
            'Người được giao (${task.assignees.length})',
            [
              if (task.assignees.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Chưa giao cho ai', style: TextStyle(color: Colors.grey)),
                ),
              ...task.assignees.map((u) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(u.initials)),
                    title: Text(u.fullName),
                    subtitle: Text(u.email),
                    trailing: u.id == task.primaryAssignee?.id
                        ? const Chip(label: Text('Phụ trách chính'), visualDensity: VisualDensity.compact)
                        : null,
                  )),
            ],
            action: task.permissions.manage
                ? TextButton.icon(
                    onPressed: () => _go(AssignTaskScreen(task: task)),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Giao việc'),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          _section(
            'Được chia sẻ (${_shares.length})',
            [
              if (_shares.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Chưa chia sẻ cho ai', style: TextStyle(color: Colors.grey)),
                ),
              ..._shares.map((s) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(s.user.initials)),
                    title: Text(s.user.fullName),
                    subtitle: Text(s.user.email),
                    trailing: Chip(
                      label: Text(AppConstants.permissionLabels[s.permission] ?? s.permission),
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
            ],
            action: task.permissions.manage
                ? TextButton.icon(
                    onPressed: () => _go(TaskSharingScreen(task: task)),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Chia sẻ'),
                  )
                : null,
          ),
          if (task.permissions.manage) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showEmailLogs,
              icon: const Icon(Icons.mark_email_read_outlined),
              label: const Text('Lịch sử gửi email'),
            ),
          ],
          const SizedBox(height: 12),
          _section('Lịch sử hoạt động', [
            if (_activities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Chưa có hoạt động', style: TextStyle(color: Colors.grey)),
              ),
            ..._activities.map((a) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(a.describe()),
                  subtitle: Text(DateFormatter.dateTime(a.createdAt)),
                )),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children, {Widget? action}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EmailLogSheet extends StatefulWidget {
  final String taskId;
  const _EmailLogSheet({required this.taskId});

  @override
  State<_EmailLogSheet> createState() => _EmailLogSheetState();
}

class _EmailLogSheetState extends State<_EmailLogSheet> {
  final _service = TaskService();
  List<EmailLog> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final logs = await _service.emailLogs(widget.taskId);
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _retry(EmailLog log) async {
    try {
      final res = await _service.retryEmail(log.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.status == 'sent' ? 'Gửi lại thành công' : 'Gửi lại thất bại: ${res.errorMessage}')),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Expanded(
                    child: Text('Lịch sử gửi email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _logs.isEmpty
                        ? const EmptyView(message: 'Chưa có email nào được gửi')
                        : ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (_, i) {
                              final l = _logs[i];
                              final color = l.status == 'sent'
                                  ? Colors.green
                                  : l.status == 'failed'
                                      ? Colors.red
                                      : Colors.orange;
                              final icon = l.status == 'sent'
                                  ? Icons.check_circle
                                  : l.status == 'failed'
                                      ? Icons.error
                                      : Icons.schedule;
                              return ListTile(
                                leading: Icon(icon, color: color),
                                title: Text(l.subject, maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  '${l.recipientEmail}\n${l.status} • ${l.attempts} lần thử • ${DateFormatter.dateTime(l.createdAt)}'
                                  '${l.errorMessage.isNotEmpty ? '\n${l.errorMessage}' : ''}',
                                ),
                                isThreeLine: true,
                                trailing: l.status == 'failed'
                                    ? TextButton(onPressed: () => _retry(l), child: const Text('Gửi lại'))
                                    : null,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
