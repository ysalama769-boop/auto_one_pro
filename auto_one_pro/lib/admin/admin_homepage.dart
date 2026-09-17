import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';

// ============================================================
// ADMIN HOMEPAGE SETTINGS (بانر + نصوص)
// ============================================================
class AdminHomepagePage extends StatefulWidget {
  final bool isArabic;
  const AdminHomepagePage({super.key, required this.isArabic});

  @override
  State<AdminHomepagePage> createState() => _AdminHomepagePageState();
}


class _AdminHomepagePageState extends State<AdminHomepagePage> {
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingImage = false;

  final heroTitleArCtrl = TextEditingController();
  final heroTitleEnCtrl = TextEditingController();
  final heroSubtitleArCtrl = TextEditingController();
  final heroSubtitleEnCtrl = TextEditingController();
  List<TextEditingController> bannerControllers = [];

  // بانر صفحة الفروع
  final branchesBannerCtrl = TextEditingController();
  // بانر صفحة الخدمات
  final servicesBannerCtrl = TextEditingController();

  // محتوى صفحة "عن أوتو ون"
  final aboutIntroArCtrl = TextEditingController();
  final aboutIntroEnCtrl = TextEditingController();
  final aboutOfferArCtrl = TextEditingController();
  final aboutOfferEnCtrl = TextEditingController();
  final aboutAvailableArCtrl = TextEditingController();
  final aboutAvailableEnCtrl = TextEditingController();
  final aboutGoalArCtrl = TextEditingController();
  final aboutGoalEnCtrl = TextEditingController();

  // خطوات "طريقة الشراء" (5 خطوات، عربي وإنجليزي)
  final List<TextEditingController> stepArCtrls =
      List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> stepEnCtrls =
      List.generate(5, (_) => TextEditingController());

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    heroTitleArCtrl.dispose();
    heroTitleEnCtrl.dispose();
    heroSubtitleArCtrl.dispose();
    heroSubtitleEnCtrl.dispose();
    for (final c in bannerControllers) {
      c.dispose();
    }
    branchesBannerCtrl.dispose();
    servicesBannerCtrl.dispose();
    aboutIntroArCtrl.dispose();
    aboutIntroEnCtrl.dispose();
    aboutOfferArCtrl.dispose();
    aboutOfferEnCtrl.dispose();
    aboutAvailableArCtrl.dispose();
    aboutAvailableEnCtrl.dispose();
    aboutGoalArCtrl.dispose();
    aboutGoalEnCtrl.dispose();
    for (final c in stepArCtrls) {
      c.dispose();
    }
    for (final c in stepEnCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('homepage_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();

      heroTitleArCtrl.text = (response?['hero_title_ar'] ?? '').toString();
      heroTitleEnCtrl.text = (response?['hero_title_en'] ?? '').toString();
      heroSubtitleArCtrl.text =
          (response?['hero_subtitle_ar'] ?? '').toString();
      heroSubtitleEnCtrl.text =
          (response?['hero_subtitle_en'] ?? '').toString();

      final banners = (response?['banner_images'] is List)
          ? List<String>.from(
              (response!['banner_images'] as List).map((e) => e.toString()))
          : <String>[];
      bannerControllers =
          banners.map((url) => TextEditingController(text: url)).toList();

      branchesBannerCtrl.text =
          (response?['branches_banner'] ?? '').toString();
      servicesBannerCtrl.text =
          (response?['services_banner'] ?? '').toString();

      aboutIntroArCtrl.text = (response?['about_intro_ar'] ?? '').toString();
      aboutIntroEnCtrl.text = (response?['about_intro_en'] ?? '').toString();
      aboutOfferArCtrl.text = (response?['about_offer_ar'] ?? '').toString();
      aboutOfferEnCtrl.text = (response?['about_offer_en'] ?? '').toString();
      aboutAvailableArCtrl.text =
          (response?['about_available_ar'] ?? '').toString();
      aboutAvailableEnCtrl.text =
          (response?['about_available_en'] ?? '').toString();
      aboutGoalArCtrl.text = (response?['about_goal_ar'] ?? '').toString();
      aboutGoalEnCtrl.text = (response?['about_goal_en'] ?? '').toString();

      for (var i = 0; i < 5; i++) {
        stepArCtrls[i].text =
            (response?['step${i + 1}_ar'] ?? '').toString();
        stepEnCtrls[i].text =
            (response?['step${i + 1}_en'] ?? '').toString();
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // بيفتح نافذة اختيار ملف من جهاز المستخدم ويرفعه على نفس مكان
  // تخزين الصور في Supabase، وبعدين يحط الرابط في خانة بانر الفروع.
  Future<void> _pickAndUploadBranchesBanner() async {
    await _pickAndUploadBanner(branchesBannerCtrl);
  }

  Future<void> _pickAndUploadServicesBanner() async {
    await _pickAndUploadBanner(servicesBannerCtrl);
  }

  Future<void> _pickAndUploadBanner(TextEditingController target) async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];

      setState(() => isUploadingImage = true);

      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        final bytes = reader.result as Uint8List;

        final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final path =
            'site/${DateTime.now().millisecondsSinceEpoch}_$safeName';

        await Supabase.instance.client.storage.from('car_images').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );

        final publicUrl = Supabase.instance.client.storage
            .from('car_images')
            .getPublicUrl(path);

        if (mounted) {
          setState(() {
            target.text = publicUrl;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'فشل رفع الصورة: $e' : 'Failed to upload image: $e',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => isUploadingImage = false);
      }
    });
  }

  Future<void> _save() async {
    setState(() => isSaving = true);
    try {
      final banners = bannerControllers
          .map((c) => c.text.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      await Supabase.instance.client.from('homepage_settings').update({
        'hero_title_ar': heroTitleArCtrl.text.trim(),
        'hero_title_en': heroTitleEnCtrl.text.trim(),
        'hero_subtitle_ar': heroSubtitleArCtrl.text.trim(),
        'hero_subtitle_en': heroSubtitleEnCtrl.text.trim(),
        'banner_images': banners,
        'branches_banner': branchesBannerCtrl.text.trim(),
        'services_banner': servicesBannerCtrl.text.trim(),
        'about_intro_ar': aboutIntroArCtrl.text.trim(),
        'about_intro_en': aboutIntroEnCtrl.text.trim(),
        'about_offer_ar': aboutOfferArCtrl.text.trim(),
        'about_offer_en': aboutOfferEnCtrl.text.trim(),
        'about_available_ar': aboutAvailableArCtrl.text.trim(),
        'about_available_en': aboutAvailableEnCtrl.text.trim(),
        'about_goal_ar': aboutGoalArCtrl.text.trim(),
        'about_goal_en': aboutGoalEnCtrl.text.trim(),
        for (var i = 0; i < 5; i++)
          'step${i + 1}_ar': stepArCtrls[i].text.trim(),
        for (var i = 0; i < 5; i++)
          'step${i + 1}_en': stepEnCtrls[i].text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', 1);

      await logActivity(
        isArabic
            ? 'عدّل إعدادات الصفحة الرئيسية'
            : 'Updated homepage settings',
      );

      // نحدّث النسخة المحمّلة في الذاكرة عشان الصفحة الرئيسية تتغيّر فورًا
      await loadHomepageSettings();

      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تم الحفظ بنجاح' : 'Saved successfully'),
        ),
      );
    } catch (e) {
      setState(() => isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'حصلت مشكلة' : 'Something went wrong'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'adminHomepageSaveFAB',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: isSaving ? null : _save,
        icon: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(isArabic ? 'حفظ' : 'Save'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          Text(
            isArabic ? 'النصوص الرئيسية' : 'Hero texts',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: heroTitleArCtrl,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان (عربي)' : 'Title (Arabic)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: heroTitleEnCtrl,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان (إنجليزي)' : 'Title (English)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: heroSubtitleArCtrl,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان الفرعي (عربي)' : 'Subtitle (Arabic)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: heroSubtitleEnCtrl,
            decoration: InputDecoration(
              labelText:
                  isArabic ? 'العنوان الفرعي (إنجليزي)' : 'Subtitle (English)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'صور البانر (سلايدر)' : 'Banner images (slider)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    bannerControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(isArabic ? 'إضافة صورة' : 'Add image'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'لو مفيش صور، السلايدر مش هيظهر خالص في الصفحة الرئيسية.'
                : 'If empty, no slider will show on the homepage.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < bannerControllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bannerControllers[i],
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'رابط صورة البانر'
                            : 'Banner image URL',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        bannerControllers[i].dispose();
                        bannerControllers.removeAt(i);
                      });
                    },
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          Container(height: 1, color: Colors.black12),
          const SizedBox(height: 24),

          Text(
            isArabic ? 'صورة بانر صفحة الفروع' : 'Branches page banner image',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: branchesBannerCtrl,
                  decoration: InputDecoration(
                    hintText:
                        isArabic ? 'رابط صورة البانر' : 'Banner image URL',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    isUploadingImage ? null : _pickAndUploadBranchesBanner,
                icon: const Icon(Icons.upload_file),
                tooltip: isArabic ? 'اختيار من الجهاز' : 'Browse',
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            isArabic ? 'صورة بانر صفحة الخدمات' : 'Services page banner image',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: servicesBannerCtrl,
                  decoration: InputDecoration(
                    hintText:
                        isArabic ? 'رابط صورة البانر' : 'Banner image URL',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    isUploadingImage ? null : _pickAndUploadServicesBanner,
                icon: const Icon(Icons.upload_file),
                tooltip: isArabic ? 'اختيار من الجهاز' : 'Browse',
              ),
            ],
          ),

          Text(
            isArabic ? 'محتوى صفحة "عن أوتو ون"' : 'About page content',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          _aboutTextField(
            aboutIntroArCtrl,
            isArabic ? 'نبذة عن المعرض (عربي)' : 'About intro (Arabic)',
          ),
          _aboutTextField(
            aboutIntroEnCtrl,
            isArabic ? 'نبذة عن المعرض (إنجليزي)' : 'About intro (English)',
          ),
          _aboutTextField(
            aboutOfferArCtrl,
            isArabic ? 'اللي بنقدمه (عربي)' : 'What we offer (Arabic)',
          ),
          _aboutTextField(
            aboutOfferEnCtrl,
            isArabic ? 'اللي بنقدمه (إنجليزي)' : 'What we offer (English)',
          ),
          _aboutTextField(
            aboutAvailableArCtrl,
            isArabic ? 'السيارات المتوفرة (عربي)' : 'Available cars (Arabic)',
          ),
          _aboutTextField(
            aboutAvailableEnCtrl,
            isArabic
                ? 'السيارات المتوفرة (إنجليزي)'
                : 'Available cars (English)',
          ),
          _aboutTextField(
            aboutGoalArCtrl,
            isArabic ? 'هدفنا وخدمتنا (عربي)' : 'Our goal (Arabic)',
          ),
          _aboutTextField(
            aboutGoalEnCtrl,
            isArabic ? 'هدفنا وخدمتنا (إنجليزي)' : 'Our goal (English)',
          ),

          const SizedBox(height: 24),
          Text(
            isArabic ? 'خطوات "طريقة الشراء"' : '"How to Buy" steps',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < 5; i++) ...[
            _aboutTextField(
              stepArCtrls[i],
              isArabic
                  ? 'الخطوة ${i + 1} (عربي)'
                  : 'Step ${i + 1} (Arabic)',
            ),
            _aboutTextField(
              stepEnCtrls[i],
              isArabic
                  ? 'الخطوة ${i + 1} (إنجليزي)'
                  : 'Step ${i + 1} (English)',
            ),
          ],
        ],
      ),
    );
  }

  Widget _aboutTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

