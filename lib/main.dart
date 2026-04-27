import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );
  runApp(const CleanCityApp());
}

class CleanCityApp extends StatelessWidget {
  const CleanCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSession =
        Supabase.instance.client.auth.currentSession != null;

    return MaterialApp(
      title: 'Clean City',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: hasSession ? '/router' : '/login',
      routes: appRoutes,
    );
  }
}
