import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/groq_service.dart';
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

  // Digest cache — shared across rebuilds
  static String? _digestText;
  static DateTime? _digestGeneratedAt;
  static bool _digestLoading = false;

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

  void _maybeGenerateDigest(List<Report> all) {
    final now = DateTime.now();
    final stale = _digestGeneratedAt == null ||
        now.difference(_digestGeneratedAt!) > const Duration(hours: 1);
    if (!stale || _digestLoading) return;

    _digestLoading = true;
    final pending = all.where((r) => r.status == 'pending').length;
    final assigned = all.where((r) => r.status == 'assigned').length;
    final completed = all.where((r) => r.status == 'completed').length;

    GroqService.generateDigest(
      total: all.length,
      pending: pending,
      assigned: assigned,
      completed: completed,
    ).then((text) {
      if (mounted) {
        setState(() {
          _digestText = text;
          _digestGeneratedAt = DateTime.now();
          _digestLoading = false;
        });
      } else {
        _digestText = text;
        _digestGeneratedAt = DateTime.now();
        _digestLoading = false;
      }
    }).catchError((_) {
      _digestLoading = false;
    });
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

                // Trigger digest generation using live data (non-blocking)
                if (all.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _maybeGenerateDigest(all));
                }

                final reports = _statusFilter == null
                    ? all
                    : all
                        .where((r) => r.status == _statusFilter)
                        .toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: reports.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) return _DigestCard(text: _digestText);
                    final report = reports[i - 1];
                    return ReportCard(
                      report: report,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReportDetailScreen(report: report),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DigestCard extends StatelessWidget {
  final String? text;

  const _DigestCard({this.text});

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Generating AI summary…',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
