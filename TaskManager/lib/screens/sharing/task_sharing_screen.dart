import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/task_share.dart';
import '../../services/api_client.dart';
import '../../services/task_share_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/user_selector.dart';

class TaskSharingScreen extends StatefulWidget {
  final Task task;
  const TaskSharingScreen({super.key, required this.task});

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  final _service = TaskShareService();
  List<TaskShare> _shares = [];
  bool _loading = true;
  String? _error;
  String _newPermission = 'viewer';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final shares = await _service.list(widget.task.id);
      if (!mounted) return;
      setState(() {
        _shares = shares;
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

  Future<void> _addPeople() async {
    final ownerId = widget.task.createdBy?.id;
    final users = await UserSelector.show(
      context,
      multi: true,
      title: 'Chọn người được chia sẻ',
      excludeIds: [
        if (ownerId != null) ownerId,
        ..._shares.map((s) => s.user.id),
      ],
    );
    if (users == null || users.isEmpty) return;
    try {
      final shares = await _service.share(widget.task.id, users.map((u) => u.id).toList(), _newPermission);
      if (!mounted) return;
      setState(() => _shares = shares);
      _toast('Đã chia sẻ cho ${users.length} người');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _changePermission(TaskShare s, String permission) async {
    try {
      final shares = await _service.updatePermission(widget.task.id, s.id, permission);
      if (!mounted) return;
      setState(() => _shares = shares);
      _toast('Đã đổi quyền');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _revoke(TaskShare s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi quyền?'),
        content: Text('${s.user.fullName} sẽ không còn truy cập được công việc này.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thu hồi')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final shares = await _service.revoke(widget.task.id, s.id);
      if (!mounted) return;
      setState(() => _shares = shares);
      _toast('Đã thu hồi quyền');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ và phân quyền')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Quyền cho người mới:'),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'viewer', label: Text('Chỉ xem'), icon: Icon(Icons.visibility_outlined)),
                      ButtonSegment(value: 'editor', label: Text('Chỉnh sửa'), icon: Icon(Icons.edit_outlined)),
                    ],
                    selected: {_newPermission},
                    onSelectionChanged: (s) => setState(() => _newPermission = s.first),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addPeople,
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Chọn người và chia sẻ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _shares.isEmpty
                        ? const EmptyView(message: 'Chưa chia sẻ cho ai', icon: Icons.share_outlined)
                        : ListView.builder(
                            itemCount: _shares.length,
                            itemBuilder: (_, i) {
                              final s = _shares[i];
                              return ListTile(
                                leading: CircleAvatar(child: Text(s.user.initials)),
                                title: Text(s.user.fullName),
                                subtitle: Text(s.user.email),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DropdownButton<String>(
                                      value: s.permission,
                                      underline: const SizedBox.shrink(),
                                      items: AppConstants.permissionLabels.entries
                                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null && v != s.permission) _changePermission(s, v);
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Thu hồi',
                                      icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                                      onPressed: () => _revoke(s),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
