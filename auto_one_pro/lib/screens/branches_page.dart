import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../admin/admin_shared.dart';

// ============================================================
// BRANCHES PAGE (فروع أوتو ون - صفحة مستقلة)
// ============================================================
class BranchesPage extends StatefulWidget {
  final bool isArabic;

  const BranchesPage({super.key, required this.isArabic});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  bool get isArabic => widget.isArabic;
  int selectedBranchIndex = 0;
  final Set<String> _registeredViews = {};

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController(text: '+966');
  final messageCtrl = TextEditingController();
  bool isSendingForm = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendContactForm() async {
    if (nameCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'من فضلك اكتب اسمك ورسالتك'
                : 'Please enter your name and message',
          ),
        ),
      );
      return;
    }

    setState(() => isSendingForm = true);

    final email = emailCtrl.text.trim();
    final notes = email.isEmpty
        ? messageCtrl.text.trim()
        : '${isArabic ? 'إيميل' : 'Email'}: $email\n\n${messageCtrl.text.trim()}';

    try {
      await Supabase.instance.client.from('customer_requests').insert({
        'customer_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'request_type': 'contact',
        'status': 'new',
        'notes': notes,
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إرسال رسالتك بنجاح، هنتواصل معاك قريب'
                : 'Your message was sent, we will contact you soon',
          ),
        ),
      );
      nameCtrl.clear();
      emailCtrl.clear();
      phoneCtrl.text = '+966';
      messageCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'حصلت مشكلة، حاول تاني' : 'Something went wrong',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSendingForm = false);
    }
  }

  Widget _contactInfoRow({
    required IconData icon,
    required String text,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isArabic ? 'معلومات التواصل' : 'Contact Information',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isArabic
              ? 'قسم الاتصال هو بوابتك للوصول إلينا، نرحب باستفساراتكم واقتراحاتكم.'
              : 'Our contact section is your gateway to reach us — we welcome your questions and suggestions.',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 22),
        _contactInfoRow(
          icon: Icons.email_outlined,
          iconColor: Colors.red,
          text: 'info@autoone.com',
          onTap: () => openLinkFromColumn('mailto:info@autoone.com'),
        ),
        _contactInfoRow(
          icon: Icons.call_outlined,
          iconColor: Colors.red,
          text: '920022122',
          onTap: () => openLinkFromColumn('tel:+966541577894'),
        ),
        _contactInfoRow(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: Colors.green,
          text: '966541577894',
          onTap: () => openLinkFromColumn('https://wa.me/966541577894'),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'تواصل معنا' : 'Contact Us',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              _formField(nameCtrl, isArabic ? 'الاسم' : 'Name'),
              _formField(
                emailCtrl,
                isArabic ? 'البريد الإلكتروني' : 'Email',
              ),
              _formField(phoneCtrl, isArabic ? 'رقم الهاتف' : 'Phone'),
              _formField(
                messageCtrl,
                isArabic ? 'الرسالة' : 'Message',
                maxLines: 4,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSendingForm ? null : _sendContactForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSendingForm
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isArabic ? 'إرسال' : 'Send'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> openLinkFromColumn(String link) async {
    final Uri url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // بنستخرج نفس كلمة البحث من رابط البحث العادي (اللي كل فرع أصلاً
  // شايله)، ونبني بيها رابط "embed" يعرض خريطة تفاعلية حقيقية من
  // غير ما نحتاج مفتاح Google Maps API.
  String _embedUrlFromSearchUrl(String searchUrl) {
    final uri = Uri.tryParse(searchUrl);
    final query = uri?.queryParameters['query'] ?? '';
    return 'https://maps.google.com/maps?q=${Uri.encodeComponent(query)}&z=15&output=embed';
  }

  String _registerMapView(int branchIndex, String embedUrl) {
    final viewType = 'branch-map-$branchIndex';
    if (!_registeredViews.contains(viewType)) {
      _registeredViews.add(viewType);
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
        final iframe = html.IFrameElement()
          ..src = embedUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;
        return iframe;
      });
    }
    return viewType;
  }

  @override
  Widget build(BuildContext context) {
  Future<void> openLink(String link) async {
    final Uri url = Uri.parse(link);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  final List<Map<String, dynamic>> branches = [
  {
    'number': '1',
    'nameAr': 'الفرع الرئيسي',
    'nameEn': 'MAIN BRANCH',
    'addressAr': 'الجوهرة - جدة',
    'addressEn': 'Al Johara - Jeddah',
    'map': 'https://www.google.com/maps/search/?api=1&query=Auto+One+Al+Johara+Jeddah',
    'showBadge': false,
  },
  {
    'number': '2',
    'nameAr': 'فرع القادسية',
    'nameEn': 'AL QADISIYAH BRANCH',
    'addressAr': 'القادسية - الرياض',
    'addressEn': 'Al Qadisiyah - Riyadh',
    'map': 'https://www.google.com/maps/search/?api=1&query=Auto+One+Al+Qadisiyah+Riyadh',
    'showBadge': false,
  },
  {
    'number': '3',
    'nameAr': 'فرع الحمدانية',
    'nameEn': 'AL HAMADANIYAH',
    'addressAr': 'الحمدانية - جدة',
    'addressEn': 'Al Hamadaniyah - Jeddah',
    'map': 'https://www.google.com/maps/search/?api=1&query=Auto+One+Al+Hamadaniyah+Jeddah',
    'showBadge': true,
  },
];

    final bannerUrl =
        (homepageSettings.value?['branches_banner'] ?? '').toString().trim();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'فروعنا' : 'Our Branches'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (bannerUrl.isNotEmpty)
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 5,
                      child: carImageAdaptive(
                        bannerUrl,
                        fit: BoxFit.contain,
                        showWatermark: false,
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: SectionNavBadge(
                          isArabic: isArabic,
                          sectionLabel:
                              isArabic ? 'فروعنا' : 'Branches',
                        ),
                      ),
                    ),
                  ],
                ),
Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      vertical: 65,
      horizontal: 25,
    ),
    color: const Color(0xFFF7F7F7),

    child: Column(
      children: [

        // ==================================================
        // TITLE
        // ==================================================

        Text(
          isArabic
              ? 'فروع AUTO ONE'
              : 'AUTO ONE BRANCHES',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          isArabic
              ? 'اختر الفرع الأقرب إليك'
              : 'Choose the branch closest to you',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: 45,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(height: 42),

        // ==================================================
        // BRANCHES
        // ==================================================

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            final branchesColumn = _BranchTabsAndMap(
              isArabic: isArabic,
              branches: branches,
              selectedIndex: selectedBranchIndex,
              onSelect: (i) => setState(() => selectedBranchIndex = i),
              embedUrlBuilder: _embedUrlFromSearchUrl,
              viewRegistrar: _registerMapView,
              onOpenInGoogleMaps: openLink,
            );

            final contactColumn = _contactColumn();

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: branchesColumn),
                  const SizedBox(width: 30),
                  Expanded(child: contactColumn),
                ],
              );
            }

            return Column(
              children: [
                branchesColumn,
                const SizedBox(height: 30),
                contactColumn,
              ],
            );
          },
        ),
      ],
    ),
  ),
              AutoOneFooter(isArabic: isArabic),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BRANCH TABS + EMBEDDED MAP (تبويب أحمر بالفروع + خريطة تفاعلية
// حقيقية للفرع المختار، بدل قايمة الكروت القديمة)
// ============================================================
class _BranchTabsAndMap extends StatelessWidget {
  final bool isArabic;
  final List<Map<String, dynamic>> branches;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String Function(String searchUrl) embedUrlBuilder;
  final String Function(int index, String embedUrl) viewRegistrar;
  final Future<void> Function(String link) onOpenInGoogleMaps;

  const _BranchTabsAndMap({
    required this.isArabic,
    required this.branches,
    required this.selectedIndex,
    required this.onSelect,
    required this.embedUrlBuilder,
    required this.viewRegistrar,
    required this.onOpenInGoogleMaps,
  });

  @override
  Widget build(BuildContext context) {
    final branch = branches[selectedIndex];
    final embedUrl = embedUrlBuilder(branch['map']!.toString());
    final viewType = viewRegistrar(selectedIndex, embedUrl);

    return Column(
      children: [
        // ==================================================
        // شريط التبويب الأحمر
        // ==================================================
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: kBrandGradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(branches.length, (i) {
              final b = branches[i];
              final isSelected = i == selectedIndex;
              final label = isArabic ? b['nameAr']! : b['nameEn']!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onSelect(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.22)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: isSelected
                          ? const Border(
                              bottom: BorderSide(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 4),

        // ==================================================
        // الخريطة التفاعلية
        // ==================================================
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(18),
          ),
          child: SizedBox(
            height: 420,
            width: double.infinity,
            child: Stack(
              children: [
                HtmlElementView(viewType: viewType),
                Positioned(
                  top: 12,
                  left: isArabic ? null : 12,
                  right: isArabic ? 12 : null,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onOpenInGoogleMaps(branch['map']!.toString()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_new_rounded, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              isArabic
                                  ? 'الفتح في خرائط Google'
                                  : 'Open in Google Maps',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ==================================================
        // عنوان الفرع المختار
        // ==================================================
        Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic ? branch['addressAr']! : branch['addressEn']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
