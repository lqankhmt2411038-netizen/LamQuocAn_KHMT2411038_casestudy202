import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/statistics_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../auth/login_screen.dart';
import '../tasks/task_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _stats = StatisticsService();
  AppUser? _user = AuthService.instance.currentUser;
  Map<String, dynamic> _taskStats = {};
  Map<String, dynamic> _assignStats = {};
  Map<String, dynamic> _deadlineStats = {};
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
      final results = await Future.wait([_stats.tasks(), _stats.assignments(), _stats.deadlines()]);
      if (!mounted) return;
      setState(() {
        _taskStats = results[0];
        _assignStats = results[1];
        _deadlineStats = results[2];
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

  Future<void> _editProfile() async {
    final ctrl = TextEditingController(text: _user?.fullName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật thông tin'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Lưu')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    try {
      final u = await AuthService.instance.updateProfile(fullName: name);
      if (!mounted) return;
      setState(() => _user = u);
      _toast('Đã cập nhật thông tin');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _changePassword() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const _ChangePasswordDialog());
    if (ok == true) _toast('Đổi mật khẩu thành công');
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân và thống kê')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _profileCard(),
                      const SizedBox(height: 20),
                      _title('Công việc theo trạng thái'),
                      _grid([
                        _stat('Tổng số', _taskStats['total'], Colors.indigo),
                        _stat('Chưa thực hiện', _taskStats['todo'], Colors.grey.shade700),
                        _stat('Đang thực hiện', _taskStats['in_progress'], Colors.blue.shade700),
                        _stat('Đã hoàn thành', _taskStats['completed'], Colors.green.shade700),
                      ]),
                      const SizedBox(height: 20),
                      _title('Giao việc'),
                      _grid([
                        _stat('Được giao cho tôi', _assignStats['assignedToMe'], Colors.deepPurple),
                        _stat('Tôi phụ trách chính', _assignStats['primaryAssignee'], Colors.teal),
                        _stat('Tôi đã giao', _assignStats['delegatedByMe'], Colors.orange.shade800),
                        _stat('Được chia sẻ', _assignStats['shared'], Colors.blueGrey),
                      ]),
                      const SizedBox(height: 20),
                      _title('Hạn hoàn thành'),
                      _deadlineSection(
                        'Sắp đến hạn (${_deadlineStats['hours'] ?? 72} giờ tới)',
                        _deadlineStats['dueSoon'],
                        Colors.orange.shade800,
                      ),
                      const SizedBox(height: 8),
                      _deadlineSection('Quá hạn', _deadlineStats['overdue'], Colors.red),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _profileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(radius: 36, child: Text(_user?.initials ?? '?', style: const TextStyle(fontSize: 28))),
            const SizedBox(height: 10),
            Text(_user?.fullName ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(_user?.email ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(onPressed: _editProfile, icon: const Icon(Icons.edit), label: const Text('Sửa thông tin')),
                OutlinedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.lock_reset), label: const Text('Đổi mật khẩu')),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      );

  Widget _grid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: children,
    );
  }

  Widget _stat(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${value ?? 0}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _deadlineSection(String title, dynamic items, Color color) {
    final list = (items as List? ?? []).cast<Map>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title: ${list.length}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Không có', style: TextStyle(color: Colors.grey)),
              ),
            ...list.map((t) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${t['title']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(DateFormatter.dateTime(DateFormatter.parse(t['dueDate']))),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: '${t['id']}')),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService.instance.changePassword(_current.text, _new.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              TextFormField(
                controller: _current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
              ),
              TextFormField(
                controller: _new,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu mới tối thiểu 6 ký tự' : null,
              ),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
                validator: (v) => v != _new.text ? 'Mật khẩu xác nhận không khớp' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: _saving ? null : _submit, child: const Text('Đổi mật khẩu')),
      ],
    );
  }
}
