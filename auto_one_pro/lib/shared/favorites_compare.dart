import 'dart:html' as html;
import 'package:flutter/material.dart';

// ============================================================
// FAVORITES (stored locally in the browser)
// ============================================================
Set<int> favoriteCarIds = {};


void loadFavorites() {
  try {
    final saved = html.window.localStorage['auto_one_favorites'];
    if (saved != null && saved.isNotEmpty) {
      favoriteCarIds =
          saved.split(',').where((s) => s.isNotEmpty).map(int.parse).toSet();
    }
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل المفضلة: $e');
  }
}


void _saveFavorites() {
  try {
    html.window.localStorage['auto_one_favorites'] = favoriteCarIds.join(',');
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر حفظ المفضلة: $e');
  }
}


void toggleFavorite(int carId) {
  if (favoriteCarIds.contains(carId)) {
    favoriteCarIds.remove(carId);
  } else {
    favoriteCarIds.add(carId);
  }
  _saveFavorites();
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

