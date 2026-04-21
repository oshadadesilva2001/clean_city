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
      final reports =
          await ReportService.fetchAllReports();
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
    setState(() => _completing = true);
    try {
      final photoPath = await StorageService.uploadPhoto(
          _completionPhoto!, widget.assignment.workerId);
      await ReportService.updateStatus(widget.assignment.reportId, 'completed');
      await AssignmentService.markComplete(widget.assignment.id, photoPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job marked as complete!')),
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
      appBar: AppBar(title: const Text('Job Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('Report not found.'))
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
                          StatusBadge(status: _report!.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                          label: 'Description',
                          value: _report!.description),
                      _InfoRow(
                        label: 'Location',
                        value:
                            '${_report!.latitude.toStringAsFixed(5)}, ${_report!.longitude.toStringAsFixed(5)}',
                      ),
                      _InfoRow(
                        label: 'Reported at',
                        value: DateFormat('dd MMM yyyy, HH:mm')
                            .format(_report!.createdAt.toLocal()),
                      ),
                      if (widget.assignment.note != null)
                        _InfoRow(
                            label: 'Note',
                            value: widget.assignment.note!),
                      const SizedBox(height: 24),
                      if (!widget.assignment.isCompleted &&
                          _report!.status != 'completed') ...[
                        const Text(
                          'Upload after-cleaning photo (required)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        PhotoPickerWidget(
                          image: _completionPhoto,
                          onImageSelected: (img) =>
                              setState(() => _completionPhoto = img),
                        ),
                        const SizedBox(height: 16),
                        LoadingButton(
                          label: 'Mark as Complete',
                          isLoading: _completing,
                          onPressed:
                              _completionPhoto != null ? _markComplete : null,
                        ),
                      ],
                      if (widget.assignment.isCompleted ||
                          _report!.status == 'completed')
                        const Center(
                          child: Chip(
                            label: Text('Job Completed',
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.green,
                          ),
                        ),
                    ],
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
