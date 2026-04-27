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
          const SnackBar(
            content: Text('Worker assigned successfully!'),
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
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No workers found.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Select a Worker',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _workers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final w = _workers[index];
                            final isSelected = _selectedWorkerId == w.id;
                            return InkWell(
                              onTap: () => setState(() => _selectedWorkerId = w.id),
                              borderRadius: index == 0 
                                ? const BorderRadius.vertical(top: Radius.circular(20))
                                : index == _workers.length - 1
                                  ? const BorderRadius.vertical(bottom: Radius.circular(20))
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_outline,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            w.displayName,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            w.email,
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Radio<String>(
                                      value: w.id,
                                      groupValue: _selectedWorkerId,
                                      onChanged: (v) => setState(() => _selectedWorkerId = v),
                                      activeColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Assignment Instructions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Add special instructions for the worker...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _suggestingNote ? null : _suggestNote,
                          icon: _suggestingNote
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Generate with AI'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      LoadingButton(
                        label: 'Assign Cleanup Task',
                        isLoading: _assigning,
                        onPressed: _assign,
                      ),
                    ],
                  ),
                ),
    );
  }
}
