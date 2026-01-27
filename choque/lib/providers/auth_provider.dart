import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import 'app_providers.dart' show currentUserProvider;

/// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth state stream provider - listens to auth changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange;
});

// NOTE: currentUserProvider is now imported from app_providers.dart
// It's a StreamProvider<User?>, use .value to get the current user synchronously

/// User profile async provider - fetches from database
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final supabase = ref.watch(supabaseProvider);
  
  try {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .single();
    
    return UserProfile.fromJson(response);
  } catch (e) {
    // Log error để debug
    debugPrint('Error fetching profile: $e');
    
    // Nếu là lỗi network, throw để provider hiển thị error state
    // Nếu là lỗi "not found", return null (user chưa có profile)
    if (e.toString().contains('Failed host lookup') || 
        e.toString().contains('SocketException') ||
        e.toString().contains('Network') ||
        e.toString().contains('timeout')) {
      // Network error - rethrow để provider hiển thị error
      rethrow;
    }
    
    // Profile not found hoặc lỗi khác - return null (user chưa có profile)
    return null;
  }
});

/// Active role state notifier
class ActiveRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.customer;
  
  void setRole(UserRole role) {
    state = role;
  }
}

/// Active role state provider (selected by user when multi-role)
final activeRoleProvider = NotifierProvider<ActiveRoleNotifier, UserRole>(() {
  return ActiveRoleNotifier();
});

/// Auth notifier for login/logout actions
class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  SupabaseClient get _supabase => ref.read(supabaseProvider);

  /// Sign in with email/password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign in with phone/password (for Vietnam users)
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Convert phone to email format for auth
      final email = '${phone.replaceAll('+', '')}@choque.local';
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign up with email/password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      state = const AsyncValue.data(null);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Send OTP to email for passwordless authentication
  Future<void> signInWithOtp({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null, // Use OTP code instead of magic link
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Verify OTP code sent to email
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
      
      // Refresh profile data if verification successful
      if (response.user != null) {
        ref.invalidate(userProfileProvider);
      }
      
      state = const AsyncValue.data(null);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Create profile for new user (public method for registration flow)
  Future<void> createProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
    DateTime? birthDate,
    String? gender,
  }) async {
    await _supabase.from('profiles').upsert({
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'gender': gender,
      'roles': ['customer'], // Default role
      'market_id': 'default',
      'is_guest': false,
      'status': 'active',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Add address for user
  Future<void> addAddress({
    required String userId,
    required String details,
    String label = 'Nhà riêng',
    bool isDefault = true,
  }) async {
    await _supabase.from('addresses').insert({
      'user_id': userId,
      'details': details,
      'label': label,
      'is_default': isDefault,
    });
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabase.from('profiles').update(updates).eq('user_id', user.id);
      
      // Invalidate profile provider to refresh data
      ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Upload avatar to Supabase Storage
  Future<String?> uploadAvatar(XFile image) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return null;

    final bytes = await image.readAsBytes();
    final fileExt = image.path.split('.').last;
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = fileName;

    await _supabase.storage.from('avatars').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );

    final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
    return imageUrl;
  }

  /// Continue as guest
  Future<AuthResponse> continueAsGuest() async {
    state = const AsyncValue.loading();
    try {
      // Sign in anonymously
      final response = await _supabase.auth.signInAnonymously();

      // Create guest profile
      if (response.user != null) {
        await _supabase.from('profiles').insert({
          'user_id': response.user!.id,
          'roles': ['customer'],
          'market_id': 'default',
          'is_guest': true,
          'status': 'active',
        });
      }

      state = const AsyncValue.data(null);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Send password recovery OTP to email
  Future<void> sendRecoveryOtp({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // Don't create new user, only for existing users
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Verify recovery OTP and get session for password update
  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      state = const AsyncValue.data(null);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update password (after reset or change)
  Future<void> updatePassword({required String newPassword}) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signOut();
      ref.read(activeRoleProvider.notifier).setRole(UserRole.customer);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Switch active role (for multi-role users)
  void switchRole(UserRole role) {
    ref.read(activeRoleProvider.notifier).setRole(role);
  }

  /// Update FCM token
  Future<void> updateFcmToken(String token) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    await _supabase.from('profiles').update({
      'fcm_token': token,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', user.id);
  }

  /// Update driver status
  Future<void> updateDriverStatus(String status) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    await _supabase.from('profiles').update({
      'driver_status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', user.id);

    ref.invalidate(userProfileProvider);
  }
}

/// Auth notifier provider
final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(() {
  return AuthNotifier();
});

/// Helper provider: Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user != null;
});

/// Helper provider: Get user's available roles
final availableRolesProvider = Provider<List<UserRole>>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (p) => p?.roles.map((r) => UserRole.fromString(r)).toList() ?? [UserRole.customer],
    loading: () => [UserRole.customer],
    error: (_, ___) => [UserRole.customer],
  );
});

/// Helper provider: Check if user needs role selection
final needsRoleSelectionProvider = Provider<bool>((ref) {
  final roles = ref.watch(availableRolesProvider);
  return roles.length > 1;
});
