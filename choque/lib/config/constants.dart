import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase Configuration Constants
///
/// Project: choque (Chợ Quê)
/// Region: ap-south-1
///
/// Credentials are loaded from .env file (not committed to git)
class AppConstants {
  // Supabase - loaded from environment
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Market
  static String get defaultMarketId =>
      dotenv.env['DEFAULT_MARKET_ID'] ?? 'huyen_demo';

  // Vietmap
  static String get vietmapTilemapKey =>
      dotenv.env['VIETMAP_TILEMAP_KEY'] ?? '';
  static String get vietmapServicesKey =>
      dotenv.env['VIETMAP_SERVICES_KEY'] ?? '';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration retryDelay = Duration(seconds: 2);
  static const int maxRetries = 2;

  // Cache
  static const Duration configCacheTTL = Duration(minutes: 15);
  static const Duration locationCacheTTL = Duration(hours: 24);

  /// Validate that required env vars are set
  static bool get isConfigValid =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
