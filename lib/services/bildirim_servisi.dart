import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ── Android bildirim kanalı ──────────────────────────────────────────────────
const AndroidNotificationChannel _kanal = AndroidNotificationChannel(
  'yuksek_oncelik',
  'Önemli Bildirimler',
  description: 'Sipariş, kiralama ve mesaj bildirimleri',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

// ── Arka plan handler ────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Arka Plan] ${message.notification?.title}');
}

class BildirimServisi {
  BildirimServisi._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// main() içinde bir kez çağır
  static Future<void> baslat() async {
    try {
      // 1) İzin iste
      final ayarlar = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] İzin: ${ayarlar.authorizationStatus}');

      // 2) Android kanalı oluştur
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_kanal);

      // 3) flutter_local_notifications başlat
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotif.initialize(initSettings);

      // 4) iOS foreground seçenekleri
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5) Arka plan handler
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

      // 6) Foreground bildirimini local notifications ile göster (Android için şart)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Ön Plan] ${message.notification?.title}');
        final bildirim = message.notification;
        if (bildirim == null) return;

        _localNotif.show(
          bildirim.hashCode,
          bildirim.title,
          bildirim.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _kanal.id,
              _kanal.name,
              channelDescription: _kanal.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      });
    } catch (e) {
      // Bildirim servisi çalışmasa bile uygulama açılmaya devam eder
      debugPrint('[FCM] Bildirim servisi başlatılamadı: $e');
    }
  }

  /// FCM V1 API üzerinden push gönder (Cloud Function çağırır)
  static Future<void> pushGonder({
    required String fcmToken,
    required String baslik,
    required String icerik,
    String tip = '',
    Map<String, dynamic> ekstra = const {},
  }) async {
    try {
      final callable =
          FirebaseFunctions.instanceFor(region: 'us-central1')
              .httpsCallable('pushGonder');
      await callable.call({
        'fcmToken': fcmToken,
        'baslik': baslik,
        'icerik': icerik,
        'tip': tip,
        'ekstra': ekstra,
      });
      debugPrint('[FCM V1] Push gönderildi');
    } catch (e) {
      debugPrint('[FCM V1] Push gönderilemedi: $e');
    }
  }

  /// Kullanıcı giriş yaptıktan sonra FCM token'ını Firestore'a kaydet
  static Future<void> tokenKaydet(String kullaniciId) async {
    if (kullaniciId.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      debugPrint('[FCM] Token kaydediliyor...');

      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(kullaniciId)
          .update({
        'fcmToken': token,
        'fcmTokenGuncellendi': FieldValue.serverTimestamp(),
      });

      _fcm.onTokenRefresh.listen((yeniToken) {
        FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(kullaniciId)
            .update({'fcmToken': yeniToken});
      });
    } catch (e) {
      debugPrint('[FCM] Token kaydedilemedi: $e');
    }
  }

  /// Admin paneli açıldığında admin token'ını kaydet
  static Future<void> adminTokenKaydet() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('ayarlar')
          .doc('admin_token')
          .set({
        'fcmToken': token,
        'guncellendi': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FCM] Admin token kaydedildi');
    } catch (e) {
      debugPrint('[FCM] Admin token kaydedilemedi: $e');
    }
  }

  /// Kullanıcı çıkış yaparken token'ı sil
  static Future<void> tokenTemizle(String kullaniciId) async {
    if (kullaniciId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(kullaniciId)
          .update({'fcmToken': FieldValue.delete()});
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('[FCM] Token temizlenemedi: $e');
    }
  }
}
