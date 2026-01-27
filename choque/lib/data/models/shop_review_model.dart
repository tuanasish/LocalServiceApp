class ShopReviewModel {
  final String id;
  final String shopId;
  final String userId;
  final String? orderId;
  final int rating;
  final String? comment;
  final bool isAnonymous;
  final DateTime createdAt;
  final String? userName; // From profiles join
  final String? userAvatar; // From profiles join

  const ShopReviewModel({
    required this.id,
    required this.shopId,
    required this.userId,
    this.orderId,
    required this.rating,
    this.comment,
    this.isAnonymous = false,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  factory ShopReviewModel.fromJson(Map<String, dynamic> json) {
    return ShopReviewModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['profiles']?['full_name'] as String?,
      userAvatar: json['profiles']?['avatar_url'] as String?,
    );
  }
}
