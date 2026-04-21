import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../widgets/report_card.dart';
import 'map_screen.dart';
import 'report_detail_screen.dart';

class AuthorityHomeScreen extends StatefulWidget {
  const AuthorityHomeScreen({super.key});

  @override
  State<AuthorityHomeScreen> createState() => _AuthorityHomeScreenState();
}

class _AuthorityHomeScreenState extends State<AuthorityHomeScreen> {
  String? _statusFilter;

  final _filters = [
    (label: 'All', value: null),
    (label: 'Pending', value: 'pending'),
    (label: 'Assigned', value: 'assigned'),
    (label: 'Completed', value: 'completed'),
  ];

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: _statusFilter == f.value,
                    onSelected: (_) =>
                        setState(() => _statusFilter = f.value),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ReportService.streamAllReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = (snapshot.data ?? [])
                    .map((e) => Report.fromJson(e))
                    .toList();
                final reports = _statusFilter == null
                    ? all
                    : all
                        .where((r) => r.status == _statusFilter)
                        .toList();
                if (reports.isEmpty) {
                  return const Center(child: Text('No reports found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: reports.length,
                  itemBuilder: (_, i) => ReportCard(
                    report: reports[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportDetailScreen(report: reports[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
