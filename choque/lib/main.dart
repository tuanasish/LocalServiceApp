import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/supabase_client.dart';
import 'routing/app_router.dart';
import 'config/constants.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/notification_handler_service.dart';
import 'providers/notification_provider.dart';

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Call internal background handler if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Validate configuration
  if (!AppConstants.isConfigValid) {
    throw Exception(
      'Missing environment variables. Please check your .env file.\n'
      'Required: SUPABASE_URL, SUPABASE_ANON_KEY',
    );
  }

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: MyApp()));
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
