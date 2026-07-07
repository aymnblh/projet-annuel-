import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // Pour kDebugMode

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 1. Initialisation complète
  Future<void> init() async {
    // Demander la permission (Surtout pour iOS et Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permission Notifications : ACCORDÉE');
    } else {
      print('❌ Permission Notifications : REFUSÉE');
    }

    // Obtenir le Token du téléphone (L'adresse pour lui écrire)
    String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print("🔔 FCM TOKEN: $token"); // Utile pour tester manuellement
    }

    // Configurer les notifications locales (Pour afficher quand l'app est ouverte)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(initSettings);

    // Écouter les messages quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  // 2. Afficher la notification visuelle (Si l'app est ouverte)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // Id du canal
            'Notifications Importantes', // Nom du canal
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  // 3. Récupérer le token (pour le sauvegarder dans le profil utilisateur)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}