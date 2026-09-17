import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// FAVORITES (محلي في المتصفح للزوار، ومرتبط بالحساب للمسجّلين)
// ============================================================
Set<int> favoriteCarIds = {};

// بيتغيّر كل ما المفضلة تتحدّث، عشان أي واجهة تعرض المفضلة تعرف
// تعمل rebuild (زي أيقونة القلب في الهيدر أو صفحة المفضلة).
final ValueNotifier<int> favoritesVersion = ValueNotifier<int>(0);

void _bumpFavoritesVersion() {
  favoritesVersion.value++;
}

void loadFavorites() {
  try {
    final saved = html.window.localStorage['auto_one_favorites'];
    if (saved != null && saved.isNotEmpty) {
      favoriteCarIds =
          saved.split(',').where((s) => s.isNotEmpty).map(int.parse).toSet();
    } else {
      favoriteCarIds = {};
    }
    _bumpFavoritesVersion();
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل المفضلة: $e');
  }
}

void _saveFavoritesLocally() {
  try {
    html.window.localStorage['auto_one_favorites'] = favoriteCarIds.join(',');
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر حفظ المفضلة: $e');
  }
}

// بتجيب مفضلة الحساب المسجّل من قاعدة البيانات وتحطها بدل المفضلة
// المحلية.
Future<void> loadFavoritesFromAccount() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  try {
    final response = await Supabase.instance.client
        .from('favorites')
        .select('car_id')
        .eq('user_id', user.id);
    favoriteCarIds =
        (response as List).map((row) => row['car_id'] as int).toSet();
    _bumpFavoritesVersion();
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل مفضلة الحساب: $e');
  }
}

// أول ما الزبون يسجّل دخول، بترحّل أي مفضلة كانت محفوظة في المتصفح
// (كزائر) لحسابه، بعدين تحمّل مفضلة الحساب الكاملة.
Future<void> mergeLocalFavoritesIntoAccount() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  try {
    final localIds = Set<int>.from(favoriteCarIds);
    if (localIds.isNotEmpty) {
      await Supabase.instance.client.from('favorites').upsert(
            localIds
                .map((carId) => {'user_id': user.id, 'car_id': carId})
                .toList(),
            onConflict: 'user_id,car_id',
          );
    }
    await loadFavoritesFromAccount();
    try {
      html.window.localStorage.remove('auto_one_favorites');
    } catch (_) {}
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر ترحيل المفضلة للحساب: $e');
  }
}

void toggleFavorite(int carId) {
  final user = Supabase.instance.client.auth.currentUser;

  if (favoriteCarIds.contains(carId)) {
    favoriteCarIds.remove(carId);
  } else {
    favoriteCarIds.add(carId);
  }
  _bumpFavoritesVersion();

  if (user != null) {
    // مسجّل دخول: نحدّث قاعدة البيانات
    if (favoriteCarIds.contains(carId)) {
      Supabase.instance.client.from('favorites').upsert(
        {'user_id': user.id, 'car_id': carId},
        onConflict: 'user_id,car_id',
      );
    } else {
      Supabase.instance.client
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('car_id', carId);
    }
  } else {
    // زائر: نحفظ في المتصفح بس
    _saveFavoritesLocally();
  }
}

// ============================================================
// COMPARISON (session only — up to 3 cars)
// ============================================================
final ValueNotifier<List<int>> compareCarIds = ValueNotifier<List<int>>([]);


void toggleCompare(int carId) {
  final list = List<int>.from(compareCarIds.value);
  if (list.contains(carId)) {
    list.remove(carId);
  } else {
    if (list.length >= 3) {
      list.removeAt(0);
    }
    list.add(carId);
  }
  compareCarIds.value = list;
}
