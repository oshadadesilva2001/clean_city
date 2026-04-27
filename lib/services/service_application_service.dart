import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_application.dart';

class ServiceApplicationService {
  static final _supabase = Supabase.instance.client;
  static const String _table = 'service_applications';

  static Future<void> submitApplication(ServiceApplication application) async {
    await _supabase.from(_table).insert(application.toJson());
  }

  static Stream<List<Map<String, dynamic>>> streamUserApplications(String userId) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
}
