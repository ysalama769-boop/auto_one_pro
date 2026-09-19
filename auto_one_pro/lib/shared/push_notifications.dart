import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../firebase_options.dart';

// ============================================================
// PUSH NOTIFICATIONS (إشعارات برة المتصفح عن طريق Firebase)
// ============================================================
// المفتاح العام (VAPID key) بتاع مشروع Firebase — لازم تجيبه من
// Project Settings → Cloud Messaging → Web configuration، وتحطه
// هنا بدل النص ده.
const String kVapidKey =
    'BDnor17uZlZYtm4_088WNlc-5pKDJ0X1tOwAV-AfgkfTD3Jxu5kglHpJPq18KDna18hwg7VwqvBu6EGi__Wqc6Y';

bool _isInitialized = false;

Future<void> initPushNotifications() async {
  if (_isInitialized) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    );
    _isInitialized = true;

    // بنستمع لأي إشعار بيوصل والتطبيق مفتوح قدام المستخدم فعليًا
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'AUTO_ONE_DEBUG: إشعار وصل والتطبيق مفتوح: ${message.notification?.title}',
      );
    });
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تهيئة Firebase: $e');
  }
}

// بتتنادى بعد ما الزبون يسجّل دخول — بتطلب إذن الإشعارات وتحفظ
// الـ token بتاعه مربوط بحسابه، عشان نقدر نبعتله إشعارات بعدين.
Future<void> registerForPushNotifications() async {
  if (!_isInitialized) {
    await initPushNotifications();
  }

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  try {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('AUTO_ONE_DEBUG: المستخدم رفض إذن الإشعارات');
      return;
    }

    final token = await messaging.getToken(vapidKey: kVapidKey);
    if (token == null) return;

    await Supabase.instance.client.from('user_fcm_tokens').upsert(
      {
        'user_id': user.id,
        'token': token,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'token',
    );

    // لو الـ token اتجدّد وهو مسجّل دخول، نحدّثه تلقائيًا
    messaging.onTokenRefresh.listen((newToken) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;
      await Supabase.instance.client.from('user_fcm_tokens').upsert(
        {
          'user_id': currentUser.id,
          'token': newToken,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'token',
      );
    });
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تسجيل إشعارات الدفع: $e');
  }
}

// بتتنادى وقت تسجيل الخروج — تمسح الـ token بتاع الجهاز ده عشان
// محدش يوصله إشعارات بعد ما يسجّل خروج.
Future<void> unregisterPushNotifications() async {
  if (!_isInitialized) return;
  try {
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kVapidKey,
    );
    if (token != null) {
      await Supabase.instance.client
          .from('user_fcm_tokens')
          .delete()
          .eq('token', token);
    }
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر إلغاء تسجيل إشعارات الدفع: $e');
  }
}
