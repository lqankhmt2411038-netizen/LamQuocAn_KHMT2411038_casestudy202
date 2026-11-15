import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../services/task_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_card.dart';
import '../../widgets/user_selector.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _service = TaskService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  // Bộ lọc
  String _scope = '';
  String? _status;
  String? _priority;
  AppUser? _assignee;
  String _sortBy = 'createdAt';
  String _order = 'desc';

  static const _scopes = <String, String>{
    '': 'Tất cả',
    'created': 'Tôi tạo',
    'assigned': 'Giao cho tôi',
    'delegated': 'Tôi đã giao',
    'shared': 'Được chia sẻ',
  };

  @override
  void initState() {
    super.initState();
    _load();
    NotificationService().refreshUnread();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      final tasks = await _service.list(
        scope: _scope,
        status: _status,
        priority: _priority,
        q: _searchCtrl.text,
        assigneeId: _assignee?.id,
        sortBy: _sortBy,
        order: _order,
      );
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _load(showSpinner: false));
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    _load(showSpinner: false);
    NotificationService().refreshUnread();
  }

  bool get _hasFilter => _status != null || _priority != null || _assignee != null;

  Future<void> _openFilterSheet() async {
    String? status = _status;
    String? priority = _priority;
    AppUser? assignee = _assignee;
    String sortBy = _sortBy;
    String order = _order;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Lọc và sắp xếp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                    ...AppConstants.statusLabels.entries
                        .map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value))),
                  ],
                  onChanged: (v) => setSheet(() => status = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Mức ưu tiên', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                    ...AppConstants.priorityLabels.entries
                        .map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value))),
                  ],
                  onChanged: (v) => setSheet(() => priority = v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_search),
                  title: Text(assignee == null ? 'Người phụ trách: Tất cả' : 'Người phụ trách: ${assignee!.fullName}'),
                  trailing: assignee == null
                      ? const Icon(Icons.chevron_right)
                      : IconButton(icon: const Icon(Icons.clear), onPressed: () => setSheet(() => assignee = null)),
                  onTap: () async {
                    final res = await UserSelector.show(ctx, multi: false, title: 'Lọc theo người phụ trách');
                    if (res != null && res.isNotEmpty) setSheet(() => assignee = res.first);
                  },
                ),
                const Divider(),
                DropdownButtonFormField<String>(
                  initialValue: sortBy,
                  decoration: const InputDecoration(labelText: 'Sắp xếp theo', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'createdAt', child: Text('Thời gian tạo')),
                    DropdownMenuItem(value: 'dueDate', child: Text('Hạn hoàn thành')),
                    DropdownMenuItem(value: 'priority', child: Text('Mức độ ưu tiên')),
                  ],
                  onChanged: (v) => setSheet(() => sortBy = v ?? sortBy),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'asc', label: Text('Tăng dần'), icon: Icon(Icons.arrow_upward)),
                    ButtonSegment(value: 'desc', label: Text('Giảm dần'), icon: Icon(Icons.arrow_downward)),
                  ],
                  selected: {order},
                  onSelectionChanged: (s) => setSheet(() => order = s.first),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setSheet(() {
                          status = null;
                          priority = null;
                          assignee = null;
                          sortBy = 'createdAt';
                          order = 'desc';
                        }),
                        child: const Text('Đặt lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (applied == true) {
      setState(() {
        _status = status;
        _priority = priority;
        _assignee = assignee;
        _sortBy = sortBy;
        _order = order;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc'),
        actions: [
          IconButton(
            tooltip: 'Lọc và sắp xếp',
            onPressed: _openFilterSheet,
            icon: Badge(isLabelVisible: _hasFilter, smallSize: 8, child: const Icon(Icons.filter_list)),
          ),
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.unreadNotifier,
            builder: (_, count, __) => IconButton(
              tooltip: 'Thông báo',
              onPressed: () => _open(const NotificationScreen()),
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text(count > 99 ? '99+' : '$count'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cá nhân và thống kê',
            onPressed: () => _open(const ProfileScreen()),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên công việc...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load(showSpinner: false);
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _scopes.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: _scope == e.key,
                          onSelected: (_) {
                            setState(() => _scope = e.key);
                            _load();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(const TaskCreateScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: () => _load(showSpinner: false),
      child: _tasks.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              EmptyView(message: 'Chưa có công việc nào phù hợp.\nNhấn "Thêm" để tạo công việc mới.'),
            ])
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: _tasks.length,
              itemBuilder: (_, i) => TaskCard(
                task: _tasks[i],
                onTap: () => _open(TaskDetailScreen(taskId: _tasks[i].id)),
              ),
            ),
    );
  }
}
