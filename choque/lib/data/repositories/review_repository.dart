import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop_review_model.dart';
import '../../config/constants.dart';

class ReviewRepository {
  final SupabaseClient _client;

  ReviewRepository(this._client);

  factory ReviewRepository.instance() {
    return ReviewRepository(Supabase.instance.client);
  }

  /// Lấy danh sách đánh giá của shop
  Future<List<ShopReviewModel>> getShopReviews(String shopId) async {
    final response = await _client
        .from('shop_reviews')
        .select('*, profiles(full_name, avatar_url)')
        .eq('shop_id', shopId)
        .order('created_at', ascending: false)
        .timeout(AppConstants.apiTimeout);

    return (response as List)
        .map((json) => ShopReviewModel.fromJson(json))
        .toList();
  }

  /// Gửi đánh giá mới
  Future<void> submitReview({
    required String shopId,
    required int rating,
    String? comment,
    String? orderId,
    bool isAnonymous = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client
        .from('shop_reviews')
        .insert({
          'shop_id': shopId,
          'user_id': userId,
          'order_id': orderId,
          'rating': rating,
          'comment': comment,
          'is_anonymous': isAnonymous,
        })
        .timeout(AppConstants.apiTimeout);
  }
}
