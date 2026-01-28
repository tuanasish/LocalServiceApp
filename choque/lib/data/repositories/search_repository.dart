import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_history_model.dart';
import '../../config/constants.dart';

/// Search Repository
///
/// Xử lý các thao tác liên quan đến search history.
class SearchRepository {
  final SupabaseClient _client;

  SearchRepository(this._client);

  factory SearchRepository.instance() {
    return SearchRepository(Supabase.instance.client);
  }

  /// Lưu search history
  Future<void> saveSearchHistory({
    required String userId,
    required String query,
    String? searchType,
  }) async {
    if (query.trim().isEmpty) return;

    await _client
        .from('search_history')
        .insert({
          'user_id': userId,
          'query': query.trim(),
          'search_type': searchType,
        })
        .timeout(AppConstants.apiTimeout);
  }

  /// Lấy search history của user
  Future<List<SearchHistoryModel>> getSearchHistory({
    required String userId,
    int limit = 10,
  }) async {
    final response = await _client
        .from('search_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit)
        .timeout(AppConstants.apiTimeout);

    return (response as List)
        .map(
          (json) => SearchHistoryModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Xóa search history
  Future<void> deleteSearchHistory(String historyId) async {
    await _client
        .from('search_history')
        .delete()
        .eq('id', historyId)
        .timeout(AppConstants.apiTimeout);
  }

  /// Xóa tất cả search history của user
  Future<void> clearSearchHistory(String userId) async {
    await _client
        .from('search_history')
        .delete()
        .eq('user_id', userId)
        .timeout(AppConstants.apiTimeout);
  }

  /// Lấy popular searches (top queries)
  Future<List<String>> getPopularSearches({
    required String marketId,
    int limit = 10,
  }) async {
    // Query để lấy top queries từ search_history
    // Có thể cần aggregate query hoặc RPC function
    // Tạm thời return empty, có thể implement sau
    return [];
  }
}
