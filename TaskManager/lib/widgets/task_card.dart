import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/date_formatter.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  const TaskCard({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    final names = <String>[];
    if (task.primaryAssignee != null) names.add('${task.primaryAssignee!.fullName} (chính)');
    for (final a in task.assignees) {
      if (a.id != task.primaryAssignee?.id) names.add(a.fullName);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: task.status),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PriorityBadge(priority: task.priority),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event, size: 15, color: overdue ? Colors.red : Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        task.dueDate == null ? 'Chưa có hạn' : DateFormatter.dateTime(task.dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: overdue ? Colors.red : Colors.grey.shade700,
                          fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (overdue)
                        const Text(' • Quá hạn', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ),
                  if (task.roleLabel.isNotEmpty)
                    Text(task.roleLabel,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                ],
              ),
              if (names.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Phụ trách: ${names.join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
