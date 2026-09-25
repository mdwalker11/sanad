import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class MediaUploadException implements Exception {
  const MediaUploadException(this.message);
  final String message;

  @override
  String toString() => 'MediaUploadException: $message';
}

String mediaStoragePath({
  required String userId,
  required String orderId,
  required String extension,
  required int timestamp,
}) {
  final safeExtension = extension.replaceAll('.', '').toLowerCase();
  if (userId.trim().isEmpty ||
      orderId.trim().isEmpty ||
      safeExtension.isEmpty) {
    throw const MediaUploadException('بيانات الصورة ناقصة');
  }
  return '$userId/$orderId/$timestamp.$safeExtension';
}

void validateMedia(Uint8List bytes, String extension) {
  if (bytes.isEmpty) throw const MediaUploadException('الملف فارغ');
  const allowed = {'jpg', 'jpeg', 'png', 'webp'};
  if (!allowed.contains(extension.replaceAll('.', '').toLowerCase())) {
    throw const MediaUploadException('نوع الملف غير مدعوم');
  }
}

class OrderMediaRepository {
  const OrderMediaRepository(this.client);

  final SupabaseClient client;

  Future<String> upload({
    required String orderId,
    required String userId,
    required Uint8List bytes,
    required String extension,
    String stage = 'request',
  }) async {
    validateMedia(bytes, extension);
    final path = mediaStoragePath(
      userId: userId,
      orderId: orderId,
      extension: extension,
      timestamp: DateTime.now().microsecondsSinceEpoch,
    );
    await client.storage.from('sanad-media').uploadBinary(path, bytes);
    await client
        .from('order_media')
        .insert({
          'order_id': orderId,
          'uploaded_by': userId,
          'media_type': extension.replaceAll('.', '').toLowerCase(),
          'stage': stage,
          'storage_path': path,
        })
        .select()
        .single();
    return path;
  }

  Future<String> signedUrl(String path) {
    return client.storage.from('sanad-media').createSignedUrl(path, 3600);
  }
}
