import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../widgets/report_card.dart';
import 'chatbot_screen.dart';
import 'submit_report_screen.dart';
import 'service_application_screen.dart';
import 'profile_screen.dart';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({super.key});

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  final String _userId = AuthService.currentUser!.id;
  bool _isFabExpanded = false;
  int _currentIndex = 1; // 0: AI Chat (Nav), 1: Home, 2: Profile

  final List<Map<String, dynamic>> _services = [
    {'name': 'Birth Certificate', 'icon': Icons.child_care_rounded, 'color': Colors.blue},
    {'name': 'Passport', 'icon': Icons.public_rounded, 'color': Colors.purple},
    {'name': 'NIC', 'icon': Icons.badge_rounded, 'color': Colors.orange},
    {'name': 'Driving License', 'icon': Icons.drive_eta_rounded, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _triggerFabPulse();
  }

  void _triggerFabPulse() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isFabExpanded = true);
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isFabExpanded = false);
        });
      }
    });
  }

  void _navigateToSubmit(ReportType type) {
    setState(() => _isFabExpanded = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubmitReportScreen(initialType: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 1 ? 0 : 1, // Logic to show Home or Profile
        children: [
          _buildHomeContent(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 1 ? _buildFabWithMenu() : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Clean City'),
              centerTitle: true,
              floating: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Services',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Apply for essential documents directly',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.all(8),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceApplicationScreen(serviceName: service['name']),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (service['color'] as Color).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(service['icon'], color: service['color']),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              service['name'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Reports',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Track the status of your reported issues',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: ReportService.streamMyReports(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('No reports yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          const Text('Tap the + button to report an issue.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                final reports = items.map((e) => Report.fromJson(e)).toList();
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ReportCard(report: reports[index]),
                    childCount: reports.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        if (_isFabExpanded)
          Positioned(
            right: 16,
            bottom: 16,
            child: _buildMultiFabContent(),
          ),
      ],
    );
  }

  Widget _buildFabWithMenu() {
    return FloatingActionButton(
      onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
      backgroundColor: _isFabExpanded ? Colors.grey : Theme.of(context).colorScheme.primary,
      child: Icon(_isFabExpanded ? Icons.close : Icons.add_rounded, size: 32, color: Colors.white),
    );
  }

  Widget _buildBottomNav() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8), // Fixed overflow here
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.auto_awesome_rounded, 'AI Chat', false, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()));
              }),
              _buildNavItem(Icons.home_rounded, 'Home', _currentIndex == 1, () {
                setState(() => _currentIndex = 1);
              }, isBig: true),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', _currentIndex == 2, () {
                setState(() => _currentIndex = 2);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap, {bool isBig = false}) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isBig ? 32 : 26,
            color: isSelected ? primaryColor : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiFabContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildFabOption('Litter', Icons.delete_outline_rounded, Colors.green, ReportType.litter),
        const SizedBox(height: 12),
        _buildFabOption('Roads', Icons.handyman_rounded, Colors.blue, ReportType.infrastructure),
        const SizedBox(height: 12),
        _buildFabOption('Lights', Icons.lightbulb_outline_rounded, Colors.orange, ReportType.lighting),
        const SizedBox(height: 12),
        _buildFabOption('Dev', Icons.add_business_rounded, Colors.purple, ReportType.development),
        const SizedBox(height: 12),
        _buildFabOption('Power', Icons.power_off_rounded, Colors.red, ReportType.power),
        const SizedBox(height: 70), // Spacer for the main FAB
      ],
    );
  }

  Widget _buildFabOption(String label, IconData icon, Color color, ReportType type) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          onPressed: () => _navigateToSubmit(type),
          backgroundColor: color,
          foregroundColor: Colors.white,
          heroTag: label,
          child: Icon(icon),
        ),
      ],
    );
  }
}
