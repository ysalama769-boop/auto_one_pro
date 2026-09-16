import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../admin/admin_shared.dart';

// ============================================================
// BRANCHES PAGE (فروع أوتو ون - صفحة مستقلة)
// ============================================================
class BranchesPage extends StatelessWidget {
  final bool isArabic;

  const BranchesPage({super.key, required this.isArabic});

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
                SizedBox(
                  width: double.infinity,
                  height: 260,
                  child: carImageAdaptive(
                    bannerUrl,
                    fit: BoxFit.cover,
                    showWatermark: false,
                  ),
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

            final isSmall =
                constraints.maxWidth < 800;

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 22,
              runSpacing: 22,

              children: branches.map((branch) {

                return Container(
                  width: isSmall
                      ? double.infinity
                      : 330,

                  padding: const EdgeInsets.all(25),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(24),

                    border: Border.all(
                      color: Colors.black12,
                    ),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Stack(
                    children: [

                      // ==================================================
                      // BIG NUMBER
                      // ==================================================

                      Positioned(
                        top: -8,
                        right: 0,

                        child: Text(
                          branch['number']!,
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF1F1F1),
                          ),
                        ),
                      ),

                      Column(
                        children: [

                         // ==================================================
// PREMIUM LOCATION ICON
// ==================================================

Container(
  width: 72,
  height: 72,
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    border: Border.all(
      color: Colors.black12,
      width: 1.2,
    ),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 14,
        offset: Offset(0, 5),
      ),
    ],
  ),
  child: Stack(
    alignment: Alignment.center,
    children: [

      // Outer red accent
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withOpacity(0.06),
        ),
      ),

      // Location pin
      ClipOval(
  child: Image.asset(
    'assets/google_maps_pin.png',
    width: 42,
    height: 42,
    fit: BoxFit.cover,
  ),
),
    ],
  ),
),
                            const SizedBox(height: 10),
                          

                          // ==================================================
                          // NAME
                          // ==================================================

                        Text(
  isArabic
      ? branch['nameAr']!
      : branch['nameEn']!,
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w900,
    color: Colors.black,
  ),
),

                          const SizedBox(height: 10),

                          // ==================================================
                          // ADDRESS
                          // ==================================================

                          Text(
                            isArabic
                                ? branch['addressAr']!
                                : branch['addressEn']!,

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black54,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // BUTTONS
                          // ==================================================

                          Row(
                            children: [

                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    openLink(
                                      branch['map']!,
                                    );
                                  },

                                  icon: const Icon(
                                    Icons.map_outlined,
                                    size: 17,
                                  ),

                                  label: Text(
                                    isArabic
                                        ? 'الموقع'
                                        : 'LOCATION',
                                  ),

                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(
                                            0xFF0B0B0B),

                                    foregroundColor:
                                        Colors.white,

                                    elevation: 0,

                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical: 13,
                                    ),

                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(12),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 9),

                              SizedBox(
                                width: 48,

                                child: ElevatedButton(
                                  onPressed: () {
                                    openLink(
                                      'tel:+966541577894',
                                    );
                                  },

                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.red,

                                    foregroundColor:
                                        Colors.white,

                                    elevation: 0,

                                    padding:
                                        EdgeInsets.zero,

                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(12),
                                    ),
                                  ),

                                  child: const Icon(
                                    Icons.phone_rounded,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                         ], 
                      ),
                    ],
                  ),
                );

              }).toList(),
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
