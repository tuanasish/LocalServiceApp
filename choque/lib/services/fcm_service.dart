import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/repositories/notification_repository.dart';

/// FCM Service
/// Handles Firebase Cloud Messaging initialization, token management, and notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM
  Future<void> initialize({
    required NotificationRepository repository,
    required Function(RemoteMessage) onMessageReceived,
    required Function(RemoteMessage) onMessageTapped,
  }) async {
    try {
      // Request permission
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('[FCMService] Notification permission denied');
        }
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications(onMessageTapped);

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        if (kDebugMode) {
          print('[FCMService] FCM Token: ${_fcmToken!.substring(0, 20)}...');
        }

        // Save token to database
        await repository.saveFCMToken(
          token: _fcmToken!,
          deviceType: Platform.isAndroid ? 'android' : 'ios',
        );
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('[FCMService] Token refreshed: ${newToken.substring(0, 20)}...');
        }

        await repository.saveFCMToken(
          token: newToken,
          deviceType: Platform.isAndroid ? 'android' : 'ios',
        );
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) {
          print('[FCMService] Foreground message: ${message.notification?.title}');
        }
        _showLocalNotification(message);
        onMessageReceived(message);
      });

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode) {
          print('[FCMService] Message tapped (background): ${message.data}');
        }
        onMessageTapped(message);
      });

      // Check if app was opened from terminated state
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('[FCMService] App opened from terminated state: ${initialMessage.data}');
        }
        onMessageTapped(initialMessage);
      }

      if (kDebugMode) {
        print('[FCMService] Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCMService] Error initializing: $e');
      }
      rethrow;
    }
  }

  /// Request notification permission
  Future<NotificationSettings> _requestPermission() async {
    return await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications(
    Function(RemoteMessage) onMessageTapped,
  ) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          // Parse payload and create RemoteMessage-like object
          // For now, we'll handle this in the notification handler
          if (kDebugMode) {
            print('[FCMService] Local notification tapped: ${details.payload}');
          }
        }
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('[FCMService] Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCMService] Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('[FCMService] Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCMService] Error unsubscribing from topic: $e');
      }
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('[FCMService] Background message: ${message.notification?.title}');
  }
}
