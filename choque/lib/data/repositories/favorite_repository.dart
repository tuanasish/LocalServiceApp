import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/merchant_model.dart';
import '../../config/constants.dart';

class FavoriteRepository {
  final SupabaseClient _client;

  FavoriteRepository(this._client);

  factory FavoriteRepository.instance() {
    return FavoriteRepository(Supabase.instance.client);
  }

  /// Lấy danh sách shop yêu thích của user
  Future<List<MerchantModel>> getMyFavorites() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('user_favorites')
        .select('shops(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .timeout(AppConstants.apiTimeout);

    return (response as List)
        .map(
          (json) =>
              MerchantModel.fromJson(json['shops'] as Map<String, dynamic>),
        )
        .toList();
  }

  /// Kiểm tra xem shop có trong danh sách yêu thích không
  Future<bool> isFavorite(String shopId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('user_favorites')
        .select()
        .eq('user_id', userId)
        .eq('shop_id', shopId)
        .maybeSingle()
        .timeout(AppConstants.apiTimeout);

    return response != null;
  }

  /// Toggle yêu thích
  Future<void> toggleFavorite(String shopId, bool isFavorite) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    if (isFavorite) {
      await _client
          .from('user_favorites')
          .insert({'user_id': userId, 'shop_id': shopId})
          .timeout(AppConstants.apiTimeout);
    } else {
      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('shop_id', shopId)
          .timeout(AppConstants.apiTimeout);
    }
  }
}
