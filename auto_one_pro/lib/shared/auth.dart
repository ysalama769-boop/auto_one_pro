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
  _authSubscription ??=
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    currentUser.value = data.session?.user;
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
