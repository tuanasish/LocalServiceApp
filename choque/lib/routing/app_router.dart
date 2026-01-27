import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Screens
import '../screens/main_shell.dart';
import '../screens/home/food_home_discover_screen.dart';
import '../screens/home/store_detail_menu_screen.dart';
import '../screens/checkout_fixed_fee_screen.dart';
import '../screens/onboarding/welcome_onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/role_switcher_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/admin/admin_system_overview_screen.dart';
import '../screens/driver/driver_dashboard_request_screen.dart';
import '../screens/driver/driver_home_dashboard_screen.dart';
import '../screens/driver/driver_order_fulfillment_screen.dart';
import '../screens/merchant/merchant_order_dashboard_screen.dart';
import '../screens/merchant/merchant_order_management_screen.dart';
import '../screens/merchant/merchant_price_management_screen.dart';
import '../screens/merchant/product_picker_screen.dart';
import '../screens/merchant/merchant_profile_screen.dart';
import '../screens/order/order_history_screen.dart';
import '../screens/order/simple_order_tracking_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/saved_addresses_screen.dart';
import '../screens/profile/add_address_screen.dart';
import '../screens/address/map_address_picker_screen.dart';
import '../screens/search/unified_search_screen.dart';
import '../screens/profile/favorites_screen.dart';
import '../data/models/location_model.dart';
import '../models/user_address.dart';

// Import Providers
import '../providers/auth_provider.dart';

// Navigation keys for each branch
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _ordersNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'orders');
final _notificationsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'notifications');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

// Removed comment - keys declared above

/// Helper function để kiểm tra lỗi network
bool _isNetworkError(Object error) {
  final errorStr = error.toString();
  return errorStr.contains('Failed host lookup') ||
         errorStr.contains('SocketException') ||
         errorStr.contains('Network') ||
         errorStr.contains('timeout');
}

// Routes that require authentication - defined outside for performance
const _authRequiredRoutes = {
  '/profile/addresses/add',
  '/profile/addresses',
  '/profile/addresses/edit',
  '/orders',
  '/notifications',
  '/profile',
  '/profile/favorites',
};

// Routes that are part of auth flow - không cần check profile
const _authFlowRoutes = {
  '/login',
  '/register',
  '/register/verify',
  '/register/profile',
  '/forgot-password',
  '/forgot-password/verify',
  '/reset-password',
  '/welcome',
  '/role-switcher',
};

/// Provider for the router - created once and reused
/// Guest-first: No login required, users can browse as guest
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      
      // OPTIMIZATION: Early return cho routes không cần check auth
      // Đa số navigations (home, store detail, search) không cần kiểm tra gì
      if (!_authRequiredRoutes.contains(location) && 
          !_authFlowRoutes.contains(location) &&
          !location.startsWith('/register')) {
        return null;
      }
      
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      
      // Guest trying to access auth-required route -> redirect to login
      // Check này rất nhanh, chỉ check isAuthenticated
      if (!isAuthenticated && _authRequiredRoutes.contains(location)) {
        return '/login?redirect=${Uri.encodeComponent(location)}';
      }
      
      // Nếu không authenticated và không phải auth-required route, cho qua
      if (!isAuthenticated) {
        return null;
      }
      
      // === Từ đây chỉ xử lý cho authenticated users ===
      
      // OPTIMIZATION: Chỉ read profile khi thực sự cần
      // Đây là điểm có thể gây chậm nên chỉ gọi khi cần thiết
      final profileAsync = ref.read(userProfileProvider);
      
      // Nếu đang loading profile, không redirect (đợi load xong)
      if (profileAsync.isLoading) {
        return null;
      }
      
      // Nếu có lỗi network, cho phép tiếp tục (để user có thể retry)
      if (profileAsync.hasError) {
        final error = profileAsync.error;
        if (error != null && _isNetworkError(error)) {
          return null;
        }
      }
      
      final hasProfile = profileAsync.asData?.value != null;
      
      // Authenticated nhưng chưa có profile -> redirect đến setup
      if (!hasProfile && 
          location != '/register/profile' && 
          location != '/register/verify' &&
          !location.startsWith('/register')) {
        return '/register/profile';
      }
      
      // Authenticated và có profile, đang ở login/register -> redirect về home/role
      if (hasProfile && (location == '/login' || location == '/register')) {
        final uri = Uri.parse(state.uri.toString());
        final redirectTo = uri.queryParameters['redirect'];
        if (redirectTo != null && redirectTo.isNotEmpty) {
          return redirectTo;
        }
        
        final needsRoleSelection = ref.read(needsRoleSelectionProvider);
        if (needsRoleSelection) {
          return '/role-switcher';
        }
        return ref.read(activeRoleProvider).route;
      }
      
      return null; // No redirect needed
    },
    routes: [
      // Add address screen (phải đặt TRƯỚC StatefulShellRoute để tránh duplicate key)
      GoRoute(
        path: '/profile/addresses/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AddAddressScreen(),
      ),
      
      // Auth routes (không có bottom nav)
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WelcomeOnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password/verify',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          final email = data['email'] as String? ?? '';
          final type = data['type'] as String? ?? 'recovery';
          return OtpVerificationScreen(email: email, type: type);
        },
      ),
      GoRoute(
        path: '/reset-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final email = data?['email'] as String?;
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/role-switcher',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RoleSwitcherScreen(),
      ),
      
      // Registration flow routes
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/register/verify',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          final email = data['email'] as String? ?? '';
          final fullName = data['full_name'] as String?;
          final type = data['type'] as String? ?? 'email';
          return OtpVerificationScreen(email: email, fullName: fullName, type: type);
        },
      ),
      GoRoute(
        path: '/register/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          final fullName = data['full_name'] as String?;
          return ProfileSetupScreen(fullName: fullName);
        },
      ),
      
      // StatefulShellRoute: Customer Bottom Navigation với persistent state
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Trang chủ (Customer)
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const FoodHomeDiscoverScreen(),
                routes: [
                  GoRoute(
                    path: 'store/:id',
                    builder: (context, state) {
                      final shopId = state.pathParameters['id']!;
                      return StoreDetailMenuScreen(shopId: shopId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 1: Đơn hàng
          StatefulShellBranch(
            navigatorKey: _ordersNavigatorKey,
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrderHistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final orderId = state.pathParameters['id']!;
                      return SimpleOrderTrackingScreen(orderId: orderId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Thông báo
          StatefulShellBranch(
            navigatorKey: _notificationsNavigatorKey,
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          // Branch 3: Tài khoản
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const UserProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'addresses',
                    builder: (context, state) => const SavedAddressesScreen(),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final address = state.extra as UserAddress;
                          return AddAddressScreen(addressToEdit: address);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'favorites',
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      
      // Role-specific dashboards (ngoài shell, không có bottom nav customer)
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminSystemOverviewScreen(),
      ),
      GoRoute(
        path: '/merchant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MerchantOrderDashboardScreen(),
        routes: [
          GoRoute(
            path: 'order/:id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final orderId = state.pathParameters['id']!;
              return MerchantOrderManagementScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: 'menu',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const MerchantPriceManagementScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final shopId = extra?['shopId'] as String? ?? '';
                  return ProductPickerScreen(shopId: shopId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const MerchantProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/driver',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DriverHomeDashboardScreen(),
        routes: [
          GoRoute(
            path: 'requests',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const DriverDashboardRequestScreen(),
          ),
          GoRoute(
            path: 'order/:id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final orderId = state.pathParameters['id']!;
              return DriverOrderFulfillmentScreen(orderId: orderId);
            },
          ),
        ],
      ),
      
      // Checkout flow (ngoài shell)
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckoutFixedFeeScreen(),
      ),
      
      // Address map picker (ngoài shell)
      GoRoute(
        path: '/address/map-picker',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final initialLocation = state.extra as LocationModel?;
          return MapAddressPickerScreen(initialLocation: initialLocation);
        },
      ),
      
      // Unified Search Screen (ngoài shell)
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return UnifiedSearchScreen(initialQuery: query);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
  
  ref.onDispose(() => router.dispose());
  return router;
});
