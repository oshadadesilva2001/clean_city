import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/supabase_client.dart';

class StorageService {
  static Future<String> uploadPhoto(XFile file, String userId) async {
    final ext = file.path.split('.').last;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '$userId/$fileName';

    await supabase.storage
        .from(kBucketReportPhotos)
        .upload(path, File(file.path));

    return path;
  }

  static Future<String> getSignedUrl(String path) async {
    return await supabase.storage
        .from(kBucketReportPhotos)
        .createSignedUrl(path, 3600);
  }
}
