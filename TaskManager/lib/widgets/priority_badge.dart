import 'package:flutter/material.dart';

import '../utils/constants.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  static Color colorOf(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.orange.shade800;
      default:
        return Colors.teal.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorOf(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            AppConstants.priorityLabels[priority] ?? priority,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
