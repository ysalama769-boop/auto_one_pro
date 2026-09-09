import 'dart:async';
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

  final heroTitleArCtrl = TextEditingController();
  final heroTitleEnCtrl = TextEditingController();
  final heroSubtitleArCtrl = TextEditingController();
  final heroSubtitleEnCtrl = TextEditingController();
  List<TextEditingController> bannerControllers = [];

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

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
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
        ],
      ),
    );
  }
}

