/// Search History Model
///
/// Lưu lịch sử tìm kiếm của user.
class SearchHistoryModel {
  final String id;
  final String userId;
  final String query;
  final String? searchType; // 'product', 'shop', 'all'
  final DateTime createdAt;

  SearchHistoryModel({
    required this.id,
    required this.userId,
    required this.query,
    this.searchType,
    required this.createdAt,
  });

  factory SearchHistoryModel.fromJson(Map<String, dynamic> json) {
    return SearchHistoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      query: json['query'] as String,
      searchType: json['search_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'query': query,
      'search_type': searchType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
