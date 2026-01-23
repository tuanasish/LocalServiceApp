# CHỢ QUÊ MVP - FLUTTER PROJECT STRUCTURE

## Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── config/
│   ├── constants.dart
│   ├── theme.dart
│   └── routes.dart
│
├── core/
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── error_handler.dart
│   ├── network/
│   │   └── network_info.dart
│   └── utils/
│       ├── formatters.dart
│       └── validators.dart
│
├── data/
│   ├── models/
│   │   ├── profile.dart
│   │   ├── order.dart
│   │   ├── shop.dart
│   │   ├── product.dart
│   │   ├── location.dart
│   │   └── app_config.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── order_repository.dart
│   │   ├── shop_repository.dart
│   │   ├── location_repository.dart
│   │   └── config_repository.dart
│   └── datasources/
│       ├── supabase_client.dart
│       └── local_storage.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── config_provider.dart
│   ├── order_provider.dart
│   ├── location_provider.dart
│   └── driver_provider.dart
│
├── screens/
│   ├── splash/
│   ├── home/
│   ├── order/
│   │   ├── create_order_screen.dart
│   │   ├── order_detail_screen.dart
│   │   └── order_list_screen.dart
│   ├── shop/
│   │   ├── shop_list_screen.dart
│   │   └── shop_menu_screen.dart
│   ├── driver/
│   │   ├── driver_home_screen.dart
│   │   └── driver_order_detail_screen.dart
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart
│   │   ├── admin_orders_screen.dart
│   │   └── admin_assign_screen.dart
│   └── merchant/
│       └── merchant_menu_screen.dart
│
├── widgets/
│   ├── common/
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── loading_overlay.dart
│   │   └── error_widget.dart
│   ├── order/
│   │   ├── order_card.dart
│   │   └── order_status_stepper.dart
│   ├── location/
│   │   ├── location_picker.dart
│   │   └── preset_location_dropdown.dart
│   └── map/
│       └── vietmap_widget.dart
│
└── services/
    ├── notification_service.dart
    ├── location_service.dart
    └── tracking_service.dart
```

---

## pubspec.yaml

```yaml
name: cho_que
description: Chợ Quê - Ứng dụng dịch vụ địa phương
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # Supabase
  supabase_flutter: ^2.3.0
  
  # Map
  vietmap_flutter_gl: ^1.0.0
  
  # GPS
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive_flutter: ^1.1.0
  
  # Network
  connectivity_plus: ^5.0.2
  
  # Push Notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  
  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  
  # Utils
  intl: ^0.18.1
  uuid: ^4.2.2
  
  # Code Generation
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.8
  freezed: ^2.4.6
  json_serializable: ^6.7.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
```

---

## Key Files

### lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'config/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive (local cache)
  await Hive.initFlutter();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  runApp(
    const ProviderScope(
      child: ChoQueApp(),
    ),
  );
}
```

### lib/config/constants.dart

```dart
class AppConstants {
  // Supabase
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // VietMap
  static const String vietmapApiKey = 'YOUR_VIETMAP_API_KEY';
  
  // Market
  static const String defaultMarketId = 'huyen_demo';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration retryDelay = Duration(seconds: 2);
  static const int maxRetries = 2;
  
  // Cache
  static const Duration configCacheTTL = Duration(minutes: 15);
  static const Duration locationCacheTTL = Duration(hours: 24);
}
```

### lib/data/models/order.dart

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus {
  pendingConfirmation,
  confirmed,
  assigned,
  pickedUp,
  completed,
  canceled;
  
  static OrderStatus fromString(String s) {
    switch (s) {
      case 'PENDING_CONFIRMATION': return OrderStatus.pendingConfirmation;
      case 'CONFIRMED': return OrderStatus.confirmed;
      case 'ASSIGNED': return OrderStatus.assigned;
      case 'PICKED_UP': return OrderStatus.pickedUp;
      case 'COMPLETED': return OrderStatus.completed;
      case 'CANCELED': return OrderStatus.canceled;
      default: return OrderStatus.pendingConfirmation;
    }
  }
  
  String toDbString() {
    switch (this) {
      case OrderStatus.pendingConfirmation: return 'PENDING_CONFIRMATION';
      case OrderStatus.confirmed: return 'CONFIRMED';
      case OrderStatus.assigned: return 'ASSIGNED';
      case OrderStatus.pickedUp: return 'PICKED_UP';
      case OrderStatus.completed: return 'COMPLETED';
      case OrderStatus.canceled: return 'CANCELED';
    }
  }
  
  String get displayName {
    switch (this) {
      case OrderStatus.pendingConfirmation: return 'Chờ xác nhận';
      case OrderStatus.confirmed: return 'Đã xác nhận';
      case OrderStatus.assigned: return 'Đã gán tài xế';
      case OrderStatus.pickedUp: return 'Đã lấy hàng';
      case OrderStatus.completed: return 'Hoàn thành';
      case OrderStatus.canceled: return 'Đã hủy';
    }
  }
}

enum ServiceType { food, ride, delivery }

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required int orderNumber,
    required String marketId,
    required ServiceType serviceType,
    required String customerId,
    String? driverId,
    String? shopId,
    required OrderStatus status,
    required LocationData pickup,
    required LocationData dropoff,
    required int deliveryFee,
    required int itemsTotal,
    required int totalAmount,
    String? customerName,
    String? customerPhone,
    String? note,
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? completedAt,
    DateTime? canceledAt,
    String? cancelReason,
  }) = _Order;
  
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

@freezed
class LocationData with _$LocationData {
  const factory LocationData({
    required String label,
    String? address,
    required double lat,
    required double lng,
  }) = _LocationData;
  
  factory LocationData.fromJson(Map<String, dynamic> json) => _$LocationDataFromJson(json);
}

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String orderId,
    String? productId,
    required String productName,
    required int quantity,
    required int unitPrice,
    required int subtotal,
    String? note,
  }) = _OrderItem;
  
  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
}
```

### lib/data/repositories/order_repository.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../../config/constants.dart';

class OrderRepository {
  final SupabaseClient _client;
  
  OrderRepository(this._client);
  
  // Create order
  Future<Order> createOrder({
    required String marketId,
    required ServiceType serviceType,
    String? shopId,
    required LocationData pickup,
    required LocationData dropoff,
    required int deliveryFee,
    List<OrderItem> items = const [],
    String? customerName,
    String? customerPhone,
    String? note,
  }) async {
    final itemsJson = items.map((i) => {
      'product_id': i.productId,
      'product_name': i.productName,
      'quantity': i.quantity,
      'unit_price': i.unitPrice,
      'subtotal': i.subtotal,
      'note': i.note,
    }).toList();
    
    final response = await _client.rpc(
      'create_order',
      params: {
        'p_market_id': marketId,
        'p_service_type': serviceType.name,
        'p_shop_id': shopId,
        'p_pickup': pickup.toJson(),
        'p_dropoff': dropoff.toJson(),
        'p_items': itemsJson,
        'p_delivery_fee': deliveryFee,
        'p_customer_name': customerName,
        'p_customer_phone': customerPhone,
        'p_note': note,
      },
    ).timeout(AppConstants.apiTimeout);
    
    return Order.fromJson(response);
  }
  
  // Cancel order by customer
  Future<Order> cancelOrderByCustomer(String orderId, {String? reason}) async {
    final response = await _client.rpc(
      'cancel_order_by_customer',
      params: {
        'p_order_id': orderId,
        'p_reason': reason,
      },
    ).timeout(AppConstants.apiTimeout);
    
    return Order.fromJson(response);
  }
  
  // Get my orders (customer)
  Future<List<Order>> getMyOrders() async {
    final response = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false)
        .limit(50)
        .timeout(AppConstants.apiTimeout);
    
    return response.map<Order>((json) => Order.fromJson(json)).toList();
  }
  
  // Get order detail
  Future<Order> getOrderDetail(String orderId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single()
        .timeout(AppConstants.apiTimeout);
    
    return Order.fromJson(response);
  }
  
  // Stream order updates
  Stream<Order> streamOrder(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((data) => Order.fromJson(data.first));
  }
  
  // Admin: Get pending orders
  Future<List<Order>> getPendingOrders(String marketId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('market_id', marketId)
        .eq('status', 'PENDING_CONFIRMATION')
        .order('created_at')
        .timeout(AppConstants.apiTimeout);
    
    return response.map<Order>((json) => Order.fromJson(json)).toList();
  }
  
  // Admin: Confirm order
  Future<Order> confirmOrder(String orderId) async {
    final response = await _client.rpc(
      'confirm_order',
      params: {'p_order_id': orderId},
    ).timeout(AppConstants.apiTimeout);
    
    return Order.fromJson(response);
  }
  
  // Admin: Assign driver
  Future<Order> assignDriver(String orderId, String driverId) async {
    final response = await _client.rpc(
      'assign_driver',
      params: {
        'p_order_id': orderId,
        'p_driver_id': driverId,
      },
    ).timeout(AppConstants.apiTimeout);
    
    return Order.fromJson(response);
  }
  
  // Driver: Get assigned orders
  Future<List<Order>> getAssignedOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    
    final response = await _client
        .from('orders')
        .select()
        .eq('driver_id', userId)
        .inFilter('status', ['ASSIGNED', 'PICKED_UP'])
        .order('assigned_at', ascending: false)
        .timeout(AppConstants.apiTimeout);
    
    return response.map<Order>((json) => Order.fromJson(json)).toList();
  }
  
  // Driver: Update status
  Future<Order> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final response = await _client.rpc(
      'update_order_status',
      params: {
        'p_order_id': orderId,
        'p_new_status': newStatus.toDbString(),
      },
    ).timeout(AppConstants.apiTimeout);
    
    return Order.fromJson(response);
  }
}
```

### lib/core/error/error_handler.dart

```dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  final String code;
  final String message;
  
  AppException(this.code, this.message);
  
  @override
  String toString() => message;
}

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }
    if (error is AuthException) {
      return _handleAuthError(error);
    }
    if (error is TimeoutException) {
      return AppException('TIMEOUT', 'Kết nối chậm, vui lòng thử lại');
    }
    return AppException('UNKNOWN', 'Đã có lỗi xảy ra');
  }
  
  static AppException _handlePostgrestError(PostgrestException error) {
    final message = error.message;
    
    // Custom RPC errors
    if (message.contains('NOT_ALLOWED')) {
      return AppException('NOT_ALLOWED', 'Bạn không có quyền thực hiện');
    }
    if (message.contains('INVALID_STATUS')) {
      return AppException('INVALID_STATUS', 'Không thể thực hiện ở trạng thái này');
    }
    if (message.contains('CANNOT_CANCEL')) {
      return AppException('CANNOT_CANCEL', 'Chỉ có thể hủy đơn khi chờ xác nhận');
    }
    if (message.contains('ORDER_NOT_FOUND')) {
      return AppException('ORDER_NOT_FOUND', 'Không tìm thấy đơn hàng');
    }
    if (message.contains('DRIVER_NOT_FOUND')) {
      return AppException('DRIVER_NOT_FOUND', 'Không tìm thấy tài xế');
    }
    if (message.contains('HAS_ACTIVE_ORDERS')) {
      return AppException('HAS_ACTIVE_ORDERS', 'Vui lòng hoàn thành đơn trước khi offline');
    }
    
    return AppException('SERVER_ERROR', 'Lỗi hệ thống');
  }
  
  static AppException _handleAuthError(AuthException error) {
    if (error.message.contains('Invalid login')) {
      return AppException('INVALID_LOGIN', 'Thông tin đăng nhập không đúng');
    }
    if (error.message.contains('expired')) {
      return AppException('SESSION_EXPIRED', 'Phiên đăng nhập hết hạn');
    }
    return AppException('AUTH_ERROR', 'Lỗi xác thực');
  }
}
```

### lib/widgets/common/app_button.dart

```dart
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color ?? theme.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildChild(theme),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildChild(theme),
      ),
    );
  }
  
  Widget _buildChild(ThemeData theme) {
    if (isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
```

---

## Android Configuration

### android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application
        android:label="Chợ Quê"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- Foreground Service for Driver -->
        <service
            android:name="com.baseflow.geolocator.GeolocatorLocationService"
            android:foregroundServiceType="location"
            android:exported="false"/>
            
    </application>
</manifest>
```

---

## iOS Configuration

### ios/Runner/Info.plist (add these keys)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Chợ Quê cần vị trí của bạn để tìm dịch vụ gần nhất</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Chợ Quê cần vị trí để cập nhật khi bạn đang giao hàng</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```
