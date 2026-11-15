import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_client.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/validators.dart';

/// Form dùng chung cho "Thêm công việc" và "Chỉnh sửa công việc".
class TaskForm extends StatefulWidget {
  final Task? task;
  final String submitLabel;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const TaskForm({super.key, this.task, required this.submitLabel, required this.onSubmit});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  DateTime? _startDate;
  DateTime? _dueDate;
  late String _priority;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _startDate = t?.startDate;
    _dueDate = t?.dueDate;
    _priority = t?.priority ?? 'medium';
    _status = t?.status ?? 'todo';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? current) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    final t = time ?? TimeOfDay.fromDateTime(current ?? now);
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await _pickDateTime(value);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.event),
          suffixIcon: value == null
              ? null
              : IconButton(icon: const Icon(Icons.clear), onPressed: () => onChanged(null)),
        ),
        child: Text(value == null ? 'Chưa đặt' : DateFormatter.dateTime(value)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate != null && _dueDate != null && _dueDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Hạn hoàn thành phải sau ngày bắt đầu')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'startDate': _startDate?.toUtc().toIso8601String(),
        'dueDate': _dueDate?.toUtc().toIso8601String(),
        'priority': _priority,
        'status': _status,
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _title,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Tên công việc *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (v) => Validators.required(v, 'Tên công việc'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 16),
          _dateField(label: 'Ngày bắt đầu', value: _startDate, onChanged: (v) => setState(() => _startDate = v)),
          const SizedBox(height: 16),
          _dateField(label: 'Hạn hoàn thành', value: _dueDate, onChanged: (v) => setState(() => _dueDate = v)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'Mức độ ưu tiên',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.flag),
            ),
            items: AppConstants.priorityLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _priority = v ?? _priority),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: InputDecoration(
              labelText: widget.task == null ? 'Trạng thái ban đầu' : 'Trạng thái',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.timelapse),
            ),
            items: AppConstants.statusLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}
