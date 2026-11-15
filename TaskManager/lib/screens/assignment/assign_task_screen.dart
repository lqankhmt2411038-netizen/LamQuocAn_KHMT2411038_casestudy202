import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../widgets/user_selector.dart';

class AssignTaskScreen extends StatefulWidget {
  final Task task;
  const AssignTaskScreen({super.key, required this.task});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _service = TaskService();
  late List<AppUser> _selected;
  String? _primaryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = List<AppUser>.from(widget.task.assignees);
    _primaryId = widget.task.primaryAssignee?.id;
  }

  Future<void> _addPeople() async {
    final res = await UserSelector.show(
      context,
      multi: true,
      title: 'Chọn người phụ trách',
      excludeIds: _selected.map((u) => u.id).toList(),
    );
    if (res == null || res.isEmpty) return;
    setState(() {
      _selected.addAll(res);
      _primaryId ??= _selected.first.id;
    });
  }

  void _remove(AppUser u) {
    setState(() {
      _selected.removeWhere((x) => x.id == u.id);
      if (_primaryId == u.id) {
        _primaryId = _selected.isEmpty ? null : _selected.first.id;
      }
    });
  }

  Future<void> _confirm() async {
    final original = widget.task.assignees.map((u) => u.id).toSet();
    final now = _selected.map((u) => u.id).toSet();
    final removed = original.difference(now);
    final added = now.difference(original);

    if (removed.isEmpty && added.isEmpty && _primaryId == widget.task.primaryAssignee?.id) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _saving = true);
    try {
      for (final id in removed) {
        await _service.unassign(widget.task.id, id);
      }
      if (added.isNotEmpty) {
        await _service.assign(widget.task.id, added.toList());
      }
      if (_primaryId != null && _primaryId != widget.task.primaryAssignee?.id) {
        await _service.setPrimaryAssignee(widget.task.id, _primaryId!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật giao việc')));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giao công việc')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Chọn một hoặc nhiều người, nhấn ngôi sao để chọn người phụ trách chính.',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addPeople,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Tìm và thêm người'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selected.isEmpty
                ? const Center(child: Text('Chưa chọn ai', style: TextStyle(color: Colors.grey)))
                : ListView(
                    children: _selected.map((u) {
                      final isPrimary = u.id == _primaryId;
                      return ListTile(
                        leading: CircleAvatar(child: Text(u.initials)),
                        title: Text(u.fullName),
                        subtitle: Text(isPrimary ? '${u.email}\nPhụ trách chính' : u.email),
                        isThreeLine: isPrimary,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Phụ trách chính',
                              icon: Icon(isPrimary ? Icons.star : Icons.star_border, color: Colors.amber.shade700),
                              onPressed: () => setState(() => _primaryId = u.id),
                            ),
                            IconButton(
                              tooltip: 'Bỏ',
                              icon: const Icon(Icons.close),
                              onPressed: () => _remove(u),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : _confirm,
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Xác nhận giao việc'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
