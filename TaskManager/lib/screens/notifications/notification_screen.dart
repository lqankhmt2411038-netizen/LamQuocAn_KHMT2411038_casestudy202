import 'package:flutter/material.dart';

import '../../models/notification.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();
  List<AppNotification> _items = [];
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
      final items = await _service.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
        _loading = false;
      });
      _service.refreshUnread();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'task_assigned':
      case 'primary_assigned':
        return Icons.assignment_ind_outlined;
      case 'task_shared':
      case 'share_permission_changed':
        return Icons.share_outlined;
      case 'share_revoked':
      case 'task_unassigned':
        return Icons.person_off_outlined;
      case 'task_completed':
        return Icons.check_circle_outline;
      case 'due_reminder':
        return Icons.alarm;
      default:
        return Icons.update;
    }
  }

  Future<void> _openItem(AppNotification n) async {
    if (!n.isRead) {
      try {
        await _service.markRead(n.id);
        setState(() => n.isRead = true);
        _service.refreshUnread();
      } on ApiException {
        // bỏ qua
      }
    }
    if (n.taskId == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: n.taskId!)));
    if (mounted) _load(showSpinner: false);
  }

  Future<void> _markAll() async {
    try {
      await _service.markAllRead();
      await _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(onPressed: _items.any((n) => !n.isRead) ? _markAll : null, child: const Text('Đọc tất cả')),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: () => _load(showSpinner: false),
                  child: _items.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          EmptyView(message: 'Chưa có thông báo nào', icon: Icons.notifications_none),
                        ])
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            return ListTile(
                              tileColor: n.isRead ? null : Theme.of(context).colorScheme.primaryContainer.withAlpha(70),
                              leading: Icon(_iconFor(n.type), color: Theme.of(context).colorScheme.primary),
                              title: Text(n.title,
                                  style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                              subtitle: Text('${n.message}\n${DateFormatter.dateTime(n.createdAt)}'),
                              isThreeLine: true,
                              trailing: n.isRead
                                  ? null
                                  : Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    ),
                              onTap: () => _openItem(n),
                            );
                          },
                        ),
                ),
    );
  }
}
