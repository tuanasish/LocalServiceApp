import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../config/constants.dart';

/// Auth Repository
/// 
/// Xử lý xác thực và quản lý phiên người dùng.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  factory AuthRepository.instance() {
    return AuthRepository(Supabase.instance.client);
  }

  /// Lấy user hiện tại
  User? get currentUser => _client.auth.currentUser;

  /// Kiểm tra đã đăng nhập chưa
  bool get isLoggedIn => currentUser != null;

  /// Lấy profile của user hiện tại
  Future<ProfileModel?> getCurrentProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle()
        .timeout(AppConstants.apiTimeout);

    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }

  /// Đăng nhập bằng OTP (Phone)
  Future<void> signInWithOtp(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
  }

  /// Xác thực OTP
  Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Đăng nhập ẩn danh (Guest mode)
  Future<AuthResponse> signInAnonymously() async {
    return await _client.auth.signInAnonymously();
  }

  /// Cập nhật profile
  Future<ProfileModel> updateProfile({
    String? fullName,
    String? phone,
    String? fcmToken,
    String? deviceId,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (fcmToken != null) updates['fcm_token'] = fcmToken;
    if (deviceId != null) updates['device_id'] = deviceId;

    final response = await _client
        .from('profiles')
        .update(updates)
        .eq('user_id', userId)
        .select()
        .single()
        .timeout(AppConstants.apiTimeout);

    return ProfileModel.fromJson(response);
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Stream theo dõi thay đổi auth state
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
