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
    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: _loadingAssignment
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_signedUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _signedUrl!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          height: 220,
                          color: Colors.grey[200],
                          child: const Center(
                              child: CircularProgressIndicator()),
                        ),
                        errorWidget: (ctx, url, err) =>
                            const Icon(Icons.broken_image, size: 64),
                      ),
                    ),
                  if (_signedUrl != null) const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Status: '),
                      StatusBadge(status: report.status),
                    ],
                  ),
                  if (report.category != null || report.priority != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (report.category != null)
                          _AiChip(
                            label: report.category!,
                            color: _categoryColor(report.category!),
                          ),
                        if (report.priority != null)
                          _AiChip(
                            label: '${report.priority!} Priority',
                            color: _priorityColor(report.priority!),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _InfoRow(
                      label: 'Description', value: report.description),
                  _InfoRow(
                    label: 'Location',
                    value:
                        '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                  ),
                  _InfoRow(
                    label: 'Reported at',
                    value: DateFormat('dd MMM yyyy, HH:mm')
                        .format(report.createdAt.toLocal()),
                  ),
                  if (_assignment != null) ...[
                    const Divider(height: 32),
                    Text('Assignment',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Assigned at',
                      value: DateFormat('dd MMM yyyy, HH:mm')
                          .format(_assignment!.assignedAt.toLocal()),
                    ),
                    if (_assignment!.note != null)
                      _InfoRow(label: 'Note', value: _assignment!.note!),
                    if (_assignment!.completedAt != null)
                      _InfoRow(
                        label: 'Completed at',
                        value: DateFormat('dd MMM yyyy, HH:mm')
                            .format(_assignment!.completedAt!.toLocal()),
                      ),
                  ],
                  const SizedBox(height: 24),
                  if (report.status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Assign Worker'),
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await nav.push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AssignWorkerScreen(report: report),
                            ),
                          );
                          if (!mounted) return;
                          nav.pop();
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.withAlpha(220),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
