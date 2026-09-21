import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/widgets.dart';
import '../shared/constants.dart';

// ============================================================
// ADMIN GATE (تسجيل دخول حقيقي عن طريق Supabase Auth)
// ============================================================
// دخول الأدمن بقى بإيميل وباسوورد حقيقيين عن طريق Supabase Auth
// (نفس نظام تسجيل دخول الزباين)، وصلاحية "أدمن" بتتأكد من جدول
// admin_users المربوط بحساب المستخدم، مش من كلمة سر مكتوبة في الكود.


// ============================================================
// ADMIN SECTION SCAFFOLD (صفحة منفصلة لأي قسم فرعي في لوحة
// التحكم — فيها زرار رجوع وزرار داشبورد)
// ============================================================
class AdminSectionScaffold extends StatelessWidget {
  final bool isArabic;
  final String title;
  final Widget body;

  const AdminSectionScaffold({
    super.key,
    required this.isArabic,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(title),
          leading: IconButton(
            icon: Icon(
              isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            tooltip: isArabic ? 'رجوع' : 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.dashboard_rounded, color: Colors.white),
              label: Text(
                isArabic ? 'الداشبورد' : 'Dashboard',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: body,
      ),
    );
  }
}

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

// نص قابل للتعديل من لوحة التحكم، وليه قيمة افتراضية لو الأدمن
// لسه ما كتبش حاجة. key_ar و key_en المفروض يكونوا موجودين
// كأعمدة في homepage_settings.
String siteText({
  required String key,
  required bool isArabic,
  required String defaultAr,
  required String defaultEn,
}) {
  final ar = (homepageSettings.value?['${key}_ar'] ?? '').toString();
  final en = (homepageSettings.value?['${key}_en'] ?? '').toString();
  if (isArabic) {
    return ar.isNotEmpty ? ar : defaultAr;
  }
  return en.isNotEmpty ? en : (ar.isNotEmpty ? ar : defaultEn);
}


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
// ضغط الصور قبل الرفع (بيقلل حجم الصور المرفوعة من لوحة
// التحكم بشكل كبير من غير ما تأثر على الشكل، وده بيسرّع تحميل
// الموقع للزوار).
// ============================================================
// بيصغّر الصورة (لو أكبر من الحد الأقصى) وبيحوّلها لـ JPEG
// بجودة معقولة، وبيرجّع البايتات الجاهزة للرفع. لو حصلت أي
// مشكلة أثناء الضغط، بيرجّع البايتات الأصلية زي ما هي عشان
// الرفع ما يفشلش خالص.
Future<Uint8List> compressImageBytes(
  Uint8List originalBytes, {
  int maxDimension = 1600,
  double quality = 0.82,
}) async {
  try {
    final blob = html.Blob([originalBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final imgElement = html.ImageElement();
    imgElement.src = url;
    await imgElement.onLoad.first;

    final naturalWidth = imgElement.naturalWidth;
    final naturalHeight = imgElement.naturalHeight;
    html.Url.revokeObjectUrl(url);

    if (naturalWidth == 0 || naturalHeight == 0) return originalBytes;

    var targetWidth = naturalWidth;
    var targetHeight = naturalHeight;
    final biggestSide = naturalWidth > naturalHeight ? naturalWidth : naturalHeight;
    if (biggestSide > maxDimension) {
      final scale = maxDimension / biggestSide;
      targetWidth = (naturalWidth * scale).round();
      targetHeight = (naturalHeight * scale).round();
    }

    final canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
    final ctx = canvas.context2D;
    ctx.drawImageScaled(imgElement, 0, 0, targetWidth, targetHeight);

    final blobResult = await canvas.toBlob('image/jpeg', quality);
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blobResult);
    await reader.onLoad.first;
    final compressed = reader.result as Uint8List;

    // لو الضغط مطلّعش فرق حقيقي أو زوّد الحجم غلط، استخدم الأصلي
    if (compressed.isEmpty || compressed.length >= originalBytes.length) {
      return originalBytes;
    }
    return compressed;
  } catch (e) {
    return originalBytes;
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

