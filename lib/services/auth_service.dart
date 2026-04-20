import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/supabase_client.dart';
import '../models/profile.dart';

class AuthService {
  static Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signUp(
      String fullName, String email, String password) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  static Future<Profile> getCurrentProfile() async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from(kTableProfiles)
        .select()
        .eq('id', uid)
        .single();
    return Profile.fromJson(data);
  }

  static User? get currentUser => supabase.auth.currentUser;
}
