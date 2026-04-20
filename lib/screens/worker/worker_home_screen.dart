import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/assignment.dart';
import '../../services/auth_service.dart';
import '../../services/assignment_service.dart';
import '../../widgets/status_badge.dart';
import 'job_detail_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final String _userId = AuthService.currentUser!.id;

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AssignmentService.streamWorkerAssignments(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No jobs assigned yet.'),
                ],
              ),
            );
          }
          final assignments =
              items.map((e) => Assignment.fromJson(e)).toList();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: assignments.length,
            itemBuilder: (_, i) {
              final a = assignments[i];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(
                    'Job assigned ${DateFormat('dd MMM yyyy').format(a.assignedAt.toLocal())}',
                  ),
                  subtitle: a.note != null ? Text(a.note!) : null,
                  trailing: StatusBadge(
                      status: a.isCompleted ? 'completed' : 'assigned'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailScreen(assignment: a),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
