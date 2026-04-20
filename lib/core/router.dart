import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/authority/authority_home_screen.dart';
import '../screens/public/public_home_screen.dart';
import '../screens/worker/worker_home_screen.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    try {
      final profile = await AuthService.getCurrentProfile();
      if (!mounted) return;
      final route = switch (profile.role) {
        'authority' => '/authority',
        'worker' => '/worker',
        _ => '/public',
      };
      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

Map<String, WidgetBuilder> get appRoutes => {
      '/login': (_) => const LoginScreen(),
      '/router': (_) => const RoleRouter(),
      '/public': (_) => const PublicHomeScreen(),
      '/authority': (_) => const AuthorityHomeScreen(),
      '/worker': (_) => const WorkerHomeScreen(),
    };
