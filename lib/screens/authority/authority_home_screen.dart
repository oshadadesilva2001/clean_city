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

  static String? _digestText;
  static DateTime? _digestGeneratedAt;
  static bool _digestLoading = false;

  final _filters = [
    (label: 'All', value: null, icon: Icons.all_inbox_rounded),
    (label: 'Pending', value: 'pending', icon: Icons.hourglass_empty_rounded),
    (label: 'Assigned', value: 'assigned', icon: Icons.person_add_alt_1_rounded),
    (label: 'Completed', value: 'completed', icon: Icons.task_alt_rounded),
  ];

  Future<void> _logout() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (proceed == true) {
      await AuthService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
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
        title: const Text('Authority Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded),
            tooltip: 'View Map',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage city reports and monitor status',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filters.map((f) {
                final isSelected = _statusFilter == f.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(f.icon, size: 16, color: isSelected ? Colors.white : Colors.black54),
                    label: Text(f.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _statusFilter = f.value),
                    showCheckmark: false,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Card(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, 
                    size: 20, 
                    color: Theme.of(context).colorScheme.primary
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (text == null)
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Analyzing reports...',
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                )
              else
                Text(
                  text!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
