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
  List<String> bannerTypes = []; // 'image' أو 'video' لكل عنصر

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

  // نصوص إضافية قابلة للتعديل (عناوين ووصف أقسام الصفحة الرئيسية
  // وصفحة الخدمات) — كل عنصر هنا اتخزن كعمودين (key_ar, key_en).
  static const List<Map<String, String>> extraTextGroups = [
    {
      'group': 'لماذا AUTO ONE',
      'key': 'why_title',
      'label': 'العنوان الرئيسي',
    },
    {
      'group': 'لماذا AUTO ONE',
      'key': 'why_subtitle',
      'label': 'الوصف تحت العنوان',
    },
    {'group': 'لماذا AUTO ONE', 'key': 'why_card1_title', 'label': 'عنوان الكارت الأول'},
    {'group': 'لماذا AUTO ONE', 'key': 'why_card1_desc', 'label': 'وصف الكارت الأول'},
    {'group': 'لماذا AUTO ONE', 'key': 'why_card2_title', 'label': 'عنوان الكارت الثاني'},
    {'group': 'لماذا AUTO ONE', 'key': 'why_card2_desc', 'label': 'وصف الكارت الثاني'},
    {'group': 'لماذا AUTO ONE', 'key': 'why_card3_title', 'label': 'عنوان الكارت الثالث'},
    {'group': 'لماذا AUTO ONE', 'key': 'why_card3_desc', 'label': 'وصف الكارت الثالث'},
    {'group': 'لماذا AUTO ONE', 'key': 'why_card4_title', 'label': 'عنوان الكارت الرابع'},
    {'group': 'لماذا AUTO ONE', 'key': 'why_card4_desc', 'label': 'وصف الكارت الرابع'},
    {'group': 'جهات التمويل', 'key': 'financing_title', 'label': 'العنوان'},
    {'group': 'جهات التمويل', 'key': 'financing_desc', 'label': 'الوصف'},
    {'group': 'تقييمات العملاء', 'key': 'reviews_title', 'label': 'العنوان'},
    {'group': 'صفحة الخدمات', 'key': 'services_title', 'label': 'العنوان'},
    {'group': 'صفحة الخدمات', 'key': 'services_desc', 'label': 'الوصف'},
  ];

  final Map<String, TextEditingController> extraArCtrls = {
    for (final g in extraTextGroups) g['key']!: TextEditingController(),
  };
  final Map<String, TextEditingController> extraEnCtrls = {
    for (final g in extraTextGroups) g['key']!: TextEditingController(),
  };

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
    for (final c in extraArCtrls.values) {
      c.dispose();
    }
    for (final c in extraEnCtrls.values) {
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

      final rawBanners = (response?['banner_images'] is List)
          ? (response!['banner_images'] as List)
          : <dynamic>[];
      bannerControllers = [];
      bannerTypes = [];
      for (final entry in rawBanners) {
        if (entry is Map) {
          bannerControllers
              .add(TextEditingController(text: (entry['url'] ?? '').toString()));
          bannerTypes.add((entry['type'] ?? 'image').toString());
        } else {
          // توافق مع الشكل القديم: رابط نصي بس = صورة
          bannerControllers.add(TextEditingController(text: entry.toString()));
          bannerTypes.add('image');
        }
      }

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

      for (final g in extraTextGroups) {
        final key = g['key']!;
        extraArCtrls[key]!.text = (response?['${key}_ar'] ?? '').toString();
        extraEnCtrls[key]!.text = (response?['${key}_en'] ?? '').toString();
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

  // بيرفع صورة أو فيديو لعنصر معيّن في سلايدر الهيرو، وبيحدد نوعه
  // (صورة/فيديو) تلقائيًا من امتداد الملف.
  Future<void> _pickAndUploadBannerAt(
    int index,
    void Function(void Function()) setSectionState,
  ) async {
    final uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*,video/*';
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

        final lowerName = file.name.toLowerCase();
        final isVideoFile = (file.type).startsWith('video/') ||
            lowerName.endsWith('.mp4') ||
            lowerName.endsWith('.mov') ||
            lowerName.endsWith('.webm');

        if (mounted && index < bannerControllers.length) {
          setState(() {
            bannerControllers[index].text = publicUrl;
            while (bannerTypes.length <= index) {
              bannerTypes.add('image');
            }
            bannerTypes[index] = isVideoFile ? 'video' : 'image';
          });
          setSectionState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'فشل رفع الملف: $e' : 'Failed to upload file: $e',
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
      final banners = <Map<String, String>>[];
      for (var i = 0; i < bannerControllers.length; i++) {
        final url = bannerControllers[i].text.trim();
        if (url.isEmpty) continue;
        banners.add({
          'url': url,
          'type': i < bannerTypes.length ? bannerTypes[i] : 'image',
        });
      }

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
        for (final g in extraTextGroups)
          '${g['key']}_ar': extraArCtrls[g['key']]!.text.trim(),
        for (final g in extraTextGroups)
          '${g['key']}_en': extraEnCtrls[g['key']]!.text.trim(),
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

    final sections = <Map<String, dynamic>>[
      {
        'label': isArabic ? 'النصوص الرئيسية' : 'Hero Texts',
        'icon': Icons.title_rounded,
        'body': _heroSectionBody,
      },
      {
        'label': isArabic ? 'صور البانر (سلايدر)' : 'Banner Slider',
        'icon': Icons.view_carousel_rounded,
        'body': _bannersSectionBody,
      },
      {
        'label': isArabic ? 'بانرات الصفحات' : 'Page Banners',
        'icon': Icons.image_outlined,
        'body': _pageBannersSectionBody,
      },
      {
        'label': isArabic ? 'محتوى "عن أوتو ون"' : 'About Page',
        'icon': Icons.info_outline_rounded,
        'body': _aboutSectionBody,
      },
      {
        'label': isArabic ? 'خطوات طريقة الشراء' : 'How to Buy Steps',
        'icon': Icons.format_list_numbered_rounded,
        'body': _stepsSectionBody,
      },
      {
        'label': isArabic ? 'نصوص إضافية' : 'Additional Texts',
        'icon': Icons.text_snippet_outlined,
        'body': _extraTextsSectionBody,
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final section = sections[i];
        return _homepageSectionCard(
          label: section['label'] as String,
          icon: section['icon'] as IconData,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AdminSectionScaffold(
                  isArabic: isArabic,
                  title: section['label'] as String,
                  body: (section['body'] as Widget Function())(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _homepageSectionCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.red, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // زرار حفظ عام يتحط آخر أي قسم فرعي — بيحفظ كل بيانات الصفحة
  // الرئيسية مرة واحدة (نفس _save()، مش بس القسم المفتوح).
  Widget _saveButtonInline() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _heroSectionBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
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
        _saveButtonInline(),
      ],
    );
  }

  Widget _bannersSectionBody() {
    return StatefulBuilder(
      builder: (context, setSectionState) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
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
                      bannerTypes.add('image');
                    });
                    setSectionState(() {});
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isArabic ? 'إضافة صورة/فيديو' : 'Add image/video'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'لو مفيش صور أو فيديوهات، السلايدر مش هيظهر خالص في الصفحة الرئيسية.'
                  : 'If empty, no slider will show on the homepage.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < bannerControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bannerControllers[i],
                              decoration: InputDecoration(
                                hintText: isArabic
                                    ? 'رابط الصورة أو الفيديو'
                                    : 'Image or video URL',
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
                                if (i < bannerTypes.length) {
                                  bannerTypes.removeAt(i);
                                }
                              });
                              setSectionState(() {});
                            },
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text(isArabic ? 'صورة' : 'Image'),
                            avatar: const Icon(Icons.image_rounded, size: 16),
                            selected: (i < bannerTypes.length
                                    ? bannerTypes[i]
                                    : 'image') ==
                                'image',
                            onSelected: (_) {
                              setState(() {
                                while (bannerTypes.length <=
                                    bannerControllers.length - 1) {
                                  bannerTypes.add('image');
                                }
                                bannerTypes[i] = 'image';
                              });
                              setSectionState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(isArabic ? 'فيديو' : 'Video'),
                            avatar:
                                const Icon(Icons.videocam_rounded, size: 16),
                            selected: (i < bannerTypes.length
                                    ? bannerTypes[i]
                                    : 'image') ==
                                'video',
                            onSelected: (_) {
                              setState(() {
                                while (bannerTypes.length <=
                                    bannerControllers.length - 1) {
                                  bannerTypes.add('image');
                                }
                                bannerTypes[i] = 'video';
                              });
                              setSectionState(() {});
                            },
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: isUploadingImage
                                ? null
                                : () => _pickAndUploadBannerAt(
                                      i,
                                      setSectionState,
                                    ),
                            icon: const Icon(Icons.upload_rounded, size: 18),
                            label: Text(
                              isArabic ? 'رفع ملف' : 'Upload file',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            _saveButtonInline(),
          ],
        );
      },
    );
  }

  Widget _pageBannersSectionBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
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
        _saveButtonInline(),
      ],
    );
  }

  Widget _aboutSectionBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
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
        _saveButtonInline(),
      ],
    );
  }

  Widget _stepsSectionBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (var i = 0; i < 5; i++) ...[
          _aboutTextField(
            stepArCtrls[i],
            isArabic ? 'الخطوة ${i + 1} (عربي)' : 'Step ${i + 1} (Arabic)',
          ),
          _aboutTextField(
            stepEnCtrls[i],
            isArabic
                ? 'الخطوة ${i + 1} (إنجليزي)'
                : 'Step ${i + 1} (English)',
          ),
        ],
        _saveButtonInline(),
      ],
    );
  }

  Widget _extraTextsSectionBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final groupName in extraTextGroups
            .map((g) => g['group']!)
            .toSet()) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(
              groupName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          for (final g in extraTextGroups.where(
            (g) => g['group'] == groupName,
          )) ...[
            _aboutTextField(
              extraArCtrls[g['key']]!,
              '${g['label']} (عربي)',
            ),
            _aboutTextField(
              extraEnCtrls[g['key']]!,
              '${g['label']} (English)',
            ),
          ],
        ],
        _saveButtonInline(),
      ],
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

