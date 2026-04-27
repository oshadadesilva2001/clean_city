import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import 'status_badge.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;

  const ReportCard({super.key, required this.report, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasAiTags = report.category != null || report.priority != null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(report.createdAt.toLocal()),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black54,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: report.status),
                ],
              ),
              if (hasAiTags) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (report.category != null)
                      _AiChip(
                        label: report.category!,
                        color: _categoryColor(report.category!),
                        icon: Icons.category_outlined,
                      ),
                    if (report.priority != null)
                      _AiChip(
                        label: report.priority!,
                        color: _priorityColor(report.priority!),
                        icon: Icons.priority_high_rounded,
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

Color _categoryColor(String category) => switch (category) {
      'Plastic' => Colors.blue,
      'Hazardous' => Colors.red,
      'Construction' => Colors.brown,
      'Organic' => Colors.green,
      'Electronic' => Colors.purple,
      _ => Colors.blueGrey,
    };

Color _priorityColor(String priority) => switch (priority) {
      'Low' => Colors.green,
      'Medium' => Colors.amber,
      'High' => Colors.orange,
      'Urgent' => Colors.red,
      _ => Colors.blueGrey,
    };

class _AiChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _AiChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
