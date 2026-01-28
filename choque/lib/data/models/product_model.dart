/// Product Model
///
/// Ánh xạ bảng `products` trong Supabase.
class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? imagePath;
  final int basePrice;
  final String? category;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    required this.basePrice,
    this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
      basePrice: json['base_price'] as int,
      category: json['category'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_path': imagePath,
      'base_price': basePrice,
      'category': category,
      'status': status,
    };
  }

  /// Tạo URL ảnh từ Supabase Storage
  String? get imageUrl => imagePath != null
      ? 'https://ipdwpzgbznphkmdewjdl.supabase.co/storage/v1/object/public/products/$imagePath'
      : null;
}
