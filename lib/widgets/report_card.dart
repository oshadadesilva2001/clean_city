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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm')
                          .format(report.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (hasAiTags) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: [
                          if (report.category != null)
                            _AiChip(
                              label: report.category!,
                              color: _categoryColor(report.category!),
                            ),
                          if (report.priority != null)
                            _AiChip(
                              label: report.priority!,
                              color: _priorityColor(report.priority!),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: report.status),
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
      'Construction' => Colors.orange,
      'Organic' => Colors.green,
      'Electronic' => Colors.purple,
      _ => Colors.grey,
    };

Color _priorityColor(String priority) => switch (priority) {
      'Low' => Colors.green,
      'Medium' => Colors.amber,
      'High' => Colors.orange,
      'Urgent' => Colors.red,
      _ => Colors.grey,
    };

class _AiChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AiChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color.withAlpha(220),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
