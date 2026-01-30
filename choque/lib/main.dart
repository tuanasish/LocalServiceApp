import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/supabase_client.dart';
import 'routing/app_router.dart';
import 'config/constants.dart';
import 'config/firebase_options_ios.dart';
import 'services/fcm_service.dart';
import 'services/notification_handler_service.dart';
import 'providers/notification_provider.dart';

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Platform.isIOS) {
    await Firebase.initializeApp(options: iosFirebaseOptions);
  } else {
    await Firebase.initializeApp();
  }
  // Call internal background handler if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase (iOS dùng options từ Dart vì không gọi FirebaseApp.configure() native)
    if (Platform.isIOS) {
      await Firebase.initializeApp(options: iosFirebaseOptions);
    } else {
      await Firebase.initializeApp();
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Load environment variables
    await dotenv.load(fileName: '.env');

    if (!AppConstants.isConfigValid) {
      _runErrorApp(
        'Thiếu cấu hình .env\n\n'
        'Cần có: SUPABASE_URL, SUPABASE_ANON_KEY\n\n'
        'Hãy copy .env.example thành .env và điền giá trị thật từ Supabase.',
      );
      return;
    }

    // Initialize Supabase
    await SupabaseService.initialize();

    runApp(const ProviderScope(child: MyApp()));
  } catch (e, st) {
    // Hiển thị lỗi thay vì màn hình trắng (ví dụ: URL Supabase sai)
    _runErrorApp(
      'Lỗi khởi tạo:\n\n$e\n\n'
      'Kiểm tra file .env: SUPABASE_URL và SUPABASE_ANON_KEY phải là giá trị thật từ Supabase (Settings → API).',
      detail: st.toString(),
    );
  }
}

/// Hiển thị app chỉ với màn hình lỗi khi init thất bại
void _runErrorApp(String message, {String? detail}) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Icon(Icons.error_outline, size: 64, color: Color(0xFF1E7F43)),
                const SizedBox(height: 24),
                Text(
                  'Chợ Quê',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    detail,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'monospace'),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notification services sau khi app start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // New FCM Service initialization
      final router = ref.read(appRouterProvider);
      final handler = NotificationHandlerService(router);
      final repository = ref.read(notificationRepositoryProvider);

      await FCMService().initialize(
        repository: repository,
        onMessageReceived: (message) => handler.handleNotificationReceived(message),
        onMessageTapped: (message) => handler.handleNotificationTapped(message),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Chợ Quê',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E7F43)),
        textTheme: GoogleFonts.interTextTheme(),
      ),
    );
  }
}
