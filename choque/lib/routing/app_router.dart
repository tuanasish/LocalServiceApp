import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import Screens
import '../screens/home/user_home_screen.dart';
import '../screens/home/food_home_discover_screen.dart';
import '../screens/home/store_detail_menu_screen.dart';
import '../screens/checkout_fixed_fee_screen.dart';
import '../screens/onboarding/welcome_onboarding_screen.dart';
import '../screens/onboarding/login_selection_screen.dart';
import '../screens/admin/admin_system_overview_screen.dart';
import '../screens/driver/driver_home_dashboard_screen.dart';
import '../screens/merchant/merchant_order_dashboard_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Welcome / Onboarding
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeOnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginSelectionScreen(),
    ),
    
    // Core User Flow
    GoRoute(
      path: '/',
      builder: (context, state) => const UserHomeScreen(),
    ),
    GoRoute(
      path: '/discover',
      builder: (context, state) => const FoodHomeDiscoverScreen(),
    ),
    GoRoute(
      path: '/store/:id',
      builder: (context, state) {
        // final String? storeId = state.pathParameters['id'];
        return const StoreDetailMenuScreen();
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutFixedFeeScreen(),
    ),

    // Roles Dashboards
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminSystemOverviewScreen(),
    ),
    GoRoute(
      path: '/driver',
      builder: (context, state) => const DriverHomeDashboardScreen(),
    ),
    GoRoute(
      path: '/merchant',
      builder: (context, state) => const MerchantOrderDashboardScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
