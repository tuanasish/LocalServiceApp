import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// =============================================================
/// IMAGE UPLOAD SERVICE
/// =============================================================
/// 
/// Utility for uploading images to Supabase Storage.

class ImageUploadService {
  final SupabaseClient _client;
  static const String _productsBucket = 'products';
  
  ImageUploadService(this._client);
  
  factory ImageUploadService.instance() {
    return ImageUploadService(Supabase.instance.client);
  }

  /// Upload an image file to the products bucket.
  /// Returns the storage path (not full URL).
  Future<String> uploadProductImage(File file) async {
    final extension = path.extension(file.path).toLowerCase();
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Invalid image format. Allowed: jpg, jpeg, png, webp, gif');
    }
    
    final uuid = const Uuid().v4();
    final fileName = '$uuid$extension';
    
    await _client.storage.from(_productsBucket).upload(
      fileName,
      file,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
      ),
    );
    
    return fileName;
  }

  /// Delete an image from the products bucket
  Future<void> deleteProductImage(String imagePath) async {
    await _client.storage.from(_productsBucket).remove([imagePath]);
  }

  /// Get public URL for an image
  String getPublicUrl(String imagePath) {
    return _client.storage.from(_productsBucket).getPublicUrl(imagePath);
  }
}
