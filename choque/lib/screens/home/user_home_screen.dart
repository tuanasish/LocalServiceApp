import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/cart_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/address_provider.dart';
import '../../models/user_address.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/merchant_card.dart';
import '../../ui/widgets/app_search_bar.dart';
import '../../utils/distance_utils.dart';

/// User Home Screen - Chuyển đổi từ Stitch design
/// Design: User Home Screen (Project: 13405594091078915398)
/// Colors: Primary #1E7F43, Font: Inter, Roundness: ROUND_TWELVE
class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  double? _userLat;
  double? _userLng;
  
  // Cache cho category filtering
  List<String>? _cachedCategories;
  
  // Cache cho popular merchants với distance đã tính
  List<dynamic>? _cachedPopularMerchants;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    // Lấy user location từ saved address hoặc current location
    final addressesAsync = ref.read(userAddressesProvider);
    addressesAsync.whenData((addresses) {
      if (addresses.isEmpty) return;
      final defaultAddress = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
      if (defaultAddress.lat != null && defaultAddress.lng != null) {
        final oldLat = _userLat;
        final oldLng = _userLng;
        setState(() {
          _userLat = defaultAddress.lat;
          _userLng = defaultAddress.lng;
          // Invalidate cache nếu location thay đổi
          if (oldLat != _userLat || oldLng != _userLng) {
            _cachedPopularMerchants = null;
          }
        });
      }
    });

    // Nếu không có từ address, thử lấy current location
    if (_userLat == null || _userLng == null) {
      try {
        final position = await Geolocator.getCurrentPosition();
        final oldLat = _userLat;
        final oldLng = _userLng;
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          // Invalidate cache nếu location thay đổi
          if (oldLat != _userLat || oldLng != _userLng) {
            _cachedPopularMerchants = null;
          }
        });
      } catch (e) {
        // Ignore location error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header với địa chỉ giao hàng
            _buildHeader(context),
            
            // Nội dung chính
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    
                    // Category Grid
                    _buildCategoryGrid(ref),
                    
                    const SizedBox(height: 32),
                    
                    // Featured Merchants
                    _buildFeaturedMerchants(context, ref),
                    
                    const SizedBox(height: 32),
                    
                    // Popular Near You
                    _buildPopularNearYou(context, ref),
                    
                    const SizedBox(height: 100), // Space cho bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, ref),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final addressesAsync = ref.watch(userAddressesProvider);
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          
          // Address và Notification
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: addressesAsync.when(
                    data: (addresses) {
                      UserAddress? defaultAddress;
                      if (addresses.isNotEmpty) {
                        try {
                          defaultAddress = addresses.firstWhere((a) => a.isDefault);
                        } catch (e) {
                          defaultAddress = addresses.first;
                        }
                      }
                      
                      final displayAddress = defaultAddress?.details ?? 
                                           defaultAddress?.fullDisplayAddress ?? 
                                           'Chưa có địa chỉ';
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'GIAO ĐẾN',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayAddress,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'GIAO ĐẾN',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    error: (e, st) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'GIAO ĐẾN',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chưa có địa chỉ',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.push('/notifications'),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: const AppSearchBar(hintText: 'Search for food, cuisines...'),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        // Cache categories để tránh tính lại mỗi lần build
        if (_cachedCategories == null || categories.length != _cachedCategories!.length) {
          // Danh sách categories ưu tiên theo yêu cầu người dùng
          final priorityCategories = [
            'Ăn vặt', 'Snacks', 'Đồ ăn vặt',
            'Tráng Miệng', 'Desserts', 'Tráng miệng',
            'Chè',
            'Hoa quả', 'Fruits', 'Trái cây',
            'Gà Rán', 'Fried Chicken', 'Gà',
          ];
          
          // Danh sách categories bổ sung
          final additionalCategories = [
            'Rice', 'Cơm',
            'Noodles', 'Phở', 'Bún',
            'Drinks', 'Đồ uống', 'Nước',
            'Burgers', 'Bánh mì',
            'Pizza',
            'Healthy', 'Lành mạnh',
          ];
          
          // Tìm categories từ database theo thứ tự ưu tiên
          final displayCategories = <String>[];
          
          // Ưu tiên các categories người dùng yêu cầu
          for (final priority in priorityCategories) {
            final found = categories.firstWhere(
              (cat) {
                final lowerCat = cat.toLowerCase();
                final lowerPriority = priority.toLowerCase();
                return lowerCat.contains(lowerPriority) || lowerPriority.contains(lowerCat);
              },
              orElse: () => '',
            );
            if (found.isNotEmpty && !displayCategories.contains(found)) {
              displayCategories.add(found);
            }
          }
          
          // Nếu chưa đủ, thêm từ danh sách bổ sung
          if (displayCategories.length < 8) {
            for (final additional in additionalCategories) {
              if (displayCategories.length >= 8) break;
              final found = categories.firstWhere(
                (cat) {
                  final lowerCat = cat.toLowerCase();
                  final lowerAdditional = additional.toLowerCase();
                  return lowerCat.contains(lowerAdditional) || lowerAdditional.contains(lowerCat);
                },
                orElse: () => '',
              );
              if (found.isNotEmpty && !displayCategories.contains(found)) {
                displayCategories.add(found);
              }
            }
          }
          
          // Nếu vẫn chưa đủ, thêm categories mặc định
          if (displayCategories.length < 8) {
            final defaultCategories = ['Ăn vặt', 'Tráng Miệng', 'Chè', 'Hoa quả', 'Gà Rán', 'Rice', 'Noodles', 'Drinks'];
            for (final defaultCat in defaultCategories) {
              if (displayCategories.length >= 8) break;
              if (!displayCategories.any((c) => c.toLowerCase().contains(defaultCat.toLowerCase()))) {
                displayCategories.add(defaultCat);
              }
            }
          }
          
          // Giới hạn 8 categories đầu tiên và cache
          _cachedCategories = displayCategories.take(8).toList();
        }
        
        final finalCategories = _cachedCategories!;
        
        if (finalCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.primary.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 24,
              crossAxisSpacing: 16,
              mainAxisExtent: 96,
            ),
            itemCount: finalCategories.length,
            itemBuilder: (context, index) {
              final categoryName = finalCategories[index];
              final categoryInfo = _getCategoryInfo(categoryName);
              return _buildCategoryItem(
                icon: categoryInfo['icon'] as IconData,
                label: categoryName,
                color: categoryInfo['color'] as MaterialColor,
              );
            },
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(), // Ẩn nếu lỗi
    );
  }

  Map<String, dynamic> _getCategoryInfo(String categoryName) {
    // Map category name từ database sang icon và color
    final lowerName = categoryName.toLowerCase();
    
    // Ưu tiên các categories người dùng yêu cầu
    if (lowerName.contains('ăn vặt') || lowerName.contains('snack')) {
      return {'icon': Icons.bakery_dining, 'color': Colors.red};
    } else if (lowerName.contains('tráng miệng') || lowerName.contains('dessert')) {
      return {'icon': Icons.icecream, 'color': Colors.pink};
    } else if (lowerName.contains('chè')) {
      return {'icon': Icons.emoji_food_beverage, 'color': Colors.purple};
    } else if (lowerName.contains('hoa quả') || lowerName.contains('trái cây') || lowerName.contains('fruit')) {
      return {'icon': Icons.apple, 'color': Colors.redAccent};
    } else if (lowerName.contains('gà rán') || lowerName.contains('fried chicken') || (lowerName.contains('gà') && lowerName.contains('rán'))) {
      return {'icon': Icons.kebab_dining, 'color': Colors.deepOrange};
    } else if (lowerName.contains('rice') || lowerName.contains('cơm')) {
      return {'icon': Icons.rice_bowl, 'color': Colors.orange};
    } else if (lowerName.contains('noodle') || lowerName.contains('bún') || lowerName.contains('phở')) {
      return {'icon': Icons.ramen_dining, 'color': Colors.yellow};
    } else if (lowerName.contains('drink') || lowerName.contains('nước') || lowerName.contains('đồ uống')) {
      return {'icon': Icons.local_bar, 'color': Colors.blue};
    } else if (lowerName.contains('burger') || lowerName.contains('bánh mì')) {
      return {'icon': Icons.lunch_dining, 'color': Colors.amber};
    } else if (lowerName.contains('pizza')) {
      return {'icon': Icons.local_pizza, 'color': Colors.pink};
    } else if (lowerName.contains('healthy') || lowerName.contains('lành mạnh')) {
      return {'icon': Icons.spa, 'color': Colors.green};
    } else if (lowerName.contains('soup') || lowerName.contains('canh') || lowerName.contains('cháo')) {
      return {'icon': Icons.soup_kitchen, 'color': Colors.deepOrange};
    } else if (lowerName.contains('salad') || lowerName.contains('gỏi')) {
      return {'icon': Icons.eco, 'color': Colors.lightGreen};
    } else if (lowerName.contains('seafood') || lowerName.contains('hải sản')) {
      return {'icon': Icons.set_meal, 'color': Colors.cyan};
    } else if (lowerName.contains('chicken') || lowerName.contains('gà')) {
      return {'icon': Icons.kebab_dining, 'color': Colors.deepOrange};
    } else if (lowerName.contains('beef') || lowerName.contains('bò')) {
      return {'icon': Icons.dining, 'color': Colors.brown};
    } else if (lowerName.contains('pork') || lowerName.contains('heo') || lowerName.contains('lợn')) {
      return {'icon': Icons.restaurant_menu, 'color': Colors.pinkAccent};
    } else if (lowerName.contains('vegetarian') || lowerName.contains('chay')) {
      return {'icon': Icons.eco, 'color': Colors.lightGreen};
    } else if (lowerName.contains('fast food') || lowerName.contains('đồ nhanh')) {
      return {'icon': Icons.fastfood, 'color': Colors.redAccent};
    } else if (lowerName.contains('breakfast') || lowerName.contains('sáng')) {
      return {'icon': Icons.breakfast_dining, 'color': Colors.orangeAccent};
    } else if (lowerName.contains('lunch') || lowerName.contains('trưa')) {
      return {'icon': Icons.lunch_dining, 'color': Colors.amber};
    } else if (lowerName.contains('dinner') || lowerName.contains('tối')) {
      return {'icon': Icons.dinner_dining, 'color': Colors.deepPurple};
    } else if (lowerName.contains('coffee') || lowerName.contains('cà phê')) {
      return {'icon': Icons.local_cafe, 'color': Colors.brown};
    } else if (lowerName.contains('tea') || lowerName.contains('trà')) {
      return {'icon': Icons.emoji_food_beverage, 'color': Colors.green};
    } else if (lowerName.contains('juice') || lowerName.contains('nước ép')) {
      return {'icon': Icons.water_drop, 'color': Colors.orange};
    } else if (lowerName.contains('smoothie') || lowerName.contains('sinh tố')) {
      return {'icon': Icons.local_drink, 'color': Colors.purple};
    } else if (lowerName.contains('cake') || lowerName.contains('bánh ngọt')) {
      return {'icon': Icons.cake, 'color': Colors.pink};
    } else if (lowerName.contains('bread') || lowerName.contains('bánh mì')) {
      return {'icon': Icons.breakfast_dining, 'color': Colors.amber};
    } else if (lowerName.contains('sushi') || lowerName.contains('sashimi')) {
      return {'icon': Icons.set_meal, 'color': Colors.red};
    } else if (lowerName.contains('korean') || lowerName.contains('hàn')) {
      return {'icon': Icons.restaurant, 'color': Colors.redAccent};
    } else if (lowerName.contains('japanese') || lowerName.contains('nhật')) {
      return {'icon': Icons.set_meal, 'color': Colors.red};
    } else if (lowerName.contains('chinese') || lowerName.contains('trung')) {
      return {'icon': Icons.dining, 'color': Colors.deepOrange};
    } else if (lowerName.contains('thai') || lowerName.contains('thái')) {
      return {'icon': Icons.restaurant_menu, 'color': Colors.orange};
    } else if (lowerName.contains('vietnamese') || lowerName.contains('việt')) {
      return {'icon': Icons.rice_bowl, 'color': Colors.green};
    }
    
    // Default
    return {'icon': Icons.restaurant, 'color': Colors.grey};
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color.shade700,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child:                 Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedMerchants(BuildContext context, WidgetRef ref) {
    // Chiều cao list card tỉ lệ theo chiều ngang màn hình để responsive.
    final screenWidth = MediaQuery.of(context).size.width;
    final listHeight = screenWidth * 0.8; // ~288px trên màn 360px, đủ cho card + shadow.

    final merchantsAsync = ref.watch(merchantsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Merchants',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'View all',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: listHeight,
          child: merchantsAsync.when(
            data: (merchants) {
              if (merchants.isEmpty) {
                return Center(
                  child: Text(
                    'Chưa có cửa hàng nào',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: merchants.length,
                separatorBuilder: (context, index) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final merchant = merchants[index];
                  // Tách MerchantCardItem thành ConsumerWidget riêng
                  // để chỉ widget đó rebuild khi category/image load xong
                  return _MerchantCardItem(
                    merchant: merchant,
                    userLat: _userLat,
                    userLng: _userLng,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Không thể tải dữ liệu',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(merchantsProvider),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPopularNearYou(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(merchantsProvider);

    return merchantsAsync.when(
      data: (merchants) {
        // Cache popular merchants với distance đã tính để tránh tính lại mỗi lần build
        // Chỉ tính lại nếu merchants list thay đổi hoặc user location thay đổi
        if (_cachedPopularMerchants == null || 
            merchants.length != _cachedPopularMerchants!.length ||
            _userLat == null || _userLng == null) {
          // Filter: chỉ lấy merchants có rating và lat/lng
          // Sort: theo rating giảm dần, sau đó theo distance
          final popularMerchants = merchants
              .where((m) => m.rating != null && m.lat != null && m.lng != null)
              .toList();
          
          // Tính distance và cache trong một lần duyệt
          if (_userLat != null && _userLng != null) {
            popularMerchants.sort((a, b) {
              // Sort theo rating trước
              final ratingCompare = (b.rating ?? 0.0).compareTo(a.rating ?? 0.0);
              if (ratingCompare != 0) return ratingCompare;
              // Nếu rating bằng, sort theo distance (đã cache trong sort)
              final distA = DistanceUtils.calculateDistance(
                _userLat!, _userLng!, a.lat!, a.lng!);
              final distB = DistanceUtils.calculateDistance(
                _userLat!, _userLng!, b.lat!, b.lng!);
              return distA.compareTo(distB);
            });
          } else {
            // Nếu không có location, chỉ sort theo rating
            popularMerchants.sort((a, b) {
              return (b.rating ?? 0.0).compareTo(a.rating ?? 0.0);
            });
          }
          
          // Cache top 2 merchants
          _cachedPopularMerchants = popularMerchants.take(2).toList();
        }
        
        final topMerchants = _cachedPopularMerchants!;
        
        if (topMerchants.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular Near You',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...topMerchants.asMap().entries.map((entry) {
                final index = entry.key;
                final merchant = entry.value;
                
                return Padding(
                  padding: EdgeInsets.only(bottom: index < topMerchants.length - 1 ? 16 : 0),
                  // Tách thành ConsumerWidget riêng để chỉ item đó rebuild
                  child: _PopularMerchantItem(
                    merchant: merchant,
                    userLat: _userLat,
                    userLng: _userLng,
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular Near You',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(Icons.home, 'Home', isActive: true),
          _buildNavItem(Icons.receipt_long, 'Orders', isActive: false),
          _buildNavItem(Icons.shopping_cart_outlined, 'Cart', isActive: false, badgeCount: ref.watch(cartProvider.select((items) => items.length))),
          _buildNavItem(Icons.person_outline, 'Profile', isActive: false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false, int badgeCount = 0}) {
    // Màu sắc cho icon: active = primary, inactive = xám
    final color = isActive 
        ? AppColors.primary
        : const Color(0xFF94A3B8);
    
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: isActive
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  icon,
                  size: 26,
                  color: color,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantCardItem extends ConsumerWidget {
  final dynamic merchant;
  final double? userLat;
  final double? userLng;

  const _MerchantCardItem({
    required this.merchant,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catAsync = ref.watch(shopPrimaryCategoryProvider(merchant.id));
    final imgAsync = ref.watch(shopImageUrlProvider(merchant.id));
    
    String? distance;
    if (userLat != null && userLng != null && merchant.lat != null && merchant.lng != null) {
      distance = DistanceUtils.formatDistance(
        DistanceUtils.calculateDistance(userLat!, userLng!, merchant.lat!, merchant.lng!),
      );
    }
    
    return MerchantCard(
      name: merchant.name,
      rating: merchant.rating ?? 0.0,
      reviews: 'Chưa có đánh giá',
      deliveryTime: '20-30 min',
      deliveryFee: '15.000đ',
      cuisine: catAsync.value ?? 'Đồ ăn',
      distance: distance ?? 'Không xác định',
      imageUrl: imgAsync.value ?? '',
      onTap: () => context.push('/store/${merchant.id}'),
    );
  }
}

class _PopularMerchantItem extends ConsumerWidget {
  final dynamic merchant;
  final double? userLat;
  final double? userLng;

  const _PopularMerchantItem({
    required this.merchant,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catAsync = ref.watch(shopPrimaryCategoryProvider(merchant.id));
    final imgAsync = ref.watch(shopImageUrlProvider(merchant.id));
    
    String? distance;
    if (userLat != null && userLng != null && merchant.lat != null && merchant.lng != null) {
      distance = DistanceUtils.formatDistance(
        DistanceUtils.calculateDistance(userLat!, userLng!, merchant.lat!, merchant.lng!),
      );
    }
    
    final imageUrl = imgAsync.value ?? '';
    final placeholder = Container(
      width: 96,
      height: 96,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.image, size: 22, color: Colors.grey),
    );
    
    return GestureDetector(
      onTap: () => context.push('/store/${merchant.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => placeholder,
                    )
                  : placeholder,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          merchant.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            (merchant.rating ?? 0.0).toString(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    catAsync.value ?? 'Đồ ăn',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.near_me, color: Color(0xFF1E7F43), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        distance ?? 'Không xác định',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule, color: Color(0xFF1E7F43), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '20-30 min',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
