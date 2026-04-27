import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/assignment.dart';
import '../../models/report.dart';
import '../../services/assignment_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/status_badge.dart';
import 'assign_worker_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Assignment? _assignment;
  bool _loadingAssignment = true;
  String? _signedUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final futures = <Future>[
      AssignmentService.fetchAssignmentForReport(widget.report.id),
    ];
    if (widget.report.photoUrl != null) {
      futures.add(StorageService.getSignedUrl(widget.report.photoUrl!));
    }
    final results = await Future.wait(futures);
    if (mounted) {
      setState(() {
        _assignment = results[0] as Assignment?;
        if (widget.report.photoUrl != null) {
          _signedUrl = results[1] as String?;
        }
        _loadingAssignment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: _loadingAssignment
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_signedUrl != null)
                    CachedNetworkImage(
                      imageUrl: _signedUrl!,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        height: 300,
                        color: Colors.grey[100],
                        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(status: report.status),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(report.createdAt.toLocal()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (report.category != null || report.priority != null) ...[
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
                                  label: '${report.priority!} Priority',
                                  color: _priorityColor(report.priority!),
                                  icon: Icons.priority_high_rounded,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.description,
                          style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _DetailItem(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                        ),
                        if (_assignment != null) ...[
                          const SizedBox(height: 16),
                          _DetailItem(
                            icon: Icons.assignment_ind_outlined,
                            label: 'Assigned on',
                            value: DateFormat('dd MMM yyyy, HH:mm').format(_assignment!.assignedAt.toLocal()),
                          ),
                          if (_assignment!.note != null && _assignment!.note!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _DetailItem(
                              icon: Icons.note_alt_outlined,
                              label: 'Assignment Note',
                              value: _assignment!.note!,
                            ),
                          ],
                          if (_assignment!.completedAt != null) ...[
                            const SizedBox(height: 16),
                            _DetailItem(
                              icon: Icons.check_circle_outline,
                              label: 'Completed on',
                              value: DateFormat('dd MMM yyyy, HH:mm').format(_assignment!.completedAt!.toLocal()),
                              valueColor: Colors.green,
                            ),
                          ],
                        ],
                        const SizedBox(height: 40),
                        if (report.status == 'pending')
                          ElevatedButton.icon(
                            icon: const Icon(Icons.person_add_rounded),
                            label: const Text('Assign Cleanup Task'),
                            onPressed: () async {
                              final nav = Navigator.of(context);
                              await nav.push(
                                MaterialPageRoute(
                                  builder: (_) => AssignWorkerScreen(report: report),
                                ),
                              );
                              if (!mounted) return;
                              // Refreshing is handled by stream, but let's go back
                              nav.pop();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
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

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
