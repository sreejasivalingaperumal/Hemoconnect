import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Storage service managing file uploads & signed URL generation for medical reports.
class StorageService {
  final SupabaseClient _client = SupabaseConfig.client;
  final String _bucketName = SupabaseConfig.storageBucketMedicalReports;

  /// Upload medical report binary bytes or file stream to Supabase Storage
  Future<String> uploadMedicalReport({
    required String userId,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '_');
    final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

    final bytes = Uint8List.fromList(fileBytes);

    await _client.storage.from(_bucketName).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

    return storagePath;
  }

  /// Create a secure temporary signed URL for viewing private medical reports (valid 1 hour)
  Future<String> getSignedReportUrl(String storagePath) async {
    try {
      // If full URL was accidentally passed
      if (storagePath.startsWith('http://') || storagePath.startsWith('https://')) {
        return storagePath;
      }

      final url = await _client.storage.from(_bucketName).createSignedUrl(
            storagePath,
            3600, // 1 hour expiration
          );
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating signed URL: $e');
      }
      // Fallback to public URL if bucket is marked public
      return _client.storage.from(_bucketName).getPublicUrl(storagePath);
    }
  }
}
