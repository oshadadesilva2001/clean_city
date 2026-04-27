import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/assignment.dart';
import '../../models/report.dart';
import '../../services/assignment_service.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/photo_picker_widget.dart';
import '../../widgets/status_badge.dart';

class JobDetailScreen extends StatefulWidget {
  final Assignment assignment;

  const JobDetailScreen({super.key, required this.assignment});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Report? _report;
  String? _signedUrl;
  bool _loading = true;
  bool _completing = false;
  XFile? _completionPhoto;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final reports = await ReportService.fetchAllReports();
      final report = reports.firstWhere(
        (r) => r.id == widget.assignment.reportId,
        orElse: () => throw Exception('Report not found'),
      );
      String? url;
      if (report.photoUrl != null) {
        url = await StorageService.getSignedUrl(report.photoUrl!);
      }
      if (mounted) {
        setState(() {
          _report = report;
          _signedUrl = url;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _markComplete() async {
    if (_completionPhoto == null) return;
    setState(() => _completing = true);
    try {
      final photoPath = await StorageService.uploadPhoto(
          _completionPhoto!, widget.assignment.workerId);
      await ReportService.updateStatus(widget.assignment.reportId, 'completed');
      await AssignmentService.markComplete(widget.assignment.id, photoPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job marked as complete!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('Report not found.'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_signedUrl != null)
                        CachedNetworkImage(
                          imageUrl: _signedUrl!,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(
                            height: 250,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (ctx, url, err) => Container(
                            height: 250,
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
                                StatusBadge(status: _report!.status),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_report!.createdAt.toLocal()),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cleanup Task',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _report!.description,
                              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 24),
                            _DetailItem(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: '${_report!.latitude.toStringAsFixed(5)}, ${_report!.longitude.toStringAsFixed(5)}',
                            ),
                            if (widget.assignment.note != null && widget.assignment.note!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _DetailItem(
                                icon: Icons.note_alt_outlined,
                                label: 'Authority Note',
                                value: widget.assignment.note!,
                              ),
                            ],
                            const SizedBox(height: 32),
                            if (!widget.assignment.isCompleted && _report!.status != 'completed') ...[
                              Text(
                                'Completion Report',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              PhotoPickerWidget(
                                image: _completionPhoto,
                                onImageSelected: (img) => setState(() => _completionPhoto = img),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please upload a photo of the area after cleaning.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              LoadingButton(
                                label: 'Mark as Completed',
                                isLoading: _completing,
                                onPressed: _completionPhoto != null ? _markComplete : null,
                              ),
                            ] else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      'This task is completed',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
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

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
