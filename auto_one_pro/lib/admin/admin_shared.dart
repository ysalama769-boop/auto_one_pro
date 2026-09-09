import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/widgets.dart';

// ============================================================
// ADMIN GATE (PASSWORD PROTECTION)
// ============================================================
// شاشة بسيطة بتطلب رقم سري قبل ما تفتح صفحة إدارة الحجوزات.
// ملحوظة: ده حماية على مستوى الواجهة بس، مش نظام تسجيل دخول أمني كامل.
const String kAdminPassword = 'autoone2026';


// ============================================================
// المستخدم الحالي المسجّل دخوله في لوحة التحكم + سجل التعديلات
// ============================================================
final ValueNotifier<Map<String, dynamic>?> currentAdminUser =
    ValueNotifier(null);


Future<void> logActivity(String action) async {
  final userName = currentAdminUser.value?['name'] ?? 'غير معروف';
  try {
    await Supabase.instance.client.from('activity_log').insert({
      'user_name': userName,
      'action': action,
    });
  } catch (e) {
    // تسجيل النشاط مش لازم يوقف العملية الأساسية لو فشل
  }
}


// ============================================================
// إعدادات الصفحة الرئيسية (بانر + نصوص) — تحميل مرة واحدة
// ============================================================
final ValueNotifier<Map<String, dynamic>?> homepageSettings =
    ValueNotifier(null);


Future<void> loadHomepageSettings() async {
  try {
    final response = await Supabase.instance.client
        .from('homepage_settings')
        .select()
        .eq('id', 1)
        .maybeSingle();
    homepageSettings.value = response;
  } catch (e) {
    // لو حصلت مشكلة، النصوص الثابتة الاحتياطية هتفضل شغالة
  }
}


// ============================================================
// ADMIN BOOKINGS PAGE
// ============================================================
// ============================================================
// SKELETON LIST (loading placeholder for lists)
// ============================================================
Widget skeletonCardList({int count = 4}) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: count,
    itemBuilder: (context, index) {
      return Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                width: 66,
                height: 66,
                child: ShimmerBox(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const SizedBox(
                      height: 14,
                      width: 140,
                      child: ShimmerBox(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const SizedBox(
                      height: 12,
                      width: 90,
                      child: ShimmerBox(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

