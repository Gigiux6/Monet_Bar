import 'dart:io';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Top-level function per gestire i messaggi in background.
/// Deve essere annotata con @pragma('vm:entry-point') per funzionare in release mode.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Se necessario, inizializzare Firebase prima (se non è già stato fatto)
  // await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configura handler per i messaggi in background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Richiedi i permessi (necessario per iOS e per Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permissions');
    } else {
      debugPrint('User declined or has not accepted notification permissions');
    }

    // Iscriviti al topic globale per ricevere le novità (se non siamo su Web, il topic pub/sub funziona meglio nativamente)
    if (!kIsWeb) {
      try {
        await _fcm.subscribeToTopic('all_users');
        debugPrint('Subscribed to topic: all_users');
      } catch (e) {
        debugPrint('Error subscribing to topic: $e');
      }
    }

    // Configura notifiche locali per visualizzarle quando l'app è in FOREGROUND
    await _setupLocalNotifications();

    // Ascolta i messaggi in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    _isInitialized = true;
  }

  Future<void> subscribeToUserTopic(String uid) async {
    if (!kIsWeb) {
      try {
        await _fcm.subscribeToTopic('user_$uid');
        debugPrint('Subscribed to topic: user_$uid');
      } catch (e) {
        debugPrint('Error subscribing to topic: $e');
      }
    }
  }

  Future<void> unsubscribeFromUserTopic(String uid) async {
    if (!kIsWeb) {
      try {
        await _fcm.unsubscribeFromTopic('user_$uid');
        debugPrint('Unsubscribed from topic: user_$uid');
      } catch (e) {
        debugPrint('Error unsubscribing from topic: $e');
      }
    }
  }




  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gestisci il tap sulla notifica se l'app è in foreground
      },
    );

    // Creazione del canale di notifica per Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@drawable/ic_notification',
            color: const Color(0xFFD4AF37),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
}
