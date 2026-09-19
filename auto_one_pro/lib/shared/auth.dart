import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'favorites_compare.dart';

// ============================================================
// AUTH STATE (حساب الزبون - إيميل وباسوورد عن طريق Supabase Auth)
// ============================================================

// المستخدم الحالي (null لو مسجّل خروج)
final ValueNotifier<User?> currentUser =
    ValueNotifier<User?>(Supabase.instance.client.auth.currentUser);

StreamSubscription<AuthState>? _authSubscription;

// بيتنادى مرة واحدة بس عند بدء التطبيق عشان نتابع أي تغيير في حالة
// تسجيل الدخول (دخول / خروج / تجديد الجلسة).
void initAuthListener() {
  currentUser.value = Supabase.instance.client.auth.currentUser;
  if (currentUser.value != null) {
    loadCustomerNotificationsCount();
  }
  _authSubscription ??=
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    currentUser.value = data.session?.user;
    if (currentUser.value != null) {
      loadCustomerNotificationsCount();
    } else {
      customerNotificationsCount.value = 0;
    }
  });
}

bool get isLoggedIn => currentUser.value != null;

Future<String?> signUpWithEmail({
  required String email,
  required String password,
  required String fullName,
}) async {
  try {
    final response = await Supabase.instance.client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
    if (response.user != null) {
      currentUser.value = response.user;
      await mergeLocalFavoritesIntoAccount();
    }
    return null; // null يعني نجاح
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}

Future<String?> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.user != null) {
      currentUser.value = response.user;
      await mergeLocalFavoritesIntoAccount();
      await loadFavoritesFromAccount();
    }
    return null;
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}

Future<void> signOutUser() async {
  await Supabase.instance.client.auth.signOut();
  currentUser.value = null;
  // نرجع نحمّل المفضلة المحلية (المتصفح) بعد الخروج
  loadFavorites();
}

String? get currentUserName {
  final user = currentUser.value;
  if (user == null) return null;
  final fullName = user.userMetadata?['full_name'] as String?;
  if (fullName != null && fullName.trim().isNotEmpty) return fullName.trim();
  return user.email;
}

// ============================================================
// إشعارات الزبون (تغييرات حالة الطلبات/الحجوزات اللي لسه ماشافهاش)
// ============================================================
final ValueNotifier<int> customerNotificationsCount = ValueNotifier<int>(0);

Future<void> loadCustomerNotificationsCount() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    customerNotificationsCount.value = 0;
    return;
  }
  try {
    // آخر مرة الزبون فتح فيها صفحة الإشعارات (لمعرفة الإعلانات الجديدة)
    final readState = await Supabase.instance.client
        .from('user_notification_reads')
        .select('last_seen_at')
        .eq('user_id', user.id)
        .maybeSingle();
    final lastSeenAt = readState?['last_seen_at']?.toString();

    final results = await Future.wait([
      Supabase.instance.client
          .from('bookings')
          .select('id')
          .eq('user_id', user.id)
          .eq('seen', false),
      Supabase.instance.client
          .from('customer_requests')
          .select('id')
          .eq('user_id', user.id)
          .eq('seen', false),
      lastSeenAt == null
          ? Supabase.instance.client.from('announcements').select('id')
          : Supabase.instance.client
              .from('announcements')
              .select('id')
              .gt('created_at', lastSeenAt),
    ]);
    final bookingsCount = (results[0] as List).length;
    final requestsCount = (results[1] as List).length;
    final announcementsCount = (results[2] as List).length;
    customerNotificationsCount.value =
        bookingsCount + requestsCount + announcementsCount;
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل عدد إشعارات الزبون: $e');
  }
}

// بتتنادى لما الزبون يفتح صفحة الإشعارات — تعلّم كل حاجاته
// كـ"متشافة" (طلبات + إعلانات).
Future<void> markCustomerNotificationsSeen() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  try {
    await Future.wait([
      Supabase.instance.client
          .from('bookings')
          .update({'seen': true})
          .eq('user_id', user.id)
          .eq('seen', false),
      Supabase.instance.client
          .from('customer_requests')
          .update({'seen': true})
          .eq('user_id', user.id)
          .eq('seen', false),
      Supabase.instance.client.from('user_notification_reads').upsert({
        'user_id': user.id,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }),
    ]);
    customerNotificationsCount.value = 0;
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحديث حالة الإشعارات: $e');
  }
}
