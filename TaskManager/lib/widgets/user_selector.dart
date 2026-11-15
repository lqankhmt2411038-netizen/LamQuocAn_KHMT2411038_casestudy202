import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/user_service.dart';

/// Bottom sheet tìm người dùng theo tên/email và chọn một hoặc nhiều người.
class UserSelector extends StatefulWidget {
  final bool multi;
  final String title;
  final List<String> excludeIds;
  final List<AppUser> initialSelected;

  const UserSelector({
    super.key,
    this.multi = true,
    this.title = 'Chọn người dùng',
    this.excludeIds = const [],
    this.initialSelected = const [],
  });

  static Future<List<AppUser>?> show(
    BuildContext context, {
    bool multi = true,
    String title = 'Chọn người dùng',
    List<String> excludeIds = const [],
    List<AppUser> initialSelected = const [],
  }) {
    return showModalBottomSheet<List<AppUser>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UserSelector(
        multi: multi,
        title: title,
        excludeIds: excludeIds,
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  State<UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends State<UserSelector> {
  final _controller = TextEditingController();
  final _service = UserService();
  Timer? _debounce;
  List<AppUser> _results = [];
  final Map<String, AppUser> _selected = {};
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    for (final u in widget.initialSelected) {
      _selected[u.id] = u;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String value) async {
    final q = value.trim();
    setState(() {
      _query = q;
      _error = null;
    });
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final users = await _service.search(q);
      if (!mounted) return;
      setState(() {
        _results = users.where((u) => !widget.excludeIds.contains(u.id)).toList();
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

  void _toggle(AppUser user) {
    if (!widget.multi) {
      Navigator.pop(context, [user]);
      return;
    }
    setState(() {
      if (_selected.containsKey(user.id)) {
        _selected.remove(user.id);
      } else {
        _selected[user.id] = user;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Nhập tên hoặc email (ít nhất 2 ký tự)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_selected.isNotEmpty && widget.multi)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _selected.values
                      .map((u) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InputChip(
                              label: Text(u.fullName),
                              onDeleted: () => setState(() => _selected.remove(u.id)),
                            ),
                          ))
                      .toList(),
                ),
              ),
            Expanded(child: _buildResults()),
            if (widget.multi)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selected.values.toList()),
                    child: Text('Xác nhận (${_selected.length})'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_query.length < 2) {
      return const Center(child: Text('Nhập tên hoặc email để tìm người dùng', style: TextStyle(color: Colors.grey)));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('Không tìm thấy người dùng phù hợp', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final u = _results[i];
        final checked = _selected.containsKey(u.id);
        return ListTile(
          leading: CircleAvatar(child: Text(u.initials)),
          title: Text(u.fullName),
          subtitle: Text(u.email),
          trailing: widget.multi
              ? Icon(checked ? Icons.check_circle : Icons.circle_outlined,
                  color: checked ? Theme.of(context).colorScheme.primary : Colors.grey)
              : null,
          onTap: () => _toggle(u),
        );
      },
    );
  }
}
