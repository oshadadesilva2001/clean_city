import '../core/constants.dart';
import '../core/supabase_client.dart';
import '../models/report.dart';

class ReportService {
  static Future<String> createReport({
    required String reporterId,
    required String description,
    required double latitude,
    required double longitude,
    String? photoUrl,
  }) async {
    final data = await supabase.from(kTableReports).insert({
      'reporter_id': reporterId,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
    }).select('id').single();
    return data['id'] as String;
  }

  static Future<List<Report>> fetchMyReports(String userId) async {
    final data = await supabase
        .from(kTableReports)
        .select()
        .eq('reporter_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Report.fromJson(e)).toList();
  }

  static Future<List<Report>> fetchAllReports({String? statusFilter}) async {
    var query = supabase.from(kTableReports).select();
    if (statusFilter != null) {
      query = query.eq('status', statusFilter) as dynamic;
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Report.fromJson(e)).toList();
  }

  static Future<void> updateStatus(String reportId, String status) async {
    await supabase
        .from(kTableReports)
        .update({'status': status})
        .eq('id', reportId);
  }

  static Future<void> updateAiFields(
      String reportId, String category, String priority) async {
    await supabase
        .from(kTableReports)
        .update({'category': category, 'priority': priority})
        .eq('id', reportId);
  }

  static Stream<List<Map<String, dynamic>>> streamAllReports() {
    return supabase
        .from(kTableReports)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  static Stream<List<Map<String, dynamic>>> streamMyReports(String userId) {
    return supabase
        .from(kTableReports)
        .stream(primaryKey: ['id'])
        .eq('reporter_id', userId)
        .order('created_at', ascending: false);
  }
}
