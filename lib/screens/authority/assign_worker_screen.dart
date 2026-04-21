import 'package:flutter/material.dart';
import '../../models/profile.dart';
import '../../models/report.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';
import '../../services/groq_service.dart';
import '../../services/report_service.dart';
import '../../widgets/loading_button.dart';

class AssignWorkerScreen extends StatefulWidget {
  final Report report;

  const AssignWorkerScreen({super.key, required this.report});

  @override
  State<AssignWorkerScreen> createState() => _AssignWorkerScreenState();
}

class _AssignWorkerScreenState extends State<AssignWorkerScreen> {
  final _noteCtrl = TextEditingController();
  List<Profile> _workers = [];
  String? _selectedWorkerId;
  bool _loadingWorkers = true;
  bool _assigning = false;
  bool _suggestingNote = false;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    try {
      final workers = await AssignmentService.fetchWorkers();
      if (mounted) {
        setState(() {
          _workers = workers;
          _loadingWorkers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingWorkers = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _suggestNote() async {
    setState(() => _suggestingNote = true);
    try {
      final note = await GroqService.suggestAssignmentNote(
          widget.report.description);
      if (mounted) {
        _noteCtrl.text = note;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate note. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _suggestingNote = false);
    }
  }

  Future<void> _assign() async {
    if (_selectedWorkerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a worker.')),
      );
      return;
    }
    setState(() => _assigning = true);
    try {
      final authorityId = AuthService.currentUser!.id;
      await AssignmentService.createAssignment(
        reportId: widget.report.id,
        workerId: _selectedWorkerId!,
        assignedBy: authorityId,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      await ReportService.updateStatus(widget.report.id, 'assigned');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker assigned!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Worker')),
      body: _loadingWorkers
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty
              ? const Center(child: Text('No workers available.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Select Worker',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      RadioGroup<String>(
                        groupValue: _selectedWorkerId,
                        onChanged: (v) =>
                            setState(() => _selectedWorkerId = v),
                        child: Column(
                          children: _workers
                              .map(
                                (w) => RadioListTile<String>(
                                  value: w.id,
                                  title: Text(w.displayName),
                                  subtitle: Text(w.email),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _suggestingNote ? null : _suggestNote,
                        icon: _suggestingNote
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Suggest Note with AI'),
                      ),
                      const SizedBox(height: 24),
                      LoadingButton(
                        label: 'Assign',
                        isLoading: _assigning,
                        onPressed: _assign,
                      ),
                    ],
                  ),
                ),
    );
  }
}
