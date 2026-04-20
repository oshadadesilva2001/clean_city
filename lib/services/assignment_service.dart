import '../core/constants.dart';
import '../core/supabase_client.dart';
import '../models/assignment.dart';
import '../models/profile.dart';

class AssignmentService {
  static Future<void> createAssignment({
    required String reportId,
    required String workerId,
    required String assignedBy,
    String? note,
  }) async {
    await supabase.from(kTableAssignments).insert({
      'report_id': reportId,
      'worker_id': workerId,
      'assigned_by': assignedBy,
      'note': note,
    });
  }

  static Future<List<Profile>> fetchWorkers() async {
    final data = await supabase
        .from(kTableProfiles)
        .select()
        .eq('role', 'worker');
    return (data as List).map((e) => Profile.fromJson(e)).toList();
  }

  static Future<Assignment?> fetchAssignmentForReport(
      String reportId) async {
    final data = await supabase
        .from(kTableAssignments)
        .select()
        .eq('report_id', reportId)
        .maybeSingle();
    if (data == null) return null;
    return Assignment.fromJson(data);
  }

  static Future<void> markComplete(String assignmentId) async {
    await supabase.from(kTableAssignments).update({
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', assignmentId);
  }

  static Stream<List<Map<String, dynamic>>> streamWorkerAssignments(
      String workerId) {
    return supabase
        .from(kTableAssignments)
        .stream(primaryKey: ['id'])
        .eq('worker_id', workerId)
        .order('assigned_at', ascending: false);
  }
}
