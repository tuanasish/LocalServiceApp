import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

/// Supabase Client Singleton
///
/// Khởi tạo một lần trong main.dart và sử dụng lại trong toàn bộ app.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Khởi tạo Supabase - gọi trong main() trước runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// Lấy user hiện tại (null nếu chưa đăng nhập)
  static User? get currentUser => client.auth.currentUser;

  /// Kiểm tra xem đã đăng nhập chưa
  static bool get isLoggedIn => currentUser != null;
}
