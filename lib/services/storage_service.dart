import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/supabase_client.dart';

class StorageService {
  static const String kBucketServiceDocs = 'service-documents';

  static Future<String> uploadPhoto(XFile file, String userId) async {
    final ext = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '$userId/$fileName';

    await supabase.storage
        .from(kBucketReportPhotos)
        .upload(path, File(file.path));

    return path;
  }

  static Future<String> uploadDocument(File file, String userId) async {
    final ext = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '$userId/docs/$fileName';

    await supabase.storage
        .from(kBucketServiceDocs)
        .upload(path, file);

    return path;
  }

  static Future<String> getSignedUrl(String path, {String? bucket}) async {
    return await supabase.storage
        .from(bucket ?? kBucketReportPhotos)
        .createSignedUrl(path, 3600);
  }
}
